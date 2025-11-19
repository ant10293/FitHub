import * as admin from "firebase-admin";
import { AppStoreServerAPIClient, Environment, SignedDataVerifier } from "@apple/app-store-server-library";
import { makeSignedDataVerifier } from "./shared";

/**
 * Updates the user's subscription status in Firestore
 */
export async function updateSubscriptionStatus(
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
export async function updateReferralCodeSubscriptions(userId: string): Promise<void> {
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

