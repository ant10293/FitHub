import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import {
  authenticateRequest,
  extractDataPayload,
  normalizeReferralCode,
  getReferralCodeRecord,
  assertUserOwnsReferralCode,
  ensureStripeAccountForAffiliate,
  getStripeClient,
  requireEnv,
  respondSuccess,
  handleFunctionError,
  STRIPE_ONBOARDING_RETURN_URL,
  STRIPE_ONBOARDING_REFRESH_URL,
} from "./utils/shared";

/**
 * Stripe Connect integration for affiliate payouts
 */
export const createAffiliateOnboardingLink = functions.https.onRequest(async (req, res) => {
  if (req.method !== "POST") {
    res.status(405).json({ error: { status: 405, message: "Method not allowed." } });
    return;
  }

  try {
    const decodedToken = await authenticateRequest(req);
    const payload = extractDataPayload(req.body);
    const referralCode = normalizeReferralCode(payload.referralCode);
    const requestedCountry = typeof payload.country === "string" ? payload.country : undefined;

    const { codeRef, codeData } = await getReferralCodeRecord(referralCode);
    assertUserOwnsReferralCode(codeData, decodedToken.uid);

    const account = await ensureStripeAccountForAffiliate({
      codeRef,
      codeData,
      user: decodedToken,
      requestedCountry,
    });

    const stripe = getStripeClient();
    const accountLink = await stripe.accountLinks.create({
      account: account.id,
      refresh_url: requireEnv(STRIPE_ONBOARDING_REFRESH_URL, "STRIPE_ONBOARDING_REFRESH_URL"),
      return_url: requireEnv(STRIPE_ONBOARDING_RETURN_URL, "STRIPE_ONBOARDING_RETURN_URL"),
      type: "account_onboarding",
    });

    await codeRef.update({
      stripeLastOnboardingAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    respondSuccess(res, {
      accountId: account.id,
      url: accountLink.url,
      expiresAt: accountLink.expires_at ?? null,
      createdAt: accountLink.created ?? null,
      detailsSubmitted: account.details_submitted ?? false,
      payoutsEnabled: account.payouts_enabled ?? false,
    });
  } catch (error) {
    handleFunctionError(res, error);
  }
});


