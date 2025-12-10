import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { rateLimitCall } from "./utils/rateLimiter";
import { RateLimits } from "./utils/rateLimiter";

/**
 * Retrieves and claims a pending affiliate link for a device
 * Called from the app on first launch
 * Returns the affiliate link token if found, then marks it as claimed
 * STRICT: Only matches exact device fingerprint - no fallbacks to prevent false claims
 */
export const getPendingAffiliateLink = functions.https.onCall(async (data, context) => {
  // Rate limit by user (if authenticated) or allow unauthenticated for first launch
  if (context.auth) {
    await rateLimitCall(context, RateLimits.CHECK_USER_EXISTS, "getPendingAffiliateLink");
  }

  const deviceFingerprint = typeof data?.deviceFingerprint === "string" ? data.deviceFingerprint : null;
  const userId = context.auth?.uid;

  console.log("[getPendingAffiliateLink] Request received:", {
    deviceFingerprint: deviceFingerprint ? deviceFingerprint.substring(0, 20) + "..." : null,
    userId: userId || "unauthenticated"
  });

  if (!deviceFingerprint) {
    throw new functions.https.HttpsError("invalid-argument", "Device fingerprint is required");
  }

  try {
    const db = admin.firestore();

    console.log("[getPendingAffiliateLink] Looking up by device fingerprint:", deviceFingerprint.substring(0, 20) + "...");

    // Query all unclaimed affiliateLinks and search through their pendingDeviceFingerprints
    const affiliateLinksSnapshot = await db.collection("affiliateLinks")
      .where("claimed", "==", false)
      .limit(100) // Reasonable limit
      .get();

    if (affiliateLinksSnapshot.empty) {
      console.log("[getPendingAffiliateLink] No unclaimed affiliate links found");
      return { success: false, linkToken: null, reason: "not_found" };
    }

    // Find the link that has this device fingerprint in its pendingDeviceFingerprints map
    let linkDoc = null;
    let linkToken = null;
    let linkData = null;

    for (const doc of affiliateLinksSnapshot.docs) {
      const data = doc.data();
      const pendingFingerprints = data.pendingDeviceFingerprints || {};
      if (pendingFingerprints[deviceFingerprint]) {
        linkDoc = doc;
        linkToken = doc.id;
        linkData = data;
        break;
      }
    }

    if (!linkDoc || !linkToken) {
      console.log("[getPendingAffiliateLink] No affiliate link found with this device fingerprint");
      return { success: false, linkToken: null, reason: "not_found" };
    }

    console.log("[getPendingAffiliateLink] Found affiliate link:", linkToken);

    if (!linkData) {
      console.log("[getPendingAffiliateLink] Link data is null");
      return { success: false, linkToken: null, reason: "invalid_data" };
    }

    // Note: No expiry check for affiliate links (expiry removed per requirements)

    console.log("[getPendingAffiliateLink] Successfully retrieved affiliate link:", linkToken);

    return {
      success: true,
      linkToken: linkToken,
    };
  } catch (error: any) {
    console.error("[getPendingAffiliateLink] Error:", error);
    throw new functions.https.HttpsError("internal", "Failed to retrieve affiliate link");
  }
});
