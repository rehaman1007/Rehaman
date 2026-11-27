import { useMemo, useState } from "react";
import {
  Box,
  Button,
  CircularProgress,
  Collapse,
  Divider,
  Drawer,
  IconButton,
  InputAdornment,
  Stack,
  TextField,
  ToggleButton,
  Typography,
} from "@mui/material";
import {
  CheckCircleOutline as ValidIcon,
  Close as CloseIcon,
  Send as SendIcon,
} from "@mui/icons-material";
import useApi from "../../hooks/useApi";
import useCustomSnackbar from "../../utils/useCustomSnackbar";

const SMS_URL = "/CC/communication/send-sms";
const MAX_SMS_LENGTH = Number(import.meta.env.VITE_SMS_MAX_LENGTH || 160);

const PROVIDER_ERROR_MESSAGES = {
  MESSAGE_TEMPLATE_VERIFY_FAILED:
    "This message is not allowed to send. Please verify the message template as per bank guidelines.",
  10008:
    "This message is not allowed to send. Please verify the message template as per bank guidelines.",
  CLI_NOT_MAPPED_WITH_TEMPLATE:
    "Sender ID (CLI) is not mapped with this template. Verify the template and environment configuration.",
  10064:
    "Sender ID (CLI) is not mapped with this template. Verify the template and environment configuration.",
};

const SMS_TEMPLATES = [
  {
    id: "eod_issue",
    label: "EoD Issue Alert",
    fields: [
      { key: "dateOrTag", label: "Date / Ref", type: "alphanumeric", sample: "2026-06-28" },
      { key: "timeOrLoc", label: "Time / Location", type: "alphanumeric", sample: "11:45 hrs" },
      { key: "module", label: "Issue Area / Module", type: "alphanumeric", sample: "abncd", fullWidth: true },
    ],
    build: (v) =>
      `${v.dateOrTag || "{#alphanumeric#}"} EoD had issue in ${v.module || "{#alphanumeric#}"} at ${v.timeOrLoc || "{#alphanumeric#}"}. SBI`,
    regex: /^.+\sEoD had issue in\s.+\sat\s.+\.\sSBI$/,
  },
  {
    id: "fincore_eod_completed",
    label: "FINCORE EoD Completed",
    fields: [
      { key: "time", label: "Completed Time", type: "alphanumeric", sample: "11:15", fullWidth: true },
      { key: "balcomp", label: "Balcomp New", type: "numeric", sample: "453" },
      { key: "cash", label: "Cash", type: "numeric", sample: "1456" },
      { key: "inr1260", label: "1260INR", type: "numeric", sample: "2478" },
      { key: "ciba", label: "CIBA", type: "numeric", sample: "45" },
    ],
    build: (v) =>
      `FINCORE EoD completed @${v.time || "{#alphanumeric#}"}. Stats Balcomp New:${v.balcomp || "{#numeric#}"}, Cash: ${v.cash || "{#numeric#}"},1260INR: ${v.inr1260 || "{#numeric#}"},CIBA: ${v.ciba || "{#numeric#}"}. SBI`,
    regex:
      /^FINCORE EoD completed @.+\. Stats Balcomp New:\s*\d+,\s*Cash:\s*\d+,\s*1260INR:\s*\d+,\s*CIBA:\s*\d+\.\sSBI$/,
  },
  {
    id: "fincore_login_otp",
    label: "FinCore Login OTP",
    fields: [
      { key: "otp", label: "OTP", type: "numeric", sample: "153236" },
      { key: "mins", label: "Validity (mins)", type: "numeric", sample: "3" },
    ],
    build: (v) =>
      `${v.otp || "{#numeric#}"} is your OTP for login to FinCore-SBI. This OTP is valid for ${v.mins || "{#numeric#}"} mins.`,
    regex:
      /^\d+\sis your OTP for login to FinCore-SBI\. This OTP is valid for \d+ mins\.$/,
  },
  // {
  //   id: "crs_temp_password_otp",
  //   label: "CRS Temp Password OTP",
  //   fields: [
  //     { key: "otp", label: "OTP", type: "numeric", sample: "915024" },
  //     { key: "mins", label: "Validity (minutes)", type: "numeric", sample: "10" },
  //   ],
  //   build: (v) =>
  //     `${v.otp || "{#numeric#}"} is the OTP to be used for setting your temporary password for CRS application in SBI. This OTP is valid for ${v.mins || "{#numeric#}"} minutes.`,
  //   regex:
  //     /^\d+\sis the OTP to be used for setting your temporary password for CRS application in SBI\. This OTP is valid for \d+ minutes\.$/,
  // },
];

