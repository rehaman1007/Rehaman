import { useMemo, useState } from "react";
import {
  Box,
  Button,
  Chip,
  CircularProgress,
  Divider,
  Drawer,
  IconButton,
  InputAdornment,
  InputBase,
  Paper,
  Stack,
  TextField,
  Tooltip,
  Typography,
} from "@mui/material";
import {
  AutoFixHigh as SampleIcon,
  CheckCircle as CheckIcon,
  Close as CloseIcon,
  Edit as EditIcon,
  RestartAlt as ResetIcon,
  Send as SendIcon,
  Sms as SmsIcon,
  Tune as GuidedIcon,
} from "@mui/icons-material";
import useApi from "../../hooks/useApi";
import useCustomSnackbar from "../../utils/useCustomSnackbar";

const SMS_URL = "/CC/communication/send-sms";
const MAX_SMS_LENGTH = Number(import.meta.env.VITE_SMS_MAX_LENGTH || 160);

const PROVIDER_ERROR_MESSAGES = {
  MESSAGE_TEMPLATE_VERIFY_FAILED:
    "This message is not allowed to send. Please verify the message as per bank guidelines.",
  10008:
    "This message is not allowed to send. Please verify the message as per bank guidelines.",
  CLI_NOT_MAPPED_WITH_TEMPLATE:
    "Sender ID (CLI) is not mapped with this template. Please verify bank template configuration.",
  10064:
    "Sender ID (CLI) is not mapped with this template. Please verify bank template configuration.",
};

const SMS_TEMPLATES = [
  {
    id: "eod_issue",
    label: "EoD Issue",
    segments: [
      { key: "dateOrTag", placeholder: "2026-06-28", type: "alphanumeric", sample: "2026-06-28" },
      " EoD had issue in ",
      { key: "module", placeholder: "module", type: "alphanumeric", sample: "abncd" },
      " at ",
      { key: "timeOrLoc", placeholder: "11:45 hrs", type: "alphanumeric", sample: "11:45 hrs" },
      ". SBI",
    ],
    regex: /^.+\sEoD had issue in\s.+\sat\s.+\.\sSBI$/,
  },
  {
    id: "eod_stats",
    label: "EoD Stats",
    segments: [
      "FINCORE EoD completed @",
      { key: "time", placeholder: "11:15", type: "alphanumeric", sample: "11:15" },
      ". Stats Balcomp New:",
      { key: "balcomp", placeholder: "453", type: "numeric", sample: "453" },
      ", Cash: ",
      { key: "cash", placeholder: "1456", type: "numeric", sample: "1456" },
      ",1260INR: ",
      { key: "inr1260", placeholder: "2478", type: "numeric", sample: "2478" },
      ",CIBA: ",
      { key: "ciba", placeholder: "45", type: "numeric", sample: "45" },
      ". SBI",
    ],
    regex:
      /^FINCORE EoD completed @.+\. Stats Balcomp New:\s*\d+,\s*Cash:\s*\d+,\s*1260INR:\s*\d+,\s*CIBA:\s*\d+\.\sSBI$/,
  },
  {
    id: "login_otp",
    label: "Login OTP",
    segments: [
      { key: "otp", placeholder: "153236", type: "numeric", sample: "153236" },
      " is your OTP for login to FinCore-SBI. This OTP is valid for ",
      { key: "mins", placeholder: "3", type: "numeric", sample: "3" },
      " mins.",
    ],
    regex:
      /^\d+\sis your OTP for login to FinCore-SBI\. This OTP is valid for \d+ mins\.$/,
  },
  {
    id: "crs_otp",
    label: "CRS OTP",
    segments: [
      { key: "otp", placeholder: "915024", type: "numeric", sample: "915024" },
      " is the OTP to be used for setting your temporary password for CRS application in SBI. This OTP is valid for ",
      { key: "mins", placeholder: "10", type: "numeric", sample: "10" },
      " minutes.",
    ],
    regex:
      /^\d+\sis the OTP to be used for setting your temporary password for CRS application in SBI\. This OTP is valid for \d+ minutes\.$/,
  },
];

function buildFromTemplate(template, vars) {
  return template.segments
    .map((seg) => (typeof seg === "string" ? seg : vars[seg.key] || ""))
    .join("");
}

function getTemplateFields(template) {
  return template.segments.filter((seg) => typeof seg !== "string");
}

