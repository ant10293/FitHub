//
//  WeekWorkout.swift
//  FitHub
//
//  Created by Anthony Cantu on 8/7/24.
//

import SwiftUI
import Combine


// MARK: - DTO used by the view -----------------------------------------

struct DayInfo: Identifiable, Hashable {
    enum Status { case pastPlanned, completed, planned, rest }

    let id: Date
    let dayName: String
    let shortDate: String
    let isToday: Bool
    let status: Status
    let workouts: [WorkoutRow]

    struct WorkoutRow: Identifiable, Hashable {
        let id: UUID
        let categoriesText: String
        let template: WorkoutTemplate
    }
}

// MARK: - Week Workout View --------------------------------------------

struct WeekWorkout: View {
    @ObservedObject var userData: UserData
    @StateObject private var vm: WeekWorkoutVM
    @Binding var selectedTemplate: SelectedTemplate?

    init(userData: UserData, selectedTemplate: Binding<SelectedTemplate?>) {
        _userData = ObservedObject(wrappedValue: userData)
        _vm = StateObject(wrappedValue: WeekWorkoutVM(userData: userData))
        _selectedTemplate = selectedTemplate
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(vm.dayInfos) { info in
                        DayWorkout(info: info, onSelect: { template in
                            // Find the template index in the appropriate array
                            selectedTemplate = .init(template: template, location: .trainer, mode: .popupOverlay)
                        })
                        .id(info.id)
                    }
                }
                .padding([.horizontal, .bottom])
            }
            .onAppear {
                proxy.scrollTo(vm.earliestFutureDate, anchor: .center)
            }
        }
    }
    
    // MARK: - Single‑day card ---------------------------------------------

    struct DayWorkout: View {
        @Environment(\.colorScheme) private var colorScheme
        let info: DayInfo
        let onSelect: (WorkoutTemplate) -> Void

        var body: some View {
            ZStack {
                VStack {
                    Text(info.dayName)
                        .font(.caption).fontWeight(.semibold)

                    Text(info.shortDate)
                        .font(.caption)

                    if info.status == .rest {
                        Text("Rest")
                            .font(.caption)
                            .foregroundStyle(colorScheme == .dark ? .white : .gray)
                    } else {
                        ForEach(info.workouts) { row in
                            Text(row.categoriesText)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(colorForStatus(info.status))
                                .multilineTextAlignment(.center)
                                .lineLimit(4)
                                .minimumScaleFactor(0.7)
                                .padding(.horizontal, 2)
                                .onTapGesture { onSelect(row.template) }
                        }
                    }
                }
                .frame(width: UIScreen.main.bounds.width * 0.225, height: UIScreen.main.bounds.width * 0.275)
                .background(cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(cardBorder, lineWidth: info.workouts.isEmpty ? 0 : 2)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(radius: 3)

                if info.isToday {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: UIScreen.main.bounds.width * 0.275, height: UIScreen.main.bounds.width * 0.325)
                        .allowsHitTesting(false)
                }
            }
        }

        // MARK: - Appearance helpers
        private var cardBackground: Color {
            colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : .white
        }
        
        private var cardBorder: Color { colorForStatus(info.status) }

        private func colorForStatus(_ s: DayInfo.Status) -> Color {
            switch s {
            case .pastPlanned: return .red
            case .completed:   return .green
            case .planned:     return .blue
            case .rest:        return .gray
            }
        }
    }
}

