//
//  ExerciseOptions.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/29/25.
//

import SwiftUI

struct ExerciseOptions: View {    
    @EnvironmentObject private var ctx: AppContext
    @Binding var showAlert: Bool
    @Binding var alertMessage: String
    @Binding var replacedExercises: [String] // Binding to the array in the parent view
    @Binding var template: WorkoutTemplate
    @Binding var isReplacing: Bool
    @State private var showSimilarExercises = false
    var exercise: Exercise
    var onClose: () -> Void
    private let modifier = ExerciseModifier()
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("\(exercise.name)")
                    .font(.headline)
                    .padding(.horizontal)
                
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .imageScale(.large)
                        .foregroundStyle(.gray)
                }
                .padding()
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Button(action: { modifier.toggleFavorite(for: exercise.id, userData: ctx.userData) }) {
                    HStack {
                        Image(systemName: ctx.userData.evaluation.favoriteExercises.contains(exercise.id) ? "heart.fill" : "heart")
                        Text("Favorite Exercise")
                            .font(.headline)
                    }
                }.padding(.vertical, -5)
                Text("Select this exercise as a favorite to ensure that it will be included in future generated workouts.")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .padding(.bottom)
                
                Button(action: { modifier.toggleDislike(for: exercise.id, userData: ctx.userData) }) {
                    HStack {
                        Image(systemName: ctx.userData.evaluation.dislikedExercises.contains(exercise.id) ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                        Text("Dislike Exercise")
                            .font(.headline)
                    }
                }.padding(.vertical, -5)
                Text("Disliking this exercise will ensure that it will not be included in future generated workouts.")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .padding(.bottom)
                
                // add an alert when replacing or deleting exercises
                // if exercise is not disliked, provide a prompt to dislike the exercise
                Button(action: { replaceExercise() }) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Replace Exercise")
                            .font(.headline)
                    }
                }.padding(.vertical, -5)
                Text("Replace '\(exercise.name)' with a similar exercise that works the same muscles.")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .padding(.bottom)
                
                Button(action: { showSimilarExercises = true }) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("Find Replacement")
                            .font(.headline)
                    }
                }.padding(.vertical, -5)
                Text("Find a replacement exercise by viewing similar exercises that work the same muscles.")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .padding(.bottom)
                
                Button(action: { removeExercise() }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Remove Exercise")
                            .font(.headline)
                    }
                }.padding(.vertical, -5)
                Text("Remove '\(exercise.name)' from this template.")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .padding(.bottom)
            }
            .padding(.horizontal)
        }
        .padding()
        .frame(width: UIScreen.main.bounds.width * 0.8)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(radius: 10)
        .sheet(isPresented: $showSimilarExercises) {
            SimilarExercises(currentExercise: exercise, template: template) { replacedExercise in
                modifier.replaceSpecific(currentExercise: exercise, with: replacedExercise, in: &template, ctx: ctx)
            }
        }
    }
    
    private func replaceExercise() {
        isReplacing = true
        modifier.replaceInBackground(
            target: exercise,
            template: template,
            exerciseData: ctx.exercises,
            equipmentData: ctx.equipment,
            userData: ctx.userData,
            replaced: replacedExercises,
            onComplete: { result in
                if let newExercise = result.newExercise {
                    template = result.updatedTemplate
                    replacedExercises = result.updatedReplaced
                    alertMessage = "Replaced '\(exercise.name)' with '\(newExercise.name)' in \(template.name)."
                } else {
                    alertMessage = "No similar exercise found to replace '\(exercise.name)'."
                }
                isReplacing = false
                showAlert = true
            }
        )
        onClose()
    }
    
    private func removeExercise() {
        let exerciseName = modifier.remove(exercise, from: &template, user: ctx.userData)
        alertMessage = "Removed '\(exerciseName)' from \(template.name)."
        showAlert = true
        onClose()
    }
}

