import * as admin from "firebase-admin";
import { HttpError } from "./httpHelpers";
import * as functions from "firebase-functions/v1";

/**
 * Rate limit configuration
 */
export interface RateLimitConfig {
  /** Maximum number of requests allowed in the time window */
  maxRequests: number;
  /** Time window in seconds */
  windowSeconds: number;
  /** Unique identifier for the rate limit (e.g., userId, IP address) */
  identifier: string;
  /** Optional: Function name for better logging */
  functionName?: string;
}

/**
 * In-memory rate limit store (fallback when Firestore fails)
 * Per-instance storage (not shared across function instances)
 */
interface InMemoryRateLimit {
  requests: number[];
  lastCleanup: number;
}

const inMemoryStore = new Map<string, InMemoryRateLimit>();
const FAILURE_THRESHOLD = 3; // Switch to in-memory after 3 consecutive failures
const FAILURE_WINDOW_MS = 60000; // 1 minute window for failure tracking

// Track Firestore failures per function
const firestoreFailureCounts = new Map<string, { count: number; lastFailure: number }>();

/**
 * Rate limit result
 */
export interface RateLimitResult {
  allowed: boolean;
  remaining: number;
  resetAt: Date;
  retryAfter?: number; // seconds until retry is allowed
}

/**
 * In-memory rate limit check (fallback when Firestore fails)
 */
function checkInMemoryRateLimit(
  config: RateLimitConfig,
  now: number
): RateLimitResult {
  const { maxRequests, windowSeconds, identifier, functionName = "unknown" } = config;
  const key = `${functionName}:${identifier}`;
  const windowStart = now - (windowSeconds * 1000);

  // Cleanup old entries periodically
  const entry = inMemoryStore.get(key);
  if (entry && now - entry.lastCleanup > 60000) { // Cleanup every minute
    entry.requests = entry.requests.filter(t => t > windowStart);
    entry.lastCleanup = now;
  }

  // Get or create entry
  if (!entry) {
    inMemoryStore.set(key, { requests: [now], lastCleanup: now });
    return { allowed: true, remaining: maxRequests - 1, resetAt: new Date(now + (windowSeconds * 1000)) };
  }

  // Filter valid requests
  const validRequests = entry.requests.filter(t => t > windowStart);

  // Check limit
  if (validRequests.length >= maxRequests) {
    const oldestRequest = Math.min(...validRequests);
    const resetAt = new Date(oldestRequest + (windowSeconds * 1000));
    return {
      allowed: false,
      remaining: 0,
      resetAt,
      retryAfter: Math.ceil((resetAt.getTime() - now) / 1000),
    };
  }

  // Add current request
  validRequests.push(now);
  entry.requests = validRequests;

  return {
    allowed: true,
    remaining: maxRequests - validRequests.length,
    resetAt: new Date(now + (windowSeconds * 1000)),
  };
}

/**
 * Track Firestore failures and determine if we should use fallback
 */
function shouldUseFallback(functionName: string, now: number): boolean {
  const key = functionName;
  const failure = firestoreFailureCounts.get(key);

  if (!failure) {
    return false;
  }

  // Reset if last failure was outside the window
  if (now - failure.lastFailure > FAILURE_WINDOW_MS) {
    firestoreFailureCounts.delete(key);
    return false;
  }

  // Use fallback if we've had enough failures
  return failure.count >= FAILURE_THRESHOLD;
}

/**
 * Record Firestore failure
 */
function recordFirestoreFailure(functionName: string, now: number): void {
  const key = functionName;
  const existing = firestoreFailureCounts.get(key);

  if (existing && now - existing.lastFailure < FAILURE_WINDOW_MS) {
    existing.count++;
    existing.lastFailure = now;
  } else {
    firestoreFailureCounts.set(key, { count: 1, lastFailure: now });
  }
}

/**
 * Record Firestore success (reset failure count)
 */
function recordFirestoreSuccess(functionName: string): void {
  firestoreFailureCounts.delete(functionName);
}

/**
 * Rate limits a request based on identifier (userId or IP)
 * Uses Firestore to track request counts with automatic cleanup
 * Falls back to in-memory rate limiting if Firestore fails repeatedly
 *
 * @param config Rate limit configuration
 * @returns Rate limit result
 */
