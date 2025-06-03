//
//  MeasurementsView.swift
//  FitHub1
//
//  Created by Anthony Cantu on 6/7/24.

import SwiftUI

struct MeasurementsView: View {
    @EnvironmentObject var userData: UserData
    @State private var showMeasurementEditor = false
    @State private var showMeasurementGraph = false
    @State private var currentMeasurementType: MeasurementType = .weight
    @State private var currentMeasurementValue: Double = 0.0
    @State private var showGraph: Bool = false
    
    var body: some View {
        ZStack {
            List {
                Section(header: Text("CORE")) {
                    ForEach(MeasurementType.coreMeasurements, id: \.self) { measurement in
                        MeasurementRow(
                            title: measurement.rawValue,
                            value: userData.currentMeasurements[measurement]?.value ?? 0.0,
                            onSelectMeasurement: { type, value in
                                currentMeasurementType = type
                                currentMeasurementValue = value
                            },
                            showMeasurementEditor: $showMeasurementEditor,
                            showMeasurementGraph: $showMeasurementGraph,
                            showGraph: $showGraph
                        )
                    }
                }
                Section(header: Text("BODY PART (Circumference)")) {
                    ForEach(MeasurementType.bodyPartMeasurements, id: \.self) { measurement in
                        MeasurementRow(
                            title: measurement.rawValue,
                            value: userData.currentMeasurements[measurement]?.value ?? 0.0,
                            onSelectMeasurement: { type, value in
                                currentMeasurementType = type
                                currentMeasurementValue = value
                            },
                            showMeasurementEditor: $showMeasurementEditor,
                            showMeasurementGraph: $showMeasurementGraph,
                            showGraph: $showGraph
                        )
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Measurements")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showGraph.toggle()
                    }) {
                        Image(systemName: showGraph ? "chart.bar" : "square.and.pencil")
                    }
                }
            }
            .sheet(isPresented: $showMeasurementGraph) {
                NavigationView {
                    MeasurementsGraph(userData: userData, selectedMeasurement: currentMeasurementType)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") {
                                showMeasurementGraph = false
                            }
                            .foregroundColor(.red)
                        }
                    }
                }
            }
            if showMeasurementEditor {
                MeasurementEditor(
                    measurementType: currentMeasurementType,
                    value: $currentMeasurementValue,
                    isPresented: $showMeasurementEditor,
                    onSave: { newValue in
                        userData.updateMeasurementValue(for: currentMeasurementType, with: newValue, shouldSave: true)
                    }
                )
            }
        }
    }
    struct MeasurementRow: View {
        var title: String
        var value: Double
        var onSelectMeasurement: (MeasurementType, Double) -> Void // Closure to handle selection
        @Binding var showMeasurementEditor: Bool
        @Binding var showMeasurementGraph: Bool
        @Binding var showGraph: Bool
        
        var body: some View {
            HStack {
                Text(title)
                Spacer()
                if value > 0 {
                    HStack {
                        Text(smartFormat(value))
                            .padding(.trailing, -2.5)
                            .foregroundColor(.gray)
                        if let measurementType = MeasurementType(rawValue: title)?.unitLabel {
                            Text(measurementType)
                                .foregroundColor(.gray)
                                .fontWeight(.light)
                        }
                    }
                    .onTapGesture {
                        if let measurementType = MeasurementType(rawValue: title) {
                            onSelectMeasurement(measurementType, value)
                            if showGraph {
                                showMeasurementGraph = true
                            } else {
                                showMeasurementEditor = true
                            }
                        }
                    }
                } else {
                    Button(action: {
                        if let measurementType = MeasurementType(rawValue: title) {
                            onSelectMeasurement(measurementType, value)
                            if showGraph {
                                showMeasurementGraph = true
                            } else {
                                showMeasurementEditor = true
                            }
                        }
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.blue)
                    }
                }
            }
            .contentShape(Rectangle())
        }
    }
}


