//
//  RPEPrompt.swift
//  FitHub
//
//  Created by Anthony Cantu on 10/12/25.
//

import SwiftUI

struct RPEPrompt: View {
    let onSelect: (Bool) -> Void

    var body: some View {
        ZStack {
            // Invisible tap layer to block background interaction
            Color.black.opacity(0.001)      // use 0.001 so it receives taps (Color.clear won’t)
                .ignoresSafeArea()
                .contentShape(Rectangle())

            VStack {
                Spacer()

                VStack(spacing: 12) {
                    Text("Do you want to log RPE?")
                        .font(.title2)
                        .multilineTextAlignment(.center)

                    Group {
                        Text("RPE (Rate of Perceived Exertion) is a 1–10 scale you can record after each set to track effort and fatigue.")
                            .foregroundStyle(.secondary)
                        Text("You can change this later in \n Settings → Set Detail.")
                    }
                    .font(.subheadline)
                    .multilineTextAlignment(.center)

                    HStack {
                        RectangularButton(title: "Not Now", bgColor: .gray) {
                            onSelect(true)
                        }
                        RectangularButton(title: "Yes, Log RPE", bgColor: .blue) {
                            onSelect(false)
                        }
                    }
                    .padding(.top, 10)
                }
                .cardContainer(cornerRadius: 10, shadowRadius: 10)
                .frame(width: screenWidth * 0.8)

                Spacer()
            }
        }
    }
}
