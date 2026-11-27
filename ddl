<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>${mailSubject!"FinCore Notification"}</title>
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
                        <td width="10"></td>
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

              <!-- CUSTOM MAIL CARD -->
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
                            line-height: 25px;
                            color: #111111;
                            font-family: &quot;Times New Roman&quot;, Times, serif;
                          "
                        >
                          <!-- GREETING -->
                          <div
                            style="
                              font-size: 20px;
                              font-weight: bold;
                              margin-bottom: 18px;
                            "
                          >
                            Dear ${recipientName!"User"},
                          </div>

                          <!-- PASTED CUSTOM BODY -->
                          <div
                            style="
                              font-size: 16px;
                              line-height: 26px;
                              margin-bottom: 28px;
                              word-break: break-word;
                            "
                          >
                            ${(mailBody!"")?esc?replace("\r\n", "<br/>")?replace("\n", "<br/>")}
                          </div>

                          <!-- SIGNATURE BLOCK -->
                          <div
                            style="
                              margin-top: 24px;
                              padding-top: 18px;
                              border-top: 1px solid rgba(124, 58, 237, 0.18);
                              font-size: 15px;
                              line-height: 22px;
                              color: #1f1f1f;
                            "
                          >
                            <div>Warm regards,</div>
                            <div style="font-weight: 700; margin-top: 6px; color: #3b0764;">
                              ${senderName!"FinCore System Team"}
                            </div>
                            <#if senderDesignation?has_content>
                              <div style="font-size: 14px; color: #444444;">
                                ${senderDesignation}
                              </div>
                            </#if>
                            <div style="font-size: 14px; color: #444444;">
                              FinCore — Insight Driven General Ledger | State Bank of India
                            </div>
                          </div>

                          <!-- SYSTEM GENERATED / DO NOT REPLY NOTICE -->
                          <div
                            style="
                              margin-top: 26px;
                              padding: 12px 16px;
                              background: rgba(255, 255, 255, 0.52);
                              border: 1px solid rgba(124, 58, 237, 0.22);
                              border-left: 4px solid #7c3aed;
                              border-radius: 12px;
                              font-size: 13px;
                              line-height: 19px;
                              color: #4a3b5c;
                            "
                          >
                            <strong>Note:</strong> This is a system-generated email from
                            <strong>FinCore</strong>. Please <strong>do not reply</strong> to
                            this message. For assistance, contact the FinCore Support Desk.
                          </div>

                          <!-- FOOTER -->
                          <div
                            style="
                              margin-top: 28px;
                              padding-top: 16px;
                              border-top: 1px solid rgba(0, 0, 0, 0.08);
                              color: #555555;
                              font-size: 13px;
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