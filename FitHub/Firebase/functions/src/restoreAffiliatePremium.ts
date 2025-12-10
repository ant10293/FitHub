import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { rateLimitCall, RateLimits } from "./utils/rateLimiter";

/**
 * Cloud Function to restore premium access for a user who previously claimed an affiliate link
 * Searches affiliateLinks collection for links claimed by this userId
 * Grants premium access if a claimed link is found
 * Rate limited: 5 requests per minute per user
 */
export const restoreAffiliatePremium = functions.https.onCall(async (data, context) => {
  // Apply rate limiting (throws if exceeded)
  await rateLimitCall(context, RateLimits.CHECK_USER_EXISTS, "restoreAffiliatePremium");

  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
  }

  const userId = context.auth.uid;

  const db = admin.firestore();

  try {
    // Use transaction to ensure atomicity
    const result = await db.runTransaction(async (transaction) => {
      // 1. Search for affiliate links claimed by this user
      const affiliateLinksSnapshot = await db.collection("affiliateLinks")
        .where("claimed", "==", true)
        .where("claimedBy", "==", userId)
        .limit(1)
        .get();

      if (affiliateLinksSnapshot.empty) {
        console.log("[restoreAffiliatePremium] No affiliate link found for userId:", userId);
        return {
          success: false,
          linkToken: null,
          premiumGranted: false,
          reason: "not_found"
        };
      }

      const linkDoc = affiliateLinksSnapshot.docs[0];
      const linkData = linkDoc.data();
      const linkToken = linkDoc.id;

      console.log("[restoreAffiliatePremium] Found claimed affiliate link:", linkToken, "for userId:", userId);

      // 2. Check if user already has premium access
      const userRef = db.collection("users").doc(userId);
      const userDoc = await transaction.get(userRef);
      const userData = userDoc.data();

      const userAlreadyHasPremiumFromThisLink =
        userData?.affiliateGrantedPremium === true &&
        userData?.affiliateLinkToken === linkToken;

      // 3. Grant premium access if not already granted
      if (!userAlreadyHasPremiumFromThisLink) {
        console.log("[restoreAffiliatePremium] Granting premium access to user:", userId);
        transaction.set(userRef, {
          affiliateGrantedPremium: true,
          affiliateLinkToken: linkToken,
          affiliateLinkClaimedAt: linkData.claimedAt || admin.firestore.FieldValue.serverTimestamp(),
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
      } else {
        console.log("[restoreAffiliatePremium] User already has premium from this link");
      }

      return {
        success: true,
        linkToken: linkToken,
        premiumGranted: !userAlreadyHasPremiumFromThisLink,
        alreadyHadPremium: userAlreadyHasPremiumFromThisLink
      };
    });

    return result;
  } catch (error: any) {
    // If it's already an HttpsError, re-throw it
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    // Log the actual error for debugging
    console.error("[restoreAffiliatePremium] Error:", error);
    console.error("Error stack:", error.stack);
    console.error("Error message:", error.message);

    // Return a more descriptive internal error
    throw new functions.https.HttpsError(
      "internal",
      `Failed to restore affiliate premium: ${error.message || String(error)}`
    );
  }
});
