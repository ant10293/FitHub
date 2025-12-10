import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { rateLimitCall } from "./utils/rateLimiter";
import { RateLimits } from "./utils/rateLimiter";
import { lookupByFingerprint, FingerprintLookupConfig } from "./utils/fingerprintHelpers";
import { extractString, requireString } from "./utils/authHelpers";

/**
 * Retrieves and claims a pending referral code for a device
 * Called from the app on first launch
 * Returns the referral code if found, then marks it as claimed
 * STRICT: Only matches exact device fingerprint - no fallbacks to prevent false claims
 */
export const getPendingReferralCode = functions.https.onCall(async (data, context) => {
  // Rate limit by user (if authenticated) or allow unauthenticated for first launch
  if (context.auth) {
    await rateLimitCall(context, RateLimits.GET_PENDING_TOKEN, "getPendingReferralCode");
  }

  const deviceFingerprint = extractString(data, "deviceFingerprint");
  const userId = context.auth?.uid;

  console.log("[getPendingReferralCode] Request received:", {
    deviceFingerprint: deviceFingerprint ? deviceFingerprint.substring(0, 20) + "..." : null,
    userId: userId || "unauthenticated"
  });

  requireString(deviceFingerprint, "Device fingerprint");

  try {
    const db = admin.firestore();

    console.log("[getPendingReferralCode] Looking up by device fingerprint:", deviceFingerprint.substring(0, 20) + "...");

    const config: FingerprintLookupConfig = {
      mainCollection: "referralCodes",
      indexCollection: "referralCodeFingerprints",
      indexTokenField: "referralCode",
      activeField: "isActive",
      inactiveValue: false, // isActive === false means inactive
      checkExpiry: true, // Referral codes have expiry
      logPrefix: "getPendingReferralCode",
    };

    const result = await lookupByFingerprint<string>(db, deviceFingerprint, config);

    if (result.success && result.token) {
      return {
        success: true,
        referralCode: result.token,
      };
    }

    return {
      success: false,
      referralCode: null,
      reason: result.reason || "not_found",
    };
  } catch (error: any) {
    console.error("[getPendingReferralCode] Error:", error);
    throw new functions.https.HttpsError("internal", "Failed to retrieve referral code");
  }
});
