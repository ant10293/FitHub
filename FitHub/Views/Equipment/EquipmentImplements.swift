//
//  EquipmentImplements.swift
//  FitHub
//
//  Created by Anthony Cantu on 12/17/25.
//

import SwiftUI

struct EquipmentImplements: View {
    @StateObject private var kbd = KeyboardManager.shared
    let equipment: GymEquipment
    let onImplementsChange: (Implements?) -> Void
    
    @State private var availableImplements: Implements?
    @Environment(\.colorScheme) private var colorScheme
    
    init(
        equipment: GymEquipment,
        onImplementsChange: @escaping (Implements?) -> Void = { _ in }
    ) {
        self.equipment = equipment
        self.onImplementsChange = onImplementsChange
        _availableImplements = State(initialValue: equipment.availableImplements)
    }
    
    var body: some View {
        List {
            Section {
                if let implements = availableImplements {
                    if implements.weights != nil {
                        weightsView()
                    } else if implements.resistanceBands != nil {
                        resistanceBandsView()
                    }
                } else {
                    Text("No implements configured")
                        .foregroundStyle(.secondary)
                }
            } header: {
                HStack {
                    Text(equipment.name)
                    Spacer()
                    if hasImplements {
                        Button(availableImplements?.allSelected == true ? "Deselect All" : "Select All") {
                            if var implements = availableImplements {
                                implements.toggleAll()
                                availableImplements = implements
                                onImplementsChange(availableImplements)
                            }
                        }
                        .foregroundStyle(.blue)
                    }
                }
                .textCase(.none)
                .font(.headline)
            }
        }
        .listStyle(GroupedListStyle())
        .overlay(kbd.isVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
        .navigationBarTitle("Select Available", displayMode: .inline)
    }
    
    private var hasImplements: Bool {
        availableImplements?.weights != nil || availableImplements?.resistanceBands != nil
    }
    
    // MARK: - Weights View
    
    @ViewBuilder
    private func weightsView() -> some View {
        if let weights = availableImplements?.weights {
            ForEach(weights.allWeights(), id: \.self) { weight in
                weightRow(weight: weight, weights: weights)
                    .padding()
            }
        }
    }
    
    private func weightRow(weight: BaseWeight, weights: Weights) -> some View {
        let isSelected = weights.isSelected(weight)
        
        return SelectableRow(
            content: {
                weight.resolvedMass.formattedText()
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
            },
            isSelected: isSelected,
            action: {
                var updated = weights
                updated.toggle(weight)
                var updatedImplements = availableImplements ?? Implements()
                updatedImplements.weights = updated
                availableImplements = updatedImplements
                
                onImplementsChange(availableImplements)
            }
        )
    }
    
    // MARK: - Resistance Bands View
    
    @ViewBuilder
    private func resistanceBandsView() -> some View {
        if let bands = availableImplements?.resistanceBands {
            ForEach(ResistanceBand.allCases, id: \.self) { bandLevel in
                resistanceBandRow(level: bandLevel, bands: bands)
            }
        }
    }
    
    private func resistanceBandRow(level: ResistanceBand, bands: ResistanceBands) -> some View {
        let bandImpl = bands.bandImplement(for: level)
        let isSelected = bands.isAvailable(level)
        let availableColors = bands.availableColors(for: level)
        let circleSize: CGFloat = screenWidth * 0.062
        
        return SelectableRow(
            content: {
                VStack(alignment: .leading, spacing: 12) {
                    // Header with name
                    Text(level.displayName)
                        .font(.headline)
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                    
                    // Color picker - always visible
                    HStack(spacing: 12) {
                        Text("Color:")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Circle()
                            .fill(bandImpl.resolvedColor.color)
                            .frame(width: circleSize, height: circleSize)
                            .overlay(
                                Circle()
                                    .stroke(Color.primary.opacity(0.2))
                            )
                        
                        Menu {
                            ForEach(availableColors, id: \.self) { colorOption in
                                Button(action: {
                                    var updated = bands
                                    updated.updateColor(level, color: colorOption)
                                    var updatedImplements = availableImplements ?? Implements()
                                    updatedImplements.resistanceBands = updated
                                    availableImplements = updatedImplements
                                    onImplementsChange(availableImplements)
                                }) {
                                    HStack {
                                        Text(colorOption.displayName)
                                        Spacer()
                                        if bandImpl.resolvedColor == colorOption {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text(bandImpl.resolvedColor.displayName)
                                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                                Image(systemName: "chevron.up.chevron.down")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    // Weight editor - always visible
                    HStack {
                        Text("Weight (\(UnitSystem.current.weightUnit)):")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        // FIXME: use a local buffer like SetLoadEditor does to prevent _. -> _
                        // TOD0: ensure that a lower band level cannot have a higher weight value, also allow 0 values to be set as nil
                        TextField("0", text: Binding(
                            get: {
                                return bandImpl.weight?.resolvedMass.fieldString ?? "0"
                            },
                            set: { newValue in
                                var updated = bands
                                updated.updateWeight(level, weight: Double(newValue) ?? 0)
                                
                                var updatedImplements = availableImplements ?? Implements()
                                updatedImplements.resistanceBands = updated
                                availableImplements = updatedImplements
                                onImplementsChange(availableImplements)
                            }
                        ))
                        .multilineTextAlignment(.center)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                    }
                }
            },
            isSelected: isSelected,
            action: {
                var updated = bands
                updated.toggle(level)
                var updatedImplements = availableImplements ?? Implements()
                updatedImplements.resistanceBands = updated
                availableImplements = updatedImplements
                onImplementsChange(availableImplements)
            }
        )
    }
    
    // MARK: - Reusable Row Component
    
    private struct SelectableRow<Content: View>: View {
        @ViewBuilder let content: () -> Content
        let isSelected: Bool
        let action: () -> Void
        
        var body: some View {
            HStack(alignment: .center, spacing: 12) {
                content()
                    .opacity(isSelected ? 1.0 : 0.4)
                
                Button(action: action) {
                    HStack {
                        Spacer()
                        Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                            .foregroundStyle(isSelected ? .blue : .gray)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

