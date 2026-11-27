import { useMemo, useState } from "react";
import {
  Alert,
  AlertTitle,
  Box,
  Button,
  Chip,
  CircularProgress,
  Collapse,
  Divider,
  Drawer,
  IconButton,
  InputAdornment,
  LinearProgress,
  MenuItem,
  Paper,
  Stack,
  TextField,
  ToggleButton,
  ToggleButtonGroup,
  Tooltip,
  Typography,
} from "@mui/material";
import {
  AutoFixHigh as SampleIcon,
  CheckCircleOutline as ValidIcon,
  Close as CloseIcon,
  ContentCopy as CopyIcon,
  RestartAlt as ResetIcon,
  Send as SendIcon,
  Sms as SmsIcon,
  WarningAmber as WarningIcon,
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
    "Sender ID (CLI) is not mapped with this template. Verify the template and environment configuration.",
  10064:
    "Sender ID (CLI) is not mapped with this template. Verify the template and environment configuration.",
};

const SMS_TEMPLATES = [
  {
    id: "eod_issue",
    label: "EoD Issue Alert",
    pattern:
      "{#alphanumeric#} EoD had issue in {#alphanumeric#} at {#alphanumeric#}. SBI",
    fields: [
      { key: "dateOrTag", label: "Date / Reference", type: "alphanumeric", sample: "2026-06-28" },
      { key: "module", label: "Issue Area / Module", type: "alphanumeric", sample: "abncd" },
      { key: "timeOrLoc", label: "Time / Location", type: "alphanumeric", sample: "11:45 hrs" },
    ],
    build: (v) =>
      `${v.dateOrTag || "{#alphanumeric#}"} EoD had issue in ${v.module || "{#alphanumeric#}"} at ${v.timeOrLoc || "{#alphanumeric#}"}. SBI`,
    regex: /^.+\sEoD had issue in\s.+\sat\s.+\.\sSBI$/,
  },
  {
    id: "fincore_eod_completed",
    label: "FINCORE EoD Completed",
    pattern:
      "FINCORE EoD completed @{#alphanumeric#}. Stats Balcomp New:{#numeric#}, Cash: {#numeric#},1260INR: {#numeric#},CIBA: {#numeric#}. SBI",
    fields: [
      { key: "time", label: "Completed Time", type: "alphanumeric", sample: "11:15" },
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
    pattern:
      "{#numeric#} is your OTP for login to FinCore-SBI. This OTP is valid for {#numeric#} mins.",
    fields: [
      { key: "otp", label: "OTP", type: "numeric", sample: "153236" },
      { key: "mins", label: "Validity (mins)", type: "numeric", sample: "3" },
    ],
    build: (v) =>
      `${v.otp || "{#numeric#}"} is your OTP for login to FinCore-SBI. This OTP is valid for ${v.mins || "{#numeric#}"} mins.`,
    regex:
      /^\d+\sis your OTP for login to FinCore-SBI\. This OTP is valid for \d+ mins\.$/,
  },
  {
    id: "crs_temp_password_otp",
    label: "CRS Temporary Password OTP",
    pattern:
      "{#numeric#} is the OTP to be used for setting your temporary password for CRS application in SBI. This OTP is valid for {#numeric#} minutes.",
    fields: [
      { key: "otp", label: "OTP", type: "numeric", sample: "915024" },
      { key: "mins", label: "Validity (minutes)", type: "numeric", sample: "10" },
    ],
    build: (v) =>
      `${v.otp || "{#numeric#}"} is the OTP to be used for setting your temporary password for CRS application in SBI. This OTP is valid for ${v.mins || "{#numeric#}"} minutes.`,
    regex:
      /^\d+\sis the OTP to be used for setting your temporary password for CRS application in SBI\. This OTP is valid for \d+ minutes\.$/,
  },
];

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
  const { errorCode, errorDesc, umid } = parseProviderResponse(
    payload?.providerResponse,
  );
  const hasProviderCode = errorCode !== null && errorCode !== "";

  // Provider error_code must be "0" even when API wrapper returns success: true
  const isSuccess =
    Boolean(payload?.success) && (!hasProviderCode || errorCode === "0");

  if (isSuccess) {
    return {
      isSuccess: true,
      title: payload?.message || "SMS Sent Successfully",
      description:
        errorDesc === "MESSAGE_SUBMIT_SUCCESS"
          ? "Message accepted by the SMS gateway."
          : "SMS request submitted successfully.",
      errorCode: errorCode || "0",
      errorDesc,
      umid,
    };
  }

  const mappedMessage =
    PROVIDER_ERROR_MESSAGES[errorDesc] || PROVIDER_ERROR_MESSAGES[errorCode];

  const fallbackReason =
    errorDesc || payload?.message || "Unknown provider error";

  return {
    isSuccess: false,
    title: "Failed to Send SMS",
    description: mappedMessage || `Provider rejected SMS: ${fallbackReason}`,
    errorCode,
    errorDesc,
    umid,
  };
}