const toggleButtonSx = {
  py: 1,
  px: 1.25,
  textTransform: "none",
  fontWeight: 500,
  fontSize: "0.82rem",
  border: "1px solid",
  borderColor: "divider",
  borderRadius: 1.5,
  justifyContent: "center",
  "&.Mui-selected": {
    bgcolor: "primary.main",
    color: "primary.contrastText",
    borderColor: "primary.main",
    fontWeight: 600,
    "&:hover": { bgcolor: "primary.dark" },
  },
};

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

  // Provider error_code must be "0" even when API wrapper returns success: true
  const isSuccess =
    Boolean(payload?.success) && (!hasProviderCode || errorCode === "0");

  if (isSuccess) {
    return {
      isSuccess: true,
      message: payload?.message || "SMS Sent Successfully.",
    };
  }

  const mapped =
    PROVIDER_ERROR_MESSAGES[errorDesc] || PROVIDER_ERROR_MESSAGES[errorCode];
  const fallback = errorDesc
    ? `Failed to send SMS: ${errorDesc}`
    : payload?.message || "Failed to send SMS.";

  return {
    isSuccess: false,
    message: mapped || fallback,
  };
}

export default function SMSDrawer({ isOpen, setIsOpen }) {
  const { callApi } = useApi();
  const showSnackbar = useCustomSnackbar();

  const env = "UAT";
  const [mobileNumber, setMobileNumber] = useState("");
  const [mobileTouched, setMobileTouched] = useState(false);
  const [selectedTemplateId, setSelectedTemplateId] = useState("");
  const [templateVars, setTemplateVars] = useState({});
  const [message, setMessage] = useState("");
  const [loading, setLoading] = useState(false);

  const selectedTemplate = useMemo(
    () => SMS_TEMPLATES.find((t) => t.id === selectedTemplateId) || null,
    [selectedTemplateId],
  );

  const matchedTemplate = useMemo(() => {
    const trimmed = message.trim();
    if (!trimmed || trimmed.includes("{#")) return null;
    return SMS_TEMPLATES.find((t) => t.regex.test(trimmed)) || null;
  }, [message]);

  const isMobileValid = /^[6-9]\d{9}$/.test(mobileNumber);
  const showMobileError =
    mobileTouched && mobileNumber.length > 0 && !isMobileValid;
  const hasUnfilledPlaceholders = /\{#(alphanumeric|numeric)#\}/.test(message);

  const handleClose = () => {
    if (typeof setIsOpen === "function") setIsOpen(false);
  };

  const handleTemplateSelect = (templateId) => {
    setSelectedTemplateId(templateId);

    const template = SMS_TEMPLATES.find((t) => t.id === templateId);
    if (!template) {
      setTemplateVars({});
      if (hasUnfilledPlaceholders) setMessage("");
      return;
    }

    const emptyVars = Object.fromEntries(
      template.fields.map((f) => [f.key, ""]),
    );
    setTemplateVars(emptyVars);
    setMessage(template.build(emptyVars));
  };

  const handleVarChange = (field, rawValue) => {
    const value =
      field.type === "numeric" ? rawValue.replace(/\D/g, "") : rawValue;
    const nextVars = { ...templateVars, [field.key]: value };
    setTemplateVars(nextVars);
    if (selectedTemplate) {
      setMessage(selectedTemplate.build(nextVars).slice(0, MAX_SMS_LENGTH));
    }
  };

  const handleFillSample = () => {
    if (!selectedTemplate) return;
    const sampleVars = Object.fromEntries(
      selectedTemplate.fields.map((f) => [f.key, f.sample]),
    );
    setTemplateVars(sampleVars);
    setMessage(selectedTemplate.build(sampleVars).slice(0, MAX_SMS_LENGTH));
  };

  const handleReset = () => {
    setMobileNumber("");
    setMobileTouched(false);
    setSelectedTemplateId("");
    setTemplateVars({});
    setMessage("");
  };

  const sendSms = async () => {
    setMobileTouched(true);

    if (!isMobileValid) {
      showSnackbar("Enter a valid 10-digit Indian mobile number.", "warning");
      return;
    }
    if (!message.trim()) {
      showSnackbar("Enter an SMS message.", "warning");
      return;
    }
    if (hasUnfilledPlaceholders) {
      showSnackbar(
        "Replace all template placeholders before sending.",
        "warning",
      );
      return;
    }

    setLoading(true);
    try {
      const response = await callApi(
        SMS_URL,
        { mobileNumber, message: message.trim(), env },
        "POST",
      );
      const data = response?.data ?? response;
      const result = evaluateSmsResponse(data);

      showSnackbar(result.message, result.isSuccess ? "success" : "error");
      if (result.isSuccess) handleReset();
    } catch (error) {
      const errorData = error?.response?.data;
      const errMsg = errorData?.providerResponse
        ? evaluateSmsResponse(errorData).message
        : errorData?.message ||
          error?.message ||
          "Network or server error while sending SMS.";
      showSnackbar(errMsg, "error");
    } finally {
      setLoading(false);
    }
  };

  return (
    <Drawer
      anchor="right"
      open={isOpen}
      onClose={handleClose}
      PaperProps={{
        sx: {
          width: { xs: "100%", sm: 420 },
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
        <Box>
          <Typography variant="subtitle1" fontWeight={700} lineHeight={1.2}>
            SMS Utility
          </Typography>
          <Typography variant="caption" color="text.secondary">
            Send DLT-verified SMS through FinCore
          </Typography>
        </Box>
        <IconButton size="small" onClick={handleClose} aria-label="Close">
          <CloseIcon fontSize="small" />
        </IconButton>
      </Box>

      <Divider />

      {/* Body */}
      <Box sx={{ flexGrow: 1, overflowY: "auto", p: 2.5 }}>
        <Stack spacing={2.5}>
          {/* Mobile Number */}
          <TextField
            fullWidth
            size="small"
            label="Mobile Number"
            placeholder="9876543210"
            value={mobileNumber}
            error={showMobileError}
            helperText={
              showMobileError
                ? "Enter a valid 10-digit Indian number (starts with 6–9)"
                : ""
            }
            onBlur={() => setMobileTouched(true)}
            onChange={(e) =>
              setMobileNumber(e.target.value.replace(/\D/g, "").slice(0, 10))
            }
            InputProps={{
              startAdornment: (
                <InputAdornment position="start">+91</InputAdornment>
              ),
              endAdornment: isMobileValid ? (
                <InputAdornment position="end">
                  <ValidIcon color="success" fontSize="small" />
                </InputAdornment>
              ) : null,
            }}
          />

          {/* Template Grid */}
          <Box>
            <Typography
              variant="caption"
              fontWeight={600}
              color="text.secondary"
              sx={{ mb: 1, display: "block" }}
            >
              Template
            </Typography>
            <Box
              sx={{
                display: "grid",
                gridTemplateColumns: "1fr 1fr",
                gap: 1,
              }}
            >
              <ToggleButton
                value=""
                selected={selectedTemplateId === ""}
                onClick={() => handleTemplateSelect("")}
                fullWidth
                sx={toggleButtonSx}
              >
                Custom
              </ToggleButton>

              {SMS_TEMPLATES.map((t) => (
                <ToggleButton
                  key={t.id}
                  value={t.id}
                  selected={selectedTemplateId === t.id}
                  onClick={() => handleTemplateSelect(t.id)}
                  fullWidth
                  sx={toggleButtonSx}
                >
                  {t.label}
                </ToggleButton>
              ))}
            </Box>
          </Box>

          {/* Compact Template Variables */}
          <Collapse in={Boolean(selectedTemplate)}>
            {selectedTemplate && (
              <Box
                sx={{
                  p: 1.75,
                  borderRadius: 2,
                  border: "1px solid",
                  borderColor: "divider",
                  bgcolor: "action.hover",
                }}
              >
                <Stack
                  direction="row"
                  justifyContent="space-between"
                  alignItems="center"
                  sx={{ mb: 1.25 }}
                >
                  <Typography
                    variant="caption"
                    fontWeight={600}
                    color="text.secondary"
                  >
                    Fill Variables
                  </Typography>
                  <Button
                    size="small"
                    onClick={handleFillSample}
                    sx={{
                      minWidth: 0,
                      p: 0,
                      fontSize: "0.75rem",
                      textTransform: "none",
                    }}
                  >
                    Fill sample
                  </Button>
                </Stack>

                <Box
                  sx={{
                    display: "grid",
                    gridTemplateColumns: "1fr 1fr",
                    gap: 1.25,
                  }}
                >
                  {selectedTemplate.fields.map((field) => (
                    <TextField
                      key={field.key}
                      size="small"
                      label={field.label}
                      placeholder={field.sample}
                      value={templateVars[field.key] || ""}
                      onChange={(e) => handleVarChange(field, e.target.value)}
                      inputProps={{
                        inputMode:
                          field.type === "numeric" ? "numeric" : "text",
                      }}
                      sx={{
                        gridColumn: field.fullWidth ? "1 / -1" : "auto",
                        bgcolor: "background.paper",
                        borderRadius: 1,
                      }}
                    />
                  ))}
                </Box>
              </Box>
            )}
          </Collapse>

          {/* Message Box */}
          <Box>
            <TextField
              fullWidth
              multiline
              minRows={4}
              label="Message"
              placeholder="Select a template above or type your SMS..."
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              inputProps={{ maxLength: MAX_SMS_LENGTH }}
              error={hasUnfilledPlaceholders}
            />

            <Stack
              direction="row"
              justifyContent="space-between"
              alignItems="center"
              sx={{ mt: 0.75, px: 0.5 }}
            >
              <Typography
                variant="caption"
                color={
                  hasUnfilledPlaceholders
                    ? "error.main"
                    : matchedTemplate
                      ? "success.main"
                      : "text.secondary"
                }
              >
                {hasUnfilledPlaceholders
                  ? "Fill all template placeholders"
                  : matchedTemplate
                    ? `Matches ${matchedTemplate.label}`
                    : message.trim()
                      ? "Custom format"
                      : ""}
              </Typography>

              <Typography variant="caption" color="text.secondary">
                {message.length}/{MAX_SMS_LENGTH}
              </Typography>
            </Stack>
          </Box>
        </Stack>
      </Box>

      <Divider />

      {/* Footer */}
      <Box sx={{ px: 2.5, py: 2, display: "flex", gap: 1.25 }}>
        <Button
          fullWidth
          variant="outlined"
          color="inherit"
          onClick={handleReset}
          disabled={loading}
          sx={{ textTransform: "none" }}
        >
          Reset
        </Button>
        <Button
          fullWidth
          variant="contained"
          disableElevation
          onClick={sendSms}
          disabled={loading || !isMobileValid || !message.trim()}
          startIcon={
            loading ? (
              <CircularProgress size={16} color="inherit" />
            ) : (
              <SendIcon fontSize="small" />
            )
          }
          sx={{ textTransform: "none" }}
        >
          {loading ? "Sending..." : "Send"}
        </Button>
      </Box>
    </Drawer>
  );
}