import React from "react";
import Home from "./pages/Home";

export default function App() {
  return <Home />;
}


import React, { useState } from "react";
import { Box, Paper, Typography } from "@mui/material";
import fincoreLogo from "../assets/Fincore_logo.svg";
import fincoreTitle from "../assets/Fincore_title.png";
import fincoreBackground from "../assets/Fincore_bg.png";
import Copyright from "../components/Copyright";
import EncryptorDecryptor from "../components/EncryptorDecryptor";
import SmsUtility from "../components/SmsUtility";
import MailUtility from "../components/MailUtility";

// content
const content = {
  brand: {
    title: "FinCore",
    subtitle: "Insight Driven General Ledger",
  },
  hero: {
    welcomeTitle:
      "Welcome to FinCore application - Enabling trusted and centralized GL reporting",
    subText:
      "FinCore Application provides a centralized platform for seamless access to and generation of critical financial reports, delivering secure, reliable and high-integrity financial data",
  },
  legal: {
    title: "Legal Warning",
    items: [
      "This application is for the use of authorized users only.",
      "All activities on this application may be recorded and monitored.",
      "Individuals using this application without authority or in excess of their authority are subject to disciplinary action and/or criminal prosecution.",
    ],
  },
};

export default function Login() {
  const [page, setPage] = useState("HOME"); // HOME | SMS | MAIL

  return (
    <Box
      sx={{
        minHeight: "100vh",
        width: "100%",
        display: "flex",
        flexDirection: "column",
        justifyContent: "center",
        alignItems: "center",
        position: "relative",
        // backgroundColor: theme.palette.background.default,
        backgroundImage: `url(${fincoreBackground})`,
        backgroundRepeat: "no-repeat",
        backgroundPosition: "center center",
        backgroundSize: "cover",
        padding: 2,
        boxSizing: "border-box",
        "&::after": {
          content: '""',
          position: "absolute",
          inset: 0,
          background:
            "linear-gradient(180deg, rgba(255,255,255,0.06) 0%, rgba(255,255,255,0.03) 50%, rgba(0,0,0,0.02) 100%)",
          pointerEvents: "none",
          zIndex: 1,
        },
      }}
    >
      {/* ... Existing Layout Containers ... */}
      <Box
        sx={{
          flexGrow: 1,
          display: "flex",
          alignItems: "center",
          width: "100%",
          py: { xs: 4, md: 6 },
          px: { xs: 2.5, sm: 4, md: 6 },
        }}
      >
        <Box
          sx={{
            width: "100%",
            maxWidth: 1200,
            position: "relative",
            zIndex: 2,
            margin: "auto",
            display: "flex",
            flexDirection: "column",
            gap: 4,
          }}
        >
          <Box
            sx={{
              display: "flex",
              flexDirection: { xs: "column", md: "row" },
              gap: { xs: 5, md: 4 },
              alignItems: "center",
              justifyContent: "space-between",
              width: "100%",
            }}
          >
            <Box
              sx={{
                flex: "1 1 50%",
                display: "flex",
                flexDirection: "column",
                gap: 2.5,
                justifyContent: "center",
                width: "100%",
              }}
            >
              <Box
                sx={{
                  display: "flex",
                  alignItems: "center",
                  gap: 2,
                }}
              >
                <Box
                  component="img"
                  src={fincoreLogo}
                  alt="Logo Icon"
                  sx={{ width: { xs: 100, sm: 130, md: 150 }, height: "auto" }}
                />
                <Box sx={{ textAlign: { xs: "center", md: "left" } }}>
                  <Box
                    component="img"
                    src={fincoreTitle}
                    alt="FinCore"
                    sx={{
                      height: { xs: 28, md: 35 },
                      width: "auto",
                      mx: { xs: "auto", md: 0 },
                      mt: { xs: 2, md: 5 },
                      mb: 1,
                    }}
                  />
                  <Typography
                    sx={{
                      fontSize: "1rem",
                      color: "text.secondary",
                    }}
                  >
                    {content?.brand?.subtitle}
                  </Typography>
                </Box>
              </Box>

              <Box
                sx={{
                  display: { xs: "none", md: "block" },
                  mt: 2,
                  mb: 1,
                  textAlign: { xs: "center", md: "left" },
                }}
              >
                <Typography
                  sx={{
                    fontWeight: 800,
                    fontSize: "2rem",
                    lineHeight: 1.3,
                    color: "text.primary",
                  }}
                >
                  {(content?.hero?.welcomeTitle || "").split(" - ")[0]}
                </Typography>
                {content?.hero?.welcomeTitle?.includes(" - ") && (
                  <Typography
                    sx={{
                      fontSize: "1rem",
                      color: "text.secondary",
                      lineHeight: 1.6,
                    }}
                  >
                    {content?.hero?.welcomeTitle.split(" - ")[1]}
                  </Typography>
                )}
              </Box>

              <Typography
                sx={{
                  fontSize: "1rem",
                  color: "text.secondary",
                  lineHeight: 1.6,
                  display: { xs: "none", md: "block" },
                  textAlign: { xs: "center", md: "left" },
                }}
              >
                {content?.hero?.subText}
              </Typography>

              <Box sx={{ display: { xs: "none", md: "block" }, mt: 3 }}>
                <Typography
                  sx={{
                    fontWeight: 800,
                    fontSize: "2rem",
                    lineHeight: 1.3,
                    color: "text.primary",
                  }}
                >
                  {content?.legal?.title}
                </Typography>
                <ul
                  sx={{
                    mt: 2,
                    margin: 0,
                    padding: 0,
                    listStyle: "none",
                    display: "flex",
                    flexDirection: "column",
                    gap: 1.5,
                    alignItems: "flex-start",
                  }}
                >
                  {content?.legal?.items.map((item, idx) => (
                    <li
                      key={idx}
                      style={{
                        display: "flex",
                        alignItems: "center",
                        gap: 1.5,
                        color: "text.primary",
                        fontSize: "1rem",
                        textAlign: "left",
                      }}
                    >
                      <span
                        style={{
                          width: 10,
                          height: 10,
                          borderRadius: "50%",
                          background: "#6256B5",
                          display: "inline-block",
                          flexShrink: 0,
                        }}
                      />{" "}
                      {item}
                    </li>
                  ))}
                </ul>
              </Box>
            </Box>

            <Box
              sx={{
                display: "flex",
                flexDirection: "column",
                alignItems: "center",
                width: "100%",
                flex: "1 1 50%",
                justifyContent: "flex-end",
              }}
            >
              <Paper
                elevation={3}
                sx={{
                  width: "100%",
                  maxWidth: 700,
                  padding: 4,
                  boxShadow: "0 12px 30px rgba(16,24,40,0.12)",
                  background:
                    "linear-gradient(180deg, rgba(255, 255, 255, 0.43), rgba(255, 255, 255, 0.38))",
                  border: `1px solid rgba(255,255,255,0.5)`,
                  backdropFilter: "blur(6px)",
                  boxSizing: "border-box",
                }}
              >
                <Typography
                  align="center"
                  sx={{
                    fontWeight: 600,
                    marginBottom: 1.5,
                    color: "text.primary",
                    fontSize: "1.1rem",
                  }}
                >
                  {page === "HOME"
                    ? "Crypto Utility"
                    : page === "SMS"
                      ? "SMS Utility"
                      : "Mail Utility"}
                </Typography>

                {page === "HOME" && <EncryptorDecryptor />}
                {page === "SMS" && <SmsUtility />}
                {page === "MAIL" && <MailUtility />}
              </Paper>

              {/* Mobile Legal Box */}
              <Box
                sx={{
                  display: { xs: "block", md: "none" },
                  mt: 5,
                  width: "100%",
                }}
              >
                <Typography
                  sx={{
                    fontSize: { xs: "1.2rem", md: "1.5rem" },
                    textAlign: "center",
                    mb: 2,
                  }}
                >
                  {content?.legal?.title}
                </Typography>
                <ul
                  sx={{
                    mt: 2,
                    margin: 0,
                    padding: 0,
                    listStyle: "none",
                    display: "flex",
                    flexDirection: "column",
                    gap: 1.5,
                    alignItems: "flex-start",
                  }}
                >
                  {content?.legal?.items.map((item, idx) => (
                    <li
                      key={idx}
                      style={{
                        display: "flex",
                        alignItems: "center",
                        gap: 1.5,
                        color: "text.primary",
                        fontSize: { xs: "0.875rem", sm: "1rem" },
                        textAlign: "left",
                      }}
                    >
                      <span
                        style={{
                          width: 10,
                          height: 10,
                          borderRadius: "50%",
                          background: "#6256B5",
                          display: "inline-block",
                          flexShrink: 0,
                        }}
                      />{" "}
                      {item}
                    </li>
                  ))}
                </ul>
              </Box>
            </Box>
          </Box>
        </Box>
      </Box>

      <Box sx={{ width: "100%", zIndex: 2 }}>
        <Copyright />
      </Box>
    </Box>
  );
}


