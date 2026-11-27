package com.sbi.fincore.communication.dto;

import lombok.Data;
import java.util.List;
import java.util.Map;

@Data
public class CustomMailPayload {
    private String templateId;
    private String toEmail;
    private List<String> ccEmails;
    private Map<String, Object> templateData;
}


package com.sbi.fincore.communication.util;

import com.sbi.fincore.communication.dto.CustomMailPayload;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Paths;
import java.util.*;
import java.util.regex.Pattern;

@Component
public class CustomMailValidator {

    public static final String DEFAULT_TEMPLATE_ID = "FINCORE_CUSTOM_MAIL_V1";
    private static final int GREETING_MAX = 80;
    private static final int SUBJECT_MIN = 3;
    private static final int SUBJECT_MAX = 150;
    private static final int BODY_MIN = 10;
    private static final int BODY_MAX = 5000;
    private static final int MAX_CC_COUNT = 10;
    private static final int MAX_FILES = 3;
    private static final long MAX_FILE_SIZE_BYTES = 5L * 1024 * 1024;   // 5 MB
    private static final long MAX_TOTAL_SIZE_BYTES = 10L * 1024 * 1024; // 10 MB

    private static final Set<String> ALLOWED_EXTENSIONS = Set.of(
            "pdf", "xlsx", "xls", "csv", "doc", "docx", "txt", "png", "jpg", "jpeg"
    );

    private static final Pattern EMAIL_PATTERN =
            Pattern.compile("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$");

    private static final Pattern CONTROL_AND_JUNK =
            Pattern.compile("[\\u0000-\\u0008\\u000B\\u000C\\u000E-\\u001F\\u007F-\\u009F\\u200B-\\u200F\\u2028-\\u202F\\uFEFF\\uFFFD]");

    private static final Pattern GREETING_DISALLOWED =
            Pattern.compile("[^a-zA-Z0-9 .,'&()/-]");

    private static final Pattern SUBJECT_DISALLOWED =
            Pattern.compile("[^a-zA-Z0-9 .,;:!?'\"()\\[\\]{}&@#$%*+\\-/_₹]");

    private static final Pattern BODY_DISALLOWED =
            Pattern.compile("[^a-zA-Z0-9 \\t\\r\\n.,;:!?'\"()\\[\\]{}&@#$%*+\\-/_=|₹]");

    public ValidatedMailData validateAndSanitize(CustomMailPayload payload, List<MultipartFile> files) throws IOException {
        if (payload == null) {
            throw new IllegalArgumentException("Mail payload is required.");
        }

        // 1. Validate To email
        String toEmail = payload.getToEmail() == null ? "" : payload.getToEmail().trim().toLowerCase(Locale.ROOT);
        if (!EMAIL_PATTERN.matcher(toEmail).matches()) {
            throw new IllegalArgumentException("Invalid recipient email address.");
        }

        // 2. Validate & deduplicate CC emails
        List<String> cleanCc = new ArrayList<>();
        if (payload.getCcEmails() != null && !payload.getCcEmails().isEmpty()) {
            Set<String> seen = new LinkedHashSet<>();
            for (String rawCc : payload.getCcEmails()) {
                if (rawCc == null || rawCc.isBlank()) continue;
                String cc = rawCc.trim().toLowerCase(Locale.ROOT);
                if (!EMAIL_PATTERN.matcher(cc).matches()) {
                    throw new IllegalArgumentException("Invalid CC email address: " + cc);
                }
                if (!cc.equals(toEmail)) {
                    seen.add(cc);
                }
            }
            if (seen.size() > MAX_CC_COUNT) {
                throw new IllegalArgumentException("Maximum " + MAX_CC_COUNT + " CC recipients allowed.");
            }
            cleanCc.addAll(seen);
        }

        // 3. Sanitize & validate templateData fields
        Map<String, Object> rawData = payload.getTemplateData() != null ? payload.getTemplateData() : Map.of();

        String greeting = sanitizeSingleLine(Objects.toString(rawData.get("recipientName"), ""), GREETING_DISALLOWED, GREETING_MAX);
        if (greeting.isEmpty()) {
            greeting = "User";
        }

        String subject = sanitizeSingleLine(Objects.toString(rawData.get("mailSubject"), ""), SUBJECT_DISALLOWED, SUBJECT_MAX);
        if (subject.length() < SUBJECT_MIN) {
            throw new IllegalArgumentException("Subject must be at least " + SUBJECT_MIN + " characters.");
        }

        String body = sanitizeBody(Objects.toString(rawData.get("mailBody"), ""));
        if (body.length() < BODY_MIN) {
            throw new IllegalArgumentException("Email body must be at least " + BODY_MIN + " characters.");
        }

        Map<String, Object> cleanTemplateData = new HashMap<>();
        cleanTemplateData.put("recipientName", greeting);
        cleanTemplateData.put("mailSubject", subject);
        cleanTemplateData.put("mailBody", body);

        // 4. Validate attachments & convert to retry-safe ByteArrayResource list
        List<Resource> resources = validateAndConvertAttachments(files);

        String templateId = (payload.getTemplateId() == null || payload.getTemplateId().isBlank())
                ? DEFAULT_TEMPLATE_ID
                : payload.getTemplateId().trim();

        return new ValidatedMailData(
                templateId,
                toEmail,
                cleanCc.isEmpty() ? null : cleanCc,
                cleanTemplateData,
                resources
        );
    }

