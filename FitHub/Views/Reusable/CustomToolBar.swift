//
//  Toolbar.swift
//  FitHub
//
//  Created by Anthony Cantu on 7/21/25.
//

import SwiftUI

struct CustomToolbar: ViewModifier {
    /// Pass a closure to show the button, or `nil` to omit it.
    let settingsDestination: (() -> AnyView)?
    let menuDestination: (() -> AnyView)?

    func body(content: Content) -> some View {
        content.toolbar {
            if let settingsDestination {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink(
                        destination: LazyDestination(destination: settingsDestination)
                    ) {
                        Image(systemName: "gear")
                            .imageScale(.large)
                            .padding()
                    }
                }
            }
            if let menuDestination {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(
                        destination: LazyDestination(destination: menuDestination)
                    ) {
                        Image(systemName: "line.horizontal.3")
                            .imageScale(.large)
                            .padding()
                    }
                }
            }
        }
    }
}

extension View {
    /// Call with nothing for an empty toolbar.
    func customToolbar(
        settingsDestination: (() -> AnyView)? = nil,
        menuDestination: (() -> AnyView)? = nil
    ) -> some View {
        modifier(CustomToolbar(
            settingsDestination: settingsDestination,
            menuDestination: menuDestination
        ))
    }
}
