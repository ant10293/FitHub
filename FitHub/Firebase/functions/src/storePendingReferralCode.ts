import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { checkRateLimit, RateLimits, getRequestIP } from "./utils/rateLimiter";

/**
 * Stores a pending referral code for a device
 * Called from the landing page when a user clicks a referral link
 * Rate limited: 10 requests per minute per IP
 */
export const storePendingReferralCode = functions.https.onRequest(async (req, res) => {
  // Handle CORS preflight
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type");

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  // Only allow POST
  if (req.method !== "POST") {
    res.status(405).send("Method not allowed");
    return;
  }

  // Rate limit by IP address
  const ip = getRequestIP(req);
  const result = await checkRateLimit({
    ...RateLimits.CHECK_USER_EXISTS, // Reuse same limits (20/min)
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

    // Create device identifier: IP + User-Agent hash (or use provided fingerprint)
    const userAgent = req.headers["user-agent"] || "";
    const deviceId = deviceFingerprint || `${ip}_${userAgent.substring(0, 50)}`.replace(/[^a-zA-Z0-9_]/g, "_");

    // Store pending referral code (expires in 30 days)
    const expiresAt = admin.firestore.Timestamp.fromMillis(Date.now() + (30 * 24 * 60 * 60 * 1000));

    // Store with device fingerprint as primary key
    // Use merge to update existing document if it exists (e.g., if IP changes but fingerprint is same)
    await db.collection("pendingReferralCodes").doc(deviceId).set({
      referralCode: referralCode,
      ipAddress: ip,
      userAgent: userAgent.substring(0, 200),
      deviceFingerprint: deviceFingerprint,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      expiresAt: expiresAt,
      claimed: false,
    }, { merge: true });
    console.log("[storePendingReferralCode] Stored with device fingerprint key:", deviceId.substring(0, 20) + "...");

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
