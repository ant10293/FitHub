import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { rateLimitCall, RateLimits } from "./utils/rateLimiter";

/**
 * Cloud Function to track referral purchase with server-side validation
 * Validates transaction, prevents duplicates, and atomically updates referral code and user documents
 * Rate limited: 10 requests per minute per user
 */
export const trackReferralPurchase = functions.https.onCall(async (data, context) => {
  // Apply rate limiting (throws if exceeded)
  await rateLimitCall(context, RateLimits.TRACK_PURCHASE);

  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
  }

  const userId = context.auth.uid;
  const productID = typeof data?.productID === "string" ? data.productID : "";
  const transactionID = typeof data?.transactionID === "number" ? String(data.transactionID) : 
                        typeof data?.transactionID === "string" ? data.transactionID : "";
  const originalTransactionID = typeof data?.originalTransactionID === "number" ? String(data.originalTransactionID) :
                                typeof data?.originalTransactionID === "string" ? data.originalTransactionID : "";
  const environment = typeof data?.environment === "string" ? data.environment : "Production";

  if (!productID || !originalTransactionID) {
    throw new functions.https.HttpsError("invalid-argument", "productID and originalTransactionID are required");
  }

  // Validate product ID format
  const validProductIDs = ["com.FitHub.premium.monthly", "com.FitHub.premium.yearly", "com.FitHub.premium.lifetime"];
  if (!validProductIDs.includes(productID)) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid product ID");
  }

  const db = admin.firestore();
  const userRef = db.collection("users").doc(userId);

  try {
    // CRITICAL: Check if this originalTransactionID already belongs to a different user
    // This prevents the same transaction from being tracked on multiple accounts
    // (which can happen when using the same Apple ID for sandbox testing)
    // This check must be done OUTSIDE the transaction because transactions can't do queries
    const existingUsersSnapshot = await db
      .collection("users")
      .where("subscriptionStatus.originalTransactionID", "==", originalTransactionID)
      .get();
    
    // Check if another user already has this transaction
    // Collect users that need cleanup (deleted accounts) vs users that should block (active accounts)
    const usersToCleanup: Array<{ userId: string; referralCode?: string; productID?: string }> = [];
    
    for (const existingUserDoc of existingUsersSnapshot.docs) {
      const existingUserId = existingUserDoc.id;
      if (existingUserId !== userId) {
        // Another user already has this originalTransactionID
        // Check if the existing user's Firebase Auth account still exists
        try {
          await admin.auth().getUser(existingUserId);
          // User still exists - subscription belongs to them
          console.log(`Transaction ${originalTransactionID} already tracked for user ${existingUserId}. Purchase will be tracked on original account.`);
          
          // Return success with info that it was tracked on another account
          // This is not an error - the purchase was successfully tracked, just on a different account
          // Note: We return the productID being purchased (not the existing account's productID)
          // because the webhook will update the existing account's subscription to this new productID
          return {
            success: true,
            trackedOnOtherAccount: true,
            originalAccountId: existingUserId,
            productID: productID, // The product ID being purchased (will be tracked on original account)
            message: `This subscription is already associated with another account. The referral purchase will be tracked on the original account.`
          };
        } catch (authError: any) {
          // If auth error is "user not found", the original account was deleted
          // In that case, we can allow the transfer and clean up orphaned data
          if (authError.code === "auth/user-not-found") {
            console.log(`Original user ${existingUserId} no longer exists. Allowing transfer to ${userId}.`);
            const existingUserData = existingUserDoc.data();
            usersToCleanup.push({
              userId: existingUserId,
              referralCode: existingUserData?.referralCode,
              productID: existingUserData?.referralPurchaseProductID
            });
          } else {
            // Some other auth error - reject to be safe
            throw new functions.https.HttpsError(
              "already-exists",
              "This subscription is already associated with another account."
            );
          }
        }
      }
    }

    // Use transaction to ensure atomicity and prevent race conditions
    const result = await db.runTransaction(async (transaction) => {
      // Clean up orphaned data from deleted users
      for (const cleanup of usersToCleanup) {
        console.log(`Cleaning up orphaned subscription data from deleted user ${cleanup.userId}`);
        
        if (cleanup.referralCode) {
          const existingCode = String(cleanup.referralCode).toUpperCase();
          const existingCodeRef = db.collection("referralCodes").doc(existingCode);
          const existingCodeDoc = await transaction.get(existingCodeRef);
          if (existingCodeDoc.exists) {
            // Remove from appropriate active array
            if (cleanup.productID?.includes("monthly")) {
              transaction.update(existingCodeRef, {
                activeMonthlySubscriptions: admin.firestore.FieldValue.arrayRemove(cleanup.userId)
              });
            } else if (cleanup.productID?.includes("yearly") || cleanup.productID?.includes("annual")) {
              transaction.update(existingCodeRef, {
                activeAnnualSubscriptions: admin.firestore.FieldValue.arrayRemove(cleanup.userId)
              });
            }
          }
        }
      }

      // 1. Get user document to check referral code and existing purchase
      const userDoc = await transaction.get(userRef);
      const userData = userDoc.data();

      // Check if user has a referral code
      if (!userData?.referralCode) {
        throw new Error("USER_NO_REFERRAL_CODE");
      }

      const referralCode = String(userData.referralCode).toUpperCase();
      const codeRef = db.collection("referralCodes").doc(referralCode);

      // Check if code exists
      const codeDoc = await transaction.get(codeRef);
      if (!codeDoc.exists) {
        throw new Error("REFERRAL_CODE_NOT_FOUND");
      }

      // Check if this purchase was already tracked (prevent duplicates)
      const existingProductID = userData.referralPurchaseProductID;
      if (existingProductID === productID) {
        // Already tracked for this product - return success (idempotent)
        return { success: true, alreadyTracked: true, referralCode: referralCode };
      }

      // Determine subscription type
      let subscriptionType: "monthly" | "yearly" | "lifetime";
      let purchasedArray: string;
      let activeArray: string;

      if (productID.includes("monthly")) {
        subscriptionType = "monthly";
        purchasedArray = "monthlyPurchasedBy";
        activeArray = "activeMonthlySubscriptions";
      } else if (productID.includes("yearly") || productID.includes("annual")) {
        subscriptionType = "yearly";
        purchasedArray = "annualPurchasedBy";
        activeArray = "activeAnnualSubscriptions";
      } else if (productID.includes("lifetime")) {
        subscriptionType = "lifetime";
        purchasedArray = "lifetimePurchasedBy";
        activeArray = "activeLifetimeSubscriptions";
      } else {
        throw new Error("INVALID_PRODUCT_TYPE");
      }

      // Get current subscription type to remove from old active array if switching
      let currentSubscriptionType: "monthly" | "yearly" | "lifetime" | null = null;
      if (existingProductID) {
        if (existingProductID.includes("monthly")) {
          currentSubscriptionType = "monthly";
        } else if (existingProductID.includes("yearly") || existingProductID.includes("annual")) {
          currentSubscriptionType = "yearly";
        } else if (existingProductID.includes("lifetime")) {
          currentSubscriptionType = "lifetime";
        }
      }

      // Prepare referral code updates
      const codeUpdates: any = {
        lastPurchaseAt: admin.firestore.FieldValue.serverTimestamp()
      };

      // Remove from old active subscription array if switching subscriptions
      if (currentSubscriptionType && currentSubscriptionType !== subscriptionType) {
        switch (currentSubscriptionType) {
          case "monthly":
            codeUpdates.activeMonthlySubscriptions = admin.firestore.FieldValue.arrayRemove(userId);
            break;
          case "yearly":
            codeUpdates.activeAnnualSubscriptions = admin.firestore.FieldValue.arrayRemove(userId);
            break;
          case "lifetime":
            // Lifetime doesn't have active array updates
            break;
        }
      }

      // Add to appropriate arrays
      codeUpdates[purchasedArray] = admin.firestore.FieldValue.arrayUnion(userId);
      codeUpdates[activeArray] = admin.firestore.FieldValue.arrayUnion(userId);

      // Update referral code document
      transaction.update(codeRef, codeUpdates);

      // Update user document
      transaction.set(userRef, {
        referralCodeUsedForPurchase: true,
        referralPurchaseDate: admin.firestore.FieldValue.serverTimestamp(),
        referralPurchaseProductID: productID,
        subscriptionStatus: {
          originalTransactionID: originalTransactionID,
          transactionID: transactionID || originalTransactionID,
          productID: productID,
          isActive: true, // Assume active on purchase
          lastValidatedAt: admin.firestore.FieldValue.serverTimestamp(),
          environment: environment
        }
      }, { merge: true });

      return { 
        success: true, 
        alreadyTracked: false, 
        referralCode: referralCode,
        subscriptionType: subscriptionType
      };
    });

    return result;
  } catch (error: any) {
    // Handle transaction errors
    if (error.message === "USER_NO_REFERRAL_CODE") {
      throw new functions.https.HttpsError("failed-precondition", "User has no referral code");
    }
    if (error.message === "REFERRAL_CODE_NOT_FOUND") {
      throw new functions.https.HttpsError("not-found", "Referral code not found");
    }
    if (error.message === "INVALID_PRODUCT_TYPE") {
      throw new functions.https.HttpsError("invalid-argument", "Invalid product type");
    }

    // If it's already an HttpsError, re-throw it
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    // Log the actual error for debugging
    console.error("Error tracking referral purchase:", error);
    console.error("Error stack:", error.stack);
    console.error("Error message:", error.message);

    // Return a more descriptive internal error
    throw new functions.https.HttpsError(
      "internal",
      `Failed to track referral purchase: ${error.message || String(error)}`
    );
  }
});
