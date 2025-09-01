//
//  ImplementRow.swift
//  FitHub
//
//  Created by Anthony Cantu on 8/27/25.
//

import SwiftUI

// MARK: - Implement Row Component
struct ImplementRow: View {
    let title: String
    let base: Mass
    let plan: Plan
    let pegCount: PegCountOption?
    let showMultiplier: Bool
    var showBaseWeightEditor: () -> Void
    
    private var implementTotal: Mass {
        if showMultiplier {
            // Single implement with multiplier: base × multiplier + plates
            return Mass(kg: (base.inKg * Double(plan.baseCount)) + (plan.perSideAchieved.inKg * Double(plan.replicates)))
        } else {
            // Multiple implements: just base + plates (no multiplier)
            return Mass(kg: base.inKg + (plan.perSideAchieved.inKg * Double(plan.replicates)))
        }
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
            
            // Weight labels and base chip
            HStack(spacing: 8) {
                if let pegCount = pegCount, pegCount == .both {
                    // Two pegs: show Left and Right labels
                labelPair(title: "Left", mass: plan.perSideAchieved)
                Spacer(minLength: 8)
                
                VStack(spacing: 2) {
                    if showMultiplier {
                        // Show per-side weight × multiplier above (per-side is the raw base weight)
                        Text("\(base.formattedText()) × \(plan.baseCount)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Show modified base value in center
                    if showMultiplier {
                        let adjustedBase = Mass(kg: base.inKg * Double(plan.baseCount))
                        baseChip(adjustedBase, showPerSide: false)
                    } else {
                        baseChip(base, showPerSide: false)
                    }
                }
                
                Spacer(minLength: 8)
                labelPair(title: "Right", mass: plan.perSideAchieved)
                } else {
                    // Single peg or no pegs: center the base weight
                    Spacer()
                    
                    VStack(spacing: 2) {
                        if showMultiplier {
                            // Show per-side weight × multiplier above (per-side is the raw base weight)
                            Text("\(base.formattedText()) × \(plan.baseCount)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        // Show modified base value in center
                        if showMultiplier {
                            let adjustedBase = Mass(kg: base.inKg * Double(plan.baseCount))
                            baseChip(adjustedBase, showPerSide: false)
                        } else {
                            baseChip(base, showPerSide: false)
                        }
                    }
                    
                    Spacer()
                }
            }
            .font(title.isEmpty ? .headline : .subheadline)

            // Plate visualization
            PlateVisualization(plan: plan, pegCount: pegCount)
        }
    }
    
    private func labelPair(title: String, mass: Mass) -> some View {
        HStack(spacing: 6) {
            Text(title)
            mass.formattedText()
        }
    }

    private func baseChip(_ base: Mass, showPerSide: Bool = false) -> some View {
        Button {
            showBaseWeightEditor()
        } label: {
            HStack(spacing: 6) {
                (Text("Base ") + base.formattedText() + Text(showPerSide ? " per side" : ""))
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
private struct PlateStackColumn: View {
    let plates: [Mass]
    let isVertical: Bool
    
    init(plates: [Mass], isVertical: Bool = false) {
        self.plates = plates
        self.isVertical = isVertical
    }

    var body: some View {
        if isVertical {
            // Vertical stack for single peg - plates oriented horizontally
            VStack(spacing: 2) {
                ForEach(plates.indices, id: \.self) { i in
                    let w = plates[i]
                    RoundedRectangle(cornerRadius: 6)
                        .fill(WeightPlates.color(for: w))
                        .frame(width: width(for: w), height: 26)
                        .overlay(
                            Text(w.displayString)
                                .font(.system(size: 9, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                                .shadow(radius: 1, y: 0.5)
                        )
                }
            }
            .frame(minWidth: 26)
            .animation(.spring(response: 0.25, dampingFraction: 0.9), value: plates)
        } else {
            // Horizontal stack for two pegs
        HStack(spacing: 6) {
            ForEach(plates.indices, id: \.self) { i in
                let w = plates[i]
                RoundedRectangle(cornerRadius: 6)
                    .fill(WeightPlates.color(for: w))
                    .frame(width: 26, height: height(for: w))
                    .overlay(
                        Text(w.displayString)
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(radius: 1, y: 0.5)
                    )
            }
        }
        .frame(minWidth: 100)
        .animation(.spring(response: 0.25, dampingFraction: 0.9), value: plates)
        }
    }

    private func height(for w: Mass) -> CGFloat {
        max(12, CGFloat(log(w.inKg + 1.5) * 15))
    }
    
    private func width(for w: Mass) -> CGFloat {
        max(26, CGFloat(log(w.inKg + 1.5) * 15))
    }
}
