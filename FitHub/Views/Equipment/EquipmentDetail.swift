//
//  EquipmentDetail.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct EquipmentDetail: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var expandList: Bool = false
    @State private var editingEquipment: Bool = false
    var equipment: GymEquipment
    let allExercises: [Exercise]
    let allEquipment: [GymEquipment]

    var exercisesForEquipment: [Exercise] {
        allExercises.filter { isExerciseCompatibleWithEquipment($0, using: equipment) }
    }

    var body: some View {
        NavigationStack {
            VStack {
                if !expandList {
                    equipment.fullImage
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: UIScreen.main.bounds.height * 0.25)

                    Text(equipment.name)
                        .font(.headline)
                        .bold()
                        .padding(.top)

                    Text(equipment.description)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .minimumScaleFactor(0.7)
                }

                Button(action: {
                    withAnimation {
                        expandList.toggle()
                    }
                }) {
                    HStack {
                        Label(
                            expandList ? "Collapse List" : "Expand List",
                            systemImage: expandList ? "chevron.down" : "chevron.up"
                        )
                        .font(.subheadline)
                        Spacer()
                    }
                    .padding(.top)
                }

                List {
                    Section {
                        ForEach(exercisesForEquipment) { exercise in
                            ExerciseRow(exercise)
                        }
                    } header: {
                        Text("Exercises using \(equipment.name)")
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
                .frame(maxHeight: !expandList ? UIScreen.main.bounds.height * 0.33 : .infinity)
            }
            .padding()
            .navigationBarTitle("Equipment Details", displayMode: .inline)
            .sheet(isPresented: $editingEquipment) { NewEquipment(original: equipment) }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        editingEquipment = true
                    } label: {
                        Image(systemName: "square.and.pencil")   // notepad-with-pencil icon
                    }
                }
            }
        }
    }
    
    /// Checks if a single piece of equipment (and its alternatives) can fulfill the exercise.
    func isExerciseCompatibleWithEquipment(_ exercise: Exercise, using equipment: GymEquipment) -> Bool {
        let name = equipment.name

        // Only include exercises that list the current equipment or where it's a valid alternative
        for required in exercise.equipmentRequired {
            // Direct match
            if required == name { return true }

            // Is this equipment a valid alternative *for* the required equipment?
            if let requiredEquip = allEquipment.first(where: { $0.name == required }),
               let alternatives = requiredEquip.alternativeEquipment, alternatives.contains(name) {
                return true
            }
        }
        // no equipment match found
        return false
    }
}
