//
//  ImplementRow.swift
//  FitHub
//
//  Created by Anthony Cantu on 8/27/25.
//

import SwiftUI

/*
 TODO: we need to accomodate bilateral independent exercises that use divided equipment.
 needs to look like old setup, except the base weight chip needs to be on each side
 ex:
 Left
 [Weight]
 Plates
 Base weight chip
 total weight (lighter color)
*/
// MARK: - Implement Row Component
struct ImplementRow: View {
    let title: String
    let base: Mass
    let plan: Plan
    let pegCount: PegCountOption?
    let showMultiplier: Bool
    let showBaseWeightEditor: () -> Void

    private var implementTotal: Mass {
        if showMultiplier {
            // Single implement with multiplier: base × multiplier + plates
            return Mass(kg: (base.inKg * Double(plan.baseCount)) + (plan.perSideAchieved.inKg * Double(plan.replicates)))
        } else {
            // Multiple implements: just base + plates (no multiplier)
            return Mass(kg: base.inKg + (plan.perSideAchieved.inKg * Double(plan.replicates)))
        }
    }

    // Determine if we should use vertical layout (too many plates to fit horizontally)
    private var shouldUseVerticalLayout: Bool {
        guard let pegCount = pegCount, pegCount == .both else { return false }
        let totalPlates = plan.leftSide.count + plan.rightSide.count
        // Use vertical layout if more than 8 plates total (4 per side)
        return totalPlates > 8
    }

    var body: some View {
        VStack(spacing: 8) {
            // Title with total weight for multiple implementations
            if !title.isEmpty {
                HStack {
                    Text(title)
                        .font(.headline.bold())

                    Spacer()

                    // Show total weight for this implement
                    implementTotal.formattedText()
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            // Conditional layout based on plate count
            if shouldUseVerticalLayout {
                // Vertical layout: Left, Base, Right stacked
                VStack(spacing: 12) {
                    // Left section
                    VStack(spacing: 4) {
                        labelPair(label: "Left", mass: plan.perSideAchieved)
                        PlateStackColumn(plates: plan.leftSide, isVertical: false)
                            .accessibilityLabel("Left plates")
                    }

                    // Base weight chip
                    baseLabelPair()

                    // Right section
                    VStack(spacing: 4) {
                        labelPair(label: "Right", mass: plan.perSideAchieved)
                        PlateStackColumn(plates: plan.rightSide, isVertical: false)
                            .accessibilityLabel("Right plates")
                    }
                }
                .font(title.isEmpty ? .headline : .subheadline)
            } else {
                // Horizontal layout: Left - Base - Right
                VStack(spacing: 8) {
                    // Weight labels and base chip
                    HStack(spacing: 8) {
                        if let pegCount = pegCount, pegCount == .both {
                            // Two pegs: show Left and Right labels
                            labelPair(label: "Left", mass: plan.perSideAchieved)
                            Spacer(minLength: 8)
                            baseLabelPair()
                            Spacer(minLength: 8)
                            labelPair(label: "Right", mass: plan.perSideAchieved)
                        } else {
                            // Single peg or no pegs: center the base weight
                            Spacer()
                            baseLabelPair()
                            Spacer()
                        }
                    }

                    // Plate visualization
                    PlateVisualization(plan: plan, pegCount: pegCount)
                }
            }
        }
        .padding(.vertical)
    }

    private func labelPair(label: String, mass: Mass) -> some View {
        VStack {
            Text(label)
                .font(title.isEmpty ? .headline : .subheadline)
            mass.formattedText()
        }
    }

    private func baseLabelPair() -> some View {
        VStack(spacing: 2) {
            Text("Base")
                .font(title.isEmpty ? .headline : .subheadline)

            if showMultiplier {
                Text("\(base.formattedText()) × \(plan.baseCount)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if showMultiplier {
                let adjustedBase = Mass(kg: base.inKg * Double(plan.baseCount))
                baseChip(adjustedBase, showPerSide: false)
            } else {
                baseChip(base, showPerSide: false)
            }
        }
    }

    private func baseChip(_ base: Mass, showPerSide: Bool = false) -> some View {
        Button {
            showBaseWeightEditor()
        } label: {
            HStack(spacing: 6) {
                (base.formattedText() + Text(showPerSide ? " per side" : ""))
                    .font(.subheadline)
                Image(systemName: "pencil")
                    .imageScale(.small)
                    .foregroundStyle(.blue)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Edit base weight")
    }
}

// MARK: - Plate Visualization Component
private struct PlateVisualization: View {
    let plan: Plan
    let pegCount: PegCountOption?

    var body: some View {
        if let pegCount = pegCount, pegCount != .none {
            if pegCount == .both {
                // Two pegs: horizontal layout
            HStack(spacing: 24) {
                    PlateStackColumn(plates: plan.leftSide, isVertical: false)
                        .accessibilityLabel("Left plates")

                    Spacer()

                    PlateStackColumn(plates: plan.rightSide, isVertical: false)
                        .accessibilityLabel("Right plates")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            } else {
                // Single peg: vertical stack
                VStack(spacing: 4) {
                    PlateStackColumn(plates: plan.leftSide, isVertical: true)
                        .accessibilityLabel("Plates")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            }
        } else {
            Text("No plates needed")
                .foregroundStyle(.secondary)
                .padding(.vertical, 4)
        }
    }
}

// MARK: - Plate Stack Column
struct PlateStackColumn: View {
    enum Orientation { case vertical, horizontal } // vertical = single peg; horizontal = two pegs

    let plates: [Mass]
    let orientation: Orientation

    init(plates: [Mass], isVertical: Bool = false) {
        self.plates = plates
        self.orientation = isVertical ? .vertical : .horizontal
    }

    var body: some View {
        stack {
            ForEach(plates.indices, id: \.self) { i in
                let w = plates[i]
                RoundedRectangle(cornerRadius: 6)
                    .fill(WeightPlates.color(for: w, in: plates))
                    .frame(width: size(for: w).width, height: size(for: w).height)
                    .overlay(
                        Text(w.displayString)
                            .font(.caption)
                            .foregroundStyle(.white)
                            .shadow(radius: 1, y: 0.5)
                    )
            }
        }
        .frame(minWidth: orientation == .vertical ? 26 : 100)
        .animation(.spring(response: 0.25, dampingFraction: 0.9), value: plates)
    }

    // MARK: - Layout helpers (no duplication)

    @ViewBuilder
    private func stack<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        switch orientation {
        case .vertical:   VStack(spacing: 2, content: content)
        case .horizontal: HStack(spacing: 6, content: content)
        }
    }

    private func size(for w: Mass) -> CGSize {
        let base = CGFloat(log(w.inKg + 1.5) * 15)  // same growth curve as before
        switch orientation {
        case .vertical:   return CGSize(width: max(26, base), height: 26)   // variable width, fixed height
        case .horizontal: return CGSize(width: 26, height: max(12, base))   // fixed width, variable height
        }
    }
}
