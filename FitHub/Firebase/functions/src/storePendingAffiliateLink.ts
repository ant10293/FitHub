import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { checkRateLimit, RateLimits, getRequestIP } from "./utils/rateLimiter";
import { setCorsHeaders, handleCorsPreflight, requirePost } from "./utils/httpHelpers";
import { generateDeviceId, createFingerprintIndex } from "./utils/fingerprintHelpers";

/**
 * Stores a pending affiliate link for a device
 * Called from the landing page when a user clicks an affiliate link
 * Rate limited: 10 requests per minute per IP
 */
export const storePendingAffiliateLink = functions.https.onRequest(async (req, res) => {
  setCorsHeaders(res);
  if (handleCorsPreflight(req, res)) return;
  if (!requirePost(req, res)) return;

  // Rate limit by IP address
  const ip = getRequestIP(req);
  const result = await checkRateLimit({
    ...RateLimits.STORE_PENDING_TOKEN,
    identifier: ip,
    functionName: "storePendingAffiliateLink",
  });

  if (!result.allowed) {
    res.status(429).json({
      error: "Rate limit exceeded",
      retryAfter: result.retryAfter,
    });
    return;
  }

  const linkToken = typeof req.body?.linkToken === "string"
    ? req.body.linkToken.trim()
    : "";
  const deviceFingerprint = typeof req.body?.deviceFingerprint === "string"
    ? req.body.deviceFingerprint
    : null;

  console.log("[storePendingAffiliateLink] Request received:", {
    linkToken: linkToken || "MISSING",
    deviceFingerprint: deviceFingerprint ? deviceFingerprint.substring(0, 20) + "..." : "MISSING",
    bodyKeys: Object.keys(req.body || {}),
    ipAddress: ip
  });

  if (!linkToken) {
    console.error("[storePendingAffiliateLink] Link token is required");
    res.status(400).json({ error: "Link token is required" });
    return;
  }

  // Validate token format (alphanumeric, 16-64 characters)
  if (linkToken.length < 16 || linkToken.length > 64 || !/^[a-zA-Z0-9]+$/.test(linkToken)) {
    console.error("[storePendingAffiliateLink] Invalid link token format:", linkToken);
    res.status(400).json({ error: "Invalid link token format" });
    return;
  }

  try {
    const db = admin.firestore();

    console.log("[storePendingAffiliateLink] Storing affiliate link:", {
      linkToken: linkToken,
      ipAddress: ip,
      deviceFingerprint: deviceFingerprint ? deviceFingerprint.substring(0, 20) + "..." : "NULL",
      deviceFingerprintLength: deviceFingerprint ? deviceFingerprint.length : 0
    });

    // Verify the affiliate link exists and is not already claimed
    const linkRef = db.collection("affiliateLinks").doc(linkToken);
    const linkDoc = await linkRef.get();

    if (!linkDoc.exists) {
      res.status(404).json({ error: "Affiliate link not found" });
      return;
    }

    const linkData = linkDoc.data()!;

    // Check if link is already claimed
    if (linkData.claimed === true) {
      res.status(400).json({ error: "Affiliate link has already been claimed" });
      return;
    }

    // Create device identifier: IP + User-Agent hash (or use provided fingerprint)
    const userAgent = req.headers["user-agent"] || "";
    const deviceId = generateDeviceId(ip, userAgent, deviceFingerprint);

    if (!deviceId || deviceId.length === 0) {
      console.error("[storePendingAffiliateLink] ERROR: deviceId is empty!");
      res.status(500).json({ error: "Failed to generate device identifier" });
      return;
    }

    // Store device fingerprints as a map (multiple devices can access the same link)
    // Structure: pendingDeviceFingerprints: { [fingerprint]: { storedAt, ipAddress, userAgent } }
    const pendingFingerprints = linkData.pendingDeviceFingerprints || {};

    // If this fingerprint already exists, that's fine (idempotent)
    if (pendingFingerprints[deviceId]) {
      console.log("[storePendingAffiliateLink] Same device fingerprint already stored (idempotent)");
      res.status(200).json({
        success: true,
        message: "Affiliate link already stored for this device",
        deviceId: deviceId,
      });
      return;
    }

    // Add new device fingerprint to the map
    pendingFingerprints[deviceId] = {
      storedAt: admin.firestore.FieldValue.serverTimestamp(),
      ipAddress: ip,
      userAgent: userAgent.substring(0, 200),
    };

    await linkRef.update({
      pendingDeviceFingerprints: pendingFingerprints,
    });

    // Create reverse index for fast O(1) lookup
    await createFingerprintIndex(db, deviceId, linkToken, {
      indexCollection: "affiliateLinkFingerprints",
      indexTokenField: "linkToken",
    });

    console.log("[storePendingAffiliateLink] Stored device fingerprint in affiliateLinks document:", {
      linkToken: linkToken,
      deviceId: deviceId.substring(0, 20) + "...",
      totalFingerprints: Object.keys(pendingFingerprints).length
    });

    res.status(200).json({
      success: true,
      message: "Affiliate link stored successfully",
      deviceId: deviceId, // Return device ID so app can use it later
    });
  } catch (error: any) {
    console.error("Error storing pending affiliate link:", error);
    res.status(500).json({ error: "Failed to store affiliate link" });
  }
});
