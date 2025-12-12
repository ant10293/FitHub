//
//  AssessmentFormView.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct AssessmentInputField {
    let label: String
    let text: Binding<String>
    let placeholder: String
}

struct AssessmentFormView<AdditionalContent: View>: View {
    @StateObject private var kbd = KeyboardManager.shared

    let title: String
    let headline: String
    let subheadline: String
    let inputFields: [AssessmentInputField]
    let additionalContent: AdditionalContent
    let submitEnabled: Bool
    let onSubmit: () -> Void

    init(
        title: String,
        headline: String,
        subheadline: String,
        inputFields: [AssessmentInputField],
        submitEnabled: Bool,
        onSubmit: @escaping () -> Void,
        @ViewBuilder additionalContent: () -> AdditionalContent = { EmptyView() }
    ) {
        self.title = title
        self.headline = headline
        self.subheadline = subheadline
        self.inputFields = inputFields
        self.submitEnabled = submitEnabled
        self.onSubmit = onSubmit
        self.additionalContent = additionalContent()
    }

    var body: some View {
        ZStack {
            Color(UIColor.secondarySystemBackground)
                .ignoresSafeArea(.all)
                .zIndex(0)

            VStack {
                Text(title)
                    .font(.largeTitle)
                    .bold()
                    .padding(.top)

                Spacer()

                headerView

                additionalContent

                inputFieldsView

                Spacer()

                if !kbd.isVisible {
                    RectangularButton(
                        title: "Submit",
                        enabled: submitEnabled,
                        bgColor: submitEnabled ? .green : .gray,
                        action: onSubmit
                    )
                    .padding()
                }

                Spacer()
            }
        }
        .overlay(kbd.isVisible ? dismissKeyboardButton : nil, alignment: .bottomTrailing)
    }

    private var headerView: some View {
        VStack(spacing: 5) {
            Text(headline)
                .font(.headline)
                .padding(.horizontal)
            Text(subheadline)
                .font(.subheadline)
                .foregroundStyle(.gray)
        }
        .multilineTextAlignment(.center)
        .padding(.top)
    }

    private var inputFieldsView: some View {
        VStack(spacing: 15) {
            ForEach(Array(inputFields.enumerated()), id: \.offset) { _, field in
                HStack {
                    Text(field.label)

                    TextField(field.placeholder, text: field.text)
                        .inputStyle(background: Color(.systemBackground), cornerRadius: 8)
                        .keyboardType(.decimalPad)
                }
                .padding(.horizontal)
            }
        }
    }
}
