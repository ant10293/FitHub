// Firebase Cloud Function alternative (if you prefer server-side)
// Deploy this if you want to use the original ReferralAttributor that calls a cloud function

const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * Cloud Function to claim a referral code
 * Called from iOS app via Firebase Functions
 */
exports.claimReferral = functions.https.onCall(async (data, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to claim referral code'
    );
  }

  const { code, source } = data;
  const userId = context.auth.uid;

  if (!code || typeof code !== 'string') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Referral code is required'
    );
  }

  const uppercasedCode = code.trim().toUpperCase();

  // Validate code format (A-Z, 0-9, 4-10 chars)
  if (!/^[A-Z0-9]{4,10}$/.test(uppercasedCode)) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Invalid referral code format'
    );
  }

  const db = admin.firestore();
  const batch = db.batch();

  try {
    // 1. Check if code exists and is active
    const codeRef = db.collection('referralCodes').doc(uppercasedCode);
    const codeDoc = await codeRef.get();

    if (!codeDoc.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        'Referral code not found'
      );
    }

    const codeData = codeDoc.data();

    if (!codeData.isActive) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'Referral code is inactive'
      );
    }

    // 2. Check if user already has a referral code
    const userRef = db.collection('users').doc(userId);
    const userDoc = await userRef.get();

    if (userDoc.exists) {
      const userData = userDoc.data();
      
      if (userData.referralCode) {
        // User already has a code, return success but don't change it
        return {
          success: true,
          message: 'User already has a referral code',
          existingCode: userData.referralCode
        };
      }

      // Check if user already claimed this specific code
      const claimedCodes = userData.claimedReferralCodes || [];
      if (claimedCodes.includes(uppercasedCode)) {
        return {
          success: true,
          message: 'Code already claimed by this user'
        };
      }
    }

    // 3. Perform the claim
    // Update user document
    batch.set(userRef, {
      referralCode: uppercasedCode,
      referralCodeClaimedAt: admin.firestore.FieldValue.serverTimestamp(),
      referralSource: source || 'unknown',
      claimedReferralCodes: admin.firestore.FieldValue.arrayUnion(uppercasedCode)
    }, { merge: true });

    // Update referral code document
    batch.update(codeRef, {
      usageCount: admin.firestore.FieldValue.increment(1),
      lastUsedAt: admin.firestore.FieldValue.serverTimestamp(),
      usedBy: admin.firestore.FieldValue.arrayUnion(userId)
    });

    // Create claim record
    const claimRef = db.collection('referralClaims').doc();
    batch.set(claimRef, {
      code: uppercasedCode,
      userId: userId,
      source: source || 'unknown',
      claimedAt: admin.firestore.FieldValue.serverTimestamp(),
      influencerName: codeData.influencerName || 'Unknown'
    });

    await batch.commit();

    return {
      success: true,
      message: 'Referral code claimed successfully',
      code: uppercasedCode
    };

  } catch (error) {
    console.error('Error claiming referral:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError(
      'internal',
      'Failed to claim referral code',
      error.message
    );
  }
});

/**
 * Admin function to create referral codes
 * Call this from Firebase Console or Admin SDK
 */
exports.createReferralCode = functions.https.onCall(async (data, context) => {
  // Only allow authenticated admins (you'll need to set up custom claims)
  if (!context.auth || !context.auth.token.admin) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Admin access required'
    );
  }

  const { code, influencerName, influencerEmail, notes } = data;

  if (!code || !influencerName) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Code and influencer name are required'
    );
  }

  const uppercasedCode = code.trim().toUpperCase();

  if (!/^[A-Z0-9]{4,10}$/.test(uppercasedCode)) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Invalid code format'
    );
  }

  const db = admin.firestore();
  const codeRef = db.collection('referralCodes').doc(uppercasedCode);

  // Check if exists
  const existing = await codeRef.get();
  if (existing.exists) {
    throw new functions.https.HttpsError(
      'already-exists',
      'Code already exists'
    );
  }

  // Create code
  await codeRef.set({
    code: uppercasedCode,
    influencerName: influencerName,
    influencerEmail: influencerEmail || '',
    notes: notes || '',
    isActive: true,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    usageCount: 0,
    usedBy: []
  });

  return {
    success: true,
    code: uppercasedCode
  };
});

