import * as admin from "firebase-admin";
import { AppStoreServerAPIClient, Environment, SignedDataVerifier } from "@apple/app-store-server-library";
import Stripe from "stripe";
import type { Response } from "express";

// Stripe configuration
const stripeSecretKey = process.env.STRIPE_SECRET_KEY;
const stripeApiVersion = process.env.STRIPE_API_VERSION as Stripe.StripeConfig["apiVersion"];
export const stripeClient = stripeSecretKey
  ? new Stripe(stripeSecretKey, { apiVersion: stripeApiVersion })
  : null;

export const STRIPE_ONBOARDING_RETURN_URL = process.env.STRIPE_ONBOARDING_RETURN_URL;
export const STRIPE_ONBOARDING_REFRESH_URL = process.env.STRIPE_ONBOARDING_REFRESH_URL;
export const STRIPE_DASHBOARD_REDIRECT_URL = process.env.STRIPE_DASHBOARD_REDIRECT_URL;

// HttpError class
export class HttpError extends Error {
  status: number;

  constructor(status: number, message: string) {
    super(message);
    this.status = status;
  }
}

export const requireEnv = (value: string | undefined, name: string): string => {
  if (!value) {
    throw new HttpError(500, `${name} is not configured.`);
  }
  return value;
};

export const getStripeClient = (): Stripe => {
  if (!stripeClient) {
    throw new HttpError(500, "Stripe is not configured. Missing STRIPE_SECRET_KEY.");
  }
  return stripeClient;
};

// App Store configuration
export type AppStoreConfig = {
  privateKey: string;
  keyId: string;
  issuerId: string;
  bundleId: string;
  appAppleId?: number;
};

