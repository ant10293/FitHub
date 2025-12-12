//
//  PremiumStore.swift
//  FitHub
//
//  Created by Anthony Cantu on 8/11/25.
//

import Foundation
import StoreKit
import Combine
import SwiftUI

// Disambiguate StoreKit symbols in case another `Transaction` exists in the project
private typealias SKTransaction = StoreKit.Transaction
private typealias SKVerificationResult<T> = StoreKit.VerificationResult<T>

// Keep IDs as UInt64 to match Transaction.id
enum PremiumSource: Equatable {
    case lifetime(transactionID: UInt64)
    case subscription(expiration: Date, willAutoRenew: Bool?, transactionID: UInt64)
}

struct PremiumEntitlement: Equatable {
    var isPremium: Bool
    var source: PremiumSource?
}

struct OverlappingSubscriptionInfo: Equatable {
    let type: PremiumStore.MembershipType
    let expiration: Date?
    let willAutoRenew: Bool?
}

@MainActor
final class PremiumStore: ObservableObject {
    // MARK: - Published state
    @Published private(set) var products: [Product] = []          // monthly, yearly, lifetime
    @Published private(set) var entitlement: PremiumEntitlement = .init(isPremium: false, source: nil)
    @Published private(set) var isLoading = false
    @Published private(set) var purchaseInFlight = false
    @Published private(set) var membershipType: MembershipType = .free
    @Published var errorMessage: String?
    @Published private(set) var overlappingSubscriptionInfo: OverlappingSubscriptionInfo?

    // Optional account token to associate purchases with an app account
    private let appAccountToken: UUID?

    // MARK: - Error Recovery
    private var lastKnownEntitlement: PremiumEntitlement?
    private var lastKnownMembershipType: MembershipType = .free
    private var retryCount: Int = 0
    private let maxRetries: Int = 3
    private var retryTask: Task<Void, Never>?
    private let userDefaults = UserDefaults.standard
    private let entitlementCacheKey = "FitHub.lastKnownEntitlement"
    private let membershipCacheKey = "FitHub.lastKnownMembershipType"
    private let lastValidationKey = "FitHub.lastEntitlementValidation"
    private let lastExpirationKey = "FitHub.lastKnownExpiration"
    private var foregroundObserver: NSObjectProtocol?

    init(appAccountToken: UUID? = nil) {
        self.appAccountToken = appAccountToken
        loadCachedEntitlement()
        listenForTransactionChanges()
        setupAppLifecycleObservers()
    }