    private List<Resource> validateAndConvertAttachments(List<MultipartFile> files) throws IOException {
        if (files == null || files.isEmpty()) {
            return Collections.emptyList();
        }

        List<MultipartFile> nonEmpty = files.stream()
                .filter(Objects::nonNull)
                .toList();

        if (nonEmpty.size() > MAX_FILES) {
            throw new IllegalArgumentException("Maximum " + MAX_FILES + " attachments allowed.");
        }

        long totalBytes = 0L;
        List<Resource> resources = new ArrayList<>();

        for (MultipartFile file : nonEmpty) {
            if (file.isEmpty() || file.getSize() == 0) {
                throw new IllegalArgumentException("Empty attachment is not allowed: " + file.getOriginalFilename());
            }
            if (file.getSize() > MAX_FILE_SIZE_BYTES) {
                throw new IllegalArgumentException("Attachment '" + file.getOriginalFilename() + "' exceeds the 5 MB limit.");
            }
            totalBytes += file.getSize();
            if (totalBytes > MAX_TOTAL_SIZE_BYTES) {
                throw new IllegalArgumentException("Combined attachments exceed the 10 MB total limit.");
            }

            // Strip any directory traversal segments from client-supplied filename
            String rawName = Objects.requireNonNullElse(file.getOriginalFilename(), "attachment");
            String safeFileName = Paths.get(rawName).getFileName().toString().replaceAll("[^a-zA-Z0-9._ -]", "_");

            String ext = safeFileName.contains(".")
                    ? safeFileName.substring(safeFileName.lastIndexOf('.') + 1).toLowerCase(Locale.ROOT)
                    : "";
            if (!ALLOWED_EXTENSIONS.contains(ext)) {
                throw new IllegalArgumentException("Unsupported attachment type: ." + ext);
            }

            // Wrap bytes in ByteArrayResource so Resilience4j @Retry can re-read the stream
            byte[] content = file.getBytes();
            resources.add(new ByteArrayResource(content) {
                @Override
                public String getFilename() {
                    return safeFileName;
                }
            });
        }

        return resources;
    }

    private String sanitizeSingleLine(String input, Pattern disallowed, int maxLen) {
        if (input == null) return "";
        String cleaned = CONTROL_AND_JUNK.matcher(input).replaceAll("");
        cleaned = disallowed.matcher(cleaned).replaceAll("");
        cleaned = cleaned.replaceAll("[ \\t]{2,}", " ").trim();
        return cleaned.length() > maxLen ? cleaned.substring(0, maxLen).trim() : cleaned;
    }

