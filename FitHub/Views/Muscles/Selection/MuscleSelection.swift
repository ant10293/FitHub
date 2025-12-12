//
//  MuscleSelection.swift
//  FitHub
//
//  Created by Anthony Cantu on 7/15/25.
//

import SwiftUI

/// Reusable muscle–group picker + body overlay.
///
/// ⬇︎  You feed it just the things that _differ_ between the two screens
///      (bindings & the small bits of business logic), and everything
///      else is handled here.
struct MuscleSelection: View {
    // MARK: ‑ Dependencies that vary between the two screens
    @Binding var selectedCategories: [SplitCategory]          // whichever “list” is current
    @Binding var showFront: Bool                              // same backing state object both screens use
    let displayName: (SplitCategory) -> String                // vm.displayName(…)
    let toggle: (SplitCategory) -> Void                       // vm.toggle(…)
    let shouldDisable: (SplitCategory) -> Bool                // vm.shouldDisable(…)
    let shouldShow:  (SplitCategory, [SplitCategory]) -> Bool // vm.shouldShow(…)

    // MARK: ‑ Layout
    var body: some View {
        VStack {
            // 1️⃣ Muscle‑group grid
            ForEach(0..<3) { col in
                HStack(spacing: 3) {
                    ForEach(SplitCategory.columnGroups[col], id: \.self) { cat in
                        let selected = selectedCategories.contains(cat)
                        let disabled = shouldDisable(cat)

                        if shouldShow(cat, selectedCategories) {
                            Button(displayName(cat)) { toggle(cat) }
                                .muscleButton(selected: selected, disabled: disabled)
                        }
                    }
                }
                .padding(.horizontal, -10)
            }

            // 2️⃣ Body overlay + flip view toggle
            ZStack {
                SimpleMuscleGroupsView(
                    showFront: $showFront,
                    gender: .male,
                    selectedSplit: selectedCategories
                )

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        flipButton
                    }
                }
            }
        }
    }

    private var flipButton: some View {
        FloatingButton(image: "arrow.2.circlepath", action: { showFront.toggle() })
            .padding(.trailing)
            .padding(.bottom)
    }
}

// MARK: ‑ Shared styling helpers
private struct MuscleButtonStyle: ViewModifier {
    let selected: Bool
    let disabled: Bool

    func body(content: Content) -> some View {
        content
            .padding(5)
            .frame(minWidth: 50, minHeight: 35)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .background(
                disabled ? Color.gray :
                (selected ? Color.blue : Color.secondary.opacity(0.8))
            )
            .foregroundStyle(disabled ? .white.opacity(0.5) : .white)
            .disabled(disabled)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .opacity(disabled ? 0.6 : 1.0)
    }
}

private extension View {
    @inline(__always)
    func muscleButton(selected: Bool, disabled: Bool) -> some View {
        modifier(MuscleButtonStyle(selected: selected, disabled: disabled))
    }
}
