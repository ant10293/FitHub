/**
 * Configuration validation utilities
 * Validates environment variables and configuration at runtime
 */

/**
 * Validates that all required environment variables are set
 * This ensures functions fail fast at runtime if config is missing
 * 
 * @throws Error if required environment variables are missing or invalid
 */
export const validateEnvironmentVariables = (): void => {
  const missing: string[] = [];
  const invalid: string[] = [];

  // Required App Store Connect variables
  if (!process.env.APPSTORE_PRIVATE_KEY) {
    missing.push("APPSTORE_PRIVATE_KEY");
  }
  if (!process.env.APPSTORE_KEY_ID) {
    missing.push("APPSTORE_KEY_ID");
  }
  if (!process.env.APPSTORE_ISSUER_ID) {
    missing.push("APPSTORE_ISSUER_ID");
  }

  // Optional App Store Connect variables (with validation if provided)
  if (process.env.APPSTORE_APP_APPLE_ID) {
    const appAppleId = Number(process.env.APPSTORE_APP_APPLE_ID);
    if (Number.isNaN(appAppleId)) {
      invalid.push("APPSTORE_APP_APPLE_ID must be a valid number");
    }
  }

  if (missing.length > 0) {
    throw new Error(
      `Missing required environment variables: ${missing.join(", ")}. ` +
      `Set these in Firebase Functions config: firebase functions:config:set appstore.key_id="..." appstore.issuer_id="..." appstore.private_key="..."`
    );
  }

  if (invalid.length > 0) {
    throw new Error(`Invalid environment variables: ${invalid.join(", ")}`);
  }
};
