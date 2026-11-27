I want a similar template as FINCORE_SYSTEM with app theme to send custom mails which directly paste in body

{
    "templateId" : "AUTH_LOGIN_OTP_V1",
    "toEmail" : "xxxx",
    "templateData" : {
        "userName" : "test user",
        "otpPlaintext" : "955066",
        "expiryMins" : "5"
    }
}


"<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Fincore OTP</title>
  </head>
  <body
    style="
      margin: 0;

      padding: 25px 15px;

      background: #ffffff;

      font-family: &quot;Times New Roman&quot;, Times, serif;
    "
  >
    <table width="100%" cellpadding="0" cellspacing="0" border="0">
      <tr>
        <td align="center">
          <div
            style="
              position: relative;
              width: 100%;
              max-width: 900px;
              overflow: hidden;
              margin: auto;
              border-radius: 30px;
              background:
                radial-gradient(
                  circle at top right,
                  rgba(128, 0, 255, 0.32) 0%,
                  rgba(128, 0, 255, 0.2) 25%,
                  rgba(156, 92, 255, 0.14) 48%,
                  transparent 72%
                ),
                linear-gradient(
                  135deg,
                  #faf7ff 0%,
                  #f3e9ff 18%,
                  #e9d5ff 40%,
                  #d8b7ff 62%,
                  #c08dff 82%,
                  #9c63ff 100%
                );
            "
          >
            <!-- TOP RIGHT CIRCLE LINES -->
            <div
              style="
                position: absolute;

                top: -160px;

                right: -70px;

                width: 420px;

                height: 420px;

                border-radius: 50%;

                box-shadow:
                  0 0 0 1px rgba(128, 0, 255, 0.03),
                  0 0 0 12px rgba(128, 0, 255, 0.025),
                  0 0 0 24px rgba(128, 0, 255, 0.025),
                  0 0 0 36px rgba(128, 0, 255, 0.025),
                  0 0 0 48px rgba(128, 0, 255, 0.025);
              "
            ></div>
            <!-- BOTTOM WAVES -->
            <!-- Wave 1 -->
            <div
              style="
                position: absolute;
                left: -20%;
                bottom: -10px;
                width: 140%;
                height: 220px;
                background: rgba(216, 183, 255, 0.2);
                border-radius: 50%;
              "
            ></div>
            <!-- Wave 2 -->
            <div
              style="
                position: absolute;
                left: -15%;
                bottom: -35px;
                width: 135%;
                height: 210px;
                background: rgba(192, 141, 255, 0.14);
                border-radius: 50%;
              "
            ></div>
            <!-- Wave 3 -->
            <div
              style="
                position: absolute;
                left: -10%;
                bottom: -55px;
                width: 130%;
                height: 220px;
                background: rgba(156, 99, 255, 0.08);
                border-radius: 50%;
              "
            ></div>
            <div style="position: relative; z-index: 2">
              <!-- HEADER -->
              <table width="100%" cellpadding="0" cellspacing="0" border="0">
                <tr>
                  <td style="padding: 22px 28px 15px 28px">
                    <table cellpadding="0" cellspacing="0" border="0">
                      <tr>
                        <!-- LOGO -->
                        <td valign="middle" style="width: 65px">
                          <img
                            src="https://fincore.sbi/assets/Fincore_transperent-CuH99SR4.svg"
                            alt="Fincore Logo"
                            width="58"
                            height="58"
                            style="
                              display: block;
                              width: 95px;
                              height: 95px;
                              border: 0;
                              outline: none;
                              text-decoration: none;
                            "
                          />
                        </td>
                        <td width="6"></td>
                        <td width="4"></td>
                        <!-- TITLE -->
                        <td valign="middle">
                          <img
                            src="https://fincore.sbi/assets/Fincore_title-Hef-qsF5.png"
                            alt="Fincore"
                            width="185"
                            style="
                              display: block;
                              width: 140px;
                              height: auto;
                              border: 0;
                              outline: none;
                              text-decoration: none;
                              padding-top: 17px;
                            "
                          />
                          <div
                            style="
                              font-size: 11px;
                              opacity: 0.8;
                              margin-top: -4px;
                              font-weight: 700;
                              padding-top: 12px;
                              display: block;
                            "
                          >
                            Insight Driven General Ledger
                          </div>
                        </td>
                      </tr>
                    </table>
                  </td>
                </tr>
              </table>

              <!-- OTP CARD -->
              <table width="100%" cellpadding="0" cellspacing="0" border="0">
                <tr>
                  <td align="center" style="padding: 0 28px 35px 28px">
                    <table
                      width="100%"
                      cellpadding="0"
                      cellspacing="0"
                      border="0"
                      style="
                        background: rgba(255, 255, 255, 0.35);

                        backdrop-filter: blur(20px);

                        -webkit-backdrop-filter: blur(20px);

                        border: 1px solid rgba(255, 255, 255, 0.45);

                        border-radius: 28px;

                        overflow: hidden;

                        box-shadow: 0 8px 32px rgba(31, 38, 135, 0.18);
                      "
                    >
                      <tr>
                        <td
                          style="
                            padding: 38px 45px;

                            font-size: 16px;

                            line-height: 24px;

                            color: #111111;

                            font-family:
                              &quot;Times New Roman&quot;, Times, serif;
                          "
                        >
                          <div
                            style="
                              font-size: 20px;

                              font-weight: bold;

                              margin-bottom: 18px;
                            "
                          >
                            Dear ${userName},
                          </div>
                          <div
                            style="
                              font-size: 16px;

                              line-height: 24px;

                              margin-bottom: 14px;
                            "
                          >
                            You are attempting to log into your
                            <strong>FinCore</strong> application.
                          </div>
                          <div
                            style="
                              font-size: 16px;

                              line-height: 24px;

                              margin-bottom: 12px;
                            "
                          >
                            Please enter the following One-Time Password (OTP)
                            to complete authentication:
                          </div>

                          <!-- OTP BOX -->

                          <div
                            style="
                              width: 150px;

                              margin: 0 auto 18px auto;

                              padding: 10px;

                              text-align: center;

                              background: rgba(255, 255, 255, 0.55);

                              backdrop-filter: blur(15px);

                              border: 1px solid rgba(124, 58, 237, 0.18);

                              border-radius: 16px;

                              box-shadow: 0 8px 32px rgba(31, 38, 135, 0.18);

                              font-size: 25px;

                              font-weight: 700;

                              letter-spacing: 5px;
                            "
                          >
                            ${otpPlaintext}
                          </div>

                          <div
                            style="
                              font-size: 16px;

                              line-height: 24px;

                              margin-bottom: 10px;
                            "
                          >
                            This code is valid for
                            <strong>${expiryMins} minutes</strong>. For your
                            security, do not share this code with anyone.
                          </div>

                          <div
                            style="
                              font-size: 16px;

                              line-height: 32px;

                              margin-bottom: 18px;
                            "
                          >
                            If you did not request this login, please ignore
                            this message or contact our support team
                            immediately.
                          </div>

                          <div
                            style="
                              margin-top: 35px;

                              padding-top: 20px;

                              border-top: 1px solid rgba(0, 0, 0, 0.08);

                              color: #555;

                              font-size: 14px;

                              text-align: center;
                            "
                          >
                            © 2026 State Bank of India. All rights reserved.
                          </div>
                        </td>
                      </tr>
                    </table>
                  </td>
                </tr>
              </table>
            </div>
          </div>
        </td>
      </tr>
    </table>
  </body>
