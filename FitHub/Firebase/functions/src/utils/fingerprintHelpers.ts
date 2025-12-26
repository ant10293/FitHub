import * as admin from "firebase-admin";

/**
 * Configuration for fingerprint-based lookup
 */
export interface FingerprintLookupConfig {
  /** Collection name for the main documents (e.g., "affiliateLinks", "referralCodes") */
  mainCollection: string;
  /** Collection name for the reverse index (e.g., "affiliateLinkFingerprints", "referralCodeFingerprints") */
  indexCollection: string;
  /** Field name in index document that contains the token/code (e.g., "linkToken", "referralCode") */
  indexTokenField: string;
  /** Field name in main document that indicates if it's active/available (e.g., "claimed", "isActive") */
  activeField: string;
  /** Value that indicates the document is NOT active (e.g., true for "claimed", false for "isActive") */
  inactiveValue: boolean;
  /** Whether to check expiry on fingerprint data */
  checkExpiry: boolean;
  /** Log prefix for console messages */
  logPrefix: string;
}

/**
 * Result of a fingerprint lookup
 */
export interface FingerprintLookupResult<T = string> {
  success: boolean;
  token?: T;
  reason?: "not_found" | "expired" | "inactive" | "invalid_data";
}

/**
 * Looks up a token/code by device fingerprint using reverse index with fallback
 */
export async function lookupByFingerprint<T = string>(
  db: admin.firestore.Firestore,
  deviceFingerprint: string,
  config: FingerprintLookupConfig
): Promise<FingerprintLookupResult<T>> {
  const { mainCollection, indexCollection, indexTokenField, activeField, inactiveValue, checkExpiry, logPrefix } = config;

  // Try reverse index first (O(1) lookup)
  const fingerprintIndexRef = db.collection(indexCollection).doc(deviceFingerprint);
  const fingerprintIndexDoc = await fingerprintIndexRef.get();

  if (fingerprintIndexDoc.exists) {
    const indexData = fingerprintIndexDoc.data();
    const token = indexData?.[indexTokenField] as T | undefined;

    if (token) {
      // Verify the document still exists and is active
      const docRef = db.collection(mainCollection).doc(String(token));
      const doc = await docRef.get();

      if (doc.exists) {
        const docData = doc.data();
        const isActive = docData?.[activeField] !== inactiveValue;

        if (isActive) {
          const pendingFingerprints = docData?.pendingDeviceFingerprints || {};
          const fingerprintData = pendingFingerprints[deviceFingerprint];

          if (fingerprintData) {
            // Check expiry if needed
            if (checkExpiry) {
              const expiresAt = fingerprintData.expiresAt?.toMillis();
              if (expiresAt && expiresAt < Date.now()) {
                // Expired, clean up
                const updatedFingerprints = { ...pendingFingerprints };
                delete updatedFingerprints[deviceFingerprint];
                await docRef.update({ pendingDeviceFingerprints: updatedFingerprints });
                await fingerprintIndexRef.delete();
                console.log(`[${logPrefix}] Index points to expired entry, cleaned up`);
                return { success: false, reason: "expired" };
              }
            }

            console.log(`[${logPrefix}] Found ${indexTokenField} via index:`, token);
            return { success: true, token };
          } else {
            // Index exists but fingerprint data missing - clean up stale index
            await fingerprintIndexRef.delete();
            console.log(`[${logPrefix}] Index points to document but fingerprint data missing, cleaned up`);
          }
        } else {
          // Document is inactive, clean up stale index
          await fingerprintIndexRef.delete();
          console.log(`[${logPrefix}] Index points to inactive document, cleaned up`);
        }
      } else {
        // Document doesn't exist, clean up stale index
        await fingerprintIndexRef.delete();
        console.log(`[${logPrefix}] Index points to non-existent document, cleaned up`);
      }
    }
  }

  // Fallback: Query collection and scan (O(n) - less efficient)
  // TODO: Remove this fallback once all fingerprints are indexed
  const snapshot = await db.collection(mainCollection)
    .where(activeField, "==", !inactiveValue)
    .limit(50)
    .get();

  if (snapshot.empty) {
    console.log(`[${logPrefix}] No active documents found`);
    return { success: false, reason: "not_found" };
  }

  // Find document with matching fingerprint
  for (const doc of snapshot.docs) {
    const data = doc.data();
    const pendingFingerprints = data.pendingDeviceFingerprints || {};
    if (pendingFingerprints[deviceFingerprint]) {
      const token = doc.id as T;
      // Create reverse index for future lookups
      await fingerprintIndexRef.set({
        [indexTokenField]: token,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`[${logPrefix}] Found ${indexTokenField} via fallback, created index:`, token);
      return { success: true, token };
    }
  }

  return { success: false, reason: "not_found" };
}

/**
 * Creates a reverse index entry for a device fingerprint
 */
export async function createFingerprintIndex(
  db: admin.firestore.Firestore,
  deviceFingerprint: string,
  token: string,
  config: Pick<FingerprintLookupConfig, "indexCollection" | "indexTokenField"> & {
    expiresAt?: admin.firestore.Timestamp;
  }
): Promise<void> {
  const { indexCollection, indexTokenField, expiresAt } = config;
  const fingerprintIndexRef = db.collection(indexCollection).doc(deviceFingerprint);

  const indexData: any = {
    [indexTokenField]: token,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  if (expiresAt) {
    indexData.expiresAt = expiresAt;
  }

  await fingerprintIndexRef.set(indexData);
}

/**
 * Generates a device identifier from IP and User-Agent
 */
export function generateDeviceId(
  ip: string,
  userAgent: string,
  providedFingerprint?: string | null
): string {
  if (providedFingerprint) {
    return providedFingerprint;
  }
  return `${ip}_${userAgent.substring(0, 50)}`.replace(/[^a-zA-Z0-9_]/g, "_");
}

