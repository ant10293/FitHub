import * as admin from "firebase-admin";
import { HttpError } from "./httpHelpers";

/**
 * Data payload type for request bodies
 */
export type DataPayload = Record<string, unknown>;

/**
 * Authenticates a request by verifying the Authorization header
 * @throws HttpError if authentication fails
 */
export const authenticateRequest = async (req: any): Promise<admin.auth.DecodedIdToken> => {
  const authHeader = req.get("Authorization") ?? req.get("authorization");
  if (!authHeader) {
    throw new HttpError(401, "Missing Authorization header.");
  }

  const match = authHeader.match(/^Bearer (.+)$/i);
  if (!match) {
    throw new HttpError(401, "Invalid Authorization token.");
  }

  try {
    return await admin.auth().verifyIdToken(match[1]);
  } catch (error) {
    console.error("Failed to verify auth token", error);
    throw new HttpError(401, "Invalid auth token.");
  }
};

/**
 * Extracts the data payload from a request body
 * @throws HttpError if payload is invalid or missing
 */
export const extractDataPayload = (body: unknown): DataPayload => {
  if (!body || typeof body !== "object") {
    throw new HttpError(400, "Invalid request body.");
  }

  const payload = (body as { data?: unknown }).data;
  if (!payload || typeof payload !== "object") {
    throw new HttpError(400, "Missing data payload.");
  }

  return payload as DataPayload;
};









































