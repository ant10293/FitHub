import * as admin from "firebase-admin";
import { Environment } from "@apple/app-store-server-library";
import { getAppStoreAPIForEnvironment, makeSignedDataVerifier } from "./appStoreHelpers";
import { updateReferralCodeSubscriptions } from "./subscriptionHelpers";

/**
 * Retry helper with exponential backoff
 */
export async function retryWithBackoff<T>(
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
export async function trackValidationFailure(
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
export function isRetryableError(error: any): boolean {
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
 * Validates a single user's subscription status
 * Improved with environment detection and better error handling
 */
export async function validateUserSubscription(userId: string): Promise<void> {
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



