import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { AppStoreServerAPIClient, Environment, SignedDataVerifier } from "@apple/app-store-server-library";
import Stripe from "stripe";
import type { Response } from "express";

// Initialize Firebase Admin
admin.initializeApp();

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
  .onRun(async () => {
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