</html>
"





@PostMapping("/send-mail")
    public ResponseEntity<EmailResponse> sendMail(@RequestBody Map<String, Object> map) {
        String templateId = map.get("templateId").toString();
        String toEmail = map.get("toEmail").toString();
        Map<String, Object> templateData = (Map<String, Object>) map.get("templateData");
        log.info("Sending Mail with Payload {}", templateId, toEmail, templateData);
        // emailService.sendEmail(event.getEnvironment(), event.getTemplateId(),
        // event.getRecipient().getEmail(), templateDataMap);
        EmailResponse emailResponseDto = emailService.sendEmail(templateId, toEmail, templateData);
        return new ResponseEntity<>(emailResponseDto, HttpStatus.OK);
    }
	
	
	/**
     * Standard dispatch without attachments.
     */
    EmailResponse sendEmail(String templateId, String toEmail, Map<String, Object> templateData);
	
	
	@Override
    @Retry(name = "bankApiRetry", fallbackMethod = "handleTotalApiFailure")
    @CircuitBreaker(name = "bankApiCircuit", fallbackMethod = "handleTotalApiFailure")
    public EmailResponse sendEmail(String templateId, String toEmail, Map<String, Object> templateData) {
        return executeEmailDispatch(templateId, toEmail, null, templateData, null);
    }
	
	
	/**
     * Private core execution logic.
     */
    private EmailResponse executeEmailDispatch(String templateId, String toEmail, List<String> bccEmails,
                                               Map<String, Object> templateData, Resource attachment) {
        log.debug("Initiating Email Dispatch Pipeline for Template ID: {}", templateId);

        String emailBody = templateService.renderTemplate(templateId, "EMAIL", "EN", templateData);
        String subject = templateService.getTemplateSubject(templateId, "EMAIL", "EN");
        FincoreSettings config = configProvider.getConfig(FUNCTIONALITY_EMAIL, environment);

        Map<String, Object> emailRequestBody = new HashMap<>();
        emailRequestBody.put("url", config.getUrl());
        emailRequestBody.put("api_key", config.getApiKey());
        emailRequestBody.put("senderId", config.getSenderId());
        emailRequestBody.put("subject", subject);
        emailRequestBody.put("emailBody", emailBody);

        if (toEmail != null) emailRequestBody.put("toEmail", toEmail);
        if (bccEmails != null) emailRequestBody.put("bccEmails", bccEmails);

        int responseCode = emailGatewayClient.sendEmail(emailRequestBody, attachment);

        EmailResponse responseDto = new EmailResponse();
        responseDto.setStatus(responseCode);

        if (responseCode >= 200 && responseCode < 300) {
            responseDto.setMessage("Email Sent Successfully");
        } else {
            responseDto.setMessage("Email Sending Failed");
            throw new VendorDeliveryException("Email Provider rejected request. HTTP " + responseCode, null);
        }
        return responseDto;
    }
	
	
	
	
	public String renderTemplate(String templateCode, String channel, String language, Map<String, Object> templateData) {
        // 1. Fetch the cached, pre-compiled Template AST Object from the dedicated cache service
        Template compiledTemplate = templateCacheService.getCompiledTemplate(templateCode, channel, language);

        // 2. Merge dynamic data (OTP, Names) into the template
        try (StringWriter writer = new StringWriter()) {
            compiledTemplate.process(templateData, writer);
            return writer.toString();
        } catch (IOException | TemplateException e) {
            log.error("Fatal error binding dynamic variables to template {}.", templateCode, e);
            throw new CommunicationExceptions.TemplateProcessingException("Failed to bind dynamic variables to template: " + templateCode, e);
        }
    }
	
	
