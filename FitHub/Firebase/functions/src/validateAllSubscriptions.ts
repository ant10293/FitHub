import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { retryWithBackoff, trackValidationFailure, validateUserSubscription, isRetryableError } from "./utils/validationHelpers";

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


