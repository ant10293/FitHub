# Rate Limiting Implementation

## Overview
Rate limiting has been implemented for all user-facing Firebase Functions to prevent abuse and control costs.

## Implementation Details

### Rate Limiter Utility (`utils/rateLimiter.ts`)
- Uses Firestore to track request counts per user/IP
- Sliding window algorithm - tracks individual request timestamps
- Automatic cleanup via `expiresAt` timestamps
- Graceful degradation - if rate limiting fails, requests are allowed (prevents single point of failure)

### Rate Limits Applied

| Function | Limit | Window | Identifier |
|----------|-------|--------|------------|
| `claimReferralCode` | 5 requests | 60 seconds | User ID |
| `trackReferralPurchase` | 10 requests | 60 seconds | User ID |
| `checkUserExists` | 20 requests | 60 seconds | IP Address |
| `createAffiliateOnboardingLink` | 5 requests | 3600 seconds (1 hour) | User ID |
| `getAffiliateDashboardLink` | 30 requests | 60 seconds | User ID |

### How It Works

1. **For onCall functions** (authenticated):
   - Uses `rateLimitCall()` helper
   - Rate limits by user ID from auth context
   - Throws `resource-exhausted` HttpsError if exceeded

2. **For onRequest functions** (authenticated):
   - Uses `rateLimitRequest()` helper
   - Rate limits by user ID from auth token
   - Throws `HttpError(429)` if exceeded

3. **For unauthenticated functions**:
   - Rate limits by IP address
   - Falls back to "unknown" if IP cannot be determined

### Firestore Structure

Rate limits are stored in the `rateLimits` collection:

```
rateLimits/{functionName}:{identifier}
  - requests: [timestamp1, timestamp2, ...]
  - createdAt: Timestamp
  - expiresAt: Timestamp
  - lastRequestAt: Timestamp
```

### Error Responses

When rate limit is exceeded:
- **onCall functions**: Returns `resource-exhausted` error with `retryAfter` (seconds) and `resetAt` (ISO timestamp)
- **onRequest functions**: Returns HTTP 429 with error message including retry time

### Cleanup

Rate limit documents automatically expire based on `expiresAt` timestamp. You can optionally:
1. Set up Firestore TTL policy (recommended)
2. Add a scheduled cleanup function
3. Manual cleanup via Firestore console

### Firestore TTL Setup (Recommended)

To automatically clean up expired rate limit documents, add a TTL policy:

```bash
# Using Firebase CLI
firebase firestore:indexes

# Or manually in firestore.indexes.json:
{
  "indexes": [],
  "fieldOverrides": [
    {
      "collectionGroup": "rateLimits",
      "fieldOverrides": [
        {
          "fieldPath": "expiresAt",
          "ttl": true
        }
      ]
    }
  ]
}
```

### Monitoring

Monitor rate limit hits in Firebase Console:
- Check `rateLimits` collection for active rate limits
- Monitor function logs for "resource-exhausted" errors
- Set up alerts for high rate limit hit rates

### Adjusting Rate Limits

Edit `RateLimits` constants in `utils/rateLimiter.ts`:

```typescript
export const RateLimits = {
  CLAIM_REFERRAL_CODE: {
    maxRequests: 5,      // Adjust as needed
    windowSeconds: 60,   // Adjust as needed
  },
  // ... other limits
};
```

### Testing

To test rate limiting:
1. Make requests faster than the limit
2. Verify you get rate limit errors
3. Wait for the window to expire
4. Verify requests work again

### Notes

- Rate limiting is per-function-instance (not global across all instances)
- If Firestore is unavailable, rate limiting gracefully fails and allows requests
- Rate limits are reset when the time window expires (sliding window)
- Each function has independent rate limits













