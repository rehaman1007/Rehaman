import React, { useState } from "react";
import {
  Box,
  Tabs,
  Tab,
  TextField,
  Button,
  Select,
  MenuItem,
  InputLabel,
  FormControl,
  Typography,
  Paper,
  Snackbar,
  Alert,
  IconButton,
  CircularProgress,
  Stack,
  Divider,
  useMediaQuery,
  useTheme,
  Fade,
} from "@mui/material";
import SendIcon from "@mui/icons-material/Send";
import EmailIcon from "@mui/icons-material/Email";
import SmartphoneIcon from "@mui/icons-material/Smartphone";
import AddIcon from "@mui/icons-material/Add";
import DeleteIcon from "@mui/icons-material/Delete";
import axios from "axios";

const API_BASE = "xyz";
const isValidMobile = (num) => xyz.test(num);
const isValidEmail = (email) => xyz.test(email);

export default function CommunicationScreen() {
  const [tab, setTab] = useState(0);
  const [snackbar, setSnackbar] = useState({
    open: false,
    severity: "success",
    msg: "",
  });

  const showSnackbar = (severity, msg) =>
    setSnackbar({ open: true, severity, msg });

  return (
    <Box
      sx={{
        minHeight: "100vh",
        bgcolor: "grey.50",
        display: "flex",
        justifyContent: "center",
        alignItems: "flex-start",
        p: { xs: 1, sm: 3, md: 4 },
      }}
    >
      <Paper
        elevation={3}
        sx={{
          width: "100%",
          maxWidth: 560,
          borderRadius: 3,
          p: { xs: 2, sm: 3, md: 4 },
          mt: { xs: 0, sm: 2 },
        }}
      >
        <Stack direction="row" alignItems="center" spacing={1} mb={2}>
          <SendIcon color="primary" />
          <Typography variant="h5" fontWeight={700}>
            Communication Console
          </Typography>
        </Stack>

        <Divider sx={{ mb: 2 }} />

        <Tabs
          value={tab}
          onChange={(_, v) => setTab(v)}
          variant="fullWidth"
          sx={{ mb: 3 }}
        >
          <Tab
            icon={<SmartphoneIcon />}
            iconPosition="start"
            label="Send SMS"
          />
          <Tab icon={<EmailIcon />} iconPosition="start" label="Send Mail" />
        </Tabs>

        <Fade in={tab === 0}>
          <SmsForm showSnackbar={showSnackbar} />
        </Fade>
        <Fade in={tab === 1}>
          <MailForm showSnackbar={showSnackbar} />
        </Fade>
      </Paper>

      <Snackbar
        open={snackbar.open}
        autoHideDuration={4000}
        onClose={() => setSnackbar((s) => ({ ...s, open: false }))}
        anchorOrigin={{ vertical: "bottom", horizontal: "center" }}
      >
        <Alert
          severity={snackbar.severity}
          variant="filled"
          onClose={() => setSnackbar((s) => ({ ...s, open: false }))}
        >
          {snackbar.msg}
        </Alert>
      </Snackbar>
    </Box>
  );
}

function SmsForm({ showSnackbar }) {
  const [mobile, setMobile] = useState("");
  const [message, setMessage] = useState("");
  const [env, setEnv] = useState("DEV");
  const [errors, setErrors] = useState({});
  const [loading, setLoading] = useState(false);
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down("sm"));

  const validate = () => {
    const e = {};
    if (!mobile) e.mobile = "Mobile number is required";
    else if (!isValidMobile(mobile))
      e.mobile = "Must be 10 digits starting with 6-9";
    if (!message.trim()) e.message = "Message is required";
    setErrors(e);
    return !Object.keys(e).length;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!validate()) return;
    setLoading(true);
    try {
      const res = await axios.post(`${API_BASE}/send-sms`, {
        mobileNumber: mobile,
        message,
        env,
      });
      showSnackbar("success", res.data.message || "SMS sent successfully");
      setMobile("");
      setMessage("");
    } catch (err) {
      showSnackbar(
        "error",
        err.response?.data?.message || "Failed to send SMS",
      );
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      <Stack spacing={2}>
        <TextField
          label="Mobile Number"
          type="tel"
          value={mobile}
          onChange={(e) =>
            setMobile(e.target.value.replace(/\D/g, "").slice(0, 10))
          }
          error={!!errors.mobile}
          helperText={errors.mobile}
          placeholder="9876543210"
          fullWidth
          inputProps={{ maxLength: 10 }}
        />

        <TextField
          label="Message"
          multiline
          minRows={3}
          value={message}
          onChange={(e) => setMessage(e.target.value)}
          error={!!errors.message}
          helperText={errors.message}
          placeholder="12345 is your OTP..."
          fullWidth
        />

        <FormControl fullWidth>
          <InputLabel>Environment</InputLabel>
          <Select
            value={env}
            label="Environment"
            onChange={(e) => setEnv(e.target.value)}
          >
            <MenuItem value="DEV">DEV</MenuItem>
            <MenuItem value="UAT">UAT</MenuItem>
            <MenuItem value="PROD">PROD</MenuItem>
          </Select>
        </FormControl>

        <Button
          type="submit"
          variant="contained"
          color="primary"
          startIcon={
            loading ? (
              <CircularProgress size={18} color="inherit" />
            ) : (
              <SendIcon />
            )
          }
          disabled={loading}
          fullWidth
          size={isMobile ? "medium" : "large"}
          sx={{ py: 1.2 }}
        >
          {loading ? "Sending..." : "Send SMS"}
        </Button>
      </Stack>
    </form>
  );
}

