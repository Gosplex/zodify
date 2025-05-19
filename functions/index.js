/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const { onRequest } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const { RtcTokenBuilder, RtcRole } = require("agora-token");

// Generate Agora RTC token for video/audio calls
exports.generateRtcToken = onRequest(
  { cors: true, secrets: ["AGORA_APP_ID", "AGORA_APP_CERTIFICATE", "API_KEY"] },
  async (request, response) => {
    // Log incoming request
    logger.info("Processing token request", {
      channelName: request.query.channelName,
      uid: request.query.uid,
      role: request.query.role,
    });

    // Prevent response caching
    response.set("Cache-Control", "private, no-cache, no-store, must-revalidate");
    response.set("Expires", "-1");
    response.set("Pragma", "no-cache");

    // Verify API key
    const apiKey = request.headers["x-api-key"];
    if (!apiKey || apiKey !== process.env.API_KEY) {
      logger.error("Unauthorized request", { apiKeyProvided: !!apiKey });
      response.status(401).json({ error: "Unauthorized" });
      return;
    }

    // Extract query parameters
    const { channelName, role, tokenType, uid, expiry } = request.query;

    // Validate channelName
    if (!channelName) {
      logger.error("Missing channelName parameter");
      response.status(400).json({ error: "channelName is required" });
      return;
    }

    // Load Agora credentials from secrets
    const appId = process.env.AGORA_APP_ID;
    const appCertificate = process.env.AGORA_APP_CERTIFICATE;

    if (!appId || !appCertificate) {
      logger.error("Agora credentials missing");
      response.status(500).json({ error: "Agora credentials not configured" });
      return;
    }

    // Set role (publisher or subscriber)
    const roleValue = role === "publisher" ? RtcRole.PUBLISHER : RtcRole.SUBSCRIBER;

    // Calculate token expiration (default: 1 hour)
    const currentTimestamp = Math.floor(Date.now() / 1000);
    const privilegeExpiredTs = currentTimestamp + (parseInt(expiry) || 3600);

    try {
      let token;
      if (tokenType === "uid") {
        const uidValue = parseInt(uid) || 0; // Use 0 if uid is invalid
        token = RtcTokenBuilder.buildTokenWithUid(
          appId,
          appCertificate,
          channelName,
          uidValue,
          roleValue,
          privilegeExpiredTs
        );
      } else if (tokenType === "userAccount") {
        token = RtcTokenBuilder.buildTokenWithUserAccount(
          appId,
          appCertificate,
          channelName,
          uid,
          roleValue,
          privilegeExpiredTs
        );
      } else {
        logger.error("Invalid tokenType", { tokenType });
        response.status(400).json({ error: "Invalid tokenType. Use 'uid' or 'userAccount'" });
        return;
      }

      // Send successful response
      logger.info("Token generated", { channelName, uid });
      response.json({ rtcToken: token });
    } catch (error) {
      logger.error("Token generation failed", { error: error.message });
      response.status(500).json({ error: "Failed to generate token", details: error.message });
    }
  }
);