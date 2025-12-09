# Pre-Launch Checklist - 2 Week Timeline

## ✅ Already Complete
- ✅ Privacy strings configured (HealthKit, Photo Library)
- ✅ App icon asset present
- ✅ Referral system implemented and working
- ✅ Firebase functions deployed
- ✅ Universal links configured
- ✅ Subscription validation working
- ✅ Rate limiting configured

---

## 🔴 CRITICAL (Must Complete - Week 1)

### 1. App Store Connect Products Setup (2-4 hours)
**Status:** ⚠️ Need to verify these are created
- [ ] Create subscription products in App Store Connect:
  - `com.FitHub.premium.monthly` (Auto-Renewable Subscription)
  - `com.FitHub.premium.yearly` (Auto-Renewable Subscription)
  - `com.FitHub.premium.lifetime` (Non-Consumable)
- [ ] Set pricing for all products
- [ ] Add product descriptions and display names
- [ ] Put monthly/yearly in same subscription group
- [ ] Wait 15-30 minutes for Apple to propagate products
- [ ] Test products load in TestFlight build

**Reference:** `ReferralSystems/APP_STORE_CONNECT_PRODUCTS_SETUP.md`

### 2. App Store Listing Metadata (3-5 hours)
**Status:** ⚠️ Need to complete
- [ ] **App Name** (up to 30 characters)
- [ ] **Subtitle** (up to 30 characters)
- [ ] **Description** (up to 4000 characters)
  - What the app does
  - Key features
  - Who it's for
- [ ] **Keywords** (up to 100 characters, comma-separated)
- [ ] **Support URL** (your website/contact)
- [ ] **Marketing URL** (optional - landing page)
- [ ] **Privacy Policy URL** (required if collecting data)
- [ ] **Category** (Health & Fitness primary, secondary?)
- [ ] **App Age Rating** (complete questionnaire)

### 3. App Screenshots (4-6 hours)
**Required sizes:**
- [ ] iPhone 6.7" (iPhone 14 Pro Max, 15 Pro Max) - 1290 x 2796 px
- [ ] iPhone 6.5" (iPhone 11 Pro Max, XS Max) - 1242 x 2688 px
- [ ] iPhone 5.5" (iPhone 8 Plus) - 1242 x 2208 px
- [ ] **Minimum 3 screenshots required, up to 10 per size**

**Screenshot content ideas:**
- Home/workout generation screen
- Exercise detail view
- Workout in progress
- Template/planning view
- Subscription/premium features

**Tools:** Use Xcode Simulator or actual device (Device → Screenshots)

### 4. Build & TestFlight Upload (2-3 hours)
- [ ] Clean build folder (Product → Clean Build Folder)
- [ ] Select "Any iOS Device" or Generic iOS Device
- [ ] Product → Archive
- [ ] Wait for archive to complete
- [ ] Click "Distribute App"
- [ ] Select "App Store Connect"
- [ ] Select "Upload"
- [ ] Follow wizard (signing, etc.)
- [ ] Upload completes
- [ ] Go to App Store Connect → TestFlight
- [ ] Wait for processing (10-30 minutes)
- [ ] Add build to Internal Testing group
- [ ] Test on device via TestFlight

### 5. Final Device Testing (4-6 hours)
Test on **actual device** (not just simulator):
- [ ] Sign in flow (Guest, Email, Sign in with Apple)
- [ ] HealthKit permission prompts appear
- [ ] Workout generation works
- [ ] Exercise selection and details
- [ ] Start/complete a workout
- [ ] Subscription purchase flow (sandbox)
- [ ] Referral code claim (universal link + manual entry)
- [ ] Notification permissions
- [ ] Photo library access (if using)
- [ ] All critical user flows work smoothly

**Estimated Total for Week 1:** 15-24 hours

---

## 🟡 IMPORTANT (Week 2 - Before Submission)

### 6. App Store Review Information (1 hour)
- [ ] **Review Notes** (instructions for reviewer)
  - Test account credentials (if needed)
  - Demo account info
  - Any special testing instructions
- [ ] **Contact Information** (your contact info for reviewers)

### 7. Compliance & Legal (2-3 hours)
- [ ] **Privacy Policy URL** - Must be live and accessible
- [ ] **Terms of Service URL** (if you have one)
- [ ] **Export Compliance** - Answer questions
- [ ] **Content Rights** - Confirm you have rights to all content

### 8. Final Submission Prep (1-2 hours)
- [ ] Test one more time on TestFlight build
- [ ] Verify all products are still loading
- [ ] Check for any crash logs in App Store Connect
- [ ] Review app metadata one last time
- [ ] Make sure version number is correct

### 9. Submit for Review (30 minutes)
- [ ] In App Store Connect → App Store tab
- [ ] Click "+ Version or Platform"
- [ ] Select your uploaded build
- [ ] Review all information
- [ ] Click "Submit for Review"
- [ ] Answer any export compliance questions
- [ ] Submit!

**Estimated Total for Week 2:** 4-6 hours

---

## 🟢 NICE TO HAVE (Optional - Can Do Post-Launch)

- [ ] App Preview video (optional but recommended)
- [ ] Promotional text (what's new - can update without new review)
- [ ] Localized descriptions (if targeting other countries)
- [ ] Analytics setup (Firebase Analytics - 30 minutes)
- [ ] Crash reporting (you said no Crashlytics, so skip)

---

## ⏱️ Timeline Estimate

### Week 1 (Days 1-7): Critical Setup
- **Days 1-2:** App Store Connect products setup + metadata writing (6-8 hours)
- **Days 3-4:** Screenshots + build/upload (6-8 hours)
- **Days 5-7:** Device testing + fixes (8-12 hours)
- **Total Week 1:** ~20-28 hours

### Week 2 (Days 8-14): Polish & Submit
- **Days 8-10:** Final testing + review information (4-6 hours)
- **Days 11-12:** Compliance + final checks (2-3 hours)
- **Day 13-14:** Submit + monitor (1-2 hours)
- **Total Week 2:** ~7-11 hours

**Grand Total:** ~27-39 hours over 2 weeks

---

## 🚨 Potential Blockers

1. **App Store Connect API Issues** - Products might take time to propagate
2. **Screenshot Creation** - Can take time if you want polished screenshots
3. **Review Rejection** - First submission might get rejected (common)
4. **Build Issues** - Archive/upload might fail (usually signing issues)

---

## 📝 Quick Tips

1. **Start with products** - These take the longest to propagate
2. **Take screenshots early** - You can update them later without new review
3. **Use TestFlight extensively** - Better to catch issues before submission
4. **Write metadata clearly** - Helps reviewers understand your app
5. **Have a test account ready** - Reviewers might need it

---

## ✅ Success Criteria

You're ready to submit when:
- ✅ All 3 products created and loading in TestFlight
- ✅ All required screenshots uploaded (minimum 3)
- ✅ App description and metadata complete
- ✅ Privacy Policy URL is live
- ✅ TestFlight build tested and working
- ✅ No critical bugs found in final testing

---

**You have 2 weeks - this is totally doable!** 🚀

Most time-consuming tasks:
1. Screenshots (4-6 hours)
2. Device testing (4-6 hours)
3. Products setup (2-4 hours)

Everything else is pretty quick. You've got this!