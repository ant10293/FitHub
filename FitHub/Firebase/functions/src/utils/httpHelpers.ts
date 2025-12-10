import type { Response } from "express";
import Stripe from "stripe";

/**
 * HTTP error class for consistent error responses
 */
export class HttpError extends Error {
  status: number;

  constructor(status: number, message: string) {
    super(message);
    this.status = status;
  }
}

/**
 * Requires an environment variable to be set
 * @throws HttpError if the value is undefined
 */
export const requireEnv = (value: string | undefined, name: string): string => {
  if (!value) {
    throw new HttpError(500, `${name} is not configured.`);
  }
  return value;
};

/**
 * Sends a successful JSON response
 */
export const respondSuccess = (res: Response, result: unknown, status = 200): void => {
  res.status(status).json({ result });
};

/**
 * Handles function errors and sends appropriate HTTP responses
 */
export const handleFunctionError = (res: Response, error: unknown): void => {
  if (error instanceof HttpError) {
    res.status(error.status).json({ error: { status: error.status, message: error.message } });
    return;
  }

  if (error instanceof Stripe.errors.StripeError) {
    const status = error.statusCode ?? 500;
    res.status(status).json({ error: { status, message: error.message } });
    return;
  }

  if (error instanceof Error) {
    console.error("Unhandled error during Stripe affiliate request:", error);
    res.status(500).json({ error: { status: 500, message: "An unexpected error occurred." } });
    return;
  }

  console.error("Unknown error during Stripe affiliate request:", error);
  res.status(500).json({ error: { status: 500, message: "An unexpected error occurred." } });
};

/**
 * Sets CORS headers for HTTP functions
 */
export const setCorsHeaders = (res: Response): void => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type");
};

/**
 * Handles CORS preflight requests
 */
export const handleCorsPreflight = (req: { method?: string }, res: Response): boolean => {
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return true;
  }
  return false;
};

/**
 * Validates that request method is POST
 */
export const requirePost = (req: { method?: string }, res: Response): boolean => {
  if (req.method !== "POST") {
    res.status(405).send("Method not allowed");
    return false;
  }
  return true;
};
