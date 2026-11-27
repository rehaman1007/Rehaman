Handle error cases for my component and make its UI/UX more responsive and interactive

MESSAGE_TEMPLATE_VERIFY_FAILED means this message is not allowed to send please verify message as per bank guidelines


{
    "success": false,
    "message": "SMS Sending Failed",
    "providerResponse": "error_code=10008&error_desc=MESSAGE_TEMPLATE_VERIFY_FAILED&umid=11261127111258948813616591"
}

{
    "success": true,
    "message": "SMS Sent Successfully",
    "providerResponse": "error_code=0&error_desc=MESSAGE_SUBMIT_SUCCESS&umid=11261127111421792781185594"
}

{
    "success": true,
    "message": "SMS Sent Successfully",
    "providerResponse": "error_code=10064&error_desc=CLI_NOT_MAPPED_WITH_TEMPLATE&umid=1126082511454908405788558"
}




Allowed templates

1. {#alphanumeric#} EoD had issue in {#alphanumeric#} at {#alphanumeric#}. SBI
eg: 2026-06-28 EoD had issue in abncd at 11:45 hrs. SBI

2. FINCORE EoD completed @{#alphanumeric#}. Stats Balcomp New:{#numeric#}, Cash: {#numeric#},1260INR: {#numeric#},CIBA: {#numeric#}. SBI
eg: FINCORE EoD completed @11:15. Stats Balcomp New:453, Cash:1456,1260INR:2478,CIBA:45. SBI

3. {#numeric#} is your OTP for login to FinCore-SBI. This OTP is valid for {#numeric#} mins.
eg: 153236 is your OTP for login to FinCore-SBI. This OTP is valid for 3 mins.

4. 915024 is the OTP to be used for setting your temporary password for CRS application in SBI. This OTP is valid for 10 minutes.
eg: 915024 is the OTP to be used for setting your temporary password for CRS application in SBI. This OTP is valid for 10 minutes.


If wanted user can maipulate this message like sending different messages in place of variable like this
{26th March Testing} EoD had issue in {generating reports} at {First floor}. SBI

this is a valid case if user send any so extract error code if success show success message or else show provide response message as failed to send

import { useState } from "react";
import {
  Drawer,
  Button,
  MenuItem,
  Stack,
  TextField,
  Typography,
  Box,
  Divider,
  IconButton,
} from "@mui/material";
import useApi from "../../hooks/useApi";
import useCustomSnackbar from "../../utils/useCustomSnackbar";
import { Close as CloseIcon } from "@mui/icons-material";

const SMS_URL = "/CC/communication/send-sms";

export default function SMSDrawer({ isOpen, setIsOpen }) {
  const { callApi } = useApi();
  const showSnackbar = useCustomSnackbar();
  const [mobileNumber, setMobileNumber] = useState("");
  const [message, setMessage] = useState(
    "",
  );
  const [env, setEnv] = useState("UAT");
  const [loading, setLoading] = useState(false);

  const sendSms = async () => {
    if (!/^[6-9]\d{9}$/.test(mobileNumber)) {
      showSnackbar("Enter a valid 10-digit Indian mobile number.", "warning");
      return;
    }
    if (!message.trim()) {
      showSnackbar("Enter an SMS message.", "warning");
      return;
    }

    setLoading(true);
    try {
      const payload = {
        mobileNumber,
        message,
        env,
      };
      const response = await callApi(SMS_URL, payload, "POST");
      console.log(response);
      showSnackbar("SMS request submitted.", "success");
      setMobileNumber("");
      setMessage("");
    } catch (error) {
      showSnackbar(
        error.response?.data?.message || "Failed to send SMS.",
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
          // bgcolor: "#f8f9fa",
        }}
      >
        {/* Header */}
        <Box
          sx={{
            p: 3,
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
            // bgcolor: "#fff",
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
          <IconButton onClick={setIsOpen}>
            <CloseIcon />
          </IconButton>
        </Box>

        <Divider />

        {/* Content */}
        <Box sx={{ flexGrow: 1, overflowY: "auto", p: 2 }}>
          <Stack spacing={2}>
            <TextField
              label="Mobile number"
              value={mobileNumber}
              onChange={(e) =>
                setMobileNumber(e.target.value.replace(/\D/g, "").slice(0, 10))
              }
            />
            <TextField
              select
              label="Environment"
              value={env}
              onChange={(e) => setEnv(e.target.value)}
            >
              {["DEV", "UAT", "PROD"].map((item) => (
                <MenuItem key={item} value={item}>
                  {item}
                </MenuItem>
              ))}
            </TextField>
            <TextField
              label="Message"
              multiline
              minRows={4}
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              inputProps={{
                maxLength: Number(import.meta.env.VITE_SMS_MAX_LENGTH || 160),
              }}
              helperText={`${message.length}/${Number(import.meta.env.VITE_SMS_MAX_LENGTH || 160)} characters`}
            />
            <Button variant="contained" onClick={sendSms} disabled={loading}>
              {loading ? "Sending..." : "Send SMS"}
            </Button>
          </Stack>
        </Box>
      </Box>
    </Drawer>
  );
}
