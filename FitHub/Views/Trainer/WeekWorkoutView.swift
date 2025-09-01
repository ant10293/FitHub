//
//  WeekWorkoutView.swift
//  FitHub
//
//  Created by Anthony Cantu on 8/7/24.
//
//
//  WeekWorkoutView.swift
//  FitHub
//
//  Created by <You> on <Today’s Date>.
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

struct WeekWorkoutView: View {
    @ObservedObject var userData: UserData
    @StateObject private var vm: WeekWorkoutVM
    @State private var selectedTemplate: WorkoutTemplate?

    init(userData: UserData) {
        _userData = ObservedObject(wrappedValue: userData)
        _vm = StateObject(wrappedValue: WeekWorkoutVM(userData: userData))
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: true) {
                HStack(spacing: 12) {
                    ForEach(vm.dayInfos) { info in
                        DayWorkoutView(info: info, onSelect: { selectedTemplate = $0 })
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

    struct DayWorkoutView: View {
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
                .frame(width: 90, height: 110)
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
                        .frame(width: 110, height: 130)
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


struct WeekLegendView: View {
    var body: some View {
        HStack(spacing: 15) {
            LegendItem(color: .blue, label: "Planned")
            LegendItem(color: .green, label: "Completed")
            LegendItem(color: .red, label: "Missed")
        }
        .padding(.top, 8)
    }
    
    struct LegendItem: View {
        var color: Color
        var label: String
        
        var body: some View {
            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 12, height: 12)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(Color.primary)
            }
        }
    }
}

extension Date {
    func startOfWeek(using calendar: Calendar = .current) -> Date {
        // Use CalendarUtility for consistent behavior
        return CalendarUtility.shared.startOfWeek(for: self) ?? self
    }
    
    // The rest stays the same
    func startOfDay(using calendar: Calendar = .current) -> Date {
        CalendarUtility.shared.startOfDay(for: self) 
    }
    
    func datesOfWeek(using calendar: Calendar = .current) -> [Date] {
        let start = self.startOfWeek(using: calendar)
        return (0..<7).compactMap { CalendarUtility.shared.date(byAdding: .day, value: $0, to: start) }
    }
}

