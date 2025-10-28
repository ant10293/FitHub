//
//  TemplateChangeLogCard.swift
//  FitHub
//
//  Created by Anthony Cantu on 8/18/25.
//

import SwiftUI

struct TemplateChangeLogCard: View {
    let template: TemplateChangelog
    @State private var isExpanded = false

    var body: some View {
        TappableDisclosure(isExpanded: $isExpanded) {
            // LABEL
            VStack(alignment: .leading, spacing: 2) {
                Text(template.dayName)
                    .font(.headline).fontWeight(.semibold)

                let metaLine = [
                    "\(template.metadata.totalSets) sets",
                    template.metadata.estimatedDuration?.displayStringCompact
                ].compactMap { $0 }.joined(separator: " • ")

                Text(metaLine)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        } content: {
            // CONTENT
            VStack(spacing: 10) {
                ForEach(template.changes) { change in
                    ExerciseChangeRow(change: change)
                        .padding(.leading, 8)
                }
                .padding(.top, 10)
            }
        }
        .cardContainer()
    }
}
