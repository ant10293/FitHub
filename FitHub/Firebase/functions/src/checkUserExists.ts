import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { checkRateLimit, RateLimits, getRequestIP } from "./utils/rateLimiter";

/**
 * Checks if a user exists by email
 * Rate limited: 20 requests per minute per IP address
 */
export const checkUserExists = functions.https.onCall(async (data, context) => {
  // Rate limit by IP address (since this function doesn't require auth)
  const ip = context.rawRequest ? getRequestIP(context.rawRequest) : "unknown";
  const result = await checkRateLimit({
    ...RateLimits.CHECK_USER_EXISTS,
    identifier: ip,
    functionName: "checkUserExists",
  });
  
  if (!result.allowed) {
    throw new functions.https.HttpsError(
      "resource-exhausted",
      `Rate limit exceeded. Please try again in ${result.retryAfter} seconds.`,
      {
        retryAfter: result.retryAfter,
        resetAt: result.resetAt.toISOString(),
      }
    );
  }

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