export default function SMSDrawer({ isOpen, setIsOpen }) {
  const { callApi } = useApi();
  const showSnackbar = useCustomSnackbar();

  const [mobileNumber, setMobileNumber] = useState("");
  const [mobileTouched, setMobileTouched] = useState(false);
  const [env, setEnv] = useState("UAT");
  const [selectedTemplateId, setSelectedTemplateId] = useState("");
  const [templateVars, setTemplateVars] = useState({});
  const [message, setMessage] = useState("");
  const [loading, setLoading] = useState(false);
  const [statusResult, setStatusResult] = useState(null);

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
  const showMobileError = mobileTouched && mobileNumber.length > 0 && !isMobileValid;
  const charPercent = Math.min((message.length / MAX_SMS_LENGTH) * 100, 100);
  const hasUnfilledPlaceholders = /\{#(alphanumeric|numeric)#\}/.test(message);

  const handleClose = () => {
    if (typeof setIsOpen === "function") {
      setIsOpen(false);
    }
  };

  const handleTemplateSelect = (templateId) => {
    setSelectedTemplateId(templateId);
    setStatusResult(null);

    const template = SMS_TEMPLATES.find((t) => t.id === templateId);
    if (!template) {
      setTemplateVars({});
      return;
    }

    const emptyVars = Object.fromEntries(template.fields.map((f) => [f.key, ""]));
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
    setStatusResult(null);
  };

  const handleReset = () => {
    setMobileNumber("");
    setMobileTouched(false);
    setSelectedTemplateId("");
    setTemplateVars({});
    setMessage("");
    setStatusResult(null);
  };

  const handleCopyUmid = async (umid) => {
    try {
      await navigator.clipboard.writeText(umid);
      showSnackbar("UMID copied to clipboard.", "info");
    } catch {
      showSnackbar("Unable to copy UMID.", "warning");
    }
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
      showSnackbar("Replace all template placeholders before sending.", "warning");
      return;
    }

    setLoading(true);
    setStatusResult(null);

    try {
      const payload = {
        mobileNumber,
        message: message.trim(),
        env,
      };
      const response = await callApi(SMS_URL, payload, "POST");
      const data = response?.data ?? response;
      const result = evaluateSmsResponse(data);

      setStatusResult(result);

      if (result.isSuccess) {
        showSnackbar(result.title, "success");
        setMobileNumber("");
        setMobileTouched(false);
        setMessage("");
        setSelectedTemplateId("");
        setTemplateVars({});
      } else {
        showSnackbar(result.description, "error");
      }
    } catch (error) {
      const errorData = error?.response?.data;
      const result = errorData?.providerResponse
        ? evaluateSmsResponse(errorData)
        : {
            isSuccess: false,
            title: "Failed to Send SMS",
            description:
              errorData?.message ||
              error?.message ||
              "Network or server error while sending SMS.",
            errorCode: error?.response?.status ? String(error.response.status) : null,
            errorDesc: null,
            umid: null,
          };

      setStatusResult(result);
      showSnackbar(result.description, "error");
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
          width: { xs: "100%", sm: 480 },
          border: "none",
          display: "flex",
          flexDirection: "column",
        },
      }}
    >
      {/* Header */}
      <Box
        sx={{
          px: 3,
          py: 2.25,
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          bgcolor: "background.paper",
        }}
      >
        <Stack direction="row" spacing={1.5} alignItems="center">
          <Box
            sx={{
              p: 1,
              borderRadius: 2,
              bgcolor: "primary.main",
              color: "primary.contrastText",
              display: "flex",
            }}
          >
            <SmsIcon fontSize="small" />
          </Box>
          <Box>
            <Typography variant="h6" fontWeight={800} lineHeight={1.2}>
              SMS Utility
            </Typography>
            <Typography variant="caption" color="text.secondary">
              Send DLT-verified SMS through FinCore
            </Typography>
          </Box>
        </Stack>
        <IconButton onClick={handleClose} aria-label="Close SMS drawer">
          <CloseIcon />
        </IconButton>
      </Box>

      <Divider />

      {/* Scrollable Body */}
      <Box sx={{ flexGrow: 1, overflowY: "auto", p: { xs: 2, sm: 3 } }}>
        <Stack spacing={2.5}>
          {/* Live Result Feedback */}
          <Collapse in={Boolean(statusResult)}>
            {statusResult && (
              <Alert
                severity={statusResult.isSuccess ? "success" : "error"}
                onClose={() => setStatusResult(null)}
                sx={{ borderRadius: 2 }}
              >
                <AlertTitle sx={{ fontWeight: 700 }}>
                  {statusResult.title}
                </AlertTitle>
                <Typography variant="body2">{statusResult.description}</Typography>

                {(statusResult.errorCode ||
                  statusResult.errorDesc ||
                  statusResult.umid) && (
                  <Stack
                    direction="row"
                    spacing={1}
                    flexWrap="wrap"
                    useFlexGap
                    sx={{ mt: 1.25 }}
                    alignItems="center"
                  >
                    {statusResult.errorCode && (
                      <Chip
                        size="small"
                        variant="outlined"
                        color={statusResult.isSuccess ? "success" : "error"}
                        label={`Code: ${statusResult.errorCode}`}
                      />
                    )}
                    {statusResult.errorDesc && (
                      <Chip
                        size="small"
                        variant="outlined"
                        label={statusResult.errorDesc}
                        sx={{ maxWidth: "100%" }}
                      />
                    )}
                    {statusResult.umid && (
                      <Tooltip title="Copy UMID">
                        <Chip
                          size="small"
                          icon={<CopyIcon fontSize="small" />}
                          label={`UMID: ${statusResult.umid.slice(0, 14)}…`}
                          onClick={() => handleCopyUmid(statusResult.umid)}
                          clickable
                        />
                      </Tooltip>
                    )}
                  </Stack>
                )}
              </Alert>
            )}
          </Collapse>

          {/* Environment Toggle */}
          <Box>
            <Typography
              variant="caption"
              fontWeight={700}
              color="text.secondary"
              sx={{ mb: 0.75, display: "block", textTransform: "uppercase" }}
            >
              Environment
            </Typography>
            <ToggleButtonGroup
              fullWidth
              exclusive
              size="small"
              value={env}
              onChange={(_, nextEnv) => {
                if (nextEnv) setEnv(nextEnv);
              }}
            >
              {["DEV", "UAT", "PROD"].map((item) => (
                <ToggleButton
                  key={item}
                  value={item}
                  color={item === "PROD" ? "error" : "primary"}
                  sx={{ fontWeight: 700 }}
                >
                  {item}
                </ToggleButton>
              ))}
            </ToggleButtonGroup>

            <Collapse in={env === "PROD"}>
              <Alert severity="warning" sx={{ mt: 1, py: 0.5, borderRadius: 1.5 }}>
                Production mode sends live SMS messages to real recipients.
              </Alert>
            </Collapse>
          </Box>

          {/* Mobile Number */}
          <TextField
            fullWidth
            label="Mobile Number"
            placeholder="9876543210"
            value={mobileNumber}
            error={showMobileError}
            helperText={
              showMobileError
                ? "Must be a 10-digit Indian number starting with 6–9."
                : `${mobileNumber.length}/10 digits`
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

          {/* Approved Template Picker */}
          <TextField
            select
            fullWidth
            label="Bank Template (Optional)"
            value={selectedTemplateId}
            onChange={(e) => handleTemplateSelect(e.target.value)}
            helperText="Select a template to fill variables, or type a custom message below."
          >
            <MenuItem value="">Custom / Manual Message</MenuItem>
            {SMS_TEMPLATES.map((template) => (
              <MenuItem key={template.id} value={template.id}>
                {template.label}
              </MenuItem>
            ))}
          </TextField>

          {/* Dynamic Variable Editor */}
          <Collapse in={Boolean(selectedTemplate)}>
            {selectedTemplate && (
              <Paper
                variant="outlined"
                sx={{ p: 2, borderRadius: 2, bgcolor: "action.hover" }}
              >
                <Stack
                  direction="row"
                  justifyContent="space-between"
                  alignItems="center"
                  sx={{ mb: 1.5 }}
                >
                  <Typography variant="subtitle2" fontWeight={700}>
                    Template Variables
                  </Typography>
                  <Button
                    size="small"
                    startIcon={<SampleIcon />}
                    onClick={handleFillSample}
                  >
                    Fill Sample
                  </Button>
                </Stack>

                <Stack spacing={1.5}>
                  {selectedTemplate.fields.map((field) => (
                    <TextField
                      key={field.key}
                      size="small"
                      fullWidth
                      label={field.label}
                      placeholder={`e.g. ${field.sample}`}
                      value={templateVars[field.key] || ""}
                      onChange={(e) => handleVarChange(field, e.target.value)}
                      inputProps={{
                        inputMode: field.type === "numeric" ? "numeric" : "text",
                      }}
                      sx={{ bgcolor: "background.paper" }}
                    />
                  ))}
                </Stack>
              </Paper>
            )}
          </Collapse>

          {/* Editable SMS Message Box */}
          <Box>
            <Stack
              direction="row"
              justifyContent="space-between"
              alignItems="center"
              sx={{ mb: 0.75 }}
            >
              <Typography variant="caption" fontWeight={700} color="text.secondary">
                MESSAGE CONTENT
              </Typography>
              {message.trim() && (
                <Chip
                  size="small"
                  icon={
                    matchedTemplate ? (
                      <ValidIcon fontSize="small" />
                    ) : (
                      <WarningIcon fontSize="small" />
                    )
                  }
                  color={matchedTemplate ? "success" : "warning"}
                  variant="outlined"
                  label={
                    matchedTemplate
                      ? `Matches: ${matchedTemplate.label}`
                      : "Unverified format (may fail bank check)"
                  }
                />
              )}
            </Stack>

            <TextField
              fullWidth
              multiline
              minRows={4}
              placeholder="Select a template above or enter your SMS message..."
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              inputProps={{ maxLength: MAX_SMS_LENGTH }}
              error={hasUnfilledPlaceholders}
              helperText={
                hasUnfilledPlaceholders
                  ? "Fill all {#alphanumeric#} / {#numeric#} placeholders before sending."
                  : `${message.length}/${MAX_SMS_LENGTH} characters`
              }
            />

            <LinearProgress
              variant="determinate"
              value={charPercent}
              color={
                charPercent > 90
                  ? "error"
                  : charPercent > 75
                    ? "warning"
                    : "primary"
              }
              sx={{ mt: 0.75, height: 5, borderRadius: 4 }}
            />
          </Box>
        </Stack>
      </Box>

      <Divider />

      {/* Sticky Action Footer */}
      <Box
        sx={{
          px: 3,
          py: 2,
          bgcolor: "background.paper",
          display: "flex",
          gap: 1.5,
        }}
      >
        <Button
          variant="outlined"
          color="inherit"
          startIcon={<ResetIcon />}
          onClick={handleReset}
          disabled={loading}
        >
          Reset
        </Button>
        <Button
          fullWidth
          variant="contained"
          color={env === "PROD" ? "error" : "primary"}
          onClick={sendSms}
          disabled={loading || !isMobileValid || !message.trim()}
          startIcon={
            loading ? (
              <CircularProgress size={18} color="inherit" />
            ) : (
              <SendIcon />
            )
          }
        >
          {loading ? "Sending..." : `Send SMS (${env})`}
        </Button>
      </Box>
    </Drawer>
  );
}