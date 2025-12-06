//
//  MeasurementCard.swift
//  FitHub
//
//  Created by Anthony Cantu on 11/9/25.
//

import SwiftUI

struct MeasurementCard<ValueView: View, ExtraView: View, Content: View>: View {
    let title: String
    let isActive: Bool
    let onTap: () -> Void
    let onClose: () -> Void

    @ViewBuilder var valueView: () -> ValueView
    @ViewBuilder var content: () -> Content
    @ViewBuilder var extraView: () -> ExtraView

    init(
        title: String,
        isActive: Bool,
        onTap: @escaping () -> Void,
        onClose: @escaping () -> Void,
        @ViewBuilder valueView: @escaping () -> ValueView,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder extraView: @escaping () -> ExtraView = { EmptyView() }
    ) {
        self.title = title
        self.isActive = isActive
        self.onTap = onTap
        self.onClose = onClose
        self.valueView = valueView
        self.content = content
        self.extraView = extraView
    }

    var body: some View {
        CustomDisclosure(
            title: title,
            isActive: isActive,
            onTap: onTap,
            onClose: onClose,
            valueView: valueView,
            content: content,
            extraView: extraView
        )
        .roundedBackground(cornerRadius: 10, color: Color(UIColor.secondarySystemBackground))
        .padding(.horizontal)
    }
}
