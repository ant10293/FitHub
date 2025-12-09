import * as admin from "firebase-admin";

// Initialize Firebase Admin
admin.initializeApp();

// Note: Environment variable validation happens lazily when getAppStoreConfig()
// is first called, not at module load. This prevents build-time failures when
// Firebase analyzes the code (env vars may not be available during analysis).

// Export all Cloud Functions
export { checkUserExists } from "./checkUserExists";
export { claimReferralCode } from "./claimReferralCode";
export { trackReferralPurchase } from "./trackReferralPurchase";
export { handleAppStoreNotification } from "./handleAppStoreNotification";
export { validateAllSubscriptions } from "./validateAllSubscriptions";
export { createAffiliateOnboardingLink } from "./createAffiliateOnboardingLink";
export { getAffiliateDashboardLink } from "./getAffiliateDashboardLink";
export { storePendingReferralCode } from "./storePendingReferralCode";
export { getPendingReferralCode } from "./getPendingReferralCode";