    private String sanitizeBody(String input) {
        if (input == null) return "";
        String cleaned = CONTROL_AND_JUNK.matcher(input).replaceAll("")
                .replace("\r\n", "\n")
                .replace("\r", "\n");
        cleaned = BODY_DISALLOWED.matcher(cleaned).replaceAll("");

        String[] lines = cleaned.split("\n", -1);
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < lines.length; i++) {
            if (i > 0) sb.append('\n');
            sb.append(lines[i].replaceAll("[ \\t]{2,}", " ").trim());
        }

        String normalized = sb.toString().replaceAll("\\n{3,}", "\n\n").trim();
        return normalized.length() > BODY_MAX ? normalized.substring(0, BODY_MAX).trim() : normalized;
    }

    public record ValidatedMailData(
            String templateId,
            String toEmail,
            List<String> ccEmails,
            Map<String, Object> templateData,
            List<Resource> attachments
    ) {}
}



// Existing signature kept backward-compatible
public int sendEmail(Map<String, Object> emailRequestBody, Resource attachment) {
    List<Resource> attachments = attachment != null ? List.of(attachment) : Collections.emptyList();
    return sendEmail(emailRequestBody, attachments);
}

// New multi-attachment overload
public int sendEmail(Map<String, Object> emailRequestBody, List<Resource> attachments) {
    // Example using RestTemplate / WebClient multipart request:
    // 1. Add emailRequestBody fields (including ccEmails if present in map)
    // 2. Append each Resource from `attachments`:
    //    if (attachments != null) {
    //        for (Resource file : attachments) {
    //            multipartBody.add("attachments", file); // match your vendor API's part name
    //        }
    //    }
    // 3. Execute POST to emailRequestBody.get("url") and return HTTP status code
}


/**
 * Standard dispatch without attachments (existing).
 */
EmailResponse sendEmail(String templateId, String toEmail, Map<String, Object> templateData);

/**
 * Custom mail dispatch with optional CC and multiple attachments.
 */
EmailResponse sendCustomEmail(String templateId, String toEmail, List<String> ccEmails,
                              Map<String, Object> templateData, List<Resource> attachments);




@Override
@Retry(name = "bankApiRetry", fallbackMethod = "handleTotalApiFailure")
@CircuitBreaker(name = "bankApiCircuit", fallbackMethod = "handleTotalApiFailure")
public EmailResponse sendEmail(String templateId, String toEmail, Map<String, Object> templateData) {
    return executeEmailDispatch(templateId, toEmail, null, null, templateData, Collections.emptyList());
}

@Override
@Retry(name = "bankApiRetry", fallbackMethod = "handleTotalApiFailure")
@CircuitBreaker(name = "bankApiCircuit", fallbackMethod = "handleTotalApiFailure")
public EmailResponse sendCustomEmail(String templateId, String toEmail, List<String> ccEmails,
                                     Map<String, Object> templateData, List<Resource> attachments) {
    return executeEmailDispatch(templateId, toEmail, ccEmails, null, templateData, attachments);
}

// Matching Resilience4j fallback for sendCustomEmail
public EmailResponse handleTotalApiFailure(String templateId, String toEmail, List<String> ccEmails,
                                           Map<String, Object> templateData, List<Resource> attachments,
                                           Throwable throwable) {
    log.error("Custom email dispatch failed after retries | templateId={} | toEmail={}", templateId, toEmail, throwable);
    EmailResponse fallback = new EmailResponse();
    fallback.setStatus(HttpStatus.SERVICE_UNAVAILABLE.value());
    fallback.setMessage("Email service is temporarily unavailable. Please try again later.");
    return fallback;
}

/**
 * Private core execution logic (now supports CC, BCC, dynamic subject, and multiple attachments).
 */
