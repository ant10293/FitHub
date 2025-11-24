//
//  SubMuscleEditor.swift
//  FitHub
//
//  Created by Anthony Cantu on 9/9/25.
//

import SwiftUI


// MARK: – Sub-muscle picker / editor
struct SubMuscleEditor: View {
    let muscle: Muscle
    @Binding var subEng: [SubMuscleEngagement]

    // add-new state
    @State private var chosen: SubMuscles? = nil
    @State private var pct: Double = 0

    // inline-edit state
    @State private var editingIndex: Int? = nil          // row that's showing a slider
    @State private var editingValue: Double = 0          // temporary value while editing

    // ───── helpers
    private var totalUsed: Double { subEng.reduce(0) { $0 + $1.engagementPercentage } }
    private var remaining: Double { max(0, 100 - totalUsed) }
    private var available: [SubMuscles] {
        let taken = Set(subEng.map(\.submuscleWorked))
        return Muscle.getSubMuscles(for: muscle).filter { !taken.contains($0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Sub-muscles").font(.headline)

            // ── Existing rows ─────────────────────────────
            if subEng.isEmpty {
                Text("None added").foregroundStyle(Color.secondary)
            } else {
                ForEach(subEng.indices, id: \.self) { idx in
                    let s = subEng[idx]

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            // MARK: this formatting looks horrible. Bullet pt is too small
                            Text("• \(s.submuscleWorked.rawValue)")
                            Spacer()
                            Text("\(Int(s.engagementPercentage)) %")
                                .font(.subheadline)
                            
                            Menu {
                                Button {
                                    // Start editing this row (only one can be edited at a time)
                                    // If another row was being edited, save it first
                                    if let previousIndex = editingIndex, previousIndex != idx {
                                        subEng[previousIndex].engagementPercentage = editingValue
                                    }
                                    editingIndex = idx
                                    editingValue = subEng[idx].engagementPercentage
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                
                                Button(role: .destructive) {
                                    // Delete this submuscle engagement
                                    subEng.remove(at: idx)
                                    // Adjust editing index if needed
                                    if let currentEditingIndex = editingIndex {
                                        if currentEditingIndex == idx {
                                            // Deleted the item being edited - stop editing
                                            editingIndex = nil
                                        } else if currentEditingIndex > idx {
                                            // Deleted an item before the one being edited - adjust index
                                            editingIndex = currentEditingIndex - 1
                                        }
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .imageScale(.medium)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }

                        // slider only if this row is "open"
                        if editingIndex == idx {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Engagement: \(Int(editingValue)) %")
                                Slider(value: $editingValue, in: 0...100, step: 1)
                                HStack {
                                    Spacer()
                                    Button {
                                        subEng[idx].engagementPercentage = editingValue
                                        editingIndex = nil
                                    } label: {
                                        Image(systemName: "checkmark.circle.fill")
                                            .imageScale(.large)
                                        Text("Save")
                                            .fontWeight(.semibold)
                                    }
                                    .tint(.green)
                                }
                            }
                        }
                    }
                }
            }

            // ── Add-new picker row ───────────────────────
            if !available.isEmpty {
                HStack(spacing: 12) {
                    Picker("Add Sub-muscle", selection: $chosen) {
                        Text("Select").tag(nil as SubMuscles?)
                        ForEach(available, id: \.self) { s in
                            Text(s.rawValue)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                                .tag(Optional(s))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onChange(of: chosen) { pct = remaining }

                    Spacer()

                    Button(action: add) {
                        Image(systemName: "checkmark.circle.fill")
                            .imageScale(.large)
                        Text("Add")
                            .fontWeight(.semibold)
                    }
                    .tint(.green)
                    .disabled(invalidEngagement)
                    .opacity(invalidEngagement ? 0.4 : 1)
                }
            }

            // slider for *new* addition
            if chosen != nil {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Engagement: \(Int(pct)) %")
                    Slider(value: $pct, in: 0...100, step: 1)
                    if pct <= 0 {
                        ErrorFooter(message: "Engagement percentage must be greater than 0%.", showImage: true)
                    }
                }
            }

            // total warning
            if !subEng.isEmpty && effectiveTotal != 100 {
                ErrorFooter(message: "Sub-muscle total is \(Int(effectiveTotal)) %. Must equal 100 %.", showImage: true)
            }
        }
    }
    
    private var invalidEngagement: Bool { pct <= 0 || chosen == nil || effectiveTotal > 100 }
    
    // Calculate effective total including any in-progress edits
    private var effectiveTotal: Double {
        if let idx = editingIndex {
            // When editing: use the editing value instead of the stored value
            let baseTotal = subEng.enumerated().reduce(0.0) { sum, item in
                if item.offset == idx {
                    return sum // Skip the item being edited
                }
                return sum + item.element.engagementPercentage
            }
            return baseTotal + editingValue + (chosen != nil ? pct : 0)
        } else {
            // When adding new: add the new percentage to the total
            return totalUsed + (chosen != nil ? pct : 0)
        }
    }
        
    // add-new action
    private func add() {
        guard let s = chosen, pct > 0 else { return }
        subEng.append(SubMuscleEngagement(submuscleWorked: s, engagementPercentage: pct))
        chosen = nil
        pct = 0
    }
}


