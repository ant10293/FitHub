import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { AppStoreServerAPIClient, Environment, SignedDataVerifier } from "@apple/app-store-server-library";
import Stripe from "stripe";
import type { Response } from "express";

// Initialize Firebase Admin
admin.initializeApp();
export const checkUserExists = functions.https.onCall(async (data) => {
  const email = typeof data?.email === "string" ? data.email.trim().toLowerCase() : "";
  if (!email) {
    throw new functions.https.HttpsError("invalid-argument", "Email is required.");
  }

  try {
    await admin.auth().getUserByEmail(email);
    return { exists: true };
  } catch (error: any) {
    if (error.code === "auth/user-not-found") {
      return { exists: false };
    }
    console.error("checkUserExists error:", error);
    throw new functions.https.HttpsError("internal", "Unable to check account status.");
  }
});

/**
 * Cloud Function to claim a referral code with server-side validation
 * Validates code exists, is active, and user hasn't already claimed a code
 * Uses Firestore transaction for atomicity
 */
export const claimReferralCode = functions.https.onCall(async (data, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
  }

  const userId = context.auth.uid;
  const referralCode = typeof data?.referralCode === "string" 
    ? data.referralCode.trim().toUpperCase() 
    : "";

  if (!referralCode) {
    throw new functions.https.HttpsError("invalid-argument", "Referral code is required");
  }

  // Validate code format (basic validation - 4-20 alphanumeric characters)
  if (referralCode.length < 4 || referralCode.length > 20 || !/^[A-Z0-9]+$/.test(referralCode)) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid referral code format");
  }

  const db = admin.firestore();
  const codeRef = db.collection("referralCodes").doc(referralCode);
  const userRef = db.collection("users").doc(userId);

  try {
    // Use transaction to ensure atomicity
    const result = await db.runTransaction(async (transaction) => {
      // 1. Check if code exists and is active
      const codeDoc = await transaction.get(codeRef);
      if (!codeDoc.exists) {
        // Throw a regular error - transaction will abort
        throw new Error("REFERRAL_CODE_NOT_FOUND");
      }

      const codeData = codeDoc.data()!;
      if (codeData.isActive !== true) {
        throw new Error("REFERRAL_CODE_INACTIVE");
      }

      // 2. Check if user already has a referral code
      const userDoc = await transaction.get(userRef);
      const userData = userDoc.data();
      
      if (userData?.referralCode) {
        // If they already have this code, return success (idempotent)
        if (String(userData.referralCode).toUpperCase() === referralCode) {
          return { success: true, referralCode: referralCode, alreadyClaimed: true };
        }
        // If they have a different code, throw error
        throw new Error("USER_ALREADY_HAS_CODE");
      }

      // 3. Perform the claim atomically
      // Use set with merge in case user document doesn't exist yet
      transaction.set(userRef, {
        referralCode: referralCode,
        referralCodeClaimedAt: admin.firestore.FieldValue.serverTimestamp(),
        referralSource: data.source || "manual_entry"
      }, { merge: true });

      transaction.update(codeRef, {
        lastUsedAt: admin.firestore.FieldValue.serverTimestamp(),
        usedBy: admin.firestore.FieldValue.arrayUnion(userId)
      });

      return { success: true, referralCode: referralCode, alreadyClaimed: false };
    });

    return result;
  } catch (error: any) {
    // Handle transaction errors
    if (error.message === "REFERRAL_CODE_NOT_FOUND") {
      throw new functions.https.HttpsError("not-found", "Referral code not found");
    }
    if (error.message === "REFERRAL_CODE_INACTIVE") {
      throw new functions.https.HttpsError("failed-precondition", "Referral code is not active");
    }
    if (error.message === "USER_ALREADY_HAS_CODE") {
      throw new functions.https.HttpsError("already-exists", "User already has a referral code");
    }
    
    // If it's already an HttpsError, re-throw it
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    // Log the actual error for debugging
    console.error("Error claiming referral code:", error);
    console.error("Error stack:", error.stack);
    console.error("Error message:", error.message);
    
    // Return a more descriptive internal error
    throw new functions.https.HttpsError(
      "internal", 
      `Failed to claim referral code: ${error.message || String(error)}`
    );
  }
});

/**
 * Cloud Function to track referral purchase with server-side validation
 * Validates transaction, prevents duplicates, and atomically updates referral code and user documents
 */
