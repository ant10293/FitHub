import * as admin from "firebase-admin";

// Initialize Firebase Admin
admin.initializeApp();

// Export all Cloud Functions
export { checkUserExists } from "./checkUserExists";
export { claimReferralCode } from "./claimReferralCode";
export { trackReferralPurchase } from "./trackReferralPurchase";
export { handleAppStoreNotification } from "./handleAppStoreNotification";
export { validateAllSubscriptions } from "./validateAllSubscriptions";
export { createAffiliateOnboardingLink } from "./createAffiliateOnboardingLink";
export { getAffiliateDashboardLink } from "./getAffiliateDashboardLink";
