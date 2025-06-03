//
//  SubscriptionView.swift
//  FitHub
//
//  Created by Anthony Cantu on 1/25/25.
//

import SwiftUI

struct SubscriptionView: View {
    @State private var isSubscribed = false
    
    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            Text("Unlock Full Potential")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 10) {
                FeatureView(icon: "chart.bar", title: "Automatic Progressive Overloading", description: "Automatically increase weights based on your performance.")
                FeatureView(icon: "wand.and.stars", title: "Automated Workout Generation", description: "Personalized workouts tailored to your goals and preferences.")
                FeatureView(icon: "chart.line.uptrend.xyaxis", title: "Charts Progress Tracking", description: "Visualize your progress with detailed charts and metrics.")
                FeatureView(icon: "ruler", title: "Body Measurement Tracking", description: "Keep track of your body measurements to see your physical changes.")
                FeatureView(icon: "figure.wave", title: "Recovery Body Visualization", description: "Monitor and visualize recovery, keep track of your fatigued and fresh muscle isgroups.")
                
                Text("And much more...")
                    .fontWeight(.semibold)
            }
            .padding()
            
            Button(action: {
                isSubscribed.toggle()
            }) {
                Text(isSubscribed ? "Subscribed" : "Subscribe Now")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(isSubscribed ? Color.green : Color.blue)
                    .cornerRadius(10)
            }
            .padding()
            
            Spacer()
        }
        .padding()
        .navigationBarTitle("FitHub Pro", displayMode: .inline)
        .background(Color(.systemGray6))
    }
    struct FeatureView: View {
        var icon: String
        var title: String
        var description: String
        
        var body: some View {
            HStack(alignment: .top) {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 20, height: 20)
                    .padding(.top, 5)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .fontWeight(.semibold)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 5)
        }
    }
}


