import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { rateLimitCall } from "./utils/rateLimiter";
import { RateLimits } from "./utils/rateLimiter";

/**
 * Retrieves and claims a pending referral code for a device
 * Called from the app on first launch
 * Returns the referral code if found, then marks it as claimed
 * STRICT: Only matches exact device fingerprint - no fallbacks to prevent false claims
 */
export const getPendingReferralCode = functions.https.onCall(async (data, context) => {
  // Rate limit by user (if authenticated) or allow unauthenticated for first launch
  if (context.auth) {
    await rateLimitCall(context, RateLimits.CHECK_USER_EXISTS, "getPendingReferralCode");
  }

  const deviceFingerprint = typeof data?.deviceFingerprint === "string" ? data.deviceFingerprint : null;
  const userId = context.auth?.uid;

  console.log("[getPendingReferralCode] Request received:", {
    deviceFingerprint: deviceFingerprint ? deviceFingerprint.substring(0, 20) + "..." : null,
    userId: userId || "unauthenticated"
  });

  if (!deviceFingerprint) {
    throw new functions.https.HttpsError("invalid-argument", "Device fingerprint is required");
  }

  try {
    const db = admin.firestore();

    console.log("[getPendingReferralCode] Looking up by device fingerprint:", deviceFingerprint.substring(0, 20) + "...");

    // Query all active referralCodes and search through their pendingDeviceFingerprints
    const referralCodesSnapshot = await db.collection("referralCodes")
      .where("isActive", "==", true)
      .limit(100) // Reasonable limit
      .get();

    if (referralCodesSnapshot.empty) {
      console.log("[getPendingReferralCode] No active referral codes found");
      return { success: false, referralCode: null, reason: "not_found" };
    }

    // Find the code that has this device fingerprint in its pendingDeviceFingerprints map
    let codeDoc = null;
    let referralCode = null;
    let codeData = null;

    for (const doc of referralCodesSnapshot.docs) {
      const data = doc.data();
      const pendingFingerprints = data.pendingDeviceFingerprints || {};
      if (pendingFingerprints[deviceFingerprint]) {
        codeDoc = doc;
        referralCode = doc.id;
        codeData = data;
        break;
      }
    }

    if (!codeDoc || !referralCode) {
      console.log("[getPendingReferralCode] No referral code found with this device fingerprint");
      return { success: false, referralCode: null, reason: "not_found" };
    }

    console.log("[getPendingReferralCode] Found referral code:", referralCode);

    if (!codeData) {
      console.log("[getPendingReferralCode] Code data is null");
      return { success: false, referralCode: null, reason: "invalid_data" };
    }

    // Check if this specific fingerprint entry has expired (keep expiry for referral codes)
    const pendingFingerprints = codeData.pendingDeviceFingerprints || {};
    const fingerprintData = pendingFingerprints[deviceFingerprint];

    if (!fingerprintData) {
      console.log("[getPendingReferralCode] Device fingerprint not found in pending fingerprints");
      return { success: false, referralCode: null, reason: "not_found" };
    }

    const expiresAt = fingerprintData.expiresAt?.toMillis();
    if (expiresAt && expiresAt < Date.now()) {
      console.log("[getPendingReferralCode] Device fingerprint entry expired");
      // Remove expired fingerprint entry
      const updatedFingerprints = { ...pendingFingerprints };
      delete updatedFingerprints[deviceFingerprint];
      await codeDoc.ref.update({
        pendingDeviceFingerprints: updatedFingerprints,
      });
      return { success: false, referralCode: null, reason: "expired" };
    }

    console.log("[getPendingReferralCode] Successfully retrieved referral code:", referralCode);

    return {
      success: true,
      referralCode: referralCode,
    };
  } catch (error: any) {
    console.error("[getPendingReferralCode] Error:", error);
    throw new functions.https.HttpsError("internal", "Failed to retrieve referral code");
  }
});
