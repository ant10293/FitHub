//
//  ExerciseDetailView.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct ExerciseDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var ctx: AppContext
    @State private var editingExercise: Bool = false
    @State private var selectedView: Views = .about
    let viewingDuringWorkout: Bool
    let exercise: Exercise
    
    var body: some View {
        VStack {
            if viewingDuringWorkout { workoutToolbar }
            
            Picker("View", selection: $selectedView) {
                ForEach(Views.allCases) { v in
                    Text(v.rawValue).tag(v)
                }
            }
            .padding(.horizontal)
            .pickerStyle(SegmentedPickerStyle())
            
            Group {
                switch selectedView {
                case .about:
                    AboutView(exercise: exercise)
                case .history:
                    ExerciseHistory(
                        completedWorkouts: ctx.userData.workoutPlans.completedWorkouts,
                        exerciseId: exercise.id
                    )
                case .percentile:
                    PercentileView(exercise: exercise)
                case .prs:
                    PRsView(exercise: exercise)
                }
            }
            .padding()
            
            Spacer()
        }
        .navigationBarTitle(exercise.name, displayMode: .inline)
        .sheet(isPresented: $editingExercise) { NewExercise(original: exercise) }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    editingExercise = true
                } label: {
                    Image(systemName: "square.and.pencil")   // notepad-with-pencil icon
                }
            }
        }
    }
    
    private enum Views: String, CaseIterable, Identifiable {
        case about = "About"
        case history = "History"
        case prs = "PRs"
        case percentile = "Percentile"
        
        var id: String { self.rawValue }
    }
        
    private var workoutToolbar: some View {
        HStack {
            Text("\(exercise.name)").bold()
                .frame(maxWidth: UIScreen.main.bounds.width * 0.66)  // ≈ 2/3 screen
                .multilineTextAlignment(.center)
                .centerHorizontally()
                .overlay(
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .imageScale(.large)
                            .foregroundStyle(.gray)
                    }
                    .padding(.trailing),
                    alignment: .trailing
                )
        }
        .padding(.vertical)
    }
}
