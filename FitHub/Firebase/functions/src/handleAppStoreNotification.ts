import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { Environment } from "@apple/app-store-server-library";
import { getAppStoreAPIForEnvironment, makeSignedDataVerifier } from "./utils/appStoreHelpers";
import { updateSubscriptionStatus, updateReferralCodeSubscriptions } from "./utils/subscriptionHelpers";

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
