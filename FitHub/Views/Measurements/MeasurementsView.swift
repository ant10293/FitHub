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
    @State private var showMeasurementGraph: Bool = false
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
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Measurements")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showGraph.toggle() }) {
                    Image(systemName: showGraph ? "chart.bar" : "square.and.pencil")
                }
            }
        }
        .sheet(isPresented: $showMeasurementGraph) {
            if let type = currentMeasurementType {
                NavigationStack {
                    MeasurementsGraph(
                        selectedMeasurement: type,
                        currentMeasurement: userData.physical.currentMeasurements[type],
                        pastMeasurements: userData.physical.pastMeasurements[type]
                    )
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") {
                                showMeasurementGraph = false
                            }
                            .foregroundStyle(.red)
                        }
                    }
                }
            }
        }
        .overlay(alignment: .center, content: {
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
        })
    }
    
    private func closeEditor() {
        currentMeasurementType = nil
        showMeasurementEditor = false
    }
    
    private func handleSelection(type: MeasurementType) {
        currentMeasurementType = type
        if showGraph {
            showMeasurementGraph = true
        } else {
            showMeasurementEditor = true
        }
    }

    struct MeasurementRow: View {
        var showGraph: Bool
        var type: MeasurementType
        var measurement: MeasurementValue
        var onSelectMeasurement: () -> Void

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
                    if showGraph {
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.blue)
                    } else {
                        Image(systemName: "plus")
                            .foregroundStyle(.blue)
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onSelectMeasurement)
        }
    }
}


