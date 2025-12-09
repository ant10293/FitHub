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

    // EXACT MATCH ONLY - lookup by device fingerprint (document ID)
    console.log("[getPendingReferralCode] Looking up by device fingerprint:", deviceFingerprint.substring(0, 20) + "...");
    const pendingRef = db.collection("pendingReferralCodes").doc(deviceFingerprint);
    const pendingDoc = await pendingRef.get();

    if (!pendingDoc.exists) {
      console.log("[getPendingReferralCode] No document found for fingerprint - exact match required");
      return { success: false, referralCode: null, reason: "not_found" };
    }

    console.log("[getPendingReferralCode] Document found:", pendingDoc.id);

    const pendingData = pendingDoc.data();

    // Check if already claimed or expired
    if (pendingData?.claimed === true) {
      console.log("[getPendingReferralCode] Code already claimed");
      return { success: false, referralCode: null, reason: "already_claimed" };
    }

    const expiresAt = pendingData?.expiresAt?.toMillis();
    if (expiresAt && expiresAt < Date.now()) {
      console.log("[getPendingReferralCode] Code expired");
      // Delete expired document
      await pendingRef.delete();
      return { success: false, referralCode: null, reason: "expired" };
    }

    const referralCode = pendingData?.referralCode;

    if (!referralCode) {
      console.log("[getPendingReferralCode] No referral code in document");
      return { success: false, referralCode: null, reason: "invalid_data" };
    }

    // Mark as claimed (don't delete yet - we'll clean up after successful claim)
    await pendingRef.update({
      claimed: true,
      claimedAt: admin.firestore.FieldValue.serverTimestamp(),
      claimedBy: userId || null,
    });

    console.log("[getPendingReferralCode] Successfully retrieved and marked as claimed:", referralCode);

    return {
      success: true,
      referralCode: referralCode,
    };
  } catch (error: any) {
    console.error("[getPendingReferralCode] Error:", error);
    throw new functions.https.HttpsError("internal", "Failed to retrieve referral code");
  }
});

