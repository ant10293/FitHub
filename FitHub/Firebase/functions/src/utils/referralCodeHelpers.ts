import * as admin from "firebase-admin";
import { HttpError } from "./httpHelpers";

/**
 * Normalizes a referral code (trims and uppercases)
 * @throws HttpError if code is empty
 */
export const normalizeReferralCode = (value: unknown): string => {
  const code = typeof value === "string" ? value.trim() : "";
  if (!code) {
    throw new HttpError(400, "referralCode is required.");
  }
  return code.toUpperCase();
};

/**
 * Gets a referral code record from Firestore
 * @throws HttpError if code not found
 */
export const getReferralCodeRecord = async (
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

/**
 * Asserts that a user owns a referral code
 * @throws HttpError if user doesn't own the code
 */
export const assertUserOwnsReferralCode = (codeData: FirebaseFirestore.DocumentData, uid: string): void => {
  const createdBy = typeof codeData.createdBy === "string" ? codeData.createdBy : undefined;
  if (createdBy && createdBy !== uid) {
    throw new HttpError(403, "You do not have permission to manage this referral code.");
  }
};