import { useState } from "react";
import {
  Drawer,
  Button,
  IconButton,
  Stack,
  TextField,
  Typography,
  Box,
  Divider,
} from "@mui/material";
import { Close as CloseIcon } from "@mui/icons-material";
import DeleteOutlineIcon from "@mui/icons-material/DeleteOutlined";
import useApi from "../../hooks/useApi";
import useCustomSnackbar from "../../utils/useCustomSnackbar";

const MAIL_URL = "/CC/communication/send-mail";

export default function MailDrawer({ isOpen, setIsOpen }) {
  const { callApi } = useApi();
  const showSnackbar = useCustomSnackbar();
  const [recipientMail, setRecipientMail] = useState("");
  const [templateID, setTemplateID] = useState("");
  const [eventType, setEventType] = useState("MANUAL_TEST");
  const [placeHolders, setPlaceHolders] = useState([{ key: "", value: "" }]);
  const [loading, setLoading] = useState(false);

  const updatePlaceholder = (index, field, value) => {
    setPlaceHolders((items) =>
      items.map((item, i) =>
        i === index ? { ...item, [field]: value } : item,
      ),
    );
  };

  const sendMail = async () => {
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(recipientMail)) {
      showSnackbar("Enter a valid recipient email.", "warning");
      return;
    }
    if (!templateID.trim()) {
      showSnackbar("Enter a template ID.", "warning");
      return;
    }
    const valid = placeHolders.filter(
      (item) => item.key.trim() && item.value.trim(),
    );
    if (!valid.length) {
      showSnackbar("Add at least one complete placeholder.", "warning");
      return;
    }
    if (new Set(valid.map((item) => item.key.trim())).size !== valid.length) {
      showSnackbar("Placeholder keys must be unique.", "warning");
      return;
    }

    setLoading(true);
    try {
      const payload = {
        recipientMail,
        templateID,
        placeHolders: valid,
        eventType,
      };
      const response = await callApi(MAIL_URL, payload);
      console.log(response);
      showSnackbar("Mail request submitted.", "success");
      setRecipientMail("");
      setTemplateID("");
      setPlaceHolders([{ key: "", value: "" }]);
    } catch (error) {
      showSnackbar(
        error.response?.data?.message || "Failed to send mail.",
        "error",
      );
    } finally {
      setLoading(false);
    }
  };

  return (
    <Drawer
      anchor="right"
      open={isOpen}
      onClose={setIsOpen}
      PaperProps={{ sx: { width: { xs: "100%", sm: 420 }, border: "none" } }}
    >
      <Box
        sx={{
          height: "100%",
          display: "flex",
          flexDirection: "column",
        }}
      >
        {/* Header */}
        <Box
          sx={{
            p: 3,
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
          }}
        >
          <Box>
            <Typography variant="h6" fontWeight="800" color="primary.main">
              SMS Util
            </Typography>
            <Typography variant="caption" color="text.secondary">
              Utility to send SMS through Fincore System
            </Typography>
          </Box>
          <IconButton onClick={setIsOpen} aria-label="Close">
            <CloseIcon />
          </IconButton>
        </Box>

        <Divider />

        {/* Content */}
        <Box sx={{ flexGrow: 1, overflowY: "auto", p: 2 }}>
          <Stack spacing={2}>
            <TextField
              label="Recipient email"
              value={recipientMail}
              onChange={(e) => setRecipientMail(e.target.value)}
            />
            <TextField
              label="Template ID"
              value={templateID}
              onChange={(e) => setTemplateID(e.target.value)}
            />
            <TextField
              label="Event type"
              value={eventType}
              onChange={(e) => setEventType(e.target.value)}
            />
            <Typography fontWeight={600} color="text.primary">
              Template placeholders
            </Typography>
            {placeHolders.map((item, index) => (
              <Stack
                key={index}
                direction={{ xs: "column", sm: "row" }}
                spacing={1}
              >
                <TextField
                  label="Key"
                  value={item.key}
                  onChange={(e) =>
                    updatePlaceholder(index, "key", e.target.value)
                  }
                />
                <TextField
                  label="Value"
                  value={item.value}
                  onChange={(e) =>
                    updatePlaceholder(index, "value", e.target.value)
                  }
                />
                <IconButton
                  aria-label="Remove placeholder"
                  disabled={placeHolders.length === 1}
                  onClick={() =>
                    setPlaceHolders((items) =>
                      items.filter((_, i) => i !== index),
                    )
                  }
                >
                  <DeleteOutlineIcon />
                </IconButton>
              </Stack>
            ))}
            <Button
              onClick={() =>
                setPlaceHolders((items) => [...items, { key: "", value: "" }])
              }
            >
              Add placeholder
            </Button>
            <Button variant="contained" onClick={sendMail} disabled={loading}>
              {loading ? "Sending..." : "Send mail"}
            </Button>
          </Stack>
        </Box>
      </Box>
    </Drawer>
  );
}
