//
//  UpdateEditorStyling.swift
//  FitHub
//
//  Created by Anthony Cantu on 9/1/25.
//

import SwiftUI

struct GenericEditor: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var inputValue: String = ""

    let title: String
    let placeholder: String
    let initialValue: String
    let onSave: (Double) -> Void
    let onExit: () -> Void

    init(
        title: String,
        placeholder: String,
        initialValue: String,
        onSave: @escaping (Double) -> Void,
        onExit: @escaping () -> Void
    ) {
        self.title = title
        self.placeholder = placeholder
        self.initialValue = initialValue
        self.onSave = onSave
        self.onExit = onExit

        _inputValue = State(initialValue: initialValue)
    }

    var body: some View {
        GenericEditWrapper(
            title: title,
            onSave: {
                if let newValue = Double(inputValue) {
                    onSave(newValue)
                }
                onExit()
            },
            onCancel: {
                onExit()
            },
            content: { focus in
                TextField(placeholder, text: $inputValue)
                    .keyboardType(.decimalPad)
                    .focused(focus)
                    .multilineTextAlignment(.center)
            }
        )
    }
}

struct GenericEditWrapper<Content: View, Extra: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isFocused: Bool

    let title: String
    let onSave: () -> Void
    let onCancel: () -> Void
    let autoFocus: Bool
    // content receives a FocusState<Bool>.Binding
    let content: (_ focus: FocusState<Bool>.Binding) -> Content
    let additionalContent: () -> Extra

    init(
        title: String,
        autoFocus: Bool = true,
        onSave: @escaping () -> Void,
        onCancel: @escaping () -> Void,
        @ViewBuilder content: @escaping (_ focus: FocusState<Bool>.Binding) -> Content,
        @ViewBuilder additionalContent: @escaping () -> Extra = { EmptyView() }
    ) {
        self.title = title
        self.onSave = onSave
        self.onCancel = onCancel
        self.autoFocus = autoFocus
        self.content = content
        self.additionalContent = additionalContent
    }

    var body: some View {
        VStack {
            Text(title)
                .font(.headline)
                .padding()

            content($isFocused) // << hand the binding to children
                .padding(8)
                .roundedBackground()
                .padding(.horizontal)

            additionalContent()

            HStack(spacing: 20) {
                Spacer()

                LabelButton(
                    title: "Cancel",
                    systemImage: "xmark",
                    tint: .red,
                    action: onCancel
                )

                LabelButton(
                    title: "Save",
                    systemImage: "checkmark",
                    tint: .green,
                    action: onSave
                )

                Spacer()
            }
            .padding()
        }
        .background(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 10)
        .padding()
        .onAppear { if autoFocus { isFocused = true } }
    }
}
