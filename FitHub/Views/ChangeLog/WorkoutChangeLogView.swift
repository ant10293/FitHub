//
//  WorkoutChangeLogView.swift
//  FitHub
//
//  Created by Anthony Cantu on 8/17/25.
//

import SwiftUI

// Views/Workouts/WorkoutChangelogView.swift
struct WorkoutChangelogView: View {
    let changelog: WorkoutChangelog
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    statsSection
                    templatesSection
                }
                .padding()
            }
            .navigationTitle("Workout Changes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "arrow.clockwise.circle.fill")
                    .foregroundStyle(.blue)
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text("New Workout Plan Generated")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Week starting \(Format.shortDate(from: changelog.weekStartDate))")
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            if changelog.isNextWeek {
                HStack {
                    Image(systemName: "calendar.badge.plus")
                        .foregroundStyle(.green)
                    Text("This week's workouts have been scheduled")
                        .foregroundStyle(.green)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .cardContainer()
    }
    
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Generation Summary")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCard(
                    title: "Generation Time",
                    value: String(format: "%.1fs", changelog.generationStats.totalGenerationTime),
                    icon: "clock",
                    color: .blue
                )
                
                /*StatCard(
                    title: "Exercises",
                    value: "\(changelog.generationStats.exercisesSelected)",
                    icon: "dumbbell.fill",
                    color: .green
                )*/
                
                StatCard(
                    title: "Deloads Applied",
                    value: "\(changelog.generationStats.deloadsApplied)",
                    icon: "chart.line.downtrend.xyaxis",
                    color: .red
                )
                
                StatCard(
                    title: "Progressive Overload",
                    value: "\(changelog.generationStats.progressiveOverloadApplied)",
                    icon: "arrow.up.circle.fill",
                    color: .orange
                )
                
                StatCard(
                    title: "Performance Updates",
                    value: "\(changelog.generationStats.performanceUpdates)",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .purple
                )
            }
        }
        .cardContainer()
    }
    
    private var templatesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Workout Changes")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(changelog.templates) { template in
                TemplateChangeLogCard(template: template)
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.title2)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