function parseProviderResponse(providerResponse) {
  if (!providerResponse || typeof providerResponse !== "string") {
    return { errorCode: null, errorDesc: null, umid: null };
  }
  const params = new URLSearchParams(providerResponse);
  return {
    errorCode: params.get("error_code"),
    errorDesc: params.get("error_desc"),
    umid: params.get("umid"),
  };
}

function evaluateSmsResponse(payload) {
  const { errorCode, errorDesc } = parseProviderResponse(
    payload?.providerResponse,
  );
  const hasProviderCode = errorCode !== null && errorCode !== "";

  // Provider error_code must be "0" even when outer success flag is true
  const isSuccess =
    Boolean(payload?.success) && (!hasProviderCode || errorCode === "0");

  if (isSuccess) {
    return {
      isSuccess: true,
      snackbarMessage: payload?.message || "SMS Sent Successfully.",
    };
  }

  const mapped =
    PROVIDER_ERROR_MESSAGES[errorDesc] || PROVIDER_ERROR_MESSAGES[errorCode];

  if (mapped) {
    return { isSuccess: false, snackbarMessage: mapped };
  }

  const providerDetail = errorDesc
    ? `Failed to send SMS: ${errorDesc}${errorCode ? ` (Code: ${errorCode})` : ""}`
    : payload?.message || "Failed to send SMS.";

  return { isSuccess: false, snackbarMessage: providerDetail };
}

