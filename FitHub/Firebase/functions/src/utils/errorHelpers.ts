import * as functions from "firebase-functions/v1";

/**
 * Error code to HttpsError code mapping
 */
export interface ErrorMapping {
  [errorCode: string]: {
    code: functions.https.FunctionsErrorCode;
    message: string;
  };
}

/**
 * Handles errors from transactions and other operations with consistent error handling
 */
export function handleFunctionError(
  error: any,
  errorMappings?: ErrorMapping,
  functionName?: string
): never {
  // Check for mapped error codes first
  if (errorMappings && error.message && errorMappings[error.message]) {
    const mapping = errorMappings[error.message];
    throw new functions.https.HttpsError(mapping.code, mapping.message);
  }

  // If it's already an HttpsError, re-throw it
  if (error instanceof functions.https.HttpsError) {
    throw error;
  }

  // Log the actual error for debugging
  const logPrefix = functionName ? `[${functionName}]` : "";
  console.error(`${logPrefix} Error:`, error);
  if (error.stack) console.error("Error stack:", error.stack);
  if (error.message) console.error("Error message:", error.message);

  // Return a more descriptive internal error
  throw new functions.https.HttpsError(
    "internal",
    `${logPrefix} ${error.message || String(error)}`
  );
}
