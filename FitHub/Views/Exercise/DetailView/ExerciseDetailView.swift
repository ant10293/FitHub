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
    @State private var editingExercise: Bool
    @State private var selectedView: Views
    @State private var loadedExercises: [Exercise]?
    let exercise: Exercise
    let viewingAsSheet: Bool

    init(
        exercise: Exercise,
        viewingAsSheet: Bool = false
    ) {
        self.exercise = exercise
        self.viewingAsSheet = viewingAsSheet
        _selectedView = State(initialValue: .about)
        _editingExercise = State(initialValue: false)
        _loadedExercises = State(initialValue: nil)
    }
    
    var body: some View {
        VStack {
            if viewingAsSheet { workoutToolbar }
            
            Picker("View", selection: $selectedView) {
                ForEach(Views.allCases) { v in
                    Text(v.rawValue).tag(v)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            Group {
                switch selectedView {
                case .about:
                    AboutView(loadedExercises: $loadedExercises, exercise: exercise)
                case .history:
                    ExerciseHistory(
                        exercise: exercise,
                        completedWorkouts: ctx.userData.workoutPlans.completedWorkouts,
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
        CenteredOverlayHeader(
            center: {
                Text("\(exercise.name)").bold()
                    .multilineTextAlignment(.center)
            },
            trailing: {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .imageScale(.large)
                        .foregroundStyle(.gray)
                }
                .padding(.trailing)
            }
        )
        .padding(.vertical)
    }
}
