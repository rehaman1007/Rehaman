export const MAIL_LIMITS = {
  GREETING_MAX: 80,
  SUBJECT_MIN: 3,
  SUBJECT_MAX: 150,
  BODY_MIN: 10,
  BODY_MAX: 5000,
  MAX_CC_COUNT: 10,
  MAX_FILES: 3,
  MAX_FILE_SIZE_MB: 5,
  MAX_TOTAL_SIZE_MB: 10,
  ALLOWED_EXTENSIONS: [
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
  ],
};

export const MAX_FILE_SIZE_BYTES = MAIL_LIMITS.MAX_FILE_SIZE_MB * 1024 * 1024;
export const MAX_TOTAL_SIZE_BYTES = MAIL_LIMITS.MAX_TOTAL_SIZE_MB * 1024 * 1024;

// Strict RFC-aligned email regex (blocks consecutive dots, missing TLD, spaces)
export const EMAIL_REGEX =
  /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;

// Strips invisible control chars, zero-width chars, replacement chars, and non-BMP emojis/junk
const CONTROL_AND_JUNK_REGEX =
  /[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F-\u009F\u200B-\u200F\u2028-\u202F\uFEFF\uFFFD]/g;

// Only standard safe characters for Greeting (e.g., "Dr. Ananya Sharma", "GL Ops Team")
const GREETING_DISALLOWED_REGEX = /[^a-zA-Z0-9 .,'&()/-]/g;

// Safe printable ASCII + common currency/punctuation for Subject
const SUBJECT_DISALLOWED_REGEX = /[^a-zA-Z0-9 .,;:!?'"()[\]{}&@#$%*+\-/_₹]/g;

// Safe printable ASCII + line breaks + common punctuation for Body
const BODY_DISALLOWED_REGEX = /[^a-zA-Z0-9 \t\r\n.,;:!?'"()[\]{}&@#$%*+\-/_=|₹]/g;

export const isValidEmail = (email) => EMAIL_REGEX.test(email.trim());

/**
 * Live input sanitizer (safe during typing: collapses double spaces without trimming trailing single space).
 */
export const sanitizeOnType = (value, type) => {
  if (!value) return "";
  let cleaned = value.replace(CONTROL_AND_JUNK_REGEX, "");

  if (type === "greeting") {
    cleaned = cleaned
      .replace(GREETING_DISALLOWED_REGEX, "")
      .replace(/[ \t]{2,}/g, " ")
      .slice(0, MAIL_LIMITS.GREETING_MAX);
  } else if (type === "subject") {
    cleaned = cleaned
      .replace(SUBJECT_DISALLOWED_REGEX, "")
      .replace(/[ \t]{2,}/g, " ")
      .slice(0, MAIL_LIMITS.SUBJECT_MAX);
  } else if (type === "body") {
    cleaned = cleaned
      .replace(/\r\n/g, "\n")
      .replace(/\r/g, "\n")
      .replace(BODY_DISALLOWED_REGEX, "")
      .replace(/[ \t]{2,}/g, " ")
      .replace(/\n{3,}/g, "\n\n")
      .slice(0, MAIL_LIMITS.BODY_MAX);
  }

  return cleaned;
};

/**
 * Final sanitizer on blur / before submit (trims edges and cleans per-line trailing spaces).
 */
export const sanitizeFinal = (value, type) => {
  const cleaned = sanitizeOnType(value, type);
  if (type === "body") {
    return cleaned
      .split("\n")
      .map((line) => line.trim())
      .join("\n")
      .replace(/\n{3,}/g, "\n\n")
      .trim();
  }
  return cleaned.trim();
};

export const formatBytes = (bytes) => {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(2)} MB`;
};

export const getFileExtension = (filename = "") =>
  filename.includes(".") ? filename.split(".").pop().toLowerCase() : "";

/**
 * Validates incoming files (from picker or drag-and-drop) against count, extension, per-file size, and total size.
 */
export const validateIncomingFiles = (incomingFiles, existingFiles) => {
  const accepted = [];
  const errors = [];

  let currentCount = existingFiles.length;
  let currentTotalBytes = existingFiles.reduce((sum, f) => sum + f.size, 0);

  for (const file of incomingFiles) {
    if (currentCount >= MAIL_LIMITS.MAX_FILES) {
      errors.push(`Maximum ${MAIL_LIMITS.MAX_FILES} attachments allowed.`);
      break;
    }

    const isDuplicate =
      existingFiles.some((f) => f.name === file.name && f.size === file.size) ||
      accepted.some((f) => f.name === file.name && f.size === file.size);

    if (isDuplicate) {
      errors.push(`"${file.name}" is already attached.`);
      continue;
    }

    const ext = getFileExtension(file.name);
    if (!MAIL_LIMITS.ALLOWED_EXTENSIONS.includes(ext)) {
      errors.push(
        `"${file.name}" has an unsupported type (.${ext || "unknown"}).`
      );
      continue;
    }

    if (file.size === 0) {
      errors.push(`"${file.name}" is empty (0 B).`);
      continue;
    }

    if (file.size > MAX_FILE_SIZE_BYTES) {
      errors.push(
        `"${file.name}" (${formatBytes(file.size)}) exceeds the ${MAIL_LIMITS.MAX_FILE_SIZE_MB} MB per-file limit.`
      );
      continue;
    }

    if (currentTotalBytes + file.size > MAX_TOTAL_SIZE_BYTES) {
      errors.push(
        `Adding "${file.name}" exceeds the ${MAIL_LIMITS.MAX_TOTAL_SIZE_MB} MB total attachment limit.`
      );
      continue;
    }

    accepted.push(file);
    currentCount += 1;
    currentTotalBytes += file.size;
  }

  return { accepted, errors };
};

export const escapeHtml = (str = "") =>
  str
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");



import { useMemo, useRef, useState } from "react";
import {
  Alert,
  Box,
  Button,
  Chip,
  Divider,
  Drawer,
  IconButton,
  InputBase,
  LinearProgress,
  Paper,
  Stack,
  Tooltip,
  Typography,
} from "@mui/material";
import {
  AttachFile as AttachFileIcon,
  Close as CloseIcon,
  CloseFullscreen as CloseFullscreenIcon,
  CloudUpload as CloudUploadIcon,
  DeleteOutline as DeleteOutlineIcon,
  Description as DescriptionIcon,
  Edit as EditIcon,
  Image as ImageIcon,
  InsertDriveFile as InsertDriveFileIcon,
  OpenInFull as OpenInFullIcon,
  PictureAsPdf as PictureAsPdfIcon,
  Send as SendIcon,
  TableChart as TableChartIcon,
  Visibility as VisibilityIcon,
} from "@mui/icons-material";
import useApi from "../../hooks/useApi";
import useCustomSnackbar from "../../utils/useCustomSnackbar";
import {
  escapeHtml,
  formatBytes,
  getFileExtension,
  isValidEmail,
  MAIL_LIMITS,
  MAX_TOTAL_SIZE_BYTES,
  sanitizeFinal,
  sanitizeOnType,
  validateIncomingFiles,
} from "../../utils/mailValidation";

const CUSTOM_MAIL_URL = "/CC/communication/send-custom-mail";
const TEMPLATE_ID = "FINCORE_CUSTOM_MAIL_V1";
const ACCEPT_ATTR = MAIL_LIMITS.ALLOWED_EXTENSIONS.map((e) => `.${e}`).join(",");

const getFileIcon = (filename) => {
  const ext = getFileExtension(filename);
  if (ext === "pdf") return <PictureAsPdfIcon fontSize="small" sx={{ color: "#dc2626" }} />;
  if (["xlsx", "xls", "csv"].includes(ext))
    return <TableChartIcon fontSize="small" sx={{ color: "#16a34a" }} />;
  if (["png", "jpg", "jpeg"].includes(ext))
    return <ImageIcon fontSize="small" sx={{ color: "#2563eb" }} />;
  if (["doc", "docx", "txt"].includes(ext))
    return <DescriptionIcon fontSize="small" sx={{ color: "#4f46e5" }} />;
  return <InsertDriveFileIcon fontSize="small" sx={{ color: "#6b7280" }} />;
};

const buildPreviewHtml = ({ greeting, subject, body }) => {
  const safeGreeting = escapeHtml(greeting || "User");
  const safeSubject = escapeHtml(subject || "FinCore Notification");
  const safeBody = escapeHtml(body || "Your email body will appear here...").replace(
    /\n/g,
    "<br/>"
  );

  return `<!doctype html>
<html lang="en">
<head><meta charset="UTF-8" /><title>${safeSubject}</title></head>
<body style="margin:0;padding:18px 12px;background:#ffffff;font-family:'Times New Roman',Times,serif;">
  <table width="100%" cellpadding="0" cellspacing="0" border="0">
    <tr><td align="center">
      <div style="position:relative;width:100%;max-width:780px;overflow:hidden;margin:auto;border-radius:26px;background:radial-gradient(circle at top right,rgba(128,0,255,0.32) 0%,rgba(128,0,255,0.2) 25%,rgba(156,92,255,0.14) 48%,transparent 72%),linear-gradient(135deg,#faf7ff 0%,#f3e9ff 18%,#e9d5ff 40%,#d8b7ff 62%,#c08dff 82%,#9c63ff 100%);">
        <div style="position:relative;z-index:2;padding:20px 24px 28px 24px;">
          <table cellpadding="0" cellspacing="0" border="0" style="margin-bottom:14px;">
            <tr>
              <td valign="middle">
                <img src="https://fincore.sbi/assets/Fincore_transperent-CuH99SR4.svg" alt="FinCore" style="display:block;width:72px;height:72px;" />
              </td>
              <td width="10"></td>
              <td valign="middle">
                <img src="https://fincore.sbi/assets/Fincore_title-Hef-qsF5.png" alt="FinCore" style="display:block;width:125px;height:auto;padding-top:10px;" />
                <div style="font-size:11px;opacity:0.8;font-weight:700;padding-top:6px;">Insight Driven General Ledger</div>
              </td>
            </tr>
          </table>
          <div style="background:rgba(255,255,255,0.42);backdrop-filter:blur(20px);border:1px solid rgba(255,255,255,0.5);border-radius:22px;padding:30px 34px;color:#111;box-shadow:0 8px 32px rgba(31,38,135,0.15);">
            <div style="font-size:19px;font-weight:bold;margin-bottom:16px;">Dear ${safeGreeting},</div>
            <div style="font-size:15px;line-height:24px;margin-bottom:24px;word-break:break-word;">${safeBody}</div>
            <div style="margin-top:20px;padding-top:16px;border-top:1px solid rgba(124,58,237,0.18);font-size:15px;line-height:22px;color:#1f1f1f;">
              <div>Warm regards,</div>
              <div style="font-weight:700;margin-top:6px;color:#3b0764;">FinCore System Team</div>
              <div style="font-size:13px;color:#444;">FinCore — Insight Driven General Ledger | State Bank of India</div>
            </div>
            <div style="margin-top:20px;padding:12px 14px;background:rgba(255,255,255,0.55);border:1px solid rgba(124,58,237,0.22);border-left:4px solid #7c3aed;border-radius:10px;font-size:12.5px;line-height:18px;color:#4a3b5c;">
              <strong>Note:</strong> This is a system-generated email from <strong>FinCore</strong>. Please <strong>do not reply</strong> to this message. For assistance, contact the FinCore Support Desk.
            </div>
            <div style="margin-top:22px;padding-top:14px;border-top:1px solid rgba(0,0,0,0.08);color:#555;font-size:12.5px;text-align:center;">
              © 2026 State Bank of India. All rights reserved.
            </div>
          </div>
        </div>
      </div>
    </td></tr>
  </table>
</body>
</html>`;
};

export default function CustomMailDrawer({ isOpen, onClose }) {
  const { callApi } = useApi();
  const showSnackbar = useCustomSnackbar();

  const fileInputRef = useRef(null);
  const dragCounterRef = useRef(0);

  // Composer state
  const [toEmail, setToEmail] = useState("");
  const [showCc, setShowCc] = useState(false);
  const [ccList, setCcList] = useState([]);
  const [ccInput, setCcInput] = useState("");
  const [greeting, setGreeting] = useState("");
  const [subject, setSubject] = useState("");
  const [body, setBody] = useState("");
  const [attachments, setAttachments] = useState([]);

  // UI & validation state
  const [errors, setErrors] = useState({});
  const [fileErrors, setFileErrors] = useState([]);
  const [isDragging, setIsDragging] = useState(false);
  const [expanded, setExpanded] = useState(false);
  const [previewMode, setPreviewMode] = useState(false);
  const [loading, setLoading] = useState(false);

  const totalAttachmentBytes = useMemo(
    () => attachments.reduce((sum, f) => sum + f.size, 0),
    [attachments]
  );

  const storagePercent = Math.min(
    100,
    Math.round((totalAttachmentBytes / MAX_TOTAL_SIZE_BYTES) * 100)
  );

  const clearFieldError = (field) => {
    setErrors((prev) => {
      if (!prev[field]) return prev;
      const next = { ...prev };
      delete next[field];
      return next;
    });
  };

  // --- CC Chip Handling (Gmail/Outlook style) ---
  const commitCcInput = (rawText) => {
    const tokens = rawText
      .split(/[,;\s]+/)
      .map((s) => s.trim().toLowerCase())
      .filter(Boolean);

    if (!tokens.length) {
      setCcInput("");
      return true;
    }

    const primaryTo = toEmail.trim().toLowerCase();
    const added = [];
    let errorMsg = "";

    for (const email of tokens) {
      if (!isValidEmail(email)) {
        errorMsg = `Invalid CC email: "${email}"`;
        break;
      }
      if (email === primaryTo) {
        errorMsg = `"${email}" is already in the To field.`;
        continue;
      }
      if (ccList.includes(email) || added.includes(email)) {
        errorMsg = `"${email}" is already added in CC.`;
        continue;
      }
      if (ccList.length + added.length >= MAIL_LIMITS.MAX_CC_COUNT) {
        errorMsg = `Maximum ${MAIL_LIMITS.MAX_CC_COUNT} CC recipients allowed.`;
        break;
      }
      added.push(email);
    }

    if (added.length) {
      setCcList((prev) => [...prev, ...added]);
    }

    if (errorMsg) {
      setErrors((prev) => ({ ...prev, cc: errorMsg }));
      return false;
    }

    clearFieldError("cc");
    setCcInput("");
    return true;
  };

  const handleCcKeyDown = (e) => {
    if (["Enter", ",", ";", "Tab"].includes(e.key) && ccInput.trim()) {
      e.preventDefault();
      commitCcInput(ccInput);
    } else if (e.key === "Backspace" && !ccInput && ccList.length) {
      setCcList((prev) => prev.slice(0, -1));
      clearFieldError("cc");
    }
  };

  const handleCcPaste = (e) => {
    const pasted = e.clipboardData.getData("text");
    if (/[,;\s]/.test(pasted)) {
      e.preventDefault();
      commitCcInput(`${ccInput} ${pasted}`);
    }
  };

  const removeCc = (emailToRemove) => {
    setCcList((prev) => prev.filter((item) => item !== emailToRemove));
    clearFieldError("cc");
  };

  // --- File Selection & Drag-and-Drop ---
  const processFiles = (fileList) => {
    const incoming = Array.from(fileList || []);
    if (!incoming.length) return;

    const { accepted, errors: validationErrors } = validateIncomingFiles(
      incoming,
      attachments
    );

    if (accepted.length) {
      setAttachments((prev) => [...prev, ...accepted]);
    }
    setFileErrors(validationErrors);
    if (validationErrors.length) {
      showSnackbar(validationErrors[0], "warning");
    }
  };

  const handleFileInputChange = (e) => {
    processFiles(e.target.files);
    e.target.value = "";
  };

  const handleDragEnter = (e) => {
    e.preventDefault();
    e.stopPropagation();
    dragCounterRef.current += 1;
    if (e.dataTransfer?.items?.length) {
      setIsDragging(true);
    }
  };

  const handleDragLeave = (e) => {
    e.preventDefault();
    e.stopPropagation();
    dragCounterRef.current -= 1;
    if (dragCounterRef.current === 0) {
      setIsDragging(false);
    }
  };

  const handleDragOver = (e) => {
    e.preventDefault();
    e.stopPropagation();
  };

  const handleDrop = (e) => {
    e.preventDefault();
    e.stopPropagation();
    dragCounterRef.current = 0;
    setIsDragging(false);
    if (!previewMode && !loading) {
      processFiles(e.dataTransfer?.files);
    }
  };

  const removeAttachment = (index) => {
    setAttachments((prev) => prev.filter((_, i) => i !== index));
    setFileErrors([]);
  };

  // --- Validation & Submission ---
  const resetForm = () => {
    setToEmail("");
    setShowCc(false);
    setCcList([]);
    setCcInput("");
    setGreeting("");
    setSubject("");
    setBody("");
    setAttachments([]);
    setErrors({});
    setFileErrors([]);
    setPreviewMode(false);
  };

  const validateAll = () => {
    const nextErrors = {};

    const cleanTo = toEmail.trim().toLowerCase();
    if (!cleanTo) {
      nextErrors.to = "Recipient email is required.";
    } else if (!isValidEmail(cleanTo)) {
      nextErrors.to = "Enter a valid recipient email address.";
    }

    if (ccInput.trim() && !commitCcInput(ccInput)) {
      nextErrors.cc = `Invalid CC email: "${ccInput.trim()}"`;
    }

    const cleanGreeting = sanitizeFinal(greeting, "greeting");
    if (cleanGreeting.length > MAIL_LIMITS.GREETING_MAX) {
      nextErrors.greeting = `Greeting cannot exceed ${MAIL_LIMITS.GREETING_MAX} characters.`;
    }

    const cleanSubject = sanitizeFinal(subject, "subject");
    if (cleanSubject.length < MAIL_LIMITS.SUBJECT_MIN) {
      nextErrors.subject = `Subject must be at least ${MAIL_LIMITS.SUBJECT_MIN} characters.`;
    }

    const cleanBody = sanitizeFinal(body, "body");
    if (cleanBody.length < MAIL_LIMITS.BODY_MIN) {
      nextErrors.body = `Email body must be at least ${MAIL_LIMITS.BODY_MIN} characters.`;
    }

    setErrors(nextErrors);
    return {
      isValid: Object.keys(nextErrors).length === 0,
      cleanTo,
      cleanGreeting: cleanGreeting || "User",
      cleanSubject,
      cleanBody,
    };
  };

  const handleSend = async () => {
    const result = validateAll();
    if (!result.isValid) {
      showSnackbar("Please fix the highlighted fields before sending.", "warning");
      return;
    }

    // Re-filter CC in case user typed To email matching an existing CC chip
    const finalCc = ccList.filter((c) => c !== result.cleanTo);

    setLoading(true);
    try {
      const payload = {
        templateId: TEMPLATE_ID,
        toEmail: result.cleanTo,
        ccEmails: finalCc.length ? finalCc : null,
        templateData: {
          mailSubject: result.cleanSubject,
          recipientName: result.cleanGreeting,
          mailBody: result.cleanBody,
        },
      };

      const formData = new FormData();
      formData.append("payload", JSON.stringify(payload));
      attachments.forEach((file) => {
        formData.append("attachments", file);
      });

      await callApi(CUSTOM_MAIL_URL, formData);

      showSnackbar("Mail sent successfully.", "success");
      resetForm();
      onClose?.();
    } catch (error) {
      showSnackbar(
        error.response?.data?.message || "Failed to send mail.",
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
          width: { xs: "100%", sm: expanded ? 860 : 620 },
          transition: "width 0.2s ease",
          border: "none",
          boxShadow: "0 12px 48px rgba(46, 16, 101, 0.22)",
        },
      }}
    >
      <Box
        onDragEnter={handleDragEnter}
        onDragLeave={handleDragLeave}
        onDragOver={handleDragOver}
        onDrop={handleDrop}
        sx={{
          position: "relative",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          bgcolor: "#ffffff",
        }}
      >
        {/* Full-Drawer Drag-and-Drop Overlay (Gmail/Outlook style) */}
        {isDragging && !previewMode && (
          <Box
            sx={{
              position: "absolute",
              inset: 0,
              zIndex: 30,
              bgcolor: "rgba(250, 247, 255, 0.94)",
              border: "2.5px dashed #7c3aed",
              borderRadius: 2,
              m: 1.5,
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
              justifyContent: "center",
              pointerEvents: "none",
              gap: 1,
            }}
          >
            <CloudUploadIcon sx={{ fontSize: 54, color: "#7c3aed" }} />
            <Typography variant="h6" fontWeight={700} color="#4c1d95">
              Drop files to attach
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Up to {MAIL_LIMITS.MAX_FILES} files • Max {MAIL_LIMITS.MAX_FILE_SIZE_MB} MB each •{" "}
              {MAIL_LIMITS.MAX_TOTAL_SIZE_MB} MB total
            </Typography>
          </Box>
        )}

        {/* Top Bar (Gmail/Outlook Compose Header) */}
        <Box
          sx={{
            px: 2.5,
            py: 1.5,
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
            background: "linear-gradient(135deg, #4c1d95 0%, #6d28d9 60%, #7c3aed 100%)",
            color: "#ffffff",
          }}
        >
          <Box>
            <Typography variant="subtitle1" fontWeight={700} lineHeight={1.2}>
              New Message
            </Typography>
            <Typography variant="caption" sx={{ opacity: 0.85 }}>
              FinCore Official Mail • Branded Template
            </Typography>
          </Box>

          <Stack direction="row" spacing={0.5} alignItems="center">
            <Tooltip title={previewMode ? "Back to Editor" : "Preview FinCore Mail"}>
              <Button
                size="small"
                variant="outlined"
                onClick={() => setPreviewMode((v) => !v)}
                startIcon={previewMode ? <EditIcon /> : <VisibilityIcon />}
                sx={{
                  color: "#ffffff",
                  borderColor: "rgba(255,255,255,0.4)",
                  textTransform: "none",
                  mr: 0.5,
                  "&:hover": {
                    borderColor: "#ffffff",
                    bgcolor: "rgba(255,255,255,0.12)",
                  },
                }}
              >
                {previewMode ? "Edit" : "Preview"}
              </Button>
            </Tooltip>

            <Tooltip title={expanded ? "Compact view" : "Expand composer"}>
              <IconButton
                size="small"
                onClick={() => setExpanded((v) => !v)}
                sx={{ color: "#ffffff", display: { xs: "none", sm: "inline-flex" } }}
              >
                {expanded ? (
                  <CloseFullscreenIcon fontSize="small" />
                ) : (
                  <OpenInFullIcon fontSize="small" />
                )}
              </IconButton>
            </Tooltip>

            <Tooltip title="Close">
              <IconButton
                size="small"
                onClick={onClose}
                disabled={loading}
                sx={{ color: "#ffffff" }}
              >
                <CloseIcon fontSize="small" />
              </IconButton>
            </Tooltip>
          </Stack>
        </Box>

        {/* Main Body: Preview Mode OR Compose Mode */}
        {previewMode ? (
          <Box sx={{ flexGrow: 1, overflow: "hidden", bgcolor: "#f8fafc", p: 1.5 }}>
            <Box
              component="iframe"
              title="FinCore Email Preview"
              sandbox=""
              srcDoc={buildPreviewHtml({
                greeting: sanitizeFinal(greeting, "greeting"),
                subject: sanitizeFinal(subject, "subject"),
                body: sanitizeFinal(body, "body"),
              })}
              sx={{
                width: "100%",
                height: "100%",
                border: "1px solid #e2e8f0",
                borderRadius: 2,
                bgcolor: "#ffffff",
              }}
            />
          </Box>
        ) : (
          <Box sx={{ flexGrow: 1, overflowY: "auto", display: "flex", flexDirection: "column" }}>
            {/* TO Row */}
            <Box
              sx={{
                px: 2.5,
                py: 1,
                display: "flex",
                alignItems: "center",
                gap: 1.5,
                borderBottom: "1px solid",
                borderColor: errors.to ? "error.main" : "divider",
              }}
            >
              <Typography
                variant="body2"
                color="text.secondary"
                sx={{ width: 64, flexShrink: 0, fontWeight: 500 }}
              >
                To <Box component="span" color="error.main">*</Box>
              </Typography>
              <InputBase
                fullWidth
                placeholder="recipient@sbi.co.in"
                value={toEmail}
                onChange={(e) => {
                  setToEmail(e.target.value.replace(/\s/g, ""));
                  clearFieldError("to");
                }}
                onBlur={() => {
                  const trimmed = toEmail.trim();
                  if (trimmed && !isValidEmail(trimmed)) {
                    setErrors((prev) => ({
                      ...prev,
                      to: "Enter a valid recipient email address.",
                    }));
                  }
                }}
                sx={{ fontSize: "0.92rem" }}
              />
              {!showCc && (
                <Button
                  size="small"
                  onClick={() => setShowCc(true)}
                  sx={{
                    minWidth: "auto",
                    textTransform: "none",
                    color: "text.secondary",
                    fontWeight: 600,
                    "&:hover": { color: "#6d28d9" },
                  }}
                >
                  Cc
                </Button>
              )}
            </Box>
            {errors.to && (
              <Typography variant="caption" color="error" sx={{ px: 2.5, pt: 0.5 }}>
                {errors.to}
              </Typography>
            )}

            {/* CC Row (Optional, Chip-based) */}
            {showCc && (
              <>
                <Box
                  sx={{
                    px: 2.5,
                    py: 1,
                    display: "flex",
                    alignItems: "flex-start",
                    gap: 1.5,
                    borderBottom: "1px solid",
                    borderColor: errors.cc ? "error.main" : "divider",
                  }}
                >
                  <Typography
                    variant="body2"
                    color="text.secondary"
                    sx={{ width: 64, flexShrink: 0, pt: 0.5, fontWeight: 500 }}
                  >
                    Cc
                  </Typography>
                  <Box
                    sx={{
                      flexGrow: 1,
                      display: "flex",
                      flexWrap: "wrap",
                      alignItems: "center",
                      gap: 0.75,
                    }}
                  >
                    {ccList.map((email) => (
                      <Chip
                        key={email}
                        label={email}
                        size="small"
                        onDelete={() => removeCc(email)}
                        sx={{
                          bgcolor: "#f3e8ff",
                          color: "#4c1d95",
                          fontWeight: 500,
                          "& .MuiChip-deleteIcon": { color: "#7c3aed" },
                        }}
                      />
                    ))}
                    <InputBase
                      placeholder={
                        ccList.length
                          ? "Add another..."
                          : "Add CC emails (press Enter or comma)"
                      }
                      value={ccInput}
                      onChange={(e) => {
                        setCcInput(e.target.value);
                        clearFieldError("cc");
                      }}
                      onKeyDown={handleCcKeyDown}
                      onPaste={handleCcPaste}
                      onBlur={() => ccInput.trim() && commitCcInput(ccInput)}
                      sx={{ flexGrow: 1, minWidth: 160, fontSize: "0.9rem" }}
                    />
                  </Box>
                </Box>
                {errors.cc && (
                  <Typography variant="caption" color="error" sx={{ px: 2.5, pt: 0.5 }}>
                    {errors.cc}
                  </Typography>
                )}
              </>
            )}

            {/* Greeting Row */}
            <Box
              sx={{
                px: 2.5,
                py: 1,
                display: "flex",
                alignItems: "center",
                gap: 1.5,
                borderBottom: "1px solid",
                borderColor: errors.greeting ? "error.main" : "divider",
              }}
            >
              <Typography
                variant="body2"
                color="text.secondary"
                sx={{ width: 64, flexShrink: 0, fontWeight: 500 }}
              >
                Greeting
              </Typography>
              <Typography variant="body2" color="text.secondary" sx={{ userSelect: "none" }}>
                Dear
              </Typography>
              <InputBase
                fullWidth
                placeholder="User (default if left blank)"
                value={greeting}
                onChange={(e) => {
                  setGreeting(sanitizeOnType(e.target.value, "greeting"));
                  clearFieldError("greeting");
                }}
                onBlur={() => setGreeting((v) => sanitizeFinal(v, "greeting"))}
                sx={{ fontSize: "0.92rem" }}
              />
              <Typography variant="caption" color="text.disabled" sx={{ flexShrink: 0 }}>
                {greeting.length}/{MAIL_LIMITS.GREETING_MAX}
              </Typography>
            </Box>

            {/* Subject Row */}
            <Box
              sx={{
                px: 2.5,
                py: 1,
                display: "flex",
                alignItems: "center",
                gap: 1.5,
                borderBottom: "1px solid",
                borderColor: errors.subject ? "error.main" : "divider",
              }}
            >
              <Typography
                variant="body2"
                color="text.secondary"
                sx={{ width: 64, flexShrink: 0, fontWeight: 500 }}
              >
                Subject <Box component="span" color="error.main">*</Box>
              </Typography>
              <InputBase
                fullWidth
                placeholder="Add a clear subject"
                value={subject}
                onChange={(e) => {
                  setSubject(sanitizeOnType(e.target.value, "subject"));
                  clearFieldError("subject");
                }}
                onBlur={() => setSubject((v) => sanitizeFinal(v, "subject"))}
                sx={{ fontSize: "0.95rem", fontWeight: 600 }}
              />
              <Typography variant="caption" color="text.disabled" sx={{ flexShrink: 0 }}>
                {subject.length}/{MAIL_LIMITS.SUBJECT_MAX}
              </Typography>
            </Box>
            {errors.subject && (
              <Typography variant="caption" color="error" sx={{ px: 2.5, pt: 0.5 }}>
                {errors.subject}
              </Typography>
            )}

            {/* Email Body Compose Area */}
            <Box sx={{ px: 2.5, pt: 2, pb: 1.5, flexGrow: 1, display: "flex", flexDirection: "column" }}>
              <InputBase
                fullWidth
                multiline
                minRows={9}
                placeholder="Type or paste your email message here...&#10;&#10;Junk characters and extra spaces are cleaned automatically."
                value={body}
                onChange={(e) => {
                  setBody(sanitizeOnType(e.target.value, "body"));
                  clearFieldError("body");
                }}
                onBlur={() => setBody((v) => sanitizeFinal(v, "body"))}
                sx={{
                  fontSize: "0.95rem",
                  lineHeight: 1.65,
                  alignItems: "flex-start",
                  flexGrow: 1,
                }}
              />

              <Box
                sx={{
                  display: "flex",
                  justifyContent: "space-between",
                  alignItems: "center",
                  mt: 1,
                }}
              >
                <Typography variant="caption" color={errors.body ? "error" : "text.disabled"}>
                  {errors.body || "Line breaks and paragraphs are preserved in the FinCore template."}
                </Typography>
                <Typography
                  variant="caption"
                  color={body.length > MAIL_LIMITS.BODY_MAX * 0.9 ? "warning.main" : "text.disabled"}
                >
                  {body.length}/{MAIL_LIMITS.BODY_MAX}
                </Typography>
              </Box>

              {/* Default Signature & System Note Indicator (Read-only) */}
              <Paper
                variant="outlined"
                sx={{
                  mt: 2,
                  p: 1.5,
                  bgcolor: "#faf7ff",
                  borderColor: "#e9d5ff",
                  borderRadius: 2,
                }}
              >
                <Typography variant="caption" color="text.secondary" display="block">
                  Warm regards,
                </Typography>
                <Typography variant="body2" fontWeight={700} sx={{ color: "#4c1d95" }}>
                  FinCore System Team
                </Typography>
                <Typography variant="caption" color="text.secondary" display="block">
                  FinCore — Insight Driven General Ledger | State Bank of India
                </Typography>
                <Typography
                  variant="caption"
                  sx={{
                    display: "block",
                    mt: 0.75,
                    pt: 0.75,
                    borderTop: "1px dashed #d8b4fe",
                    color: "#6b21a8",
                  }}
                >
                  System-generated Do-Not-Reply notice is appended automatically.
                </Typography>
              </Paper>

              {/* Attachments Section (Drag & Drop Zone + File Cards) */}
              <Box sx={{ mt: 2 }}>
                <input
                  ref={fileInputRef}
                  type="file"
                  multiple
                  hidden
                  accept={ACCEPT_ATTR}
                  onChange={handleFileInputChange}
                />

                {attachments.length > 0 && (
                  <Box sx={{ mb: 1.25 }}>
                    <Box
                      sx={{
                        display: "flex",
                        justifyContent: "space-between",
                        alignItems: "center",
                        mb: 0.5,
                      }}
                    >
                      <Typography variant="caption" fontWeight={600} color="text.secondary">
                        Attachments ({attachments.length}/{MAIL_LIMITS.MAX_FILES})
                      </Typography>
                      <Typography variant="caption" color="text.secondary">
                        {formatBytes(totalAttachmentBytes)} / {MAIL_LIMITS.MAX_TOTAL_SIZE_MB} MB
                      </Typography>
                    </Box>

                    <LinearProgress
                      variant="determinate"
                      value={storagePercent}
                      sx={{
                        height: 5,
                        borderRadius: 3,
                        mb: 1.25,
                        bgcolor: "#ede9fe",
                        "& .MuiLinearProgress-bar": {
                          bgcolor: storagePercent > 85 ? "#d97706" : "#7c3aed",
                        },
                      }}
                    />

                    <Stack spacing={0.75}>
                      {attachments.map((file, idx) => (
                        <Paper
                          key={`${file.name}-${file.size}`}
                          variant="outlined"
                          sx={{
                            px: 1.5,
                            py: 0.85,
                            display: "flex",
                            alignItems: "center",
                            justifyContent: "space-between",
                            gap: 1,
                            borderRadius: 1.5,
                            borderColor: "#e5e7eb",
                            bgcolor: "#fafafa",
                          }}
                        >
                          <Stack
                            direction="row"
                            spacing={1.25}
                            alignItems="center"
                            sx={{ minWidth: 0 }}
                          >
                            {getFileIcon(file.name)}
                            <Box sx={{ minWidth: 0 }}>
                              <Typography variant="body2" fontWeight={500} noWrap>
                                {file.name}
                              </Typography>
                              <Typography variant="caption" color="text.secondary">
                                {formatBytes(file.size)}
                              </Typography>
                            </Box>
                          </Stack>
                          <IconButton
                            size="small"
                            onClick={() => removeAttachment(idx)}
                            disabled={loading}
                            aria-label={`Remove ${file.name}`}
                          >
                            <CloseIcon fontSize="small" />
                          </IconButton>
                        </Paper>
                      ))}
                    </Stack>
                  </Box>
                )}

                {/* Compact Click/Drop Attachment Strip */}
                {attachments.length < MAIL_LIMITS.MAX_FILES && (
                  <Box
                    onClick={() => !loading && fileInputRef.current?.click()}
                    sx={{
                      p: 1.25,
                      border: "1.5px dashed #c4b5fd",
                      borderRadius: 2,
                      bgcolor: "#fcfaff",
                      textAlign: "center",
                      cursor: loading ? "default" : "pointer",
                      transition: "background-color 0.15s ease",
                      "&:hover": { bgcolor: "#f5f0ff" },
                    }}
                  >
                    <Typography variant="caption" color="#5b21b6" fontWeight={600}>
                      Click to attach or drag &amp; drop files anywhere
                    </Typography>
                    <Typography variant="caption" color="text.secondary" display="block">
                      Max {MAIL_LIMITS.MAX_FILES} files • {MAIL_LIMITS.MAX_FILE_SIZE_MB} MB each •{" "}
                      {MAIL_LIMITS.MAX_TOTAL_SIZE_MB} MB total (PDF, Excel, CSV, Word, TXT, Images)
                    </Typography>
                  </Box>
                )}

                {fileErrors.length > 0 && (
                  <Alert
                    severity="warning"
                    onClose={() => setFileErrors([])}
                    sx={{ mt: 1, py: 0.25 }}
                  >
                    {fileErrors.map((err, i) => (
                      <div key={i}>{err}</div>
                    ))}
                  </Alert>
                )}
              </Box>
            </Box>
          </Box>
        )}

        <Divider />

        {/* Sticky Bottom Action Bar (Gmail/Outlook style) */}
        <Box
          sx={{
            px: 2.5,
            py: 1.5,
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
            bgcolor: "#fafafa",
          }}
        >
          <Stack direction="row" spacing={1} alignItems="center">
            <Button
              variant="contained"
              endIcon={<SendIcon />}
              onClick={handleSend}
              disabled={loading}
              sx={{
                px: 3,
                borderRadius: 6,
                textTransform: "none",
                fontWeight: 700,
                bgcolor: "#7c3aed",
                "&:hover": { bgcolor: "#6d28d9" },
              }}
            >
              {loading ? "Sending..." : "Send"}
            </Button>

            {!previewMode && (
              <Tooltip
                title={
                  attachments.length >= MAIL_LIMITS.MAX_FILES
                    ? `Limit reached (${MAIL_LIMITS.MAX_FILES} files)`
                    : "Attach files"
                }
              >
                <span>
                  <IconButton
                    onClick={() => fileInputRef.current?.click()}
                    disabled={loading || attachments.length >= MAIL_LIMITS.MAX_FILES}
                    sx={{ color: "#4c1d95" }}
                  >
                    <AttachFileIcon />
                  </IconButton>
                </span>
              </Tooltip>
            )}
          </Stack>

          <Tooltip title="Discard draft">
            <span>
              <IconButton
                onClick={resetForm}
                disabled={loading}
                color="default"
                aria-label="Discard draft"
              >
                <DeleteOutlineIcon />
              </IconButton>
            </span>
          </Tooltip>
        </Box>
      </Box>
    </Drawer>
  );
}