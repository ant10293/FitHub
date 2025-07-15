//
//  MeasurementsView.swift
//  FitHub1
//
//  Created by Anthony Cantu on 6/7/24.

import SwiftUI

struct MeasurementsView: View {
    @ObservedObject var userData: UserData
    @State private var showMeasurementEditor = false
    @State private var showMeasurementGraph = false
    @State private var currentMeasurementType: MeasurementType = .weight
    @State private var currentMeasurementValue: Double = 0.0
    @State private var showGraph: Bool = false
    
    var body: some View {
        ZStack {
            List {
                Section {
                    ForEach(MeasurementType.coreMeasurements, id: \.self) { measurement in
                        MeasurementRow(
                            showMeasurementEditor: $showMeasurementEditor,
                            showMeasurementGraph: $showMeasurementGraph,
                            showGraph: $showGraph,
                            title: measurement.rawValue,
                            value: userData.physical.currentMeasurements[measurement]?.value ?? 0.0,
                            onSelectMeasurement: { type, value in
                                currentMeasurementType = type
                                currentMeasurementValue = value
                            }
                        )
                    }
                } header: {
                    Text("CORE")
                }
                
                Section {
                    ForEach(MeasurementType.bodyPartMeasurements, id: \.self) { measurement in
                        MeasurementRow(
                            showMeasurementEditor: $showMeasurementEditor,
                            showMeasurementGraph: $showMeasurementGraph,
                            showGraph: $showGraph,
                            title: measurement.rawValue,
                            value: userData.physical.currentMeasurements[measurement]?.value ?? 0.0,
                            onSelectMeasurement: { type, value in
                                currentMeasurementType = type
                                currentMeasurementValue = value
                            }
                        )
                    }
                } header: {
                    Text("BODY PART (Circumference)")
                }
            }
            .disabled(showMeasurementEditor)
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Measurements")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showGraph.toggle() }) {
                        Image(systemName: showGraph ? "chart.bar" : "square.and.pencil")
                    }
                }
            }
            .sheet(isPresented: $showMeasurementGraph) {
                NavigationStack {
                    MeasurementsGraph(
                        selectedMeasurement: currentMeasurementType,
                        currentMeasurement: userData.physical.currentMeasurements[currentMeasurementType],
                        pastMeasurements: userData.physical.pastMeasurements[currentMeasurementType]
                    )
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
        @Binding var showMeasurementEditor: Bool
        @Binding var showMeasurementGraph: Bool
        @Binding var showGraph: Bool
        var title: String
        var value: Double
        var onSelectMeasurement: (MeasurementType, Double) -> Void // Closure to handle selection
        
        var body: some View {
            HStack {
                Text(title)
                Spacer()
                if value > 0 {
                    HStack {
                        Text(Format.smartFormat(value))
                            .padding(.trailing, -2.5)
                            .foregroundStyle(Color.gray)
                        if let measurementType = MeasurementType(rawValue: title)?.unitLabel {
                            Text(measurementType)
                                .foregroundStyle(Color.gray)
                                .fontWeight(.light)
                        }
                        if showGraph {
                            Image(systemName: "chevron.right")
                                .foregroundStyle(Color.blue)
                        }
                    }
                } else {
                    if showGraph {
                        Image(systemName: "chevron.right")
                            .foregroundStyle(Color.blue)
                    } else {
                        Image(systemName: "plus")
                            .foregroundStyle(Color.blue)
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: handleTap)
        }
        
        private func handleTap() {
            if let measurementType = MeasurementType(rawValue: title) {
                onSelectMeasurement(measurementType, value)
                if showGraph {
                    showMeasurementGraph = true
                } else {
                    showMeasurementEditor = true
                }
            }
        }
    }
}