private EmailResponse executeEmailDispatch(String templateId, String toEmail,
                                           List<String> ccEmails, List<String> bccEmails,
                                           Map<String, Object> templateData,
                                           List<Resource> attachments) {
    log.debug("Initiating Email Dispatch Pipeline for Template ID: {}", templateId);

    String emailBody = templateService.renderTemplate(templateId, "EMAIL", "EN", templateData);
    String subject = templateService.getTemplateSubject(templateId, "EMAIL", "EN");

    // Override subject when supplied by custom mail composer
    if (templateData != null && templateData.get("mailSubject") != null) {
        String customSubject = templateData.get("mailSubject").toString().trim();
        if (!customSubject.isEmpty()) {
            subject = customSubject;
        }
    }

    FincoreSettings config = configProvider.getConfig(FUNCTIONALITY_EMAIL, environment);

    Map<String, Object> emailRequestBody = new HashMap<>();
    emailRequestBody.put("url", config.getUrl());
    emailRequestBody.put("api_key", config.getApiKey());
    emailRequestBody.put("senderId", config.getSenderId());
    emailRequestBody.put("subject", subject);
    emailRequestBody.put("emailBody", emailBody);

    if (toEmail != null) emailRequestBody.put("toEmail", toEmail);
    if (ccEmails != null && !ccEmails.isEmpty()) emailRequestBody.put("ccEmails", ccEmails);
    if (bccEmails != null && !bccEmails.isEmpty()) emailRequestBody.put("bccEmails", bccEmails);

    int responseCode = emailGatewayClient.sendEmail(emailRequestBody, attachments);

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



@Autowired
private ObjectMapper objectMapper;

@Autowired
private CustomMailValidator customMailValidator;

@PostMapping(value = "/send-custom-mail", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
public ResponseEntity<EmailResponse> sendCustomMail(
        @RequestPart("payload") String payloadJson,
        @RequestPart(value = "attachments", required = false) List<MultipartFile> attachments) throws IOException {

    CustomMailPayload rawPayload = objectMapper.readValue(payloadJson, CustomMailPayload.class);
    CustomMailValidator.ValidatedMailData validated =
            customMailValidator.validateAndSanitize(rawPayload, attachments);

    log.info("Dispatching Custom Mail | templateId={} | toEmail={} | ccCount={} | attachmentCount={}",
            validated.templateId(),
            validated.toEmail(),
            validated.ccEmails() != null ? validated.ccEmails().size() : 0,
            validated.attachments().size());

    EmailResponse response = emailService.sendCustomEmail(
            validated.templateId(),
            validated.toEmail(),
            validated.ccEmails(),
            validated.templateData(),
            validated.attachments()
    );

    return ResponseEntity.ok(response);
}


@ExceptionHandler(IllegalArgumentException.class)
public ResponseEntity<EmailResponse> handleValidationError(IllegalArgumentException ex) {
    EmailResponse response = new EmailResponse();
    response.setStatus(HttpStatus.BAD_REQUEST.value());
    response.setMessage(ex.getMessage());
    return ResponseEntity.badRequest().body(response);
}

@ExceptionHandler(MaxUploadSizeExceededException.class)
public ResponseEntity<EmailResponse> handleMaxUploadSize(MaxUploadSizeExceededException ex) {
    EmailResponse response = new EmailResponse();
    response.setStatus(HttpStatus.PAYLOAD_TOO_LARGE.value());
    response.setMessage("Attachment size exceeds the allowed limit (5 MB per file, 10 MB total).");
    return ResponseEntity.status(HttpStatus.PAYLOAD_TOO_LARGE).body(response);
}

@ExceptionHandler(JsonProcessingException.class)
public ResponseEntity<EmailResponse> handleInvalidPayloadJson(JsonProcessingException ex) {
    EmailResponse response = new EmailResponse();
    response.setStatus(HttpStatus.BAD_REQUEST.value());
    response.setMessage("Malformed mail payload.");
    return ResponseEntity.badRequest().body(response);
}
