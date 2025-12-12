//
//  MenuPickerRow.swift
//  FitHub
//
//  Created by Anthony Cantu on 10/9/25.
//

import SwiftUI

struct MenuPickerRow<Selection: Hashable, Options: View>: View {
    let title: String
    @Binding var selection: Selection
    var showDivider: Bool = true
    var insets: EdgeInsets = .init(top: 6, leading: 16, bottom: 6, trailing: 16)
    var description: String? = nil
    @ViewBuilder var options: () -> Options

    var body: some View {
        VStack(spacing: 0) {
            if showDivider { Divider() }

            ZStack(alignment: .trailing) {
                // base row with padding → controls height
                HStack {
                    Text(title)
                        .fixedSize(horizontal: false, vertical: true) // allow wrap
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(insets)

                // picker on the right, with same trailing padding
                Picker("", selection: $selection) {
                    options()
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .padding(.trailing, insets.trailing)
                .padding(.vertical, insets.top) // keep it vertically comfortable
            }

            // Description text (if provided)
            if let description = description {
                HStack {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, insets.leading)
                .padding(.bottom, 8)
            }
        }
    }
}
