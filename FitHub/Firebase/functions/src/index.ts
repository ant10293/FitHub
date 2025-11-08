import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { AppStoreServerAPIClient, Environment, SignedDataVerifier } from "@apple/app-store-server-library";

// Initialize Firebase Admin
admin.initializeApp();

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

const getAppStoreAPI = (): AppStoreServerAPIClient => {
  return getAppStoreAPIForEnvironment(Environment.PRODUCTION);
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
    const usersSnapshot = await admin.firestore()
      .collection("users")
      .where("subscriptionStatus.originalTransactionID", "==", String(originalTransactionId))
      .limit(1)
      .get();

    if (usersSnapshot.empty) {
      console.warn(`No user found for transaction ${originalTransactionId}`);
      // Still return 200 to acknowledge receipt (user might not have referral code)
      res.status(200).send("OK");
      return;
    }

    const userId = usersSnapshot.docs[0].id;
    console.log(`Found user ${userId} for transaction ${originalTransactionId}`);

    // Update subscription status based on notification type
      const appStoreAPI = getAppStoreAPIForEnvironment(detectedEnvironment);
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
 */
async function updateReferralCodeSubscriptions(userId: string): Promise<void> {
  const userDoc = await admin.firestore().collection("users").doc(userId).get();
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
  
  const updates: any = {};
  
  if (isActive) {
    // Add to active array if not already there
    updates[activeArray] = admin.firestore.FieldValue.arrayUnion(userId);
  } else {
    // Remove from active array
    updates[activeArray] = admin.firestore.FieldValue.arrayRemove(userId);
  }
  
  // Ensure user is in purchased array (they purchased at some point)
  updates[purchasedArray] = admin.firestore.FieldValue.arrayUnion(userId);
  updates.lastValidationAt = admin.firestore.FieldValue.serverTimestamp();
  
  await codeRef.update(updates);
  
  console.log(`Updated referral code ${referralCode} subscriptions for user ${userId}`);
}

/**
 * Daily scheduled function to validate all subscriptions
 * Runs at 2 AM UTC every day as a backup to webhooks
 */
export const validateAllSubscriptions = functions.pubsub
  .schedule("0 2 * * *")
  .timeZone("UTC")
  .onRun(async (context) => {
    console.log("Starting daily subscription validation...");
    
    const codesSnapshot = await admin.firestore()
      .collection("referralCodes")
      .get();
    
    console.log(`Validating subscriptions for ${codesSnapshot.size} referral codes`);
    
    let validatedCount = 0;
    let errorCount = 0;
    
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
      
      // Validate each user's subscription
      for (const userId of uniqueUserIds) {
        try {
          await validateUserSubscription(userId);
          validatedCount++;
        } catch (error) {
          console.error(`Error validating subscription for user ${userId}:`, error);
          errorCount++;
        }
      }
    }
    
    console.log(`Daily validation complete: ${validatedCount} validated, ${errorCount} errors`);
  });

/**
 * Validates a single user's subscription status
 */
async function validateUserSubscription(userId: string): Promise<void> {
  const userDoc = await admin.firestore().collection("users").doc(userId).get();
  const userData = userDoc.data();
  
  if (!userData?.subscriptionStatus?.originalTransactionID) {
    return; // No subscription to validate
  }
  
  const originalTransactionId = userData.subscriptionStatus.originalTransactionID;
  
  try {
    const appStoreAPI = getAppStoreAPI();
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
    
    if (!matchingTransaction) {
      console.warn(`No matching transaction found for ${originalTransactionId}`);
      return;
    }
    
    const status = matchingTransaction.status;
    const isActive = status === 1;
    
    // Update user's subscription status
    await admin.firestore().collection("users").doc(userId).update({
      "subscriptionStatus.isActive": isActive,
      "subscriptionStatus.lastValidatedAt": admin.firestore.FieldValue.serverTimestamp(),
    });
    
    // Update referral code active subscriptions
    await updateReferralCodeSubscriptions(userId);
  } catch (error) {
    console.error(`Error validating subscription for user ${userId}:`, error);
    throw error;
  }
}