export const trackReferralPurchase = functions.https.onCall(async (data, context) => {
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


const stripeSecretKey = process.env.STRIPE_SECRET_KEY;
const stripeApiVersion = process.env.STRIPE_API_VERSION as Stripe.StripeConfig["apiVersion"];
const stripeClient = stripeSecretKey
  ? new Stripe(stripeSecretKey, { apiVersion: stripeApiVersion })
  : null;

const STRIPE_ONBOARDING_RETURN_URL = process.env.STRIPE_ONBOARDING_RETURN_URL;
const STRIPE_ONBOARDING_REFRESH_URL = process.env.STRIPE_ONBOARDING_REFRESH_URL;
const STRIPE_DASHBOARD_REDIRECT_URL = process.env.STRIPE_DASHBOARD_REDIRECT_URL;

class HttpError extends Error {
  status: number;

  constructor(status: number, message: string) {
    super(message);
    this.status = status;
  }
}

const requireEnv = (value: string | undefined, name: string): string => {
  if (!value) {
    throw new HttpError(500, `${name} is not configured.`);
  }
  return value;
};

const getStripeClient = (): Stripe => {
  if (!stripeClient) {
    throw new HttpError(500, "Stripe is not configured. Missing STRIPE_SECRET_KEY.");
  }
  return stripeClient;
};

type AppStoreConfig = {
  privateKey: string;
  keyId: string;
  issuerId: string;
  bundleId: string;
  appAppleId?: number;
};

const getAppStoreConfig = (): AppStoreConfig => {
  const privateKeyEnv = process.env.APPSTORE_PRIVATE_KEY;
  const keyIdEnv = process.env.APPSTORE_KEY_ID;
  const issuerIdEnv = process.env.APPSTORE_ISSUER_ID;
  const bundleIdEnv = process.env.APPSTORE_BUNDLE_ID;
  const appAppleIdEnv = process.env.APPSTORE_APP_APPLE_ID;

  if (!privateKeyEnv || !keyIdEnv || !issuerIdEnv) {
    throw new Error("Missing App Store Connect configuration. Ensure APPSTORE_PRIVATE_KEY, APPSTORE_KEY_ID, and APPSTORE_ISSUER_ID are set.");
  }

  const bundleId = bundleIdEnv ?? "com.AnthonyC.FitHub";
  const appAppleId = appAppleIdEnv ? Number(appAppleIdEnv) : undefined;
  if (appAppleIdEnv && Number.isNaN(appAppleId)) {
    throw new Error("APPSTORE_APP_APPLE_ID must be a valid number if provided.");
  }

  return {
    privateKey: privateKeyEnv.replace(/\\n/g, "\n"),
    keyId: keyIdEnv,
    issuerId: issuerIdEnv,
    bundleId,
    appAppleId,
  };
};

const getAppStoreAPIForEnvironment = (environment: Environment): AppStoreServerAPIClient => {
  const config = getAppStoreConfig();

  return new AppStoreServerAPIClient(
    config.privateKey,
    config.keyId,
    config.issuerId,
    config.bundleId,
    environment
  );
};

const APPLE_ROOT_CERTIFICATES = [
  Buffer.from(
    "MIICQzCCAcmgAwIBAgIILcX8iNLFS5UwCgYIKoZIzj0EAwMwZzEbMBkGA1UEAwwSQXBwbGUgUm9vdCBDQSAtIEczMSYwJAYDVQQLDB1BcHBsZSBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTETMBEGA1UECgwKQXBwbGUgSW5jLjELMAkGA1UEBhMCVVMwHhcNMTQwNDMwMTgxOTA2WhcNMzkwNDMwMTgxOTA2WjBnMRswGQYDVQQDDBJBcHBsZSBSb290IENBIC0gRzMxJjAkBgNVBAsMHUFwcGxlIENlcnRpZmljYXRpb24gQXV0aG9yaXR5MRMwEQYDVQQKDApBcHBsZSBJbmMuMQswCQYDVQQGEwJVUzB2MBAGByqGSM49AgEGBSuBBAAiA2IABJjpLz1AcqTtkyJygRMc3RCV8cWjTnHcFBbZDuWmBSp3ZHtfTjjTuxxEtX/1H7YyYl3J6YRbTzBPEVoA/VhYDKX1DyxNB0cTddqXl5dvMVztK517IDvYuVTZXpmkOlEKMaNCMEAwHQYDVR0OBBYEFLuw3qFYM4iapIqZ3r6966/ayySrMA8GA1UdEwEB/wQFMAMBAf8wDgYDVR0PAQH/BAQDAgEGMAoGCCqGSM49BAMDA2gAMGUCMQCD6cHEFl4aXTQY2e3v9GwOAEZLuN+yRhHFD/3meoyhpmvOwgPUnPWTxnS4at+qIxUCMG1mihDK1A3UT82NQz60imOlM27jbdoXt2QfyFMm+YhidDkLF1vLUagM6BgD56KyKA==",
    "base64"
  ),
];

const makeSignedDataVerifier = (environment: Environment): SignedDataVerifier => {
  const config = getAppStoreConfig();
  const appAppleId = environment === Environment.PRODUCTION ? config.appAppleId : undefined;
  return new SignedDataVerifier(APPLE_ROOT_CERTIFICATES, true, environment, config.bundleId, appAppleId);
};

/**
 * Handles App Store Server Notifications (webhooks from Apple)
 * Configure this URL in App Store Connect → App Information → App Store Server Notifications
 */
export const handleAppStoreNotification = functions.https.onRequest(async (req, res) => {
  // Only accept POST requests
  if (req.method !== "POST") {
    res.status(405).send("Method not allowed");
    return;
  }

  try {
    const signedPayload = req.body?.signedPayload;
    if (!signedPayload) {
      console.warn("Missing signedPayload in notification");
      res.status(200).send("OK");
      return;
    }

    // Decode and verify the signed payload (Production first, then Sandbox)
    let decodedNotification: any;
    let detectedEnvironment = Environment.PRODUCTION;

    try {
      const verifier = makeSignedDataVerifier(Environment.PRODUCTION);
      decodedNotification = await verifier.verifyAndDecodeNotification(signedPayload);
    } catch (prodError) {
      try {
        const sandboxVerifier = makeSignedDataVerifier(Environment.SANDBOX);
        decodedNotification = await sandboxVerifier.verifyAndDecodeNotification(signedPayload);
        detectedEnvironment = Environment.SANDBOX;
        console.log("Detected SANDBOX environment");
      } catch (sandboxError) {
        console.error("Failed to decode signedPayload in both environments:", prodError);
        res.status(200).send("Decode failed");
        return;
      }
    }

    const notificationType: string | undefined = decodedNotification?.notificationType;
    const notificationSubtype: string | undefined = decodedNotification?.subtype;
    const typeLogSuffix = notificationSubtype ? ` (${notificationSubtype})` : "";
    console.log(`Received App Store notification: ${notificationType ?? "unknown"}${typeLogSuffix}`);

    const data = decodedNotification?.data ?? {};
    const signedTransactionInfo: string | undefined = data.signedTransactionInfo;
    const signedRenewalInfo: string | undefined = data.signedRenewalInfo;

    let originalTransactionId: string | undefined =
      data.originalTransactionId ?? decodedNotification?.summary?.originalTransactionId;
    let transactionInfo: any | null = null;

    if (signedTransactionInfo) {
      try {
        const transactionVerifier = makeSignedDataVerifier(detectedEnvironment);
        transactionInfo = await transactionVerifier.verifyAndDecodeTransaction(signedTransactionInfo);
        if (!originalTransactionId) {
          originalTransactionId = transactionInfo.originalTransactionId ?? transactionInfo.transactionId;
        }
      } catch (decodeError) {
        console.error("Failed to decode signedTransactionInfo:", decodeError);
      }
    }

    if (!originalTransactionId) {
      console.warn("No originalTransactionId available in notification");
      res.status(200).send("OK");
      return;
    }

    console.log(`Processing notification for transaction: ${originalTransactionId} (${detectedEnvironment})`);

    // Find user by matching originalTransactionID in their subscriptionStatus
    // Note: In sandbox testing, the same Apple ID can be used by multiple Firebase accounts
    // We'll update all matching users, but typically there should only be one
    const usersSnapshot = await admin.firestore()
      .collection("users")
      .where("subscriptionStatus.originalTransactionID", "==", String(originalTransactionId))
      .get();

    if (usersSnapshot.empty) {
      console.warn(`No user found for transaction ${originalTransactionId}`);
      // Still return 200 to acknowledge receipt (user might not have referral code)
      res.status(200).send("OK");
      return;
    }

    // Update all users with this originalTransactionID
    // (In production, there should typically only be one, but we handle multiple for safety)
    const appStoreAPI = getAppStoreAPIForEnvironment(detectedEnvironment);
    
    for (const userDoc of usersSnapshot.docs) {
      const userId = userDoc.id;
      console.log(`Found user ${userId} for transaction ${originalTransactionId}`);
      
      try {
        // Update subscription status based on notification type
        await updateSubscriptionStatus(
          userId,
          originalTransactionId,
          notificationType,
          appStoreAPI,
          detectedEnvironment,
          signedRenewalInfo,
          transactionInfo ?? undefined
        );
        
        // Update referral code active subscriptions
        await updateReferralCodeSubscriptions(userId);
      } catch (error) {
        console.error(`Error updating subscription for user ${userId}:`, error);
        // Continue with other users even if one fails
      }
    }
    
    if (usersSnapshot.size > 1) {
      console.warn(`⚠️ Multiple users (${usersSnapshot.size}) found for transaction ${originalTransactionId}. This may indicate cross-account tracking issue.`);
    }

    res.status(200).send("OK");
  } catch (error) {
    console.error("Error processing App Store notification:", error);
    // Return 200 to prevent Apple from retrying (we'll validate separately)
    res.status(200).send("Error logged");
  }
});

/**
 * Updates the user's subscription status in Firestore
 */
async function updateSubscriptionStatus(
  userId: string,
  originalTransactionId: string,
  notificationType: string | undefined,
  appStoreAPI: AppStoreServerAPIClient,
  environment: Environment,
  signedRenewalInfo?: string,
  decodedTransaction?: any
): Promise<void> {
  const userRef = admin.firestore().collection("users").doc(userId);
  
  try {
    console.log(`Refreshing subscription status for user ${userId} from notification ${notificationType ?? "unknown"}`);
    // Get subscription status from App Store Server API
    const statusResponse = await appStoreAPI.getAllSubscriptionStatuses(originalTransactionId);
    
    if (!statusResponse.data || statusResponse.data.length === 0) {
      console.warn(`No subscription status found for transaction ${originalTransactionId}`);
      return;
    }

    // Find the transaction that matches our originalTransactionId
    let matchingTransaction: any = null;
    for (const group of statusResponse.data) {
      if (group.lastTransactions) {
        matchingTransaction = group.lastTransactions.find(
          (t: any) => t.originalTransactionId === originalTransactionId
        );
        if (matchingTransaction) break;
      }
    }
    
    let transactionInfo: any = decodedTransaction;
    if ((!matchingTransaction || !matchingTransaction.signedTransactionInfo) && !transactionInfo) {
      console.warn(`No matching transaction found for ${originalTransactionId}`);
      return;
    }

    // Decode the transaction if we don't already have it
    if (!transactionInfo && matchingTransaction?.signedTransactionInfo) {
      const verifier: SignedDataVerifier = makeSignedDataVerifier(environment);
      transactionInfo = await verifier.verifyAndDecodeTransaction(matchingTransaction.signedTransactionInfo);
    }
    
    // Determine if subscription is active
    // Status 1 = Active, Status 2 = Expired, etc.
    const status = matchingTransaction?.status ?? decodedTransaction?.status;
    const isActive = status === 1;
    const expiresAt = transactionInfo.expiresDate 
      ? admin.firestore.Timestamp.fromDate(new Date(transactionInfo.expiresDate)) 
      : null;
    
    // Get auto-renew status from renewal info if available
    let autoRenews = false;
    const renewalJWSToDecode = matchingTransaction?.signedRenewalInfo ?? signedRenewalInfo;
    if (renewalJWSToDecode) {
      try {
        const verifier: SignedDataVerifier = makeSignedDataVerifier(environment);
        const renewalInfo = await verifier.verifyAndDecodeRenewalInfo(renewalJWSToDecode);
        autoRenews = renewalInfo.autoRenewStatus === 1;
      } catch (error) {
        console.warn(`Could not decode renewal info: ${error}`);
      }
    }

    if (!transactionInfo) {
      console.warn(`Unable to resolve transaction info for ${originalTransactionId}`);
      return;
    }
    const environmentString = transactionInfo.environment === "Production" ? "Production" : "Sandbox";

    await userRef.update({
      "subscriptionStatus": {
        originalTransactionID: String(originalTransactionId),
        productID: transactionInfo.productId,
        isActive,
        expiresAt,
        autoRenews,
        lastValidatedAt: admin.firestore.FieldValue.serverTimestamp(),
        environment: environmentString,
      },
    });

    console.log(`Updated subscription status for user ${userId}: active=${isActive}`);
  } catch (error) {
    console.error(`Error updating subscription status for user ${userId}:`, error);
    throw error;
  }
}

/**
 * Updates the referral code's active subscription arrays based on user's current status
 * Also handles subscription type changes (e.g., monthly -> annual)
 */
async function updateReferralCodeSubscriptions(userId: string): Promise<void> {
  const userRef = admin.firestore().collection("users").doc(userId);
  const userDoc = await userRef.get();
  const userData = userDoc.data();
  
  if (!userData?.referralCode) {
    return; // User doesn't have a referral code
  }

  const referralCode = userData.referralCode.toUpperCase();
  const codeRef = admin.firestore().collection("referralCodes").doc(referralCode);
  const subscriptionStatus = userData.subscriptionStatus;
  
  if (!subscriptionStatus) {
    return; // No subscription status to update
  }

  const productID = subscriptionStatus.productID;
  const isActive = subscriptionStatus.isActive;
  const oldProductID = userData.referralPurchaseProductID;
  
  // Determine which arrays to update based on product ID
  let activeArray: string;
  let purchasedArray: string;
  
  if (productID.includes("monthly")) {
    activeArray = "activeMonthlySubscriptions";
    purchasedArray = "monthlyPurchasedBy";
  } else if (productID.includes("yearly") || productID.includes("annual")) {
    activeArray = "activeAnnualSubscriptions";
    purchasedArray = "annualPurchasedBy";
  } else if (productID.includes("lifetime")) {
    activeArray = "activeLifetimeSubscriptions";
    purchasedArray = "lifetimePurchasedBy";
  } else {
    console.warn(`Unknown product ID: ${productID}`);
    return;
  }
  
  // Determine old arrays if subscription type changed
  let oldActiveArray: string | null = null;
  if (oldProductID && oldProductID !== productID) {
    if (oldProductID.includes("monthly")) {
      oldActiveArray = "activeMonthlySubscriptions";
    } else if (oldProductID.includes("yearly") || oldProductID.includes("annual")) {
      oldActiveArray = "activeAnnualSubscriptions";
    } else if (oldProductID.includes("lifetime")) {
      oldActiveArray = "activeLifetimeSubscriptions";
    }
  }
  
  const codeUpdates: any = {};
  const userUpdates: any = {};
  
  // If subscription type changed, remove from old active array
  if (oldActiveArray && oldActiveArray !== activeArray) {
    codeUpdates[oldActiveArray] = admin.firestore.FieldValue.arrayRemove(userId);
    console.log(`Removing user ${userId} from ${oldActiveArray} (subscription changed from ${oldProductID} to ${productID})`);
  }
  
  // Update current subscription arrays
  if (isActive) {
    // Add to active array if not already there
    codeUpdates[activeArray] = admin.firestore.FieldValue.arrayUnion(userId);
  } else {
    // Remove from active array
    codeUpdates[activeArray] = admin.firestore.FieldValue.arrayRemove(userId);
  }
  
  // Ensure user is in purchased array (they purchased at some point)
  codeUpdates[purchasedArray] = admin.firestore.FieldValue.arrayUnion(userId);
  codeUpdates.lastValidationAt = admin.firestore.FieldValue.serverTimestamp();
  
  // Update user's referralPurchaseProductID if it changed
  if (oldProductID !== productID) {
    userUpdates.referralPurchaseProductID = productID;
    userUpdates.referralPurchaseDate = admin.firestore.FieldValue.serverTimestamp();
    console.log(`Updating user ${userId} referralPurchaseProductID from ${oldProductID} to ${productID}`);
  }
  
  // Perform updates in a batch
  const batch = admin.firestore().batch();
  batch.update(codeRef, codeUpdates);
  if (Object.keys(userUpdates).length > 0) {
    batch.update(userRef, userUpdates);
  }
  await batch.commit();
  
  console.log(`Updated referral code ${referralCode} subscriptions for user ${userId}`);
}

/**
 * Retry helper with exponential backoff
 */
async function retryWithBackoff<T>(
  fn: () => Promise<T>,
  maxRetries: number = 3,
  initialDelayMs: number = 1000
): Promise<T> {
  let lastError: any;
  
  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error;
      
      // Don't retry on the last attempt
      if (attempt === maxRetries) {
        break;
      }
      
      // Calculate delay with exponential backoff
      const delayMs = initialDelayMs * Math.pow(2, attempt);
      console.log(`Retry attempt ${attempt + 1}/${maxRetries} after ${delayMs}ms delay`);
      await new Promise(resolve => setTimeout(resolve, delayMs));
    }
  }
  
  throw lastError;
}

