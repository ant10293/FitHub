import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { retryWithBackoff, trackValidationFailure, validateUserSubscription, isRetryableError } from "./utils/validationHelpers";

/**
 * Daily scheduled function to validate all subscriptions
 * Runs at 2 AM UTC every day as a backup to webhooks
 * Includes retry logic and failure tracking
 * Wrapped with job-level retry for retryable errors
 */
export const validateAllSubscriptions = functions.pubsub
  .schedule("0 2 * * *")
  .timeZone("UTC")
  .onRun(async () => {
    // Wrap entire job in retry logic, but only retry on retryable errors
    // The job handles partial failures gracefully (user-level errors don't fail the job)
    let lastError: any;
    const maxJobRetries = 2;
    const initialDelayMs = 5000;

    for (let attempt = 0; attempt <= maxJobRetries; attempt++) {
      try {
        await runValidationJob();
        return; // Success - exit
      } catch (error) {
        lastError = error;

        // Only retry if error is retryable and we haven't exceeded max retries
        if (attempt < maxJobRetries && isRetryableError(error)) {
          const delayMs = initialDelayMs * Math.pow(2, attempt);
          console.log(`Job-level retry attempt ${attempt + 1}/${maxJobRetries} after ${delayMs}ms delay (retryable error)`);
          await new Promise(resolve => setTimeout(resolve, delayMs));
        } else {
          // Non-retryable error or max retries reached - log and throw
          if (!isRetryableError(error)) {
            console.error("Job failed with non-retryable error:", error);
          } else {
            console.error("Job failed after max retries:", error);
          }
          throw error; // Let Firebase Functions handle the failure
        }
      }
    }

    // Should never reach here, but just in case
    throw lastError;
  });

/**
 * Main validation job logic
 * Separated to allow job-level retry
 */
async function runValidationJob(): Promise<void> {
  console.log("Starting daily subscription validation...");

  const codesSnapshot = await admin.firestore()
    .collection("referralCodes")
    .get();

  console.log(`Validating subscriptions for ${codesSnapshot.size} referral codes`);

  let validatedCount = 0;
  let errorCount = 0;
  const failedUserIds: string[] = [];
  const persistentFailures: Array<{ userId: string; failureCount: number }> = [];

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
          3, // max 3 retries per user
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
        const failureCount = userData?.subscriptionStatus?.validationFailureCount || 0;

        await trackValidationFailure(userId, error, originalTransactionId);

        // Track persistent failures (users with 3+ consecutive failures)
        // Check >= 2 because trackValidationFailure increments it, so this will be their 3rd+ failure
        if (failureCount >= 2) {
          persistentFailures.push({ userId, failureCount: failureCount + 1 });
        }

        // Log error with context
        console.error(`Failed to validate subscription for user ${userId} after retries:`, {
          error: error instanceof Error ? error.message : String(error),
          originalTransactionId,
          retryable: isRetryableError(error),
          failureCount: failureCount + 1, // +1 because we just incremented it
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
    persistentFailures: persistentFailures.length,
  };

  console.log(`Daily validation complete:`, summary);

  // Calculate error rate and alert if high
  const totalValidations = validatedCount + errorCount;
  let errorRate = 0;
  let highErrorRate = false;

  if (totalValidations > 0) {
    errorRate = (errorCount / totalValidations) * 100;
    highErrorRate = errorRate > 10;

    if (highErrorRate) {
      console.error(`⚠️ HIGH VALIDATION ERROR RATE: ${errorRate.toFixed(2)}% (${errorCount}/${totalValidations})`);
    }
  }

  // Store summary in Firestore for monitoring
  try {
    const summaryDoc = {
      ...summary,
      errorRate: errorRate.toFixed(2),
      highErrorRate: highErrorRate,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      failedUserIds: failedUserIds.slice(0, 100), // Store up to 100 failed user IDs
      persistentFailureUserIds: persistentFailures.map(f => f.userId).slice(0, 50), // Store up to 50 persistent failures
    };

    await admin.firestore().collection("validationRuns").add(summaryDoc);

    // If high error rate, also create an alert document for monitoring systems
    if (highErrorRate) {
      await admin.firestore().collection("validationAlerts").add({
        type: "high_error_rate",
        errorRate: errorRate.toFixed(2),
        errorCount,
        totalValidations,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        resolved: false,
      });
    }

    // Log persistent failures for manual review
    if (persistentFailures.length > 0) {
      console.warn(`⚠️ Found ${persistentFailures.length} users with persistent validation failures (3+ consecutive failures)`);
      console.warn(`Persistent failure user IDs: ${persistentFailures.map(f => f.userId).join(", ")}`);

      // Store persistent failures for manual review
      await admin.firestore().collection("validationAlerts").add({
        type: "persistent_failures",
        count: persistentFailures.length,
        userIds: persistentFailures.map(f => f.userId).slice(0, 50),
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        resolved: false,
      });
    }
  } catch (summaryError) {
    console.error("Failed to store validation summary:", summaryError);
    // Don't throw - we want the job to complete even if summary storage fails
  }
}
