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

// free < monthly < annual < lifetime
// keep track of purchase date and show how many days until auto renewal
@MainActor
final class PremiumStore: ObservableObject {
    // MARK: - Public API
    @Published private(set) var products: [Product] = []          // monthly, yearly, lifetime
    @Published private(set) var entitlement: PremiumEntitlement = .init(isPremium: false, source: nil)
    @Published private(set) var isLoading = false
    @Published private(set) var purchaseInFlight = false
    @Published private(set) var membershipType: MembershipType = .free
    @Published var errorMessage: String?

    // Map product IDs — keep these in sync with App Store Connect
    enum ID {
        static let monthly  = "com.FitHub.premium.monthly"
        static let yearly   = "com.FitHub.premium.yearly"
        static let lifetime = "com.FitHub.premium.lifetime"
    }
    
    enum MembershipType: String, CaseIterable, Comparable {
        case free, monthly, yearly, lifetime
        
        private var rank: Int {
            switch self {
            case .free:     return 0
            case .monthly:  return 1
            case .yearly:   return 2   // aka “annual”
            case .lifetime: return 3
            }
        }

        static func < (lhs: MembershipType, rhs: MembershipType) -> Bool {
            lhs.rank < rhs.rank
        }
    }
    // Optional: tie to your signed-in user to link server events
    private let appAccountToken: UUID?

    init(appAccountToken: UUID? = nil) {
        self.appAccountToken = appAccountToken
        listenForTransactionChanges()
    }

    var currentMembershipType: MembershipType { membershipType }

    // Load product data + refresh entitlement
    func configure() async {
        isLoading = true
        defer { isLoading = false }
        await loadProducts()
        await refreshEntitlement()
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
                let transaction = try verify(verification)
                await transaction.finish()
                await refreshEntitlement()

            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restore() async {
        // With StoreKit 2, entitlement refresh is enough
        await refreshEntitlement()
    }

    // MARK: - Private
    private func loadProducts() async {
        do {
            let ids = [ID.monthly, ID.yearly, ID.lifetime]
            let fetched = try await Product.products(for: ids)
            print("Fetched products:", fetched.map(\.id))
            products = ids.compactMap { id in fetched.first(where: { $0.id == id }) }
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
            print("Product load error:", error)
        }
    }
    
    @MainActor
    private func refreshEntitlement() async {
        var best = PremiumEntitlement(isPremium: false, source: nil)
        var kind: MembershipType = .free

        for await result in SKTransaction.currentEntitlements {
            guard case .verified(let t) = result else { continue }
            guard t.revocationDate == nil else { continue }

            switch t.productID {
            case ID.lifetime:
                best  = .init(isPremium: true, source: .lifetime(transactionID: t.id))
                kind  = .lifetime
                entitlement     = best
                membershipType  = kind   // lifetime trumps everything
                return

            case ID.monthly, ID.yearly:
                let isActive = t.expirationDate.map { $0 > Date() } ?? true
                if isActive {
                    let auto = await willAutoRenew(for: t)
                    best = .init(
                        isPremium: true,
                        source: .subscription(
                            expiration: t.expirationDate ?? .distantFuture,
                            willAutoRenew: auto,
                            transactionID: t.id
                        )
                    )
                    kind = (t.productID == ID.yearly) ? .yearly : .monthly
                    // keep scanning in case we encounter lifetime later
                }

            default:
                break
            }
        }

        entitlement    = best
        membershipType = kind
    }
    
    @MainActor
    private func willAutoRenew(for transaction: SKTransaction) async -> Bool? {
        guard let product = products.first(where: { $0.id == transaction.productID }),
              let sub = product.subscription else { return nil }

        do {
            let statuses = try await sub.status  // [Product.SubscriptionInfo.Status]
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
            return nil
        }
    }

    private func listenForTransactionChanges() {
        Task.detached { [weak self] in
            guard let self else { return }
            for await update in SKTransaction.updates {
                if case .verified(let t) = update {
                    await t.finish()
                    await self.refreshEntitlement()
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
