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
    var minSpacer: CGFloat = 12
    var insets: EdgeInsets = .init(top: 6, leading: 16, bottom: 6, trailing: 16)
    @ViewBuilder var options: () -> Options

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                Spacer(minLength: minSpacer)
                Picker("", selection: $selection) {
                    options()
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(insets)

            if showDivider { Divider() }
        }
    }
}