function MailForm({ showSnackbar }) {
  const [toEmail, setToEmail] = useState("");
  const [templateId, setTemplateId] = useState("");
  const [placeholders, setPlaceholders] = useState([{ key: "", value: "" }]);
  const [errors, setErrors] = useState({});
  const [loading, setLoading] = useState(false);
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down("sm"));

  const validate = () => {
    const e = {};
    if (!toEmail) e.toEmail = "Recipient email is required";
    else if (!isValidEmail(toEmail)) e.toEmail = "Invalid email format";
    if (!templateId) e.templateId = "Template ID is required";
    if (!placeholders.some((p) => p.key && p.value))
      e.placeholders = "At least one placeholder is required";
    setErrors(e);
    return !Object.keys(e).length;
  };

  const updatePh = (i, field, val) => {
    const next = [...placeholders];
    next[i][field] = val;
    setPlaceholders(next);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!validate()) return;
    setLoading(true);
    try {
      const phMap = {};
      placeholders.forEach((p) => {
        if (p.key && p.value) phMap[p.key] = p.value;
      });
      const res = await axios.post(`${API_BASE}/send-mail`, {
        recipientMail: toEmail,
        templateID: templateId,
        placeHolders: phMap,
        eventType: "MANUAL_TEST",
      });
      showSnackbar("success", res.data.message || "Mail sent successfully");
      setToEmail("");
      setTemplateId("");
      setPlaceholders([{ key: "", value: "" }]);
    } catch (err) {
      showSnackbar(
        "error",
        err.response?.data?.message || "Failed to send mail",
      );
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      <Stack spacing={2}>
        <TextField
          label="To (Email)"
          type="email"
          value={toEmail}
          onChange={(e) => setToEmail(e.target.value)}
          error={!!errors.toEmail}
          helperText={errors.toEmail}
          placeholder="user@example.com"
          fullWidth
        />

        <TextField
          label="Template ID"
          value={templateId}
          onChange={(e) => setTemplateId(e.target.value)}
          error={!!errors.templateId}
          helperText={errors.templateId}
          placeholder="OTP_LOGIN"
          fullWidth
        />

        <Box>
          <Typography variant="subtitle2" gutterBottom>
            Placeholders
          </Typography>
          {errors.placeholders && (
            <Typography color="error" variant="caption" display="block" mb={1}>
              {errors.placeholders}
            </Typography>
          )}
          <Stack spacing={1}>
            {placeholders.map((ph, i) => (
              <Stack key={i} direction="row" spacing={1} alignItems="center">
                <TextField
                  label="Key"
                  size={isMobile ? "small" : "medium"}
                  value={ph.key}
                  onChange={(e) => updatePh(i, "key", e.target.value)}
                  placeholder="otp"
                  fullWidth
                />
                <TextField
                  label="Value"
                  size={isMobile ? "small" : "medium"}
                  value={ph.value}
                  onChange={(e) => updatePh(i, "value", e.target.value)}
                  placeholder="153236"
                  fullWidth
                />
                {placeholders.length > 1 && (
                  <IconButton
                    onClick={() =>
                      setPlaceholders(
                        placeholders.filter((_, idx) => idx !== i),
                      )
                    }
                    color="error"
                    size="small"
                  >
                    <DeleteIcon fontSize="small" />
                  </IconButton>
                )}
              </Stack>
            ))}
          </Stack>
          <Button
            startIcon={<AddIcon />}
            onClick={() =>
              setPlaceholders([...placeholders, { key: "", value: "" }])
            }
            sx={{ mt: 1 }}
            color="primary"
            size="small"
          >
            Add Placeholder
          </Button>
        </Box>

        <Button
          type="submit"
          variant="contained"
          color="primary"
          startIcon={
            loading ? (
              <CircularProgress size={18} color="inherit" />
            ) : (
              <EmailIcon />
            )
          }
          disabled={loading}
          fullWidth
          size={isMobile ? "medium" : "large"}
          sx={{ py: 1.2 }}
        >
          {loading ? "Sending..." : "Send Mail"}
        </Button>
      </Stack>
    </form>
  );
}