/**
 * Track validation failure in Firestore for monitoring
 */
async function trackValidationFailure(
  userId: string,
  error: any,
  originalTransactionId: string
): Promise<void> {
  try {
    const errorMessage = error?.message || String(error);
    const errorCode = error?.code || "UNKNOWN";
    
    await admin.firestore().collection("users").doc(userId).update({
      "subscriptionStatus.lastValidationError": errorMessage,
      "subscriptionStatus.lastValidationErrorAt": admin.firestore.FieldValue.serverTimestamp(),
      "subscriptionStatus.validationFailureCount": admin.firestore.FieldValue.increment(1),
    });
    
    // Also log to a separate collection for monitoring
    await admin.firestore().collection("validationFailures").add({
      userId,
      originalTransactionId,
      errorMessage,
      errorCode,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      retryable: isRetryableError(error),
    });
  } catch (trackingError) {
    // Don't fail validation if tracking fails
    console.error("Failed to track validation failure:", trackingError);
  }
}

/**
 * Check if an error is retryable (network errors, rate limits, etc.)
 */
function isRetryableError(error: any): boolean {
  const errorMessage = String(error?.message || error).toLowerCase();
  const errorCode = String(error?.code || "").toLowerCase();
  
  // Retry on network errors, rate limits, and temporary server errors
  return (
    errorMessage.includes("network") ||
    errorMessage.includes("timeout") ||
    errorMessage.includes("rate limit") ||
    errorMessage.includes("too many requests") ||
    errorCode === "429" || // Too Many Requests
    errorCode === "503" || // Service Unavailable
    errorCode === "500" || // Internal Server Error
    errorCode === "502" || // Bad Gateway
    errorCode === "504"    // Gateway Timeout
  );
}

