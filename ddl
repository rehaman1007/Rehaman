
import React from "react";
import Box from "@mui/material/Box";
import Home from "./pages/Home";
import fincoreBackground from "./assets/Fincore_bg.png";

export default function App() {
  return (
    <Box
      sx={{
        minHeight: "100vh",
        width: "100%",
        position: "relative",
        overflow: "hidden",
        backgroundImage: `url(${fincoreBackground})`,
        backgroundRepeat: "no-repeat",
        backgroundPosition: "center",
        backgroundSize: "cover",

        "&::before": {
          content: '""',
          position: "absolute",
          inset: 0,
          background:
            "linear-gradient(135deg, rgba(255,255,255,0.12), rgba(98,86,181,0.06))",
          pointerEvents: "none",
          zIndex: 0,
        },
      }}
    >
      <Box sx={{ position: "relative", zIndex: 1 }}>
        <Home />
      </Box>
    </Box>
  );
}






import React, { useState } from "react";
import {
  Box,
  Paper,
  Typography,
  Tabs,
  Tab,
  Fade,
} from "@mui/material";

import fincoreLogo from "../assets/Fincore_logo.svg";
import fincoreTitle from "../assets/Fincore_title.png";

import Copyright from "../components/Copyright";
import EncryptorDecryptor from "../components/EncryptorDecryptor";
import SmsUtility from "../components/SmsUtility";
import MailUtility from "../components/MailUtility";

