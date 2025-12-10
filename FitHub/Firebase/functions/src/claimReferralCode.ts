import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { rateLimitCall, RateLimits } from "./utils/rateLimiter";
import { requireAuth, extractString, requireString } from "./utils/authHelpers";
import { handleFunctionError, ErrorMapping } from "./utils/errorHelpers";

/**
 * Cloud Function to claim a referral code with server-side validation
 * Validates code exists, is active, and user hasn't already claimed a code
 * Uses Firestore transaction for atomicity
 * Rate limited: 5 requests per minute per user
 */
export const claimReferralCode = functions.https.onCall(async (data, context) => {
  // Apply rate limiting (throws if exceeded)
  await rateLimitCall(context, RateLimits.CLAIM_REFERRAL_CODE, "claimReferralCode");

  // Verify authentication
  const userId = requireAuth(context);

  // Extract and validate referral code
  const referralCode = extractString(data, "referralCode", { trim: true, uppercase: true });
  requireString(referralCode, "Referral code");

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
        // But still clean up pending fingerprints since the code is effectively claimed
        if (String(userData.referralCode).toUpperCase() === referralCode) {
          transaction.update(codeRef, {
            pendingDeviceFingerprints: admin.firestore.FieldValue.delete(), // Clean up pending fingerprints
          });
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
        usedBy: admin.firestore.FieldValue.arrayUnion(userId),
        pendingDeviceFingerprints: admin.firestore.FieldValue.delete(), // Clean up pending fingerprints
      });

      return { success: true, referralCode: referralCode, alreadyClaimed: false };
    });

    return result;
  } catch (error: any) {
    const errorMappings: ErrorMapping = {
      REFERRAL_CODE_NOT_FOUND: {
        code: "not-found",
        message: "Referral code not found",
      },
      REFERRAL_CODE_INACTIVE: {
        code: "failed-precondition",
        message: "Referral code is not active",
      },
      USER_ALREADY_HAS_CODE: {
        code: "already-exists",
        message: "User already has a referral code",
      },
    };

    handleFunctionError(error, errorMappings, "claimReferralCode");
  }
});