/**
 * Daily scheduled function to validate all subscriptions
 * Runs at 2 AM UTC every day as a backup to webhooks
 * Includes retry logic and failure tracking
 */
export const validateAllSubscriptions = functions.pubsub
  .schedule("0 2 * * *")
  .timeZone("UTC")
  .onRun(async () => {
    console.log("Starting daily subscription validation...");
    
    const codesSnapshot = await admin.firestore()
      .collection("referralCodes")
      .get();
    
    console.log(`Validating subscriptions for ${codesSnapshot.size} referral codes`);
    
    let validatedCount = 0;
    let errorCount = 0;
    const failedUserIds: string[] = [];
    
    for (const codeDoc of codesSnapshot.docs) {
      const codeData = codeDoc.data();
      
      // Get all users who purchased (combine all types)
      const allUserIds = [
        ...(codeData.monthlyPurchasedBy || []),
        ...(codeData.annualPurchasedBy || []),
        ...(codeData.lifetimePurchasedBy || []),
      ];
      
      // Remove duplicates
      const uniqueUserIds = [...new Set(allUserIds)];
      
      // Validate each user's subscription with retry logic
      for (const userId of uniqueUserIds) {
        try {
          await retryWithBackoff(
            () => validateUserSubscription(userId),
            3, // max 3 retries
            2000 // start with 2 second delay
          );
          validatedCount++;
          
          // Clear previous validation errors on success
          try {
            await admin.firestore().collection("users").doc(userId).update({
              "subscriptionStatus.lastValidationError": admin.firestore.FieldValue.delete(),
              "subscriptionStatus.validationFailureCount": admin.firestore.FieldValue.delete(),
            });
          } catch (clearError) {
            // Don't fail if clearing errors fails
            console.warn(`Failed to clear validation errors for user ${userId}:`, clearError);
          }
        } catch (error) {
          errorCount++;
          failedUserIds.push(userId);
          
          const userDoc = await admin.firestore().collection("users").doc(userId).get();
          const userData = userDoc.data();
          const originalTransactionId = userData?.subscriptionStatus?.originalTransactionID || "unknown";
          
          await trackValidationFailure(userId, error, originalTransactionId);
          
          // Log error with context
          console.error(`Failed to validate subscription for user ${userId} after retries:`, {
            error: error instanceof Error ? error.message : String(error),
            originalTransactionId,
            retryable: isRetryableError(error),
          });
        }
      }
    }
    
    // Log summary
    const summary = {
      totalCodes: codesSnapshot.size,
      validated: validatedCount,
      errors: errorCount,
      failedUsers: failedUserIds.length,
    };
    
    console.log(`Daily validation complete:`, summary);
    
    // Alert if error rate is high (>10% failures)
    const totalValidations = validatedCount + errorCount;
    if (totalValidations > 0) {
      const errorRate = (errorCount / totalValidations) * 100;
      if (errorRate > 10) {
        console.error(`⚠️ HIGH VALIDATION ERROR RATE: ${errorRate.toFixed(2)}% (${errorCount}/${totalValidations})`);
        // In production, you might want to send an alert here (e.g., via email, Slack, etc.)
      }
    }
    
    // Store summary in Firestore for monitoring
    try {
      await admin.firestore().collection("validationRuns").add({
        ...summary,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        failedUserIds: failedUserIds.slice(0, 100), // Store up to 100 failed user IDs
      });
    } catch (summaryError) {
      console.error("Failed to store validation summary:", summaryError);
    }
  });

