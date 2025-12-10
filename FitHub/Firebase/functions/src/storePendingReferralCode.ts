import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { checkRateLimit, RateLimits, getRequestIP } from "./utils/rateLimiter";
import { setCorsHeaders, handleCorsPreflight, requirePost } from "./utils/httpHelpers";
import { generateDeviceId, createFingerprintIndex } from "./utils/fingerprintHelpers";

/**
 * Stores a pending referral code for a device
 * Called from the landing page when a user clicks a referral link
 * Rate limited: 10 requests per minute per IP
 */
export const storePendingReferralCode = functions.https.onRequest(async (req, res) => {
  setCorsHeaders(res);
  if (handleCorsPreflight(req, res)) return;
  if (!requirePost(req, res)) return;

  // Rate limit by IP address
  const ip = getRequestIP(req);
  const result = await checkRateLimit({
    ...RateLimits.STORE_PENDING_TOKEN,
    identifier: ip,
    functionName: "storePendingReferralCode",
  });

  if (!result.allowed) {
    res.status(429).json({
      error: "Rate limit exceeded",
      retryAfter: result.retryAfter,
    });
    return;
  }

  const referralCode = typeof req.body?.referralCode === "string"
    ? req.body.referralCode.trim().toUpperCase()
    : "";
  const deviceFingerprint = typeof req.body?.deviceFingerprint === "string"
    ? req.body.deviceFingerprint
    : null;

  if (!referralCode) {
    res.status(400).json({ error: "Referral code is required" });
    return;
  }

  // Validate code format (basic validation)
  if (referralCode.length < 4 || referralCode.length > 20 || !/^[A-Z0-9]+$/.test(referralCode)) {
    res.status(400).json({ error: "Invalid referral code format" });
    return;
  }

  try {
    const db = admin.firestore();

    console.log("[storePendingReferralCode] Storing referral code:", {
      referralCode: referralCode,
      ipAddress: ip,
      deviceFingerprint: deviceFingerprint ? deviceFingerprint.substring(0, 20) + "..." : null
    });

    // Verify the referral code exists
    const codeRef = db.collection("referralCodes").doc(referralCode);
    const codeDoc = await codeRef.get();

    if (!codeDoc.exists) {
      res.status(404).json({ error: "Referral code not found" });
      return;
    }

    const codeData = codeDoc.data()!;
    if (codeData.isActive !== true) {
      res.status(400).json({ error: "Referral code is not active" });
      return;
    }

    // Create device identifier: IP + User-Agent hash (or use provided fingerprint)
    const userAgent = req.headers["user-agent"] || "";
    const deviceId = generateDeviceId(ip, userAgent, deviceFingerprint);

    if (!deviceId || deviceId.length === 0) {
      console.error("[storePendingReferralCode] ERROR: deviceId is empty!");
      res.status(500).json({ error: "Failed to generate device identifier" });
      return;
    }

    // Store pending referral code (expires in 30 days) - keep expiry for referral codes
    const expiresAt = admin.firestore.Timestamp.fromMillis(Date.now() + (30 * 24 * 60 * 60 * 1000));

    // Store device fingerprints as a map in the referralCodes document
    // Structure: pendingDeviceFingerprints: { [fingerprint]: { storedAt, expiresAt, ipAddress, userAgent } }
    const pendingFingerprints = codeData.pendingDeviceFingerprints || {};

    // If this fingerprint already exists, that's fine (idempotent)
    if (pendingFingerprints[deviceId]) {
      console.log("[storePendingReferralCode] Same device fingerprint already stored (idempotent)");
      res.status(200).json({
        success: true,
        message: "Referral code already stored for this device",
        deviceId: deviceId,
      });
      return;
    }

    // Add new device fingerprint to the map
    pendingFingerprints[deviceId] = {
      storedAt: admin.firestore.FieldValue.serverTimestamp(),
      expiresAt: expiresAt, // Keep expiry for referral codes
      ipAddress: ip,
      userAgent: userAgent.substring(0, 200),
    };

    await codeRef.update({
      pendingDeviceFingerprints: pendingFingerprints,
    });

    // Create reverse index for fast O(1) lookup
    await createFingerprintIndex(db, deviceId, referralCode, {
      indexCollection: "referralCodeFingerprints",
      indexTokenField: "referralCode",
      expiresAt: expiresAt,
    });

    console.log("[storePendingReferralCode] Stored device fingerprint in referralCodes document:", {
      referralCode: referralCode,
      deviceId: deviceId.substring(0, 20) + "...",
      totalFingerprints: Object.keys(pendingFingerprints).length
    });

    res.status(200).json({
      success: true,
      message: "Referral code stored successfully",
      deviceId: deviceId, // Return device ID so app can use it later
    });
  } catch (error: any) {
    console.error("Error storing pending referral code:", error);
    res.status(500).json({ error: "Failed to store referral code" });
  }
});
