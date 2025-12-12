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
    let template: WorkoutTemplate
    let onClose: () -> Void
    let onBeginWorkout: () -> Void
    let onEdit: () -> Void

    var body: some View {
        VStack {
            headerToolbar

            if let completionTime = template.estimatedCompletionTime, !template.exercises.isEmpty {
                Text("Est. Duration: \(Format.formatDuration(completionTime.inSeconds, roundSeconds: true))")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }

            if template.exercises.isEmpty {
                emptyView
            } else {
                TemplateExerciseList(
                    template: template,
                    userData: userData,
                    secondary: true,
                    heartOverlay: true,
                    detail: { exercise in
                        exercise.setsSubtitle
                            .font(.caption)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                )
            }

            Spacer()

            if disableTemplate, !template.exercises.isEmpty {
                Text(disableMessage)
                    .font(.caption)
                    .foregroundStyle(Color.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            RectangularButton(
                title: "Begin Workout",
                enabled: !disableTemplate && !userData.isWorkingOut,
                width: .fit,
                action: onBeginWorkout
            )
        }
        .padding()
        .background(Color(colorScheme == .dark ? UIColor.secondarySystemBackground : UIColor.systemBackground).opacity(0.6))
    }

    private var disableTemplate: Bool { template.shouldDisableTemplate  }

    private var emptyView: some View {
        List {
            EmptyState(
                systemName: "figure.walk",
                title: "Nothing Here...",
                subtitle: "Press 'Edit' to Build your Workout!"
            )
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(colorScheme == .dark ? UIColor.secondarySystemBackground : UIColor.systemBackground)))
        }
    }

    private var headerToolbar: some View {
        CenteredOverlayHeader(
            leading: {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .padding()
                }
                .contentShape(Rectangle())
            },
            center: {
                Text(template.name)
                    .bold()
                    .multilineTextAlignment(.center)

            },
            trailing: {
                Button(action: onEdit) {
                    Text("Edit")
                        .padding()
                }
                .contentShape(Rectangle())
            }
        )
    }
}