export const getAppStoreConfig = (): AppStoreConfig => {
  const privateKeyEnv = process.env.APPSTORE_PRIVATE_KEY;
  const keyIdEnv = process.env.APPSTORE_KEY_ID;
  const issuerIdEnv = process.env.APPSTORE_ISSUER_ID;
  const bundleIdEnv = process.env.APPSTORE_BUNDLE_ID;
  const appAppleIdEnv = process.env.APPSTORE_APP_APPLE_ID;

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

export const makeSignedDataVerifier = (environment: Environment): SignedDataVerifier => {
  const config = getAppStoreConfig();
  const appAppleId = environment === Environment.PRODUCTION ? config.appAppleId : undefined;
  return new SignedDataVerifier(APPLE_ROOT_CERTIFICATES, true, environment, config.bundleId, appAppleId);
};

// Stripe helper functions
export const isStripeResourceMissing = (error: unknown): boolean => {
  return error instanceof Stripe.errors.StripeError && error.code === "resource_missing";
};

export const respondSuccess = (res: Response, result: unknown, status = 200): void => {
  res.status(status).json({ result });
};

export const handleFunctionError = (res: Response, error: unknown): void => {
  if (error instanceof HttpError) {
    res.status(error.status).json({ error: { status: error.status, message: error.message } });
    return;
  }

  if (error instanceof Stripe.errors.StripeError) {
    const status = error.statusCode ?? 500;
    res.status(status).json({ error: { status, message: error.message } });
    return;
  }

  if (error instanceof Error) {
    console.error("Unhandled error during Stripe affiliate request:", error);
    res.status(500).json({ error: { status: 500, message: "An unexpected error occurred." } });
    return;
  }

  console.error("Unknown error during Stripe affiliate request:", error);
  res.status(500).json({ error: { status: 500, message: "An unexpected error occurred." } });
};

// Shared types
export type DataPayload = Record<string, unknown>;

// Shared helper functions for Stripe affiliate functions
export const authenticateRequest = async (req: any): Promise<admin.auth.DecodedIdToken> => {
  const authHeader = req.get("Authorization") ?? req.get("authorization");
  if (!authHeader) {
    throw new HttpError(401, "Missing Authorization header.");
  }

  const match = authHeader.match(/^Bearer (.+)$/i);
  if (!match) {
    throw new HttpError(401, "Invalid Authorization token.");
  }

  try {
    return await admin.auth().verifyIdToken(match[1]);
  } catch (error) {
    console.error("Failed to verify auth token", error);
    throw new HttpError(401, "Invalid auth token.");
  }
};

export const extractDataPayload = (body: unknown): DataPayload => {
  if (!body || typeof body !== "object") {
    throw new HttpError(400, "Invalid request body.");
  }

  const payload = (body as { data?: unknown }).data;
  if (!payload || typeof payload !== "object") {
    throw new HttpError(400, "Missing data payload.");
  }

  return payload as DataPayload;
};

export const normalizeReferralCode = (value: unknown): string => {
  const code = typeof value === "string" ? value.trim() : "";
  if (!code) {
    throw new HttpError(400, "referralCode is required.");
  }
  return code.toUpperCase();
};

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

export const assertUserOwnsReferralCode = (codeData: FirebaseFirestore.DocumentData, uid: string): void => {
  const createdBy = typeof codeData.createdBy === "string" ? codeData.createdBy : undefined;
  if (createdBy && createdBy !== uid) {
    throw new HttpError(403, "You do not have permission to manage this referral code.");
  }
};

export interface EnsureStripeAccountOptions {
  codeRef: FirebaseFirestore.DocumentReference<FirebaseFirestore.DocumentData>;
  codeData: FirebaseFirestore.DocumentData;
  user: admin.auth.DecodedIdToken;
  requestedCountry?: string;
}

export const ensureStripeAccountForAffiliate = async (
  options: EnsureStripeAccountOptions
): Promise<Stripe.Account> => {
  const stripe = getStripeClient();
  const { codeRef, codeData, user, requestedCountry } = options;

  const existingAccountId =
    typeof codeData.stripeAccountId === "string" && codeData.stripeAccountId.trim().length > 0
      ? codeData.stripeAccountId.trim()
      : undefined;

  let account: Stripe.Account | null = null;

  if (existingAccountId) {
    try {
      account = await stripe.accounts.retrieve(existingAccountId);
    } catch (error) {
      if (isStripeResourceMissing(error)) {
        await clearStripeAccountFields(codeRef);
        account = null;
      } else {
        throw error;
      }
    }
  }

  if (!account) {
    let normalizedCountry: string | undefined;
    if (typeof requestedCountry === "string" && requestedCountry.trim().length === 2) {
      normalizedCountry = requestedCountry.trim().toUpperCase();
    } else if (
      typeof codeData.stripeAccountCountry === "string" &&
      codeData.stripeAccountCountry.trim().length === 2
    ) {
      normalizedCountry = codeData.stripeAccountCountry.trim().toUpperCase();
    }

    if (!normalizedCountry || !/^[A-Z]{2}$/.test(normalizedCountry)) {
      normalizedCountry = "US";
    }

    const emailFromDoc =
      typeof codeData.influencerEmail === "string" && codeData.influencerEmail.trim().length > 0
        ? codeData.influencerEmail.trim()
        : undefined;

    account = await stripe.accounts.create({
      type: "express",
      country: normalizedCountry,
      email: emailFromDoc ?? user.email ?? undefined,
      metadata: {
        referral_code: codeRef.id,
        owner_uid: user.uid,
      },
      business_profile: {
        product_description: "FitHub affiliate payouts",
      },
      capabilities: {
        transfers: { requested: true },
      },
    });
  }

  await syncStripeAccountFields(codeRef, account);
  return account;
};

export const syncStripeAccountFields = async (
  codeRef: FirebaseFirestore.DocumentReference<FirebaseFirestore.DocumentData>,
  account: Stripe.Account
): Promise<void> => {
  const requirements = account.requirements ?? null;

  await codeRef.update({
    stripeAccountId: account.id,
    stripeAccountCountry: account.country ?? null,
    stripeDetailsSubmitted: account.details_submitted ?? false,
    stripePayoutsEnabled: account.payouts_enabled ?? false,
    stripeRequirementsDue: requirements?.currently_due ?? [],
    stripeLastStripeSyncAt: admin.firestore.FieldValue.serverTimestamp(),
  });
};

export const clearStripeAccountFields = async (
  codeRef: FirebaseFirestore.DocumentReference<FirebaseFirestore.DocumentData>
): Promise<void> => {
  await codeRef.update({
    stripeAccountId: null,
    stripeAccountCountry: null,
    stripeDetailsSubmitted: false,
    stripePayoutsEnabled: false,
    stripeRequirementsDue: [],
    stripeLastStripeSyncAt: admin.firestore.FieldValue.serverTimestamp(),
  });
};


