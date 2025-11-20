import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { authenticateRequest, extractDataPayload } from "./utils/requestHelpers";
import { normalizeReferralCode, getReferralCodeRecord, assertUserOwnsReferralCode } from "./utils/referralCodeHelpers";
import {
  getStripeClient,
  isStripeResourceMissing,
  syncStripeAccountFields,
  clearStripeAccountFields,
  STRIPE_DASHBOARD_REDIRECT_URL,
} from "./utils/stripeHelpers";
import { HttpError, respondSuccess, handleFunctionError } from "./utils/httpHelpers";
import { rateLimitRequest, RateLimits } from "./utils/rateLimiter";

/**
 * Gets Stripe dashboard link for affiliate
 * Rate limited: 30 requests per minute per user
 */
export const getAffiliateDashboardLink = functions.https.onRequest(async (req, res) => {
  if (req.method !== "POST") {
    res.status(405).json({ error: { status: 405, message: "Method not allowed." } });
    return;
  }

  try {
    // Authenticate first (needed for user-based rate limiting)
    const decodedToken = await authenticateRequest(req);
    
    // Apply rate limiting (throws if exceeded)
    await rateLimitRequest(req, RateLimits.AFFILIATE_DASHBOARD, async () => decodedToken.uid);
    const payload = extractDataPayload(req.body);
    const referralCode = normalizeReferralCode(payload.referralCode);

    const { codeRef, codeData } = await getReferralCodeRecord(referralCode);
    assertUserOwnsReferralCode(codeData, decodedToken.uid);

    const accountId =
      typeof codeData.stripeAccountId === "string" && codeData.stripeAccountId.trim().length > 0
        ? codeData.stripeAccountId.trim()
        : undefined;

    if (!accountId) {
      throw new HttpError(400, "Stripe account not connected. Please connect your Stripe account first.");
    }

    const stripe = getStripeClient();
    let account;

    try {
      account = await stripe.accounts.retrieve(accountId);
    } catch (error) {
      if (isStripeResourceMissing(error)) {
        await clearStripeAccountFields(codeRef);
        throw new HttpError(410, "Stripe account no longer exists. Please reconnect your Stripe account.");
      }
      throw error;
    }

    await syncStripeAccountFields(codeRef, account);

    const loginLinkResponse = await stripe.accounts.createLoginLink(account.id);
    const loginUrl = new URL(loginLinkResponse.url);

    if (typeof STRIPE_DASHBOARD_REDIRECT_URL === "string" && STRIPE_DASHBOARD_REDIRECT_URL.trim().length > 0) {
      loginUrl.searchParams.set("redirect_url", STRIPE_DASHBOARD_REDIRECT_URL.trim());
    }

    await codeRef.update({
      stripeLastDashboardLinkAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    respondSuccess(res, {
      accountId: account.id,
      url: loginUrl.toString(),
      expiresAt: null,
      createdAt: loginLinkResponse.created ?? null,
      payoutsEnabled: account.payouts_enabled ?? false,
    });
  } catch (error) {
    handleFunctionError(res, error);
  }
});