export default function SMSDrawer({ isOpen, setIsOpen }) {
  const { callApi } = useApi();
  const showSnackbar = useCustomSnackbar();

  const [mobileNumber, setMobileNumber] = useState("");
  const [mobileTouched, setMobileTouched] = useState(false);
  const [selectedTemplateId, setSelectedTemplateId] = useState("eod_issue");
  const [templateVars, setTemplateVars] = useState({});
  const [rawMessage, setRawMessage] = useState("");
  const [isRawMode, setIsRawMode] = useState(false);
  const [showMissingVars, setShowMissingVars] = useState(false);
  const [loading, setLoading] = useState(false);

  const selectedTemplate = useMemo(
    () => SMS_TEMPLATES.find((t) => t.id === selectedTemplateId) || null,
    [selectedTemplateId],
  );

  const isGuided = Boolean(selectedTemplate) && !isRawMode;

  const finalMessage = useMemo(() => {
    if (isGuided && selectedTemplate) {
      return buildFromTemplate(selectedTemplate, templateVars);
    }
    return rawMessage;
  }, [isGuided, selectedTemplate, templateVars, rawMessage]);

  const missingVarKeys = useMemo(() => {
    if (!isGuided || !selectedTemplate) return [];
    return getTemplateFields(selectedTemplate)
      .filter((f) => !(templateVars[f.key] || "").trim())
      .map((f) => f.key);
  }, [isGuided, selectedTemplate, templateVars]);

  const matchedTemplate = useMemo(() => {
    const trimmed = finalMessage.trim();
    if (!trimmed) return null;
    if (isGuided && missingVarKeys.length > 0) return null;
    return SMS_TEMPLATES.find((t) => t.regex.test(trimmed)) || null;
  }, [finalMessage, isGuided, missingVarKeys]);

  const isMobileValid = /^[6-9]\d{9}$/.test(mobileNumber);
  const showMobileError =
    mobileTouched && mobileNumber.length > 0 && !isMobileValid;
  const isOverLimit = finalMessage.length > MAX_SMS_LENGTH;

  const handleClose = () => {
    if (typeof setIsOpen === "function") setIsOpen(false);
  };

  const handleSelectTemplate = (templateId) => {
    setShowMissingVars(false);
    if (!templateId) {
      // Switch to pure custom mode, preserving any current text
      if (isGuided && selectedTemplate) {
        const hasValues = Object.values(templateVars).some((v) => v?.trim());
        setRawMessage(hasValues ? finalMessage : "");
      }
      setSelectedTemplateId("");
      setIsRawMode(true);
      return;
    }

    setSelectedTemplateId(templateId);
    setTemplateVars({});
    setIsRawMode(false);
  };

  const handleVarChange = (field, rawVal) => {
    const value =
      field.type === "numeric" ? rawVal.replace(/\D/g, "") : rawVal;
    setTemplateVars((prev) => ({ ...prev, [field.key]: value }));
  };

  const handleFillSample = () => {
    if (!selectedTemplate) return;
    const sampleVars = Object.fromEntries(
      getTemplateFields(selectedTemplate).map((f) => [f.key, f.sample]),
    );
    setTemplateVars(sampleVars);
    setShowMissingVars(false);
    if (isRawMode) {
      setRawMessage(buildFromTemplate(selectedTemplate, sampleVars));
    }
  };

  const handleToggleMode = () => {
    if (!selectedTemplate) return;
    if (!isRawMode) {
      setRawMessage(finalMessage);
      setIsRawMode(true);
    } else {
      setIsRawMode(false);
    }
  };

  const handleReset = () => {
    setMobileNumber("");
    setMobileTouched(false);
    setTemplateVars({});
    setRawMessage("");
    setShowMissingVars(false);
  };

  const sendSms = async () => {
    setMobileTouched(true);

    if (!isMobileValid) {
      showSnackbar("Enter a valid 10-digit Indian mobile number.", "warning");
      return;
    }

    if (isGuided && missingVarKeys.length > 0) {
      setShowMissingVars(true);
      showSnackbar("Fill all highlighted template fields before sending.", "warning");
      return;
    }

    const trimmedMessage = finalMessage.trim();
    if (!trimmedMessage) {
      showSnackbar("Enter an SMS message.", "warning");
      return;
    }

    if (trimmedMessage.length > MAX_SMS_LENGTH) {
      showSnackbar(
        `Message exceeds the ${MAX_SMS_LENGTH}-character limit.`,
        "warning",
      );
      return;
    }

    setLoading(true);
    try {
      const response = await callApi(
        SMS_URL,
        { mobileNumber, message: trimmedMessage },
        "POST",
      );
      const data = response?.data ?? response;
      const result = evaluateSmsResponse(data);

      showSnackbar(
        result.snackbarMessage,
        result.isSuccess ? "success" : "error",
      );

      if (result.isSuccess) {
        handleReset();
      }
    } catch (error) {
      const errorData = error?.response?.data;
      if (errorData?.providerResponse) {
        const result = evaluateSmsResponse(errorData);
        showSnackbar(result.snackbarMessage, "error");
      } else {
        showSnackbar(
          errorData?.message || error?.message || "Failed to send SMS.",
          "error",
        );
      }
    } finally {
      setLoading(false);
    }
  };

  const handleKeyDown = (e) => {
    if ((e.ctrlKey || e.metaKey) && e.key === "Enter" && !loading) {
      e.preventDefault();
      sendSms();
    }
  };

  return (
    <Drawer
      anchor="right"
      open={isOpen}
      onClose={handleClose}
      PaperProps={{
        sx: {
          width: { xs: "100%", sm: 440 },
          border: "none",
          display: "flex",
          flexDirection: "column",
        },
      }}
    >
      {/* Header */}
      <Box
        sx={{
          px: 2.5,
          py: 2,
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
        }}
      >
        <Stack direction="row" spacing={1.5} alignItems="center">
          <Box
            sx={{
              width: 36,
              height: 36,
              borderRadius: 2,
              bgcolor: "primary.main",
              color: "primary.contrastText",
              display: "grid",
              placeItems: "center",
            }}
          >
            <SmsIcon fontSize="small" />
          </Box>
          <Box>
            <Typography variant="subtitle1" fontWeight={800} lineHeight={1.2}>
              Send SMS
            </Typography>
            <Typography variant="caption" color="text.secondary">
              FinCore SMS Gateway
            </Typography>
          </Box>
        </Stack>
        <IconButton onClick={handleClose} size="small" aria-label="Close">
          <CloseIcon />
        </IconButton>
      </Box>

      <Divider />

      {/* Body */}
      <Box
        sx={{ flexGrow: 1, overflowY: "auto", p: 2.5 }}
        onKeyDown={handleKeyDown}
      >
        <Stack spacing={3}>
          {/* Recipient */}
          <TextField
            fullWidth
            size="medium"
            label="Recipient Mobile"
            placeholder="9876543210"
            value={mobileNumber}
            error={showMobileError}
            helperText={
              showMobileError
                ? "Enter a valid 10-digit Indian mobile number (starts with 6–9)"
                : ""
            }
            onBlur={() => setMobileTouched(true)}
            onChange={(e) =>
              setMobileNumber(e.target.value.replace(/\D/g, "").slice(0, 10))
            }
            InputProps={{
              startAdornment: (
                <InputAdornment position="start">
                  <Typography variant="body2" fontWeight={700} color="text.secondary">
                    +91
                  </Typography>
                </InputAdornment>
              ),
              endAdornment: isMobileValid ? (
                <InputAdornment position="end">
                  <CheckIcon color="success" fontSize="small" />
                </InputAdornment>
              ) : null,
            }}
          />

          {/* Quick Template Chips */}
          <Box>
            <Typography
              variant="caption"
              fontWeight={700}
              color="text.secondary"
              sx={{ mb: 1, display: "block", letterSpacing: 0.5 }}
            >
              TEMPLATE
            </Typography>
            <Stack direction="row" spacing={1} flexWrap="wrap" useFlexGap>
              {SMS_TEMPLATES.map((tpl) => {
                const active = selectedTemplateId === tpl.id;
                return (
                  <Chip
                    key={tpl.id}
                    label={tpl.label}
                    size="small"
                    clickable
                    color={active ? "primary" : "default"}
                    variant={active ? "filled" : "outlined"}
                    onClick={() => handleSelectTemplate(tpl.id)}
                    sx={{ fontWeight: active ? 700 : 500 }}
                  />
                );
              })}
              <Chip
                label="Custom"
                size="small"
                clickable
                color={!selectedTemplateId ? "primary" : "default"}
                variant={!selectedTemplateId ? "filled" : "outlined"}
                onClick={() => handleSelectTemplate("")}
                sx={{ fontWeight: !selectedTemplateId ? 700 : 500 }}
              />
            </Stack>
          </Box>

          {/* Interactive Message Composer */}
          <Paper
            variant="outlined"
            sx={{
              borderRadius: 2.5,
              overflow: "hidden",
              borderColor: isOverLimit ? "error.main" : "divider",
              transition: "border-color 0.2s ease",
              "&:focus-within": {
                borderColor: isOverLimit ? "error.main" : "primary.main",
                boxShadow: (theme) =>
                  `0 0 0 1px ${
                    isOverLimit
                      ? theme.palette.error.main
                      : theme.palette.primary.main
                  }`,
              },
            }}
          >
            {/* Composer Toolbar */}
            <Box
              sx={{
                px: 1.75,
                py: 1,
                bgcolor: "action.hover",
                display: "flex",
                justifyContent: "space-between",
                alignItems: "center",
                borderBottom: "1px solid",
                borderColor: "divider",
              }}
            >
              <Typography variant="caption" fontWeight={700} color="text.secondary">
                {selectedTemplate
                  ? isRawMode
                    ? `${selectedTemplate.label} • Raw Edit`
                    : `${selectedTemplate.label} • Fill blanks`
                  : "Custom Message"}
              </Typography>

              <Stack direction="row" spacing={0.5}>
                {selectedTemplate && (
                  <>
                    <Tooltip title="Fill sample values">
                      <Button
                        size="small"
                        startIcon={<SampleIcon sx={{ fontSize: 15 }} />}
                        onClick={handleFillSample}
                        sx={{ minWidth: 0, px: 1, fontSize: "0.75rem", textTransform: "none" }}
                      >
                        Sample
                      </Button>
                    </Tooltip>
                    <Tooltip
                      title={
                        isRawMode
                          ? "Switch back to fill-in-the-blanks"
                          : "Edit full SMS text freely"
                      }
                    >
                      <Button
                        size="small"
                        color="inherit"
                        startIcon={
                          isRawMode ? (
                            <GuidedIcon sx={{ fontSize: 15 }} />
                          ) : (
                            <EditIcon sx={{ fontSize: 15 }} />
                          )
                        }
                        onClick={handleToggleMode}
                        sx={{ minWidth: 0, px: 1, fontSize: "0.75rem", textTransform: "none" }}
                      >
                        {isRawMode ? "Guided" : "Raw"}
                      </Button>
                    </Tooltip>
                  </>
                )}
              </Stack>
            </Box>

            {/* Composer Surface */}
            <Box sx={{ p: 2, minHeight: 150, bgcolor: "background.paper" }}>
              {isGuided && selectedTemplate ? (
                <Box
                  sx={{
                    fontSize: "0.95rem",
                    lineHeight: 2.35,
                    color: "text.primary",
                    wordBreak: "break-word",
                  }}
                >
                  {selectedTemplate.segments.map((seg, idx) => {
                    if (typeof seg === "string") {
                      return <span key={idx}>{seg}</span>;
                    }

                    const val = templateVars[seg.key] || "";
                    const isMissing = showMissingVars && !val.trim();
                    const charWidth = Math.max(
                      val.length,
                      seg.placeholder.length,
                      4,
                    );

                    return (
                      <Box
                        key={seg.key}
                        component="input"
                        type="text"
                        inputMode={seg.type === "numeric" ? "numeric" : "text"}
                        placeholder={seg.placeholder}
                        value={val}
                        onChange={(e) => handleVarChange(seg, e.target.value)}
                        sx={{
                          display: "inline-block",
                          font: "inherit",
                          fontWeight: 600,
                          lineHeight: 1.4,
                          px: 1,
                          py: 0.25,
                          mx: 0.25,
                          width: `${charWidth + 2.5}ch`,
                          maxWidth: "100%",
                          borderRadius: 1.25,
                          border: "1.5px solid",
                          borderColor: isMissing
                            ? "error.main"
                            : val
                              ? "primary.light"
                              : "divider",
                          bgcolor: isMissing
                            ? "error.lighter"
                            : val
                              ? "action.selected"
                              : "action.hover",
                          color: "text.primary",
                          outline: "none",
                          transition: "all 0.15s ease",
                          "&::placeholder": {
                            color: "text.disabled",
                            fontWeight: 400,
                          },
                          "&:focus": {
                            borderColor: "primary.main",
                            bgcolor: "background.paper",
                            boxShadow: (theme) =>
                              `0 0 0 2px ${theme.palette.primary.main}22`,
                          },
                        }}
                      />
                    );
                  })}
                </Box>
              ) : (
                <InputBase
                  fullWidth
                  multiline
                  minRows={5}
                  placeholder="Type or paste your SMS message here..."
                  value={rawMessage}
                  onChange={(e) => setRawMessage(e.target.value)}
                  sx={{
                    fontSize: "0.95rem",
                    lineHeight: 1.6,
                    alignItems: "flex-start",
                  }}
                />
              )}
            </Box>

            {/* Composer Footer */}
            <Box
              sx={{
                px: 1.75,
                py: 0.85,
                borderTop: "1px solid",
                borderColor: "divider",
                display: "flex",
                justifyContent: "space-between",
                alignItems: "center",
                bgcolor: "background.default",
              }}
            >
              <Stack direction="row" spacing={0.75} alignItems="center">
                <Box
                  sx={{
                    width: 8,
                    height: 8,
                    borderRadius: "50%",
                    bgcolor: matchedTemplate
                      ? "success.main"
                      : finalMessage.trim()
                        ? "warning.main"
                        : "text.disabled",
                  }}
                />
                <Typography variant="caption" color="text.secondary">
                  {matchedTemplate
                    ? "Approved format"
                    : isGuided && missingVarKeys.length > 0
                      ? `${missingVarKeys.length} blank${missingVarKeys.length > 1 ? "s" : ""} remaining`
                      : finalMessage.trim()
                        ? "Custom format"
                        : "Ready"}
                </Typography>
              </Stack>

              <Typography
                variant="caption"
                fontWeight={isOverLimit ? 700 : 500}
                color={isOverLimit ? "error.main" : "text.secondary"}
              >
                {finalMessage.length} / {MAX_SMS_LENGTH}
              </Typography>
            </Box>
          </Paper>
        </Stack>
      </Box>

      <Divider />

      {/* Sticky Footer */}
      <Box
        sx={{
          px: 2.5,
          py: 2,
          display: "flex",
          gap: 1.25,
          alignItems: "center",
        }}
      >
        <Tooltip title="Clear inputs">
          <span>
            <IconButton
              onClick={handleReset}
              disabled={loading}
              sx={{
                border: "1px solid",
                borderColor: "divider",
                borderRadius: 2,
              }}
            >
              <ResetIcon fontSize="small" />
            </IconButton>
          </span>
        </Tooltip>

        <Button
          fullWidth
          size="large"
          variant="contained"
          onClick={sendSms}
          disabled={loading || !isMobileValid || !finalMessage.trim() || isOverLimit}
          startIcon={
            loading ? (
              <CircularProgress size={18} color="inherit" />
            ) : (
              <SendIcon />
            )
          }
          sx={{ borderRadius: 2, fontWeight: 700, textTransform: "none" }}
        >
          {loading ? "Sending..." : "Send SMS"}
        </Button>
      </Box>
    </Drawer>
  );
}