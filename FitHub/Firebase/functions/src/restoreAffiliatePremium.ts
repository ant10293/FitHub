import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { rateLimitCall, RateLimits } from "./utils/rateLimiter";
import { requireAuth } from "./utils/authHelpers";
import { handleFunctionError } from "./utils/errorHelpers";

/**
 * Cloud Function to check if a user has premium access from a claimed affiliate link
 * Simply queries affiliateLinks collection - no transactions or writes needed
 * Rate limited: 5 requests per minute per user
 */
export const restoreAffiliatePremium = functions.https.onCall(async (data, context) => {
  // Apply rate limiting (throws if exceeded)
  await rateLimitCall(context, RateLimits.AUTHENTICATED_CALL, "restoreAffiliatePremium");

  // Verify authentication
  const userId = requireAuth(context);

  const db = admin.firestore();

  try {
    console.log("[restoreAffiliatePremium] Searching for affiliate links claimed by userId:", userId);

    // Search for affiliate links claimed by this user
    const affiliateLinksSnapshot = await db.collection("affiliateLinks")
      .where("claimed", "==", true)
      .where("claimedBy", "==", userId)
      .limit(1)
      .get();

    console.log("[restoreAffiliatePremium] Query returned", affiliateLinksSnapshot.size, "documents");

    if (affiliateLinksSnapshot.empty) {
      // Debug: Check if there are any claimed links at all for this user (without the claimed filter)
      const allLinksSnapshot = await db.collection("affiliateLinks")
        .where("claimedBy", "==", userId)
        .limit(5)
        .get();

      console.log("[restoreAffiliatePremium] Total links with claimedBy=", userId, ":", allLinksSnapshot.size);
      if (allLinksSnapshot.size > 0) {
        allLinksSnapshot.docs.forEach((doc, index) => {
          const data = doc.data();
          console.log(`[restoreAffiliatePremium] Link ${index + 1}:`, {
            linkToken: doc.id,
            claimed: data.claimed,
            claimedBy: data.claimedBy,
            claimedAt: data.claimedAt,
          });
        });
      }

      console.log("[restoreAffiliatePremium] No affiliate link found for userId:", userId);
      return {
        success: false,
        linkToken: null,
        premiumGranted: false,
        reason: "not_found",
      };
    }

    const linkDoc = affiliateLinksSnapshot.docs[0];
    const linkToken = linkDoc.id;

    console.log("[restoreAffiliatePremium] Found claimed affiliate link:", linkToken, "for userId:", userId);

    return {
      success: true,
      linkToken: linkToken,
      premiumGranted: true,
      alreadyHadPremium: false,
    };
  } catch (error: any) {
    handleFunctionError(error, undefined, "restoreAffiliatePremium");
  }
});
