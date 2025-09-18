//
//  TemplatePopUp.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct TemplatePopup: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var userData: UserData
    @State private var disableMessage: String = "Invalid exercise(s) in template."
    var template: WorkoutTemplate
    var onClose: () -> Void
    var onBeginWorkout: () -> Void
    var onEdit: () -> Void
    private var disableTemplate: Bool { template.shouldDisableTemplate }

    var body: some View {
        VStack {
            headerToolbar
            
            if let completionTime = template.estimatedCompletionTime, !template.exercises.isEmpty {
                Text("Est. Duration: \(Format.formatDuration(completionTime.inSeconds, roundSeconds: true))")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
                      
            List {
                if template.exercises.isEmpty {
                    emptyView
                } else {
                    Section {
                        ForEach(template.exercises, id: \.id) { exercise in
                            ExerciseRow(
                                exercise,
                                secondary: true,
                                heartOverlay: true,
                                favState: FavoriteState.getState(for: exercise, userData: userData)
                            ) { } detail: {
                                exercise.setsSubtitle
                                    .font(.caption)
                                    .foregroundStyle(Color.secondary)
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
                    .foregroundStyle(Color.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            RectangularButton(title: "Begin Workout", enabled: !disableTemplate, width: .fit, action: onBeginWorkout)
        }
        .padding()
        .background(Color(colorScheme == .dark ? UIColor.secondarySystemBackground : UIColor.systemBackground).opacity(0.6))
    }
    
    private var emptyView: some View {
        VStack {
            Image(systemName: "figure.walk")
                .font(.largeTitle)
                .padding()
                .foregroundStyle(.blue)
            Text("Nothing Here...")
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text("Press 'Edit' to Build your Workout!")
                .foregroundStyle(Color.primary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true) // Allow text to grow vertically
                .padding(.bottom)
        }
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(colorScheme == .dark ? UIColor.secondarySystemBackground : UIColor.systemBackground)))
    }
    
    private var headerToolbar: some View {
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
    }
}
