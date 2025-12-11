//
//  FreePlanLimitView.swift
//  FitHub
//
//  Created on 12/10/25.
//

import SwiftUI

struct FreePlanLimitView: View {
    @EnvironmentObject private var ctx: AppContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingSubscription: Bool = false
    let feature: BlockedFeature
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.orange)
                        
                        Text(feature.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text(feature.body)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top)
                    
                    // Upgrade message
                    VStack(spacing: 8) {
                        Text("Upgrade your membership to access all features")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                    .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                    
                    // Features section
                    featuresSection
                    
                    // Upgrade button
                    RectangularButton(
                        title: "Upgrade to Premium",
                        systemImage: "star.fill",
                        enabled: true,
                        bgColor: .blue,
                        fgColor: .white,
                        width: .fill,
                        fontWeight: .semibold,
                        iconPosition: .leading,
                        action: {
                            showingSubscription = true
                        }
                    )
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitle("Upgrade Required", displayMode: .inline)
            .onChange(of: ctx.store.membershipType) { _, newValue in
                if newValue != .free {
                    dismiss()
                }
            }
            .sheet(isPresented: $showingSubscription) {
                SubscriptionView()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - FeatureRow
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            FeatureRow(icon: "chart.bar", title: "Automatic Overloading & Deloading", description: "Automatically adjust weights based on performance.")
            
            FeatureRow(icon: "wand.and.stars", title: "Automated Workout Generation", description: "Personalized plans tailored to your goals.")
            
            FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Progress Charts", description: "Visualize strength and volume trends.")
            
            FeatureRow(icon: "ruler", title: "Body Measurements", description: "Track your physique changes.")
            
            // FeatureRow(icon: "figure.wave", title: "Recovery Visualization", description: "Manage fatigue across muscle groups.")
            
            Text("And much more…")
                .fontWeight(.semibold)
                .padding(.top, 4)
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private struct FeatureRow: View {
        let icon: String
        let title: String
        let description: String
        
        var body: some View {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(.blue)
                    .imageScale(.medium)
                    .padding(.top, 5)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .fontWeight(.semibold)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 5)
        }
    }
}


enum BlockedFeature: String, Identifiable {
    case generationLimit, templateLimit, overloadAccess
    
    var id: String { self.rawValue }
    
    var title: String {
        switch self {
        case .generationLimit:
            return "Workout Generation Limit Reached"
        case .templateLimit:
            return "Workout Template Limit Reached"
        case .overloadAccess:
            return "Overload Calculator Requires Premium"
        }
    }
    
    var body: String {
        switch self {
        case .generationLimit:
            return "You've reached the limit of generated workouts for the free plan."
        case .templateLimit:
            return "You've reached the limit of created workout templates for the free plan."
        case .overloadAccess:
            return "Overload Calculator cannot be accessed with the free plan."
        }
    }
}
