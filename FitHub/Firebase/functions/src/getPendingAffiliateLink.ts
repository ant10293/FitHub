import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { rateLimitCall } from "./utils/rateLimiter";
import { RateLimits } from "./utils/rateLimiter";
import { lookupByFingerprint, FingerprintLookupConfig } from "./utils/fingerprintHelpers";
import { extractString, requireString } from "./utils/authHelpers";

/**
 * Retrieves and claims a pending affiliate link for a device
 * Called from the app on first launch
 * Returns the affiliate link token if found, then marks it as claimed
 * STRICT: Only matches exact device fingerprint - no fallbacks to prevent false claims
 */
export const getPendingAffiliateLink = functions.https.onCall(async (data, context) => {
  // Rate limit by user (if authenticated) or allow unauthenticated for first launch
  if (context.auth) {
    await rateLimitCall(context, RateLimits.GET_PENDING_TOKEN, "getPendingAffiliateLink");
  }

  const deviceFingerprint = extractString(data, "deviceFingerprint");
  const userId = context.auth?.uid;

  console.log("[getPendingAffiliateLink] Request received:", {
    deviceFingerprint: deviceFingerprint ? deviceFingerprint.substring(0, 20) + "..." : null,
    userId: userId || "unauthenticated"
  });

  requireString(deviceFingerprint, "Device fingerprint");

  try {
    const db = admin.firestore();

    console.log("[getPendingAffiliateLink] Looking up by device fingerprint:", deviceFingerprint.substring(0, 20) + "...");

    const config: FingerprintLookupConfig = {
      mainCollection: "affiliateLinks",
      indexCollection: "affiliateLinkFingerprints",
      indexTokenField: "linkToken",
      activeField: "claimed",
      inactiveValue: true, // claimed === true means inactive
      checkExpiry: false, // Affiliate links don't expire
      logPrefix: "getPendingAffiliateLink",
    };

    const result = await lookupByFingerprint<string>(db, deviceFingerprint, config);

    if (result.success && result.token) {
      return {
        success: true,
        linkToken: result.token,
      };
    }

    return {
      success: false,
      linkToken: null,
      reason: result.reason || "not_found",
    };
  } catch (error: any) {
    console.error("[getPendingAffiliateLink] Error:", error);
    throw new functions.https.HttpsError("internal", "Failed to retrieve affiliate link");
  }
});
