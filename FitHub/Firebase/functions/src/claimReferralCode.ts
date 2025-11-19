import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";

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


