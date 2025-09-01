//
//  AdjustmentsPicker.swift
//  FitHub
//
//  Created by Anthony Cantu on 7/9/25.
//

import SwiftUI


struct AdjustmentPicker: View {
    @Binding var adjustments: [AdjustmentCategory]?

    // add-new state
    @State private var chosen: AdjustmentCategory? = nil

    // Convenience
    private var used: Set<AdjustmentCategory> { Set(adjustments ?? []) }
    private var avail: [AdjustmentCategory] {
        AdjustmentCategory.allCases.filter { !used.contains($0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Adjustments").font(.headline)

            // ── Existing rows ───────────────────────────
            if (adjustments ?? []).isEmpty {
                Text("None added").foregroundStyle(Color.secondary)
            } else {
                ForEach(adjustments ?? [], id: \.self) { cat in
                    HStack {
                        Text(cat.rawValue)
                        Spacer()
                        Button {
                            remove(cat)
                        } label: {
                            Image(systemName: "minus.circle")
                                .foregroundStyle(.red)
                        }
                    }
                }
                .onDelete { idx in remove(at: idx) }   // swipe-to-delete
            }

            // ── Add-new picker row ─────────────────────
            if !avail.isEmpty {
                HStack(spacing: 12) {
                    Picker("Add Adjustment", selection: $chosen) {
                        Text("Select").tag(nil as AdjustmentCategory?)
                        ForEach(avail, id: \.self) { c in
                            Text(c.rawValue).tag(Optional(c))
                        }
                    }

                    Spacer()

                    Button {
                        add()
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Add").fontWeight(.semibold)
                    }
                    .tint(.green)
                    .disabled(chosen == nil)
                    .opacity(chosen == nil ? 0.4 : 1)
                }
            }
        }
    }

    // ── Actions ───────────────────────────────────────
    private func add() {
        guard let c = chosen else { return }

        if var list = adjustments {
            if !list.contains(c) {
                list.append(c)
                adjustments = list                                 // write back!
            }
        } else {
            adjustments = [c]                                      // first item
        }

        chosen = nil
    }

    private func remove(_ cat: AdjustmentCategory) {
        adjustments?.removeAll { $0 == cat }
        if adjustments?.isEmpty == true { adjustments = nil }  // back to nil
    }

    private func remove(at offsets: IndexSet) {
        adjustments?.remove(atOffsets: offsets)
        if adjustments?.isEmpty == true { adjustments = nil }
    }
}