export async function checkRateLimit(config: RateLimitConfig): Promise<RateLimitResult> {
  const { maxRequests, windowSeconds, identifier, functionName = "unknown" } = config;

  const now = Date.now();
  const windowStart = now - (windowSeconds * 1000);

  // Check if we should use fallback due to repeated Firestore failures
  if (shouldUseFallback(functionName, now)) {
    console.warn(`Using in-memory rate limit fallback for ${functionName} (Firestore failures detected)`);
    return checkInMemoryRateLimit(config, now);
  }

  const db = admin.firestore();
  const rateLimitDocId = `${functionName}:${identifier}`;
  const rateLimitRef = db.collection("rateLimits").doc(rateLimitDocId);

  try {
    // Use transaction to atomically check and update rate limit
    const result = await db.runTransaction(async (transaction) => {
      const doc = await transaction.get(rateLimitRef);
      const data = doc.data();

      // Initialize if doesn't exist
      if (!data) {
        const newData = {
          requests: [now],
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          expiresAt: admin.firestore.Timestamp.fromMillis(now + (windowSeconds * 1000)),
        };
        transaction.set(rateLimitRef, newData);
        return { allowed: true, remaining: maxRequests - 1, resetAt: new Date(now + (windowSeconds * 1000)) };
      }

      // Filter out requests outside the current window
      const requests = (data.requests || []) as number[];
      const validRequests = requests.filter((timestamp: number) => timestamp > windowStart);

      // Check if limit exceeded
      if (validRequests.length >= maxRequests) {
        // Calculate when the oldest request in window expires
        const oldestRequest = Math.min(...validRequests);
        const resetAt = new Date(oldestRequest + (windowSeconds * 1000));
        const retryAfter = Math.ceil((resetAt.getTime() - now) / 1000);

        return {
          allowed: false,
          remaining: 0,
          resetAt,
          retryAfter,
        };
      }

      // Add current request
      validRequests.push(now);
      const expiresAt = admin.firestore.Timestamp.fromMillis(now + (windowSeconds * 1000));

      transaction.update(rateLimitRef, {
        requests: validRequests,
        expiresAt,
        lastRequestAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        allowed: true,
        remaining: maxRequests - validRequests.length,
        resetAt: new Date(now + (windowSeconds * 1000)),
      };
    });

    // Success - reset failure count
    recordFirestoreSuccess(functionName);
    return result;
  } catch (error) {
    // Record failure and use fallback
    recordFirestoreFailure(functionName, now);
    console.error(`Rate limit check failed for ${functionName}:${identifier}:`, error);

    // Use in-memory fallback
    const fallbackResult = checkInMemoryRateLimit(config, now);
    console.warn(`Using in-memory rate limit fallback for ${functionName}:${identifier}`);

    // Track failure for monitoring (don't block request)
    try {
      await admin.firestore().collection("rateLimitFailures").add({
        functionName,
        identifier,
        error: error instanceof Error ? error.message : String(error),
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        usedFallback: true,
      });
    } catch (trackingError) {
      // Don't fail if tracking fails
      console.warn("Failed to track rate limit failure:", trackingError);
    }

    return fallbackResult;
  }
}

/**
 * Rate limit middleware for onCall functions
 * Throws HttpsError if rate limit exceeded
 */
export async function rateLimitCall(
  context: functions.https.CallableContext,
  config: Omit<RateLimitConfig, "identifier" | "functionName">,
  functionName?: string
): Promise<void> {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
  }

  const identifier = context.auth.uid;
  // Use provided functionName, or try to extract from URL, or default to "unknown"
  const resolvedFunctionName = functionName || context.rawRequest?.url?.split("/").pop() || "unknown";

  const result = await checkRateLimit({
    ...config,
    identifier,
    functionName: resolvedFunctionName,
  });

  if (!result.allowed) {
    throw new functions.https.HttpsError(
      "resource-exhausted",
      `Rate limit exceeded. Please try again in ${result.retryAfter} seconds.`,
      {
        retryAfter: result.retryAfter,
        resetAt: result.resetAt.toISOString(),
      }
    );
  }
}

/**
 * Rate limit middleware for onRequest functions
 * Throws HttpError if rate limit exceeded
 */
export async function rateLimitRequest(
  req: any,
  config: Omit<RateLimitConfig, "identifier" | "functionName">,
  getUserIdentifier?: (req: any) => Promise<string>
): Promise<void> {
  // Try to get user identifier from auth token if available
  let identifier: string;

  if (getUserIdentifier) {
    identifier = await getUserIdentifier(req);
  } else {
    // Fallback to IP address
    identifier = req.ip || req.headers["x-forwarded-for"] || req.connection.remoteAddress || "unknown";
  }

  const functionName = req.path?.split("/").pop() || "unknown";

  const result = await checkRateLimit({
    ...config,
    identifier,
    functionName,
  });

  if (!result.allowed) {
    throw new HttpError(
      429,
      `Rate limit exceeded. Please try again in ${result.retryAfter} seconds.`,
    );
  }
}

/**
 * Gets IP address from request
 */
export function getRequestIP(req: any): string {
  return (
    req.headers["x-forwarded-for"]?.split(",")[0]?.trim() ||
    req.headers["x-real-ip"] ||
    req.ip ||
    req.connection?.remoteAddress ||
    "unknown"
  );
}

/**
 * Predefined rate limit configurations
 */
export const RateLimits = {
  // Referral code claiming - 5 attempts per minute per user
  CLAIM_REFERRAL_CODE: {
    maxRequests: 5,
    windowSeconds: 60,
  },

  // Purchase tracking - 10 attempts per minute per user (allows retries)
  TRACK_PURCHASE: {
    maxRequests: 10,
    windowSeconds: 60,
  },

  // User existence check - 20 attempts per minute per IP
  CHECK_USER_EXISTS: {
    maxRequests: 20,
    windowSeconds: 60,
  },

  // Affiliate onboarding - 5 attempts per hour per user
  AFFILIATE_ONBOARDING: {
    maxRequests: 5,
    windowSeconds: 3600,
  },

  // Affiliate dashboard - 30 requests per minute per user
  AFFILIATE_DASHBOARD: {
    maxRequests: 30,
    windowSeconds: 60,
  },
} as const;
