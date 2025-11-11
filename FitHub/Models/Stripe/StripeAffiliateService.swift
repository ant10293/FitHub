//
//  StripeAffiliateService.swift
//  FitHub
//
//  Created by GPT-5 Codex on 11/10/25.
//

import Foundation
import FirebaseAuth
import FirebaseCore


/// Handles calling backend Cloud Functions that orchestrate Stripe Connect payouts.
struct StripeAffiliateService {
    static let shared = StripeAffiliateService()
    
    private enum ServiceError: LocalizedError {
        case unauthenticated
        case invalidResponse
        case missingURL
        case server(String)
        
        var errorDescription: String? {
            switch self {
            case .unauthenticated:
                return "You must be signed in to manage payouts."
            case .invalidResponse:
                return "Unexpected response from the server."
            case .missingURL:
                return "Unable to create Stripe link because no URL was returned."
            case .server(let message):
                return message
            }
        }
    }
    
    private struct CloudFunctionEnvelope<T: Decodable>: Decodable {
        let result: T
    }
    
    private struct CloudFunctionErrorEnvelope: Decodable {
        struct Payload: Decodable {
            let status: String?
            let message: String
        }
        
        let error: Payload
    }
    
    struct OnboardingLink: Decodable {
        let accountId: String
        let url: String
        let expiresAt: Int?
        let createdAt: Int?
        let detailsSubmitted: Bool?
        let payoutsEnabled: Bool?
    }
    
    struct DashboardLink: Decodable {
        let accountId: String
        let url: String
        let expiresAt: Int?
        let createdAt: Int?
        let payoutsEnabled: Bool?
    }
    
    struct PayoutResult: Decodable {
        let accountId: String
        let transferId: String
        let amountCents: Int
        let currency: String
        let destination: String?
        let livemode: Bool?
    }
    
    private let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 30
        return URLSession(configuration: configuration)
    }()
    
    private var projectID: String {
        FirebaseApp.app()?.options.projectID ?? "fithubv1-d3c91"
    }
    
    private let region = "us-central1"
    
    private init() { }
    
    // MARK: - Public API
    
    func createOnboardingLink(referralCode: String, country: String? = nil) async throws -> OnboardingLink {
        var payload: [String: Any] = ["referralCode": referralCode]
        if let country, !country.isEmpty {
            payload["country"] = country
        }
        return try await callFunction(named: "createAffiliateOnboardingLink", payload: payload)
    }
    
    func createDashboardLink(referralCode: String) async throws -> DashboardLink {
        try await callFunction(named: "getAffiliateDashboardLink", payload: ["referralCode": referralCode])
    }
    
    func createPayout(referralCode: String, amountCents: Int, currency: String = "usd", description: String? = nil, note: String? = nil) async throws -> PayoutResult {
        var payload: [String: Any] = [
            "referralCode": referralCode,
            "amountCents": amountCents,
            "currency": currency
        ]
        if let description, !description.isEmpty {
            payload["description"] = description
        }
        if let note, !note.isEmpty {
            payload["note"] = note
        }
        
        return try await callFunction(named: "createAffiliatePayout", payload: payload)
    }
    
    // MARK: - Core request helper
    
    private func callFunction<T: Decodable>(named name: String, payload: [String: Any]) async throws -> T {
        guard let user = Auth.auth().currentUser else {
            throw ServiceError.unauthenticated
        }
        
        let token = try await fetchIDToken(for: user)
        let url = try endpointURL(for: name)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["data": payload], options: [])
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ServiceError.invalidResponse
        }
        
        guard (200..<300).contains(httpResponse.statusCode) else {
            if let serverError = try? JSONDecoder().decode(CloudFunctionErrorEnvelope.self, from: data) {
                throw ServiceError.server(serverError.error.message)
            }
            throw ServiceError.server("Server returned status code \(httpResponse.statusCode).")
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let envelope = try decoder.decode(CloudFunctionEnvelope<T>.self, from: data)
            return envelope.result
        } catch {
            throw ServiceError.invalidResponse
        }
    }
    
    private func endpointURL(for function: String) throws -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "\(region)-\(projectID).cloudfunctions.net"
        components.path = "/\(function)"
        guard let url = components.url else {
            throw ServiceError.missingURL
        }
        return url
    }
    
    private func fetchIDToken(for user: User) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            user.getIDToken { token, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let token else {
                    continuation.resume(throwing: ServiceError.unauthenticated)
                    return
                }
                continuation.resume(returning: token)
            }
        }
    }
}

