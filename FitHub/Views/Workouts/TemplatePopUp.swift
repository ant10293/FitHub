//
//  TemplatePopUp.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct TemplatePopup: View {
    @Binding var template: WorkoutTemplate
    @State private var disableMessage: String = "Invalid exercise(s) in template."
    var onClose: () -> Void
    var onBeginWorkout: () -> Void
    var onEdit: () -> Void
    
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
                
                Button(action: {
                    onEdit()
                }) {
                    Text("Edit")
                        .padding()
                }
                .contentShape(Rectangle())
            }
            
            if template.estimatedCompletionTime != nil && !template.exercises.isEmpty {
                Text("Est. Completion Time: \(formatDuration(template.estimatedCompletionTime!))")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Divider()
            
            if(template.exercises.isEmpty) {
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
                .padding()
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(UIColor.secondarySystemBackground)))
                .padding()
            } else {
                List(template.exercises, id: \.id) { exercise in
                    HStack {
                        Image(exercise.fullImagePath)
                            .resizable()
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 6)) // Apply rounded rectangle shape
                        VStack(alignment: .leading) {
                            Text(exercise.name)
                                .font(.subheadline)
                            Text("Sets: ")
                                .font(.caption)
                                .bold() +
                            Text("\(exercise.sets)")
                                .font(.caption)
                        }
                    }
                    .listRowBackground(Color(UIColor.systemBackground))
                }
                .scrollContentBackground(.hidden) // Hides the default background
                .background(Color(UIColor.secondarySystemBackground))
            }
            Spacer()
            
            let disableTemplate: Bool = WorkoutTemplate.shouldDisableTemplate(template: template)
            
            if disableTemplate {
                if !template.exercises.isEmpty {
                    Text(disableMessage)
                        .font(.caption)
                        .foregroundColor(Color.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            Button("Begin Workout") {
                onBeginWorkout()
            }
            .foregroundColor(.white)
            .padding()
            .background(disableTemplate ? Color.gray : Color.blue)
            .disabled(disableTemplate)
            .cornerRadius(8)
        }
        .padding()
    }
    
    func formatDuration(_ seconds: Int) -> String {
        // Round seconds up to the nearest minute
        let totalMinutes = (seconds + 59) / 60
        
        // Break into hours and minutes
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        // Format the string based on hours and minutes
        if hours > 0 {
            return minutes > 0 ? "\(hours) hr \(minutes) min" : "\(hours) hr"
        } else {
            return "\(minutes) min"
        }
    }
}
