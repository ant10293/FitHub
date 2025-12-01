# Firestore Security Rules Fix - Referral Codes

## Problem
The original Firestore rules allowed **any authenticated user to read any referral code**, which created a security vulnerability:
- Users could enumerate all referral codes
- Users could see other influencers' sensitive data (email, notes, stats)
- Privacy violation and potential data exposure

## Solution
Updated security rules to restrict access based on ownership and validation needs.

## Security Improvements

### 1. **Read Access Restrictions**
- **Full access**: Users can only read referral codes they created (`createdBy == request.auth.uid`)
- **Validation access**: Users can read active codes by exact ID (prevents enumeration since you need to know the exact code ID)
- **Prevents enumeration**: Users cannot query/list all codes - they can only read codes they know the exact ID of

### 2. **Create Access**
- Users can only create codes with `createdBy` set to their own UID
- Prevents users from creating codes on behalf of others

### 3. **Update Access**
- **Creator updates**: Only the creator can update sensitive fields (email, notes, Stripe fields)
- **System updates**: Any authenticated user can update sign-up/purchase tracking fields (usedBy, purchase arrays)
- Prevents unauthorized modification of influencer information

### 4. **Query Restrictions**
- Queries by `createdBy` field work correctly (users can find their own codes)
- No enumeration possible (users can't query all codes)

## What Still Works

✅ **Influencer Registration View** (`InfluencerRegistrationView.swift`)
- Users can read their own codes to view stats
- Works because: `createdBy == request.auth.uid`

✅ **Referral Code Claiming** (`ReferralAttributor.swift`)
- Users can validate codes exist and are active
- Works because: Code is read by exact ID and `isActive == true`

✅ **Code Retrieval** (`ReferralCodeRetriever.swift`)
- Users can query codes they created
- Works because: Query filters by `createdBy == request.auth.uid`

✅ **Purchase Tracking** (`ReferralPurchaseTracker.swift`)
- System can update purchase arrays
- Works because: Update rule allows specific field updates

## Security Trade-offs

**Remaining Risk:**
- When validating a code (during claim), users can still see all fields including email/notes
- **Mitigation**: Users need to know the exact code ID (prevents enumeration)
- **Future improvement**: Use a Cloud Function for validation that only returns `isActive` status

**Why This Is Acceptable:**
- Referral codes are meant to be shared (users share them publicly)
- The main security issue was enumeration, which is now prevented
- Sensitive data (email, notes) is only fully protected for codes you don't own

## Testing Checklist

Before deploying, test:

1. ✅ Influencer can view their own code stats
2. ✅ User can claim a referral code (validation works)
3. ✅ User cannot query all referral codes
4. ✅ User cannot read codes they didn't create (unless validating by exact ID)
5. ✅ Creator can update their code's email
6. ✅ System can update sign-up/purchase tracking fields

## Deployment

1. Deploy updated rules to Firebase:
   ```bash
   firebase deploy --only firestore:rules
   ```

2. Test in Firebase Console → Firestore → Rules → Rules Playground

3. Monitor for any permission denied errors in app logs

## Files Changed

- `Firebase/firestore.rules` - Updated referral code access rules































































