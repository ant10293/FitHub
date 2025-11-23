//
//  EmptyState.swift
//  FitHub
//
//  Created by Anthony Cantu on 11/22/25.
//

import SwiftUI

struct EmptyState: View {
    let systemName: String
    let title: String
    let subtitle: String?
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemName)
                .symbolRenderingMode(.hierarchical)
                .font(.system(.largeTitle, weight: .regular))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.title3.weight(.semibold))
            
            if let subtitle {
                Text(subtitle)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

