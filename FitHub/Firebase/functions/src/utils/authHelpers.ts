import * as functions from "firebase-functions/v1";
import type { CallableContext } from "firebase-functions/v1/https";

/**
 * Requires authentication and returns the user ID
 * @throws HttpsError if user is not authenticated
 */
export function requireAuth(context: CallableContext): string {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
  }
  return context.auth.uid;
}

/**
 * Safely extracts a string value from data, with optional trimming and transformation
 */
export function extractString(
  data: any,
  key: string,
  options?: {
    trim?: boolean;
    uppercase?: boolean;
    lowercase?: boolean;
    defaultValue?: string;
  }
): string {
  const value = typeof data?.[key] === "string" ? data[key] : options?.defaultValue ?? "";
  let result = value;
  if (options?.trim) result = result.trim();
  if (options?.uppercase) result = result.toUpperCase();
  if (options?.lowercase) result = result.toLowerCase();
  return result;
}

/**
 * Validates that a required string value is not empty
 * @throws HttpsError if value is empty
 */
export function requireString(value: string, fieldName: string): void {
  if (!value || value.length === 0) {
    throw new functions.https.HttpsError("invalid-argument", `${fieldName} is required`);
  }
}

