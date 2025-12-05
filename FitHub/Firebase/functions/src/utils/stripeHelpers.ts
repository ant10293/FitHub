import * as admin from "firebase-admin";
import Stripe from "stripe";
import { HttpError } from "./httpHelpers";

// Stripe configuration
const stripeSecretKey = process.env.STRIPE_SECRET_KEY;
const stripeApiVersion = process.env.STRIPE_API_VERSION as Stripe.StripeConfig["apiVersion"];
export const stripeClient = stripeSecretKey
  ? new Stripe(stripeSecretKey, { apiVersion: stripeApiVersion })
  : null;

export const STRIPE_ONBOARDING_RETURN_URL = process.env.STRIPE_ONBOARDING_RETURN_URL;
export const STRIPE_ONBOARDING_REFRESH_URL = process.env.STRIPE_ONBOARDING_REFRESH_URL;
export const STRIPE_DASHBOARD_REDIRECT_URL = process.env.STRIPE_DASHBOARD_REDIRECT_URL;

/**
 * Gets the Stripe client instance
 * @throws HttpError if Stripe is not configured
 */
export const getStripeClient = (): Stripe => {
  if (!stripeClient) {
    throw new HttpError(500, "Stripe is not configured. Missing STRIPE_SECRET_KEY.");
  }
  return stripeClient;
};

/**
 * Checks if an error is a Stripe "resource missing" error
 */
export const isStripeResourceMissing = (error: unknown): boolean => {
  return error instanceof Stripe.errors.StripeError && error.code === "resource_missing";
};

export interface EnsureStripeAccountOptions {
  codeRef: FirebaseFirestore.DocumentReference<FirebaseFirestore.DocumentData>;
  codeData: FirebaseFirestore.DocumentData;
  user: admin.auth.DecodedIdToken;
  requestedCountry?: string;
}

/**
 * Ensures a Stripe account exists for an affiliate referral code
 * Creates a new account if one doesn't exist, or retrieves existing account
 */
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

/**
 * Syncs Stripe account fields to Firestore
 */
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

/**
 * Clears Stripe account fields from Firestore
 */
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













































































