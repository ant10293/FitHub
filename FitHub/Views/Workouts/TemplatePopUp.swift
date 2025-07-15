//
//  TemplatePopUp.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct TemplatePopup: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var template: WorkoutTemplate
    @State private var disableMessage: String = "Invalid exercise(s) in template."
    var onClose: () -> Void
    var onBeginWorkout: () -> Void
    var onEdit: () -> Void
    
    var disableTemplate: Bool { WorkoutTemplate.shouldDisableTemplate(template: template) }

    var body: some View {
        VStack {
            HStack {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .contentShape(Rectangle())
                        .padding()
                }
                
                Spacer()
                Text(template.name).bold().zIndex(1).multilineTextAlignment(.center)
                Spacer()
                
                Button(action: onEdit) {
                    Text("Edit")
                        .padding()
                }
                .contentShape(Rectangle())
            }
            
            if let completionTime = template.estimatedCompletionTime, !template.exercises.isEmpty {
                Text("Est. Completion Time: \(Format.formatDuration(completionTime, roundSeconds: true))")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Divider()
          
            List {
                if template.exercises.isEmpty {
                    VStack {
                        Image(systemName: "figure.walk")
                            .font(.largeTitle)
                            .padding()
                            .foregroundColor(.blue)
                        Text("Nothing Here...")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Press 'Edit' to Build your Workout!")
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true) // Allow text to grow vertically
                            .padding(.bottom)
                    }
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(colorScheme == .dark ? UIColor.secondarySystemBackground : UIColor.systemBackground)))
                } else {
                    Section {
                        ForEach(template.exercises, id: \.id) { exercise in
                            ExerciseRow(exercise, secondary: true) { } detail: {
                                Text("Sets: ")
                                    .font(.caption)
                                    .bold() +
                                Text("\(exercise.sets)")
                                    .font(.caption)
                            }
                            .listRowBackground(Color(colorScheme == .dark ? UIColor.secondarySystemBackground : UIColor.systemBackground))
                        }
                    } header: {
                        Text("\(template.numExercises) Exercises")
                            .font(.caption)
                    }
                }
            }

            Spacer()
            
            if disableTemplate, !template.exercises.isEmpty {
                Text(disableMessage)
                    .font(.caption)
                    .foregroundColor(Color.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button(action: onBeginWorkout) {
                Text("Begin Workout")
                .padding()
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.blue))
                .foregroundColor(.white)
                .disabled(disableTemplate)
            }
            
        
            
        }
        .padding()
        .background(Color(colorScheme == .dark ? UIColor.secondarySystemBackground : UIColor.systemBackground).opacity(0.6))
    }
}