/**
 * Validates a single user's subscription status
 * Improved with environment detection and better error handling
 */
async function validateUserSubscription(userId: string): Promise<void> {
  const userDoc = await admin.firestore().collection("users").doc(userId).get();
  const userData = userDoc.data();
  
  if (!userData?.subscriptionStatus?.originalTransactionID) {
    return; // No subscription to validate
  }
  
  const originalTransactionId = userData.subscriptionStatus.originalTransactionID;
  const environment = userData.subscriptionStatus.environment || "Production";
  
  try {
    // Detect environment from subscription status or default to Production
    const detectedEnvironment = environment === "Sandbox" 
      ? Environment.SANDBOX 
      : Environment.PRODUCTION;
    
    const appStoreAPI = getAppStoreAPIForEnvironment(detectedEnvironment);
    
    // Add timeout to prevent hanging requests
    const timeoutPromise = new Promise((_, reject) => {
      setTimeout(() => reject(new Error("Validation timeout after 30 seconds")), 30000);
    });
    
    const statusResponse = await Promise.race([
      appStoreAPI.getAllSubscriptionStatuses(originalTransactionId),
      timeoutPromise,
    ]) as any;
    
    if (!statusResponse.data || statusResponse.data.length === 0) {
      console.warn(`No subscription status found for transaction ${originalTransactionId} (user ${userId})`);
      // Don't throw - this might be a valid case (refunded subscription, etc.)
      return;
    }
    
    // Find the transaction that matches our originalTransactionId
    let matchingTransaction: any = null;
    for (const group of statusResponse.data) {
      if (group.lastTransactions) {
        matchingTransaction = group.lastTransactions.find(
          (t: any) => t.originalTransactionId === originalTransactionId
        );
        if (matchingTransaction) break;
      }
    }
    
    if (!matchingTransaction) {
      console.warn(`No matching transaction found for ${originalTransactionId} (user ${userId})`);
      // Don't throw - transaction might have been deleted or refunded
      return;
    }
    
    const status = matchingTransaction.status;
    const isActive = status === 1;
    
    // Get expiration date if available
    let expiresAt: admin.firestore.Timestamp | null = null;
    if (matchingTransaction.signedTransactionInfo) {
      try {
        const verifier = makeSignedDataVerifier(detectedEnvironment);
        const transactionInfo = await verifier.verifyAndDecodeTransaction(
          matchingTransaction.signedTransactionInfo
        );
        if (transactionInfo.expiresDate) {
          expiresAt = admin.firestore.Timestamp.fromDate(new Date(transactionInfo.expiresDate));
        }
      } catch (decodeError) {
        console.warn(`Could not decode transaction info for user ${userId}:`, decodeError);
      }
    }
    
    // Update user's subscription status
    const updateData: any = {
      "subscriptionStatus.isActive": isActive,
      "subscriptionStatus.lastValidatedAt": admin.firestore.FieldValue.serverTimestamp(),
      "subscriptionStatus.environment": environment,
    };
    
    if (expiresAt) {
      updateData["subscriptionStatus.expiresAt"] = expiresAt;
    }
    
    await admin.firestore().collection("users").doc(userId).update(updateData);
    
    // Update referral code active subscriptions
    await updateReferralCodeSubscriptions(userId);
    
    console.log(`✅ Successfully validated subscription for user ${userId}: active=${isActive}`);
  } catch (error) {
    // Categorize error for better handling
    const errorMessage = error instanceof Error ? error.message : String(error);
    const isRetryable = isRetryableError(error);
    
    console.error(`Error validating subscription for user ${userId}:`, {
      error: errorMessage,
      originalTransactionId,
      environment,
      retryable: isRetryable,
    });
    
    // Re-throw to allow retry logic in caller
    throw error;
  }
}