    deinit {
        if let observer = foregroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Product IDs and enum-owned helpers
    enum ID {
        static let monthly  = "com.FitHub.premium.monthly"
        static let yearly   = "com.FitHub.premium.yearly"
        static let lifetime = "com.FitHub.premium.lifetime"

        /// Preferred paywall order
        static var displayOrder: [String] { [monthly, yearly, lifetime] }

        /// Map StoreKit productID -> MembershipType
        static func membershipType(for productID: String?) -> PremiumStore.MembershipType {
            guard let pid = productID else { return .free }
            switch pid {
            case monthly:  return .monthly
            case yearly:   return .yearly
            case lifetime: return .lifetime
            default:       return .free
            }
        }

        /// UI title for each product id
        static func displayTitle(for productID: String) -> String {
            switch productID {
            case monthly:  return "Monthly"
            case yearly:   return "Annual"
            case lifetime: return "Lifetime"
            default:       return "Plan"
            }
        }

        /// Optional badge for each product id
        static func badge(for productID: String) -> String? {
            switch productID {
            case yearly:   return "Best Value"
            case lifetime: return "One-Time"
            default:       return nil
            }
        }

        /// Subscription (vs one-time)
        static func isSubscription(_ productID: String) -> Bool {
            productID == monthly || productID == yearly
        }
    }

    enum MembershipType: String, CaseIterable, Comparable {
        case free, monthly, yearly, lifetime

        private var rank: Int {
            switch self {
            case .free:     return 0
            case .monthly:  return 1
            case .yearly:   return 2
            case .lifetime: return 3
            }
        }
        static func < (lhs: MembershipType, rhs: MembershipType) -> Bool { lhs.rank < rhs.rank }

        // MARK: Identity (kept out of the view)
        var isSubscription: Bool { self == .monthly || self == .yearly }

        var productID: String? {
            switch self {
            case .free:     return nil
            case .monthly:  return PremiumStore.ID.monthly
            case .yearly:   return PremiumStore.ID.yearly
            case .lifetime: return PremiumStore.ID.lifetime
            }
        }

        var displayName: String {
            switch self {
            case .free:     return "Free"
            case .monthly:  return "Monthly"
            case .yearly:   return "Annual"
            case .lifetime: return "Lifetime"
            }
        }

        var badge: String? {
            switch self {
            case .yearly:   return "Best Value"
            case .lifetime: return "One-Time"
            default:        return nil
            }
        }

        static func from(productID: String?) -> Self {
            PremiumStore.ID.membershipType(for: productID)
        }

        // MARK: Price + footnote formatting (single mapping; no redundancy)
        /// Single source of truth for both the price suffix and cycle text.
        private static func priceTokens(for unit: StoreKit.Product.SubscriptionPeriod.Unit) -> (suffix: String, cycle: String) {
            switch unit {
            case .week:  return ("/wk", "wk")
            case .month: return ("/mo", "mo")
            case .year:  return ("/yr", "yr")
            default:     return ("", "period")
            }
        }

        /// Card price text (e.g. "$4.99 /mo" or "$79.99" or "Free")
        func trailingPriceText(for product: StoreKit.Product) -> String {
            switch self {
            case .lifetime:
                return product.displayPrice
            case .monthly, .yearly:
                if let sub = product.subscription {
                    let tok = Self.priceTokens(for: sub.subscriptionPeriod.unit)
                    return product.displayPrice + " " + tok.suffix
                }
                return product.displayPrice
            case .free:
                return "Free"
            }
        }

        /// Default auto-renew footnote (nil for lifetime/free)
        func defaultAutoRenewFootnote(for product: StoreKit.Product) -> String? {
            guard isSubscription, let sub = product.subscription else { return nil }
            let cycle = Self.priceTokens(for: sub.subscriptionPeriod.unit).cycle
            return "Plan auto-renews for \(product.displayPrice)/\(cycle) until canceled."
        }
    }

    // MARK: - Public API
    func configure() async {
        isLoading = true
        defer { isLoading = false }
        await loadProducts()
        await refreshEntitlementWithRetry()
    }

    func buy(product: Product) async {
        purchaseInFlight = true
        defer { purchaseInFlight = false }
        do {
            let result: Product.PurchaseResult
            if let token = appAccountToken {
                result = try await product.purchase(options: [.appAccountToken(token)])
            } else {
                result = try await product.purchase()
            }

            switch result {
            case .success(let verification):
                do {
                    let transaction = try verify(verification)

                    // MARK: Affiliate System guard
                    if useAffiliateSystem {
                        // Track referral purchase if user has a referral code (non-blocking)
                        // Note: trackPurchase handles errors internally and doesn't throw
                        Task {
                            await ReferralPurchaseTracker().trackPurchase(
                                productID: product.id,
                                transactionID: transaction.id,
                                originalTransactionID: transaction.originalID,
                                environment: transaction.environment.rawValue
                            )
                        }
                    }

                    await transaction.finish()
                    await refreshEntitlementWithRetry()
                } catch {
                    // Transaction verification failed
                    errorMessage = PurchaseErrorHandler.handleVerificationError(error)
                    // Still try to refresh entitlement in case it works
                    await refreshEntitlementWithRetry()
                }
            case .userCancelled:
                // User cancelled - no error message needed
                break
            case .pending:
                // Purchase is pending (e.g., waiting for approval)
                errorMessage = "Your purchase is pending approval. You'll be notified when it's complete."
            @unknown default:
                errorMessage = "Purchase completed with unknown status. Please check your subscription status."
            }
        } catch {
            // Handle purchase errors with user-friendly messages
            if let message = PurchaseErrorHandler.handlePurchaseError(error) {
                errorMessage = message
            }
            // Retry entitlement refresh on purchase error
            await refreshEntitlementWithRetry()
        }
    }

    func restore() async {
        // With StoreKit 2, entitlement refresh generally suffices
        await refreshEntitlementWithRetry()
    }

    func autoRenewFootnote(for product: Product) -> String? {
        let membership = MembershipType.from(productID: product.id)
        guard membership.isSubscription else { return nil }

        let defaultFootnote = membership.defaultAutoRenewFootnote(for: product)

        guard membership == membershipType else { return defaultFootnote }
        guard case let .subscription(expiration, willAutoRenew, _) = entitlement.source else {
            return defaultFootnote
        }

        if let willAutoRenew = willAutoRenew, !willAutoRenew {
            let formatted = Format.formatDate(expiration, dateStyle: .medium, timeStyle: .short)
            return "Auto-renew is turned off. Access ends on \(formatted)."
        }

        return defaultFootnote
    }

    // MARK: - Private
    private func loadProducts() async {
        do {
            let ids = [ID.monthly, ID.yearly, ID.lifetime]
            let fetched = try await Product.products(for: ids)
            // Centralized ordering
            products = ID.displayOrder.compactMap { id in fetched.first(where: { $0.id == id }) }
        } catch {
            errorMessage = PurchaseErrorHandler.handleProductLoadingError(error)
        }
    }

    // MARK: - Error Recovery Methods

    /// Refreshes entitlement with retry logic and fallback to cached state
    private func refreshEntitlementWithRetry() async {
        retryCount = 0
        await refreshEntitlementWithRetryInternal()
    }

    private func refreshEntitlementWithRetryInternal() async {
        do {
            try await refreshEntitlement()
            // Success - reset retry count and cache the result
            retryCount = 0
            cacheEntitlement()
        } catch {
            print("⚠️ [PremiumStore] Entitlement refresh failed (attempt \(retryCount + 1)/\(maxRetries)): \(error.localizedDescription)")

            if retryCount < maxRetries {
                // Retry with exponential backoff
                retryCount += 1
                let delay = min(Double(retryCount) * 2.0, 10.0) // Max 10 seconds

                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                await refreshEntitlementWithRetryInternal()
            } else {
                // Max retries reached - fallback to cached state
                print("⚠️ [PremiumStore] Max retries reached, falling back to cached entitlement")
                fallbackToCachedEntitlement()
                errorMessage = "Unable to verify subscription. Using last known status. Please check your connection and try again."
            }
        }
    }

    /// Refreshes entitlement - can throw errors
    @MainActor
    private func refreshEntitlement() async throws {
        overlappingSubscriptionInfo = nil

        var lifetimeTransactionID: UInt64?
        var bestEntitlement = PremiumEntitlement(isPremium: false, source: nil)
        var bestMembership: MembershipType = .free
        var overlapCandidate: OverlappingSubscriptionInfo?

        // Process entitlements with timeout protection
        // currentEntitlements should complete after enumerating all current entitlements
        // We add a timeout as a safety net in case StoreKit hangs
        typealias EntitlementResult = (lifetimeID: UInt64?, bestEntitlement: PremiumEntitlement, bestMembership: MembershipType, overlap: OverlappingSubscriptionInfo?)

        let entitlementTask = Task<EntitlementResult, Error> {
            var localLifetimeID: UInt64?
            var localBestEntitlement = PremiumEntitlement(isPremium: false, source: nil)
            var localBestMembership: MembershipType = .free
            var localOverlap: OverlappingSubscriptionInfo?

        for await result in SKTransaction.currentEntitlements {
                try Task.checkCancellation()

            guard case .verified(let t) = result else { continue }
            guard t.revocationDate == nil else { continue }

            switch t.productID {
            case ID.lifetime:
                    localLifetimeID = t.id

            case ID.monthly, ID.yearly:
                let membership: MembershipType = (t.productID == ID.yearly) ? .yearly : .monthly
                let isActive = t.expirationDate.map { $0 > Date() } ?? true
                guard isActive else { continue }

                    let auto = await self.willAutoRenew(for: t)
                let expiration = t.expirationDate ?? .distantFuture
                let source = PremiumSource.subscription(
                    expiration: expiration,
                    willAutoRenew: auto,
                    transactionID: t.id
                )

                    if membership > localBestMembership {
                        localBestEntitlement = .init(isPremium: true, source: source)
                        localBestMembership = membership
                }

                let willRenew = auto ?? true
                if willRenew {
                    let candidate = OverlappingSubscriptionInfo(
                        type: membership,
                        expiration: t.expirationDate,
                        willAutoRenew: auto
                    )
                        if let current = localOverlap {
                        let currentExpiration = current.expiration ?? .distantPast
                        let candidateExpiration = candidate.expiration ?? .distantFuture
                        if candidateExpiration > currentExpiration {
                                localOverlap = candidate
                        }
                    } else {
                            localOverlap = candidate
                    }
                }

            default:
                break
            }
        }

            return (localLifetimeID, localBestEntitlement, localBestMembership, localOverlap)
        }

        // Timeout safety net (30 seconds)
        let timeoutTask = Task {
            try await Task.sleep(nanoseconds: 30_000_000_000)
            entitlementTask.cancel()
        }

        // Wait for entitlement processing or timeout
        let result: EntitlementResult
        do {
            result = try await entitlementTask.value
            timeoutTask.cancel()
        } catch {
            timeoutTask.cancel()
            if error is CancellationError {
                // Timeout occurred - fallback to cached state
                print("⚠️ [PremiumStore] Entitlement refresh timed out")
                throw error
            } else {
                throw error
            }
        }

        lifetimeTransactionID = result.lifetimeID
        bestEntitlement = result.bestEntitlement
        bestMembership = result.bestMembership
        overlapCandidate = result.overlap

        if let lifetimeID = lifetimeTransactionID {
            entitlement = .init(isPremium: true, source: .lifetime(transactionID: lifetimeID))
            membershipType = .lifetime
            overlappingSubscriptionInfo = overlapCandidate
            return
        }

        overlappingSubscriptionInfo = nil
        entitlement = bestEntitlement
        membershipType = bestMembership
    }

    /// Falls back to cached entitlement when validation fails
    private func fallbackToCachedEntitlement() {
        // Helper to check if subscription expired
        func isExpired() -> Bool {
            if let source = lastKnownEntitlement?.source,
               case .subscription(let expiration, _, _) = source {
                return expiration < Date()
            }
            if let expiration = userDefaults.object(forKey: lastExpirationKey) as? Date {
                return expiration < Date()
            }
            return false
        }

        if let cached = lastKnownEntitlement, cached.isPremium, !isExpired() {
            entitlement = cached
            membershipType = lastKnownMembershipType
            print("✅ [PremiumStore] Restored cached entitlement: \(membershipType)")
        } else if let lastValidation = userDefaults.object(forKey: lastValidationKey) as? Date,
                  Date().timeIntervalSince(lastValidation) < 1800, // 30 min grace period
                  lastKnownMembershipType != .free,
                  !isExpired() {
            print("⚠️ [PremiumStore] Using grace period - keeping premium status")
            entitlement = .init(isPremium: true, source: nil)
            membershipType = lastKnownMembershipType
        } else {
            entitlement = .init(isPremium: false, source: nil)
            membershipType = .free
        }
    }

    /// Caches current entitlement state
    private func cacheEntitlement() {
        lastKnownEntitlement = entitlement
        lastKnownMembershipType = membershipType
        userDefaults.set(Date(), forKey: lastValidationKey)

        // Cache membership type as string
        userDefaults.set(membershipType.rawValue, forKey: membershipCacheKey)

        // Cache expiration date if available (for grace period validation)
        if let source = entitlement.source,
           case .subscription(let expiration, _, _) = source {
            userDefaults.set(expiration, forKey: lastExpirationKey)
        } else if entitlement.isPremium && membershipType == .lifetime {
            // Lifetime subscriptions don't expire - set a far future date
            userDefaults.set(Date.distantFuture, forKey: lastExpirationKey)
        } else {
            // No expiration or free tier - remove stored expiration
            userDefaults.removeObject(forKey: lastExpirationKey)
        }
    }

    /// Loads cached entitlement on startup
    private func loadCachedEntitlement() {
        if let cachedTypeString = userDefaults.string(forKey: membershipCacheKey),
           let cachedType = MembershipType(rawValue: cachedTypeString) {
            lastKnownMembershipType = cachedType
            // Set initial state from cache (will be refreshed on configure)
            if cachedType != .free {
                membershipType = cachedType
                entitlement = .init(isPremium: true, source: nil) // Source will be refreshed
                print("✅ [PremiumStore] Loaded cached membership type: \(cachedType)")
            }
        }
    }

    /// Sets up observers for app lifecycle events to retry validation
    private func setupAppLifecycleObservers() {
        foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                // Retry validation when app comes to foreground
                await self?.refreshEntitlementWithRetry()
            }
        }
    }

    @MainActor
    private func willAutoRenew(for transaction: SKTransaction) async -> Bool? {
        guard let product = products.first(where: { $0.id == transaction.productID }),
              let sub = product.subscription else { return nil }

        do {
            // Add timeout to prevent hanging
            let statuses = try await withTimeout(seconds: 10) {
                try await sub.status
            }

            let matched = statuses.first(where: { status in
                if case .verified(let tx) = status.transaction { return tx.id == transaction.id }
                return false
            }) ?? statuses.first

            guard let status = matched else { return nil }
            if case .verified(let info) = status.renewalInfo {
                return info.willAutoRenew
            }
            return nil
        } catch {
            print("⚠️ [PremiumStore] Failed to get auto-renew status: \(error.localizedDescription)")
            // Return nil on error - will default to assuming auto-renew is on
            return nil
        }
    }

    /// Helper to add timeout to async operations
    private func withTimeout<T>(seconds: Double, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw NSError(domain: "PremiumStore", code: -1, userInfo: [NSLocalizedDescriptionKey: "Operation timed out"])
            }

            guard let result = try await group.next() else {
                group.cancelAll()
                throw NSError(domain: "PremiumStore", code: -1, userInfo: [NSLocalizedDescriptionKey: "Task group returned no result"])
            }
            group.cancelAll()
            return result
        }
    }

    private func listenForTransactionChanges() {
        Task.detached { [weak self] in
            guard let self else { return }
            for await update in SKTransaction.updates {
                if case .verified(let t) = update {
                    await t.finish()
                    await self.refreshEntitlementWithRetry()
                }
            }
        }
    }

    private func verify<T>(_ result: SKVerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe): return safe
        case .unverified(_, let error): throw error
        }
    }
}
