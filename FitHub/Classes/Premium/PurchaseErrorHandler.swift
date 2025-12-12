//
//  PurchaseErrorHandler.swift
//  FitHub
//
//  Handles all purchase-related errors with user-friendly messages
//  Separated from PremiumStore to keep it focused and maintainable
//

import Foundation
import StoreKit

/// Handles purchase-related errors and provides user-friendly error messages
@MainActor
final class PurchaseErrorHandler {
    /// Error types specific to purchases
    enum PurchaseError: LocalizedError {
        case networkUnavailable
        case paymentDeclined
        case productUnavailable
        case purchaseCancelled
        case transactionVerificationFailed
        case entitlementRefreshFailed
        case referralTrackingFailed
        case unknown(Error)

        var errorDescription: String? {
            switch self {
            case .networkUnavailable:
                return "Unable to connect to the App Store. Please check your internet connection and try again."
            case .paymentDeclined:
                return "Your payment was declined. Please check your payment method in Settings and try again."
            case .productUnavailable:
                return "This product is currently unavailable. Please try again later."
            case .purchaseCancelled:
                return nil // User cancelled - no error message needed
            case .transactionVerificationFailed:
                return "We couldn't verify your purchase. Please contact support if this issue persists."
            case .entitlementRefreshFailed:
                return "Unable to verify your subscription status. Your purchase may still be processing. Please wait a moment and try again."
            case .referralTrackingFailed:
                return nil // Referral tracking failures shouldn't block the purchase
            case .unknown(let error):
                return "An unexpected error occurred: \(error.localizedDescription)"
            }
        }
    }

    /// Processes a purchase error and returns a user-friendly message
    /// - Parameter error: The error that occurred during purchase
    /// - Returns: A user-friendly error message, or nil if no message should be shown
    static func handlePurchaseError(_ error: Error) -> String? {
        let purchaseError = categorizeError(error)

        // Log error for debugging
        print("⚠️ [PurchaseErrorHandler] Purchase error: \(String(describing: purchaseError)) - \(error.localizedDescription)")

        // Return user-friendly message
        return purchaseError.errorDescription
    }

    /// Categorizes an error into a specific purchase error type
    private static func categorizeError(_ error: Error) -> PurchaseError {
        let nsError = error as NSError
        let errorDescription = error.localizedDescription.lowercased()

        // Check for StoreKit 2 errors
        if let storeKitError = error as? StoreKit.StoreKitError {
            return handleStoreKitError(storeKitError)
        }

        // Check error domain
        switch nsError.domain {
        case "NSURLErrorDomain":
            // Network errors
            if nsError.code == NSURLErrorNotConnectedToInternet ||
               nsError.code == NSURLErrorNetworkConnectionLost ||
               nsError.code == NSURLErrorTimedOut {
                return .networkUnavailable
            }

        case "SKErrorDomain":
            // StoreKit error codes
            switch nsError.code {
            case 0: // SKErrorUnknown
                return .unknown(error)
            case 1: // SKErrorClientInvalid
                return .productUnavailable
            case 2: // SKErrorPaymentCancelled
                return .purchaseCancelled
            case 3: // SKErrorPaymentInvalid
                return .paymentDeclined
            case 4: // SKErrorPaymentNotAllowed
                return .paymentDeclined
            case 5: // SKErrorStoreProductNotAvailable
                return .productUnavailable
            case 6: // SKErrorCloudServicePermissionDenied
                return .unknown(error)
            case 7: // SKErrorCloudServiceNetworkConnectionFailed
                return .networkUnavailable
            case 8: // SKErrorCloudServiceRevoked
                return .unknown(error)
            default:
                return .unknown(error)
            }

        default:
            // Check error message for common patterns
            if errorDescription.contains("network") ||
               errorDescription.contains("internet") ||
               errorDescription.contains("connection") {
                return .networkUnavailable
            }

            if errorDescription.contains("payment") ||
               errorDescription.contains("declined") ||
               errorDescription.contains("invalid card") {
                return .paymentDeclined
            }

            if errorDescription.contains("unavailable") ||
               errorDescription.contains("not found") {
                return .productUnavailable
            }

            if errorDescription.contains("cancelled") ||
               errorDescription.contains("canceled") {
                return .purchaseCancelled
            }
        }

        return .unknown(error)
    }

    /// Handles StoreKit 2 errors specifically
    private static func handleStoreKitError(_ error: StoreKit.StoreKitError) -> PurchaseError {
        switch error {
        case .networkError:
            return .networkUnavailable
        case .systemError:
            return .unknown(error)
        case .unknown:
            return .unknown(error)
        case .userCancelled:
            return .purchaseCancelled
        case .notAvailableInStorefront:
            return .productUnavailable
        case .notEntitled:
            return .productUnavailable
        case .unsupported:
            return .productUnavailable
        @unknown default:
            return .unknown(error)
        }
    }

    /// Handles transaction verification errors
    static func handleVerificationError(_ error: Error) -> String {
        print("⚠️ [PurchaseErrorHandler] Transaction verification failed: \(error.localizedDescription)")

        return PurchaseError.transactionVerificationFailed.errorDescription ?? "Transaction verification failed"
    }

    /// Handles referral tracking errors (non-blocking)
    static func handleReferralTrackingError(_ error: Error) {
        // Log but don't show to user - referral tracking shouldn't block purchases
        print("⚠️ [PurchaseErrorHandler] Referral tracking failed (non-blocking): \(error.localizedDescription)")
    }

    /// Handles entitlement refresh errors
    static func handleEntitlementRefreshError(_ error: Error) -> String {
        print("⚠️ [PurchaseErrorHandler] Entitlement refresh failed: \(error.localizedDescription)")

        return PurchaseError.entitlementRefreshFailed.errorDescription ?? "Unable to refresh subscription status"
    }

    /// Handles product loading errors
    static func handleProductLoadingError(_ error: Error) -> String {
        print("⚠️ [PurchaseErrorHandler] Product loading failed: \(error.localizedDescription)")

        let purchaseError = categorizeError(error)
        return purchaseError.errorDescription ?? "Failed to load products. Please try again later."
    }
}
