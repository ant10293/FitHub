//
//  CustomDisclosure.swift
//  FitHub
//
//  Created by Anthony Cantu on 12/5/25.
//
import SwiftUI

struct CustomDisclosure<ValueView: View, ExtraView: View, Content: View>: View {
    let title: String
    let note: String?
    let isActive: Bool
    let usePadding: Bool
    let onTap: () -> Void
    let onClose: () -> Void

    @ViewBuilder var valueView: () -> ValueView
    @ViewBuilder var content: () -> Content
    @ViewBuilder var extraView: () -> ExtraView

    init(
        title: String,
        note: String? = nil,
        isActive: Bool,
        usePadding: Bool = true,
        onTap: @escaping () -> Void,
        onClose: @escaping () -> Void,
        @ViewBuilder valueView: @escaping () -> ValueView,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder extraView: @escaping () -> ExtraView = { EmptyView() }
    ) {
        self.title = title
        self.note = note
        self.isActive = isActive
        self.usePadding = usePadding
        self.onTap = onTap
        self.onClose = onClose
        self.valueView = valueView
        self.content = content
        self.extraView = extraView
    }

    var body: some View {
        let padding = usePadding ? screenWidth * 0.04 : 0

        return VStack(spacing: 0) {
            Button(action: onTap) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(.blue)
                        if let note {
                            Text(note)
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                    }
                    Spacer()
                    valueView()
                        .foregroundStyle(.gray)
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(isActive ? 90 : 0))
                        .foregroundStyle(.blue)
                }
                .padding(usePadding ? padding : 0)
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())

            if isActive {
                VStack {
                    content()
                    HStack {
                        Spacer()
                        FloatingButton(image: "checkmark", action: onClose)
                    }
                    extraView()
                }
                .padding(usePadding ? padding : 0)
            }
        }
    }
}
