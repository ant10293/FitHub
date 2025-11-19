import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";

export const checkUserExists = functions.https.onCall(async (data) => {
  const email = typeof data?.email === "string" ? data.email.trim().toLowerCase() : "";
  if (!email) {
    throw new functions.https.HttpsError("invalid-argument", "Email is required.");
  }

  try {
    await admin.auth().getUserByEmail(email);
    return { exists: true };
  } catch (error: any) {
    if (error.code === "auth/user-not-found") {
      return { exists: false };
    }
    console.error("checkUserExists error:", error);
    throw new functions.https.HttpsError("internal", "Unable to check account status.");
  }
});


