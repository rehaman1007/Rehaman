{
  "templateId": "FINCORE_CUSTOM_MAIL_V1",
  "toEmail": "recipient@sbi.co.in",
  "templateData": {
    "mailSubject": "Monthly GL Reconciliation Reminder",
    "recipientName": "Ananya Sharma",
    "mailBody": "Please complete the GL verification before 5:00 PM today.\n\nThe summary sheet is attached for reference.",
    "senderName": "FinCore Operations Desk",
    "senderDesignation": "General Ledger Administration"
  }
}



private static final long MAX_ATTACHMENT_BYTES = 5L * 1024 * 1024; // 5 MB
private static final Set<String> ALLOWED_EXTENSIONS = Set.of(
        "pdf", "xlsx", "xls", "csv", "doc", "docx", "txt", "png", "jpg", "jpeg"
);

@PostMapping(value = "/send-custom-mail", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
public ResponseEntity<EmailResponse> sendCustomMail(
        @RequestPart("payload") String payloadJson,
        @RequestPart(value = "attachment", required = false) MultipartFile attachment) throws IOException {

    Map<String, Object> map = objectMapper.readValue(payloadJson, new TypeReference<>() {});
    String templateId = Objects.toString(map.get("templateId"), "FINCORE_CUSTOM_MAIL_V1");
    String toEmail = Objects.toString(map.get("toEmail"), "").trim();

    @SuppressWarnings("unchecked")
    List<String> bccEmails = (List<String>) map.get("bccEmails");

    @SuppressWarnings("unchecked")
    Map<String, Object> templateData = (Map<String, Object>) map.get("templateData");

    Resource attachmentResource = null;
    if (attachment != null && !attachment.isEmpty()) {
        validateAttachment(attachment);

        String originalFilename = Objects.requireNonNullElse(attachment.getOriginalFilename(), "attachment");
        byte[] fileBytes = attachment.getBytes();

        // Re-readable Resource safe for @Retry
        attachmentResource = new ByteArrayResource(fileBytes) {
            @Override
            public String getFilename() {
                return originalFilename;
            }
        };
    }

    log.info("Sending Custom Mail | templateId={} | toEmail={} | hasAttachment={}",
            templateId, toEmail, attachmentResource != null);

    EmailResponse response = emailService.sendEmail(
            templateId, toEmail, bccEmails, templateData, attachmentResource
    );
    return ResponseEntity.ok(response);
}

private void validateAttachment(MultipartFile file) {
    if (file.getSize() > MAX_ATTACHMENT_BYTES) {
        throw new IllegalArgumentException("Attachment exceeds the maximum allowed size of 5 MB.");
    }
    String filename = Objects.requireNonNullElse(file.getOriginalFilename(), "");
    String ext = filename.contains(".")
            ? filename.substring(filename.lastIndexOf('.') + 1).toLowerCase(Locale.ROOT)
            : "";
    if (!ALLOWED_EXTENSIONS.contains(ext)) {
        throw new IllegalArgumentException("Unsupported attachment type: ." + ext);
    }
}



@Override
@Retry(name = "bankApiRetry", fallbackMethod = "handleTotalApiFailure")
@CircuitBreaker(name = "bankApiCircuit", fallbackMethod = "handleTotalApiFailure")
public EmailResponse sendEmail(String templateId, String toEmail, List<String> bccEmails,
                               Map<String, Object> templateData, Resource attachment) {
    return executeEmailDispatch(templateId, toEmail, bccEmails, templateData, attachment);
}


String subject = templateService.getTemplateSubject(templateId, "EMAIL", "EN");
if (templateData != null && templateData.get("mailSubject") != null
        && !templateData.get("mailSubject").toString().isBlank()) {
    subject = templateData.get("mailSubject").toString().trim();
}



import { useRef, useState } from "react";
import {
  Alert,
  Box,
  Button,
  Chip,
  Divider,
  Drawer,
  IconButton,
  Paper,
  Stack,
  TextField,
  Typography,
} from "@mui/material";
import {
  AttachFile as AttachFileIcon,
  Close as CloseIcon,
  DeleteOutline as DeleteOutlineIcon,
  Send as SendIcon,
} from "@mui/icons-material";
import useApi from "../../hooks/useApi";
import useCustomSnackbar from "../../utils/useCustomSnackbar";

const CUSTOM_MAIL_URL = "/CC/communication/send-custom-mail";
const TEMPLATE_ID = "FINCORE_CUSTOM_MAIL_V1";

// Keep in sync with backend limits
const MAX_FILE_SIZE_MB = 5;
const MAX_FILE_SIZE_BYTES = MAX_FILE_SIZE_MB * 1024 * 1024;
const ALLOWED_EXTENSIONS = [
  "pdf",
  "xlsx",
  "xls",
  "csv",
  "doc",
  "docx",
  "txt",
  "png",
  "jpg",
  "jpeg",
];
const ACCEPT_ATTR = ALLOWED_EXTENSIONS.map((ext) => `.${ext}`).join(",");

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

const formatBytes = (bytes) => {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(2)} MB`;
};

const INITIAL_FORM = {
  toEmail: "",
  bccEmails: "",
  recipientName: "",
  mailSubject: "",
  mailBody: "",
  senderName: "FinCore System Team",
  senderDesignation: "General Ledger Administration",
};

export default function CustomMailDrawer({ isOpen, onClose }) {
  const { callApi } = useApi();
  const showSnackbar = useCustomSnackbar();
  const fileInputRef = useRef(null);

  const [form, setForm] = useState(INITIAL_FORM);
  const [attachment, setAttachment] = useState(null);
  const [fileError, setFileError] = useState("");
  const [loading, setLoading] = useState(false);

  const handleFieldChange = (field) => (e) => {
    setForm((prev) => ({ ...prev, [field]: e.target.value }));
  };

  const handleFileSelect = (e) => {
    const file = e.target.files?.[0];
    // Reset input value so selecting the same file again still triggers onChange
    e.target.value = "";
    if (!file) return;

    setFileError("");

    const ext = file.name.includes(".")
      ? file.name.split(".").pop().toLowerCase()
      : "";

    if (!ALLOWED_EXTENSIONS.includes(ext)) {
      const msg = `Unsupported file type (.${ext || "unknown"}). Allowed: ${ALLOWED_EXTENSIONS.join(", ")}.`;
      setFileError(msg);
      showSnackbar(msg, "warning");
      return;
    }

    if (file.size === 0) {
      const msg = "Selected file is empty.";
      setFileError(msg);
      showSnackbar(msg, "warning");
      return;
    }

    if (file.size > MAX_FILE_SIZE_BYTES) {
      const msg = `File "${file.name}" is ${formatBytes(file.size)}. Maximum allowed size is ${MAX_FILE_SIZE_MB} MB.`;
      setFileError(msg);
      showSnackbar(msg, "warning");
      return;
    }

    setAttachment(file);
  };

  const removeAttachment = () => {
    setAttachment(null);
    setFileError("");
  };

  const resetForm = () => {
    setForm(INITIAL_FORM);
    setAttachment(null);
    setFileError("");
  };

  const handleSendMail = async () => {
    const toEmail = form.toEmail.trim();
    if (!EMAIL_REGEX.test(toEmail)) {
      showSnackbar("Enter a valid recipient email address.", "warning");
      return;
    }

    const bccList = form.bccEmails
      .split(",")
      .map((s) => s.trim())
      .filter(Boolean);

    const invalidBcc = bccList.find((mail) => !EMAIL_REGEX.test(mail));
    if (invalidBcc) {
      showSnackbar(`Invalid BCC email: ${invalidBcc}`, "warning");
      return;
    }

    if (!form.mailSubject.trim()) {
      showSnackbar("Enter an email subject.", "warning");
      return;
    }

    if (!form.mailBody.trim()) {
      showSnackbar("Paste or enter the email body content.", "warning");
      return;
    }

    if (attachment && attachment.size > MAX_FILE_SIZE_BYTES) {
      showSnackbar(
        `Attachment exceeds the ${MAX_FILE_SIZE_MB} MB limit.`,
        "warning"
      );
      return;
    }

    setLoading(true);
    try {
      const payload = {
        templateId: TEMPLATE_ID,
        toEmail,
        bccEmails: bccList.length ? bccList : null,
        templateData: {
          mailSubject: form.mailSubject.trim(),
          recipientName: form.recipientName.trim() || "User",
          mailBody: form.mailBody.trim(),
          senderName: form.senderName.trim() || "FinCore System Team",
          senderDesignation: form.senderDesignation.trim(),
        },
      };

      const formData = new FormData();
      formData.append("payload", JSON.stringify(payload));
      if (attachment) {
        formData.append("attachment", attachment);
      }

      // Note: Do NOT manually set Content-Type for FormData if using Axios/fetch;
      // the browser sets the multipart boundary automatically.
      await callApi(CUSTOM_MAIL_URL, formData);

      showSnackbar("Custom mail sent successfully.", "success");
      resetForm();
      onClose?.();
    } catch (error) {
      showSnackbar(
        error.response?.data?.message || "Failed to send custom mail.",
        "error"
      );
    } finally {
      setLoading(false);
    }
  };

  return (
    <Drawer
      anchor="right"
      open={isOpen}
      onClose={() => !loading && onClose?.()}
      PaperProps={{
        sx: {
          width: { xs: "100%", sm: 500 },
          border: "none",
        },
      }}
    >
      <Box sx={{ height: "100%", display: "flex", flexDirection: "column" }}>
        {/* Header with FinCore purple accent */}
        <Box
          sx={{
            p: 2.5,
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
            background:
              "linear-gradient(135deg, #faf7ff 0%, #f3e9ff 55%, #e9d5ff 100%)",
          }}
        >
          <Box>
            <Typography variant="h6" fontWeight={800} sx={{ color: "#4c1d95" }}>
              FinCore Custom Mail
            </Typography>
            <Typography variant="caption" color="text.secondary">
              Sends branded FinCore email with signature &amp; do-not-reply notice
            </Typography>
          </Box>
          <IconButton
            onClick={onClose}
            disabled={loading}
            aria-label="Close drawer"
          >
            <CloseIcon />
          </IconButton>
        </Box>

        <Divider />

        {/* Form Content */}
        <Box sx={{ flexGrow: 1, overflowY: "auto", p: 2.5 }}>
          <Stack spacing={2}>
            <TextField
              label="To Email"
              required
              fullWidth
              size="small"
              placeholder="recipient@sbi.co.in"
              value={form.toEmail}
              onChange={handleFieldChange("toEmail")}
            />

            <TextField
              label="BCC Emails (optional)"
              fullWidth
              size="small"
              placeholder="user1@sbi.co.in, user2@sbi.co.in"
              helperText="Separate multiple addresses with commas"
              value={form.bccEmails}
              onChange={handleFieldChange("bccEmails")}
            />

            <TextField
              label="Recipient Name (Greeting)"
              fullWidth
              size="small"
              placeholder="Defaults to 'User' if left blank"
              value={form.recipientName}
              onChange={handleFieldChange("recipientName")}
            />

            <TextField
              label="Subject"
              required
              fullWidth
              size="small"
              value={form.mailSubject}
              onChange={handleFieldChange("mailSubject")}
            />

            <TextField
              label="Email Body"
              required
              fullWidth
              multiline
              minRows={6}
              maxRows={12}
              placeholder="Paste or type your message here. Line breaks and paragraphs are preserved automatically..."
              value={form.mailBody}
              onChange={handleFieldChange("mailBody")}
            />

            {/* Signature Section */}
            <Divider textAlign="left">
              <Typography variant="caption" color="text.secondary" fontWeight={700}>
                SIGNATURE
              </Typography>
            </Divider>

            <Stack direction={{ xs: "column", sm: "row" }} spacing={1.5}>
              <TextField
                label="Sender / Team Name"
                fullWidth
                size="small"
                value={form.senderName}
                onChange={handleFieldChange("senderName")}
              />
              <TextField
                label="Designation / Dept"
                fullWidth
                size="small"
                value={form.senderDesignation}
                onChange={handleFieldChange("senderDesignation")}
              />
            </Stack>

            {/* Attachment Section */}
            <Divider textAlign="left">
              <Typography variant="caption" color="text.secondary" fontWeight={700}>
                ATTACHMENT (MAX {MAX_FILE_SIZE_MB} MB)
              </Typography>
            </Divider>

            <input
              ref={fileInputRef}
              type="file"
              hidden
              accept={ACCEPT_ATTR}
              onChange={handleFileSelect}
            />

            {!attachment ? (
              <Button
                variant="outlined"
                startIcon={<AttachFileIcon />}
                onClick={() => fileInputRef.current?.click()}
                disabled={loading}
                sx={{
                  borderStyle: "dashed",
                  borderColor: "#7c3aed",
                  color: "#5b21b6",
                  py: 1.25,
                }}
              >
                Attach File (PDF, Excel, CSV, Word, Image — max {MAX_FILE_SIZE_MB} MB)
              </Button>
            ) : (
              <Paper
                variant="outlined"
                sx={{
                  p: 1.5,
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "space-between",
                  gap: 1,
                  bgcolor: "#faf7ff",
                  borderColor: "#c4b5fd",
                }}
              >
                <Box sx={{ minWidth: 0 }}>
                  <Typography variant="body2" fontWeight={600} noWrap>
                    {attachment.name}
                  </Typography>
                  <Chip
                    label={formatBytes(attachment.size)}
                    size="small"
                    sx={{ mt: 0.5, height: 20, fontSize: "0.7rem" }}
                  />
                </Box>
                <IconButton
                  size="small"
                  color="error"
                  onClick={removeAttachment}
                  disabled={loading}
                  aria-label="Remove attachment"
                >
                  <DeleteOutlineIcon fontSize="small" />
                </IconButton>
              </Paper>
            )}

            {fileError && (
              <Alert severity="error" onClose={() => setFileError("")}>
                {fileError}
              </Alert>
            )}

            <Alert severity="info" variant="outlined" sx={{ py: 0.5 }}>
              A <strong>FinCore branded header</strong>, your signature, and a{" "}
              <strong>system-generated do-not-reply</strong> footer are appended automatically.
            </Alert>
          </Stack>
        </Box>

        <Divider />

        {/* Sticky Footer Actions */}
        <Box
          sx={{
            p: 2,
            display: "flex",
            justifyContent: "flex-end",
            gap: 1.5,
            bgcolor: "background.paper",
          }}
        >
          <Button onClick={resetForm} disabled={loading} color="inherit">
            Clear
          </Button>
          <Button
            variant="contained"
            startIcon={<SendIcon />}
            onClick={handleSendMail}
            disabled={loading}
            sx={{
              bgcolor: "#7c3aed",
              "&:hover": { bgcolor: "#6d28d9" },
            }}
          >
            {loading ? "Sending..." : "Send Mail"}
          </Button>
        </Box>
      </Box>
    </Drawer>
  );
}