import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { rateLimitCall, RateLimits } from "./utils/rateLimiter";

/**
 * Cloud Function to claim an affiliate link with server-side validation
 * Validates link exists, is not already claimed, and grants premium access
 * Uses Firestore transaction for atomicity
 * Rate limited: 5 requests per minute per user
 */
export const claimAffiliateLink = functions.https.onCall(async (data, context) => {
  // Apply rate limiting (throws if exceeded)
  await rateLimitCall(context, RateLimits.CLAIM_REFERRAL_CODE, "claimAffiliateLink");

  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
  }

  const userId = context.auth.uid;
  const linkToken = typeof data?.linkToken === "string"
    ? data.linkToken.trim()
    : "";

  if (!linkToken) {
    throw new functions.https.HttpsError("invalid-argument", "Link token is required");
  }

  // Validate token format (alphanumeric, 16-64 characters)
  if (linkToken.length < 16 || linkToken.length > 64 || !/^[a-zA-Z0-9]+$/.test(linkToken)) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid link token format");
  }

  const db = admin.firestore();
  const linkRef = db.collection("affiliateLinks").doc(linkToken);
  const userRef = db.collection("users").doc(userId);

  try {
    // Use transaction to ensure atomicity
    const result = await db.runTransaction(async (transaction) => {
      // 1. Check if link exists
      const linkDoc = await transaction.get(linkRef);
      if (!linkDoc.exists) {
        throw new Error("AFFILIATE_LINK_NOT_FOUND");
      }

      const linkData = linkDoc.data()!;

      // 2. Check if link is already claimed
      if (linkData.claimed === true) {
        // If claimed by this user, return success (idempotent)
        if (linkData.claimedBy === userId) {
          return {
            success: true,
            linkToken: linkToken,
            alreadyClaimed: true,
            premiumGranted: true
          };
        }
        // If claimed by different user, throw error
        throw new Error("AFFILIATE_LINK_ALREADY_CLAIMED");
      }

      // 3. Check if user already has premium access from this specific link
      const userDoc = await transaction.get(userRef);
      const userData = userDoc.data();

      const userAlreadyHasPremiumFromThisLink =
        userData?.affiliateGrantedPremium === true &&
        userData?.affiliateLinkToken === linkToken;

      // 4. Perform the claim atomically
      // Always mark link as claimed and store the userId who claimed it
      // Also clean up pendingDeviceFingerprints since it's been claimed
      transaction.update(linkRef, {
        claimed: true,
        claimedBy: userId,  // This is where we store the userId - the person who claimed the link
        claimedAt: admin.firestore.FieldValue.serverTimestamp(),
        pendingDeviceFingerprints: admin.firestore.FieldValue.delete(), // Clean up pending fingerprints
      });

      // Grant premium access to user (only if they don't already have it from this link)
      if (!userAlreadyHasPremiumFromThisLink) {
        // Set affiliateGrantedPremium flag and update subscriptionStatus
        transaction.set(userRef, {
          affiliateGrantedPremium: true,
          affiliateLinkToken: linkToken,
          affiliateLinkClaimedAt: admin.firestore.FieldValue.serverTimestamp(),
          subscriptionStatus: {
            productID: "com.FitHub.premium.affiliate",
            isActive: true,
            expiresAt: null, // Affiliate premium doesn't expire
            originalTransactionID: `affiliate_${linkToken}`,
            lastValidatedAt: admin.firestore.FieldValue.serverTimestamp(),
            autoRenews: false,
            environment: "Production"
          }
        }, { merge: true });
      }

      return {
        success: true,
        linkToken: linkToken,
        alreadyClaimed: userAlreadyHasPremiumFromThisLink,
        premiumGranted: true
      };
    });

    return result;
  } catch (error: any) {
    // Handle transaction errors
    if (error.message === "AFFILIATE_LINK_NOT_FOUND") {
      throw new functions.https.HttpsError("not-found", "Affiliate link not found");
    }
    if (error.message === "AFFILIATE_LINK_ALREADY_CLAIMED") {
      throw new functions.https.HttpsError("failed-precondition", "Affiliate link has already been claimed");
    }

    // If it's already an HttpsError, re-throw it
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    // Log the actual error for debugging
    console.error("Error claiming affiliate link:", error);
    console.error("Error stack:", error.stack);
    console.error("Error message:", error.message);

    // Return a more descriptive internal error
    throw new functions.https.HttpsError(
      "internal",
      `Failed to claim affiliate link: ${error.message || String(error)}`
    );
  }
});