import { createTheme } from "@mui/material/styles";

const theme = createTheme({
  palette: {
    primary: { main: "#6256B5", light: "#8B82D5", dark: "#433A91" },
    secondary: { main: "#B34B91" },
    background: { default: "#F5F2FB", paper: "#FFFFFF" },
    text: { primary: "#55558A", secondary: "#77758F" },
    warning: { main: "#B34B91" },
  },
  typography: {
    fontFamily: '"Roboto", "Arial", sans-serif',
    h3: { fontWeight: 800, fontSize: "2rem", lineHeight: 1.3 },
    h4: { fontWeight: 700, fontSize: "2rem", lineHeight: 1 },
    h5: { fontWeight: 500, fontSize: "1.25rem", lineHeight: 1.2 },
    h6: { fontWeight: 600, fontSize: "1.1rem" },
    body1: { fontSize: "1rem", lineHeight: 1.6 },
    body2: { fontSize: "0.85rem", lineHeight: 1.4, fontWeight: 400 },
    caption: { fontSize: "0.625rem", fontWeight: 700, letterSpacing: "1.5px" },
    button: { textTransform: "none", fontWeight: 600 },
  },
  shape: { borderRadius: 10 },
  components: {
    MuiButton: {
      styleOverrides: {
        root: { borderRadius: 10, minHeight: 42, boxShadow: "none" },
        containedPrimary: {
          background: "linear-gradient(100deg, #8D83E8 0%, #7065D4 100%)",
          color: "#fff",
          fontWeight: 700,
          padding: "12px 16px",
          "&:hover": {
            background: "linear-gradient(100deg, #7E74D9 0%, #6257C6 100%)",
            boxShadow: "none",
          },
        },
      },
    },
    MuiPaper: {
      styleOverrides: {
        root: {
          borderRadius: 18,
          padding: "16px",
          boxShadow: "0 12px 30px rgba(16,24,40,0.12)",
          background:
            "linear-gradient(180deg, rgba(255,255,255,0.43), rgba(255,255,255,0.38))",
          border: "1px solid rgba(255,255,255,0.5)",
          backdropFilter: "blur(6px)",
          boxSizing: "border-box",
          "@media (max-width: 600px)": { padding: "10px" },
        },
      },
    },
    MuiTextField: {
      defaultProps: { fullWidth: true, size: "small" },
    },
    MuiOutlinedInput: {
      styleOverrides: {
        root: {
          borderRadius: 10,
          backgroundColor: "rgba(255,255,255,0.95)",
          "& fieldset": { borderColor: "rgba(0,0,0,0.06)" },
        },
      },
    },
    MuiTabs: {
      styleOverrides: {
        root: {
          borderBottom: "1px solid rgba(98, 86, 181, 0.14)",
        },
        indicator: { height: 3, borderRadius: 3 },
      },
    },
    MuiTab: {
      styleOverrides: {
        root: {
          minHeight: 42,
          fontSize: "0.78rem",
          fontWeight: 600,
          textTransform: "none",
        },
      },
    },
    MuiList: {
      styleOverrides: {
        root: {
          margin: 0,
          padding: 0,
          listStyle: "none",
          display: "flex",
          flexDirection: "column",
          gap: "12px",
        },
      },
    },
    MuiListItem: {
      styleOverrides: {
        root: {
          display: "flex",
          alignItems: "center",
          gap: "12px",
          color: "inherit",
          fontSize: "1rem",
          textAlign: "left",
        },
      },
    },
  },
});

export default theme;