/**
 * Stripe Connect integration for affiliate payouts
 */
export const createAffiliateOnboardingLink = functions.https.onRequest(async (req, res) => {
  if (req.method !== "POST") {
    res.status(405).json({ error: { status: 405, message: "Method not allowed." } });
    return;
  }

  try {
    const decodedToken = await authenticateRequest(req);
    const payload = extractDataPayload(req.body);
    const referralCode = normalizeReferralCode(payload.referralCode);
    const requestedCountry = typeof payload.country === "string" ? payload.country : undefined;

    const { codeRef, codeData } = await getReferralCodeRecord(referralCode);
    assertUserOwnsReferralCode(codeData, decodedToken.uid);

    const account = await ensureStripeAccountForAffiliate({
      codeRef,
      codeData,
      user: decodedToken,
      requestedCountry,
    });

    const stripe = getStripeClient();
    const accountLink = await stripe.accountLinks.create({
      account: account.id,
      refresh_url: requireEnv(STRIPE_ONBOARDING_REFRESH_URL, "STRIPE_ONBOARDING_REFRESH_URL"),
      return_url: requireEnv(STRIPE_ONBOARDING_RETURN_URL, "STRIPE_ONBOARDING_RETURN_URL"),
      type: "account_onboarding",
    });

    await codeRef.update({
      stripeLastOnboardingAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    respondSuccess(res, {
      accountId: account.id,
      url: accountLink.url,
      expiresAt: accountLink.expires_at ?? null,
      createdAt: accountLink.created ?? null,
      detailsSubmitted: account.details_submitted ?? false,
      payoutsEnabled: account.payouts_enabled ?? false,
    });
  } catch (error) {
    handleFunctionError(res, error);
  }
});

export const getAffiliateDashboardLink = functions.https.onRequest(async (req, res) => {
  if (req.method !== "POST") {
    res.status(405).json({ error: { status: 405, message: "Method not allowed." } });
    return;
  }

  try {
    const decodedToken = await authenticateRequest(req);
    const payload = extractDataPayload(req.body);
    const referralCode = normalizeReferralCode(payload.referralCode);

    const { codeRef, codeData } = await getReferralCodeRecord(referralCode);
    assertUserOwnsReferralCode(codeData, decodedToken.uid);

    const accountId =
      typeof codeData.stripeAccountId === "string" && codeData.stripeAccountId.trim().length > 0
        ? codeData.stripeAccountId.trim()
        : undefined;

    if (!accountId) {
      throw new HttpError(400, "Stripe account not connected. Please connect your Stripe account first.");
    }

    const stripe = getStripeClient();
    let account: Stripe.Account;

    try {
      account = await stripe.accounts.retrieve(accountId);
    } catch (error) {
      if (isStripeResourceMissing(error)) {
        await clearStripeAccountFields(codeRef);
        throw new HttpError(410, "Stripe account no longer exists. Please reconnect your Stripe account.");
      }
      throw error;
    }

    await syncStripeAccountFields(codeRef, account);

    const loginLinkResponse = await stripe.accounts.createLoginLink(account.id);
    const loginUrl = new URL(loginLinkResponse.url);

    if (typeof STRIPE_DASHBOARD_REDIRECT_URL === "string" && STRIPE_DASHBOARD_REDIRECT_URL.trim().length > 0) {
      loginUrl.searchParams.set("redirect_url", STRIPE_DASHBOARD_REDIRECT_URL.trim());
    }

    await codeRef.update({
      stripeLastDashboardLinkAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    respondSuccess(res, {
      accountId: account.id,
      url: loginUrl.toString(),
      expiresAt: null,
      createdAt: loginLinkResponse.created ?? null,
      payoutsEnabled: account.payouts_enabled ?? false,
    });
  } catch (error) {
    handleFunctionError(res, error);
  }
});

type DataPayload = Record<string, unknown>;

const authenticateRequest = async (req: functions.https.Request): Promise<admin.auth.DecodedIdToken> => {
  const authHeader = req.get("Authorization") ?? req.get("authorization");
  if (!authHeader) {
    throw new HttpError(401, "Missing Authorization header.");
  }

  const match = authHeader.match(/^Bearer (.+)$/i);
  if (!match) {
    throw new HttpError(401, "Invalid Authorization token.");
  }

  try {
    return await admin.auth().verifyIdToken(match[1]);
  } catch (error) {
    console.error("Failed to verify auth token", error);
    throw new HttpError(401, "Invalid auth token.");
  }
};

const extractDataPayload = (body: unknown): DataPayload => {
  if (!body || typeof body !== "object") {
    throw new HttpError(400, "Invalid request body.");
  }

  const payload = (body as { data?: unknown }).data;
  if (!payload || typeof payload !== "object") {
    throw new HttpError(400, "Missing data payload.");
  }

  return payload as DataPayload;
};

const normalizeReferralCode = (value: unknown): string => {
  const code = typeof value === "string" ? value.trim() : "";
  if (!code) {
    throw new HttpError(400, "referralCode is required.");
  }
  return code.toUpperCase();
};

const getReferralCodeRecord = async (
  referralCode: string
): Promise<{
  codeRef: FirebaseFirestore.DocumentReference<FirebaseFirestore.DocumentData>;
  codeData: FirebaseFirestore.DocumentData;
}> => {
  const codeRef = admin.firestore().collection("referralCodes").doc(referralCode);
  const snapshot = await codeRef.get();

  if (!snapshot.exists) {
    throw new HttpError(404, "Referral code not found.");
  }

  return {
    codeRef,
    codeData: snapshot.data() ?? {},
  };
};

const assertUserOwnsReferralCode = (codeData: FirebaseFirestore.DocumentData, uid: string): void => {
  const createdBy = typeof codeData.createdBy === "string" ? codeData.createdBy : undefined;
  if (createdBy && createdBy !== uid) {
    throw new HttpError(403, "You do not have permission to manage this referral code.");
  }
};

interface EnsureStripeAccountOptions {
  codeRef: FirebaseFirestore.DocumentReference<FirebaseFirestore.DocumentData>;
  codeData: FirebaseFirestore.DocumentData;
  user: admin.auth.DecodedIdToken;
  requestedCountry?: string;
}

const ensureStripeAccountForAffiliate = async (
  options: EnsureStripeAccountOptions
): Promise<Stripe.Account> => {
  const stripe = getStripeClient();
  const { codeRef, codeData, user, requestedCountry } = options;

  const existingAccountId =
    typeof codeData.stripeAccountId === "string" && codeData.stripeAccountId.trim().length > 0
      ? codeData.stripeAccountId.trim()
      : undefined;

  let account: Stripe.Account | null = null;

  if (existingAccountId) {
    try {
      account = await stripe.accounts.retrieve(existingAccountId);
    } catch (error) {
      if (isStripeResourceMissing(error)) {
        await clearStripeAccountFields(codeRef);
        account = null;
      } else {
        throw error;
      }
    }
  }

  if (!account) {
    let normalizedCountry: string | undefined;
    if (typeof requestedCountry === "string" && requestedCountry.trim().length === 2) {
      normalizedCountry = requestedCountry.trim().toUpperCase();
    } else if (
      typeof codeData.stripeAccountCountry === "string" &&
      codeData.stripeAccountCountry.trim().length === 2
    ) {
      normalizedCountry = codeData.stripeAccountCountry.trim().toUpperCase();
    }

    if (!normalizedCountry || !/^[A-Z]{2}$/.test(normalizedCountry)) {
      normalizedCountry = "US";
    }

    const emailFromDoc =
      typeof codeData.influencerEmail === "string" && codeData.influencerEmail.trim().length > 0
        ? codeData.influencerEmail.trim()
        : undefined;

    account = await stripe.accounts.create({
      type: "express",
      country: normalizedCountry,
      email: emailFromDoc ?? user.email ?? undefined,
      metadata: {
        referral_code: codeRef.id,
        owner_uid: user.uid,
      },
      business_profile: {
        product_description: "FitHub affiliate payouts",
      },
      capabilities: {
        transfers: { requested: true },
      },
    });
  }

  await syncStripeAccountFields(codeRef, account);
  return account;
};

const syncStripeAccountFields = async (
  codeRef: FirebaseFirestore.DocumentReference<FirebaseFirestore.DocumentData>,
  account: Stripe.Account
): Promise<void> => {
  const requirements = account.requirements ?? null;

  await codeRef.update({
    stripeAccountId: account.id,
    stripeAccountCountry: account.country ?? null,
    stripeDetailsSubmitted: account.details_submitted ?? false,
    stripePayoutsEnabled: account.payouts_enabled ?? false,
    stripeRequirementsDue: requirements?.currently_due ?? [],
    stripeLastStripeSyncAt: admin.firestore.FieldValue.serverTimestamp(),
  });
};

const clearStripeAccountFields = async (
  codeRef: FirebaseFirestore.DocumentReference<FirebaseFirestore.DocumentData>
): Promise<void> => {
  await codeRef.update({
    stripeAccountId: null,
    stripeAccountCountry: null,
    stripeDetailsSubmitted: false,
    stripePayoutsEnabled: false,
    stripeRequirementsDue: [],
    stripeLastStripeSyncAt: admin.firestore.FieldValue.serverTimestamp(),
  });
};

const isStripeResourceMissing = (error: unknown): boolean => {
  return error instanceof Stripe.errors.StripeError && error.code === "resource_missing";
};

const respondSuccess = (res: Response, result: unknown, status = 200): void => {
  res.status(status).json({ result });
};

const handleFunctionError = (res: Response, error: unknown): void => {
  if (error instanceof HttpError) {
    res.status(error.status).json({ error: { status: error.status, message: error.message } });
    return;
  }

  if (error instanceof Stripe.errors.StripeError) {
    const status = error.statusCode ?? 500;
    res.status(status).json({ error: { status, message: error.message } });
    return;
  }

  if (error instanceof Error) {
    console.error("Unhandled error during Stripe affiliate request:", error);
    res.status(500).json({ error: { status: 500, message: "An unexpected error occurred." } });
    return;
  }

  console.error("Unknown error during Stripe affiliate request:", error);
  res.status(500).json({ error: { status: 500, message: "An unexpected error occurred." } });
};
