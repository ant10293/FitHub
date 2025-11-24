//
//  MeasurementsView.swift
//  FitHub1
//
//  Created by Anthony Cantu on 6/7/24.
//
//  MeasurementsView.swift
//  FitHub1
//
//  Created by Anthony Cantu on 6/7/24.

import SwiftUI

struct MeasurementsView: View {
    @ObservedObject var userData: UserData
    @State private var currentMeasurementType: MeasurementType? = nil
    @State private var showMeasurementEditor: Bool = false
    @State private var showGraph: Bool = false

    var body: some View {
        List {
            Section(header: Text("CORE")) {
                ForEach(MeasurementType.coreMeasurements, id: \.self) { measurement in
                    MeasurementRow(
                        showGraph: showGraph,
                        type: measurement,
                        measurement: userData.currentMeasurementValue(for: measurement),
                        onSelectMeasurement: {
                            handleSelection(type: measurement)
                        }
                    )
                }
            }
            
            Section(header: Text("BODY PART (Circumference)")) {
                ForEach(MeasurementType.bodyPartMeasurements, id: \.self) { measurement in
                    MeasurementRow(
                        showGraph: showGraph,
                        type: measurement,
                        measurement: userData.currentMeasurementValue(for: measurement),
                        onSelectMeasurement: {
                            handleSelection(type: measurement)
                        }
                    )
                }
            }
        }
        .disabled(showMeasurementEditor)
        .navigationTitle("Measurements")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showGraph.toggle()
                } label: {
                    Image(systemName: showGraph ? "square.and.pencil" : "chart.bar")
                }
            }
        }
        .sheet(item: graphMeasurementType) { type in
            NavigationStack {
                MeasurementsGraph(
                    selectedMeasurement: type,
                    currentMeasurement: userData.physical.currentMeasurements[type],
                    pastMeasurements: userData.physical.pastMeasurements[type]
                )
                .padding()
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") {
                            currentMeasurementType = nil
                        }
                    }
                }
            }
        }
        .overlay(alignment: .center) {
            if showMeasurementEditor, let type = currentMeasurementType {
                MeasurementEditor(
                    measurement: userData.currentMeasurementValue(for: type),
                    measurementType: type,
                    onSave: { newValue in
                        userData.updateMeasurementValue(for: type, with: newValue)
                        closeEditor()
                    },
                    onExit: {
                        closeEditor()
                    }
                )
                .id(type)
                .padding(.horizontal)
            }
        }
    }
    
    // Computed binding: only return measurement type when in graph mode
    private var graphMeasurementType: Binding<MeasurementType?> {
        Binding(
            get: { showGraph ? currentMeasurementType : nil },
            set: { newValue in
                // When sheet is dismissed (swiped away), clear the measurement type
                currentMeasurementType = newValue
            }
        )
    }
    
    private func closeEditor() {
        currentMeasurementType = nil
        showMeasurementEditor = false
    }
    
    private func handleSelection(type: MeasurementType) {
        currentMeasurementType = type
        if showGraph {
            // Sheet will automatically present because graphMeasurementType computed property returns the type
        } else {
            // For editor view, show the editor
            showMeasurementEditor = true
        }
    }

    private struct MeasurementRow: View {
        let showGraph: Bool
        let type: MeasurementType
        let measurement: MeasurementValue
        let onSelectMeasurement: () -> Void

        var body: some View {
            HStack {
                Text(type.rawValue)
                Spacer()
                if measurement.displayValue > 0 {
                    HStack {
                        measurement.formattedText
                            .foregroundStyle(.gray)
                        
                        if showGraph {
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.blue)
                        }
                    }
                } else {
                    let imageName: String = {
                        if showGraph {
                            return "chevron.right"
                        } else {
                            return "plus"
                        }
                    }()
                    
                    Image(systemName: imageName)
                        .foregroundStyle(.blue)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onSelectMeasurement)
        }
    }
}


