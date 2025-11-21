import { AppStoreServerAPIClient, Environment, SignedDataVerifier } from "@apple/app-store-server-library";
import { validateEnvironmentVariables } from "./configValidation";

// App Store configuration
export type AppStoreConfig = {
  privateKey: string;
  keyId: string;
  issuerId: string;
  bundleId: string;
  appAppleId?: number;
};

// Lazy validation flag - only validate once per function instance
let appStoreConfigValidated = false;

/**
 * Gets the App Store Connect configuration
 * Validates environment variables on first access (lazy validation)
 */
export const getAppStoreConfig = (): AppStoreConfig => {
  // Validate environment variables on first access (lazy validation)
  // This ensures we fail fast at runtime, but don't break during Firebase's code analysis
  if (!appStoreConfigValidated) {
    validateEnvironmentVariables();
    appStoreConfigValidated = true;
  }

  const privateKeyEnv = process.env.APPSTORE_PRIVATE_KEY;
  const keyIdEnv = process.env.APPSTORE_KEY_ID;
  const issuerIdEnv = process.env.APPSTORE_ISSUER_ID;
  const bundleIdEnv = process.env.APPSTORE_BUNDLE_ID;
  const appAppleIdEnv = process.env.APPSTORE_APP_APPLE_ID;

  // These should never be null/undefined if validateEnvironmentVariables passed,
  // but we keep the check for safety
  if (!privateKeyEnv || !keyIdEnv || !issuerIdEnv) {
    throw new Error("Missing App Store Connect configuration. Ensure APPSTORE_PRIVATE_KEY, APPSTORE_KEY_ID, and APPSTORE_ISSUER_ID are set.");
  }

  const bundleId = bundleIdEnv ?? "com.AnthonyC.FitHub";
  const appAppleId = appAppleIdEnv ? Number(appAppleIdEnv) : undefined;
  if (appAppleIdEnv && Number.isNaN(appAppleId)) {
    throw new Error("APPSTORE_APP_APPLE_ID must be a valid number if provided.");
  }

  return {
    privateKey: privateKeyEnv.replace(/\\n/g, "\n"),
    keyId: keyIdEnv,
    issuerId: issuerIdEnv,
    bundleId,
    appAppleId,
  };
};

/**
 * Gets an App Store Server API client for the specified environment
 */
export const getAppStoreAPIForEnvironment = (environment: Environment): AppStoreServerAPIClient => {
  const config = getAppStoreConfig();

  return new AppStoreServerAPIClient(
    config.privateKey,
    config.keyId,
    config.issuerId,
    config.bundleId,
    environment
  );
};

const APPLE_ROOT_CERTIFICATES = [
  Buffer.from(
    "MIICQzCCAcmgAwIBAgIILcX8iNLFS5UwCgYIKoZIzj0EAwMwZzEbMBkGA1UEAwwSQXBwbGUgUm9vdCBDQSAtIEczMSYwJAYDVQQLDB1BcHBsZSBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTETMBEGA1UECgwKQXBwbGUgSW5jLjELMAkGA1UEBhMCVVMwHhcNMTQwNDMwMTgxOTA2WhcNMzkwNDMwMTgxOTA2WjBnMRswGQYDVQQDDBJBcHBsZSBSb290IENBIC0gRzMxJjAkBgNVBAsMHUFwcGxlIENlcnRpZmljYXRpb24gQXV0aG9yaXR5MRMwEQYDVQQKDApBcHBsZSBJbmMuMQswCQYDVQQGEwJVUzB2MBAGByqGSM49AgEGBSuBBAAiA2IABJjpLz1AcqTtkyJygRMc3RCV8cWjTnHcFBbZDuWmBSp3ZHtfTjjTuxxEtX/1H7YyYl3J6YRbTzBPEVoA/VhYDKX1DyxNB0cTddqXl5dvMVztK517IDvYuVTZXpmkOlEKMaNCMEAwHQYDVR0OBBYEFLuw3qFYM4iapIqZ3r6966/ayySrMA8GA1UdEwEB/wQFMAMBAf8wDgYDVR0PAQH/BAQDAgEGMAoGCCqGSM49BAMDA2gAMGUCMQCD6cHEFl4aXTQY2e3v9GwOAEZLuN+yRhHFD/3meoyhpmvOwgPUnPWTxnS4at+qIxUCMG1mihDK1A3UT82NQz60imOlM27jbdoXt2QfyFMm+YhidDkLF1vLUagM6BgD56KyKA==",
    "base64"
  ),
];

/**
 * Creates a signed data verifier for App Store notifications
 */
export const makeSignedDataVerifier = (environment: Environment): SignedDataVerifier => {
  const config = getAppStoreConfig();
  const appAppleId = environment === Environment.PRODUCTION ? config.appAppleId : undefined;
  return new SignedDataVerifier(APPLE_ROOT_CERTIFICATES, true, environment, config.bundleId, appAppleId);
};













