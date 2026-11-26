{
"mobileNumber": "xxxxxxxxxx",
"message": "153236 is your OTP for login to FinCore-SBI. This OTP is valid for 3 mins.",
"env":"UAT"
}

import { useState } from "react";
import { Button, MenuItem, Stack, TextField } from "@mui/material";
import UtilityCard from "./UtilityCard";
import api from "../api";
import { useSnackbar } from "../context/SnackbarContext";

const SMS_URL = "https://xyz.abc/api/communication/send-sms";
export default function SmsUtility() {
  const [mobileNumber, setMobileNumber] = useState("");
  const [message, setMessage] = useState("");
  const [env, setEnv] = useState("UAT");
  const [loading, setLoading] = useState(false);
  const { showSnackbar } = useSnackbar();

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
      await api.post(SMS_URL, {
        mobileNumber,
        message,
        env,
      });
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
    <UtilityCard
      title="SMS Utility"
      description="Send a test message to a mobile number."
    >
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
    </UtilityCard>
  );
}



