//
//  CenteredOverlayHeader.swift
//  FitHub
//
//  Created by Anthony Cantu on 11/27/25.
//
import SwiftUI

struct CenteredOverlayHeader<Leading: View, Center: View, Trailing: View>: View {
    @State private var leadingWidth: CGFloat = 0
    @State private var trailingWidth: CGFloat = 0

    private let leading: Leading
    private let center: Center
    private let trailing: Trailing

    init(
        @ViewBuilder leading: () -> Leading = { EmptyView() },
        @ViewBuilder center: () -> Center = { EmptyView() },
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.leading = leading()
        self.center = center()
        self.trailing = trailing()
    }

    var body: some View {
        ZStack {
            // Row with leading + trailing, used for positioning and measuring
            HStack {
                leading
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .preference(key: LeadingWidthKey.self,
                                            value: geo.size.width)
                        }
                    )

                Spacer()

                trailing
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .preference(key: TrailingWidthKey.self,
                                            value: geo.size.width)
                        }
                    )
            }

            // Center content, padded so it never overlaps edges
            HStack {
                let sidePadding = max(leadingWidth, trailingWidth)

                Spacer()
                    .frame(width: sidePadding)

                center
                    .frame(maxWidth: .infinity)

                Spacer()
                    .frame(width: sidePadding)
            }
        }
        .onPreferenceChange(LeadingWidthKey.self) { leadingWidth = $0 }
        .onPreferenceChange(TrailingWidthKey.self) { trailingWidth = $0 }
    }
}

private struct LeadingWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct TrailingWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