const content = {
  brand: {
    subtitle: "Insight Driven General Ledger",
  },

  hero: {
    title: "Welcome to FinCore application",
    subtitle: "Enabling trusted and centralized GL reporting",
    description:
      "FinCore Application provides a centralized platform for seamless access to and generation of critical financial reports, delivering secure, reliable and high-integrity financial data.",
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

const utilities = [
  {
    label: "Encryptor / Decryptor",
    value: "HOME",
    component: <EncryptorDecryptor />,
  },
  {
    label: "SMS Utility",
    value: "SMS",
    component: <SmsUtility />,
  },
  {
    label: "Mail Utility",
    value: "MAIL",
    component: <MailUtility />,
  },
];

export default function Home() {
  const [page, setPage] = useState("HOME");

  const selectedUtility = utilities.find(
    (utility) => utility.value === page
  );

  return (
    <Box
      sx={{
        minHeight: "100vh",
        height: { xs: "auto", md: "100vh" },
        width: "100%",
        display: "flex",
        flexDirection: "column",
        boxSizing: "border-box",
        overflowX: "hidden",
      }}
    >
      {/* MAIN TWO-COLUMN LAYOUT */}
      <Box
        sx={{
          flex: 1,
          minHeight: 0,
          width: "100%",
          display: "grid",
          gridTemplateColumns: {
            xs: "1fr",
            md: "1fr 1fr",
          },
          gap: {
            xs: 3,
            md: 0,
          },
          px: {
            xs: 2,
            sm: 3,
            md: 4,
            lg: 6,
          },
          py: {
            xs: 3,
            md: 3,
          },
          boxSizing: "border-box",
        }}
      >
        {/* LEFT COLUMN - FINCORE INFORMATION */}
        <Box
          sx={{
            minWidth: 0,
            display: "flex",
            flexDirection: "column",
            justifyContent: "center",
            px: {
              xs: 1,
              sm: 2,
              md: 3,
              lg: 5,
            },
            py: {
              xs: 3,
              md: 2,
            },
            animation: "slideInLeft 700ms ease-out",

            "@keyframes slideInLeft": {
              from: {
                opacity: 0,
                transform: "translateX(-25px)",
              },
              to: {
                opacity: 1,
                transform: "translateX(0)",
              },
            },
          }}
        >
          {/* FINCORE BRANDING */}
          <Box
            sx={{
              display: "flex",
              alignItems: "center",
              gap: {
                xs: 1.5,
                sm: 2,
              },
              mb: {
                xs: 4,
                md: 5,
              },
            }}
          >
            <Box
              component="img"
              src={fincoreLogo}
              alt="FinCore Logo"
              sx={{
                width: {
                  xs: 75,
                  sm: 100,
                  md: 115,
                  lg: 135,
                },
                height: "auto",
                objectFit: "contain",
              }}
            />

            <Box>
              <Box
                component="img"
                src={fincoreTitle}
                alt="FinCore"
                sx={{
                  width: {
                    xs: 145,
                    sm: 180,
                    md: 190,
                    lg: 220,
                  },
                  height: "auto",
                  display: "block",
                  mb: 0.5,
                }}
              />

              <Typography
                sx={{
                  color: "text.secondary",
                  fontSize: {
                    xs: "0.75rem",
                    sm: "0.9rem",
                  },
                }}
              >
                {content.brand.subtitle}
              </Typography>
            </Box>
          </Box>

          {/* WELCOME SECTION */}
          <Box sx={{ mb: 4 }}>
            <Typography
              variant="h3"
              sx={{
                color: "text.primary",
                fontWeight: 800,
                fontSize: {
                  xs: "1.7rem",
                  sm: "2rem",
                  lg: "2.2rem",
                },
                lineHeight: 1.3,
                mb: 1,
              }}
            >
              {content.hero.title}
            </Typography>

            <Typography
              sx={{
                color: "text.secondary",
                fontSize: {
                  xs: "0.95rem",
                  sm: "1.05rem",
                },
                fontWeight: 500,
                mb: 2,
              }}
            >
              {content.hero.subtitle}
            </Typography>

            <Typography
              sx={{
                color: "text.secondary",
                fontSize: "0.9rem",
                lineHeight: 1.9,
                maxWidth: 570,
              }}
            >
              {content.hero.description}
            </Typography>
          </Box>

          {/* LEGAL WARNING SECTION */}
          <Box
            sx={{
              mt: {
                xs: 1,
                md: 2,
              },
              maxWidth: 590,
            }}
          >
            <Typography
              variant="h4"
              sx={{
                color: "text.primary",
                fontWeight: 800,
                fontSize: {
                  xs: "1.5rem",
                  sm: "1.8rem",
                },
                mb: 2,
              }}
            >
              {content.legal.title}
            </Typography>

            <Box
              component="ul"
              sx={{
                m: 0,
                p: 0,
                listStyle: "none",
                display: "flex",
                flexDirection: "column",
                gap: 2,
              }}
            >
              {content.legal.items.map((item, index) => (
                <Box
                  component="li"
                  key={index}
                  sx={{
                    display: "flex",
                    alignItems: "flex-start",
                    gap: 1.5,
                    color: "text.secondary",
                    fontSize: {
                      xs: "0.82rem",
                      sm: "0.9rem",
                    },
                    lineHeight: 1.8,
                    transition: "transform 200ms ease",

                    "&:hover": {
                      transform: "translateX(5px)",
                    },
                  }}
                >
                  <Box
                    sx={{
                      width: 9,
                      height: 9,
                      minWidth: 9,
                      borderRadius: "50%",
                      background:
                        "linear-gradient(135deg, #B34B91, #6256B5)",
                      mt: 1,
                    }}
                  />

                  {item}
                </Box>
              ))}
            </Box>
          </Box>
        </Box>

        {/* RIGHT COLUMN - UTILITIES */}
        <Box
          sx={{
            minWidth: 0,
            minHeight: {
              xs: 600,
              md: 0,
            },
            width: "100%",
            height: {
              xs: "auto",
              md: "100%",
            },
            display: "flex",
            flexDirection: "column",
            animation: "slideInRight 700ms ease-out",

            "@keyframes slideInRight": {
              from: {
                opacity: 0,
                transform: "translateX(25px)",
              },
              to: {
                opacity: 1,
                transform: "translateX(0)",
              },
            },
          }}
        >
          <Paper
            elevation={0}
            sx={{
              width: "100%",
              height: {
                xs: "auto",
                md: "100%",
              },
              minHeight: {
                xs: 600,
                md: 0,
              },
              flex: 1,
              display: "flex",
              flexDirection: "column",
              boxSizing: "border-box",
              overflow: "hidden",
              p: {
                xs: 2,
                sm: 3,
                md: 3,
                lg: 4,
              },
              background:
                "linear-gradient(180deg, rgba(255,255,255,0.58), rgba(255,255,255,0.42))",
              border: "1px solid rgba(255,255,255,0.7)",
              backdropFilter: "blur(12px)",
              boxShadow: "0 15px 45px rgba(65,55,130,0.13)",
              transition: "box-shadow 300ms ease",

              "&:hover": {
                boxShadow: "0 18px 50px rgba(65,55,130,0.18)",
              },
            }}
          >
            {/* PANEL HEADER */}
            <Box sx={{ mb: 2 }}>
              <Typography
                variant="caption"
                sx={{
                  color: "primary.light",
                  letterSpacing: 2,
                  fontWeight: 700,
                }}
              >
                FINCORE DEVELOPER TOOLKIT
              </Typography>

              <Typography
                variant="h5"
                sx={{
                  color: "text.primary",
                  fontWeight: 800,
                  mt: 0.5,
                }}
              >
                Utilities
              </Typography>

              <Typography
                variant="body2"
                color="text.secondary"
                sx={{ mt: 0.5 }}
              >
                Select a utility to get started.
              </Typography>
            </Box>

            {/* UTILITY NAVIGATION */}
            <Tabs
              value={page}
              onChange={(_, newValue) => setPage(newValue)}
              variant="fullWidth"
              sx={{
                flexShrink: 0,
                mb: 2,

                "& .MuiTab-root": {
                  minWidth: 0,
                  px: {
                    xs: 0.5,
                    sm: 1,
                  },
                  fontSize: {
                    xs: "0.7rem",
                    sm: "0.8rem",
                  },
                  transition: "all 200ms ease",
                },
              }}
            >
              {utilities.map((utility) => (
                <Tab
                  key={utility.value}
                  label={utility.label}
                  value={utility.value}
                />
              ))}
            </Tabs>

            {/* DYNAMIC UTILITY CONTENT */}
            <Box
              sx={{
                flex: 1,
                minHeight: 0,
                width: "100%",
                overflowY: "auto",
                overflowX: "hidden",
                pr: 0.5,

                "&::-webkit-scrollbar": {
                  width: 5,
                },

                "&::-webkit-scrollbar-thumb": {
                  backgroundColor: "rgba(98,86,181,0.3)",
                  borderRadius: 10,
                },
              }}
            >
              <Fade in key={page} timeout={350}>
                <Box
                  sx={{
                    width: "100%",
                    minHeight: "100%",
                    animation: "contentFade 350ms ease",

                    "@keyframes contentFade": {
                      from: {
                        opacity: 0,
                        transform: "translateY(8px)",
                      },
                      to: {
                        opacity: 1,
                        transform: "translateY(0)",
                      },
                    },
                  }}
                >
                  {selectedUtility?.component}
                </Box>
              </Fade>
            </Box>
          </Paper>
        </Box>
      </Box>

      {/* COPYRIGHT */}
      <Box
        sx={{
          flexShrink: 0,
          width: "100%",
          px: 2,
          position: "relative",
          zIndex: 2,
        }}
      >
        <Copyright />
      </Box>
    </Box>
  );
}




