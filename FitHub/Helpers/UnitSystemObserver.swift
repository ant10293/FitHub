//
//  UnitSystemObserver.swift
//  FitHub
//
//  Created by Auto on 1/15/25.
//

import Foundation
import SwiftUI

extension Foundation.Notification.Name {
    static let unitSystemDidChange = Foundation.Notification.Name("unitSystemDidChange")
}

/// A view modifier that refreshes the view when the unit system changes
struct UnitSystemObserver: ViewModifier {
    @State private var refreshTrigger = UUID()
    
    func body(content: Content) -> some View {
        content
            .id(refreshTrigger)
            .onReceive(NotificationCenter.default.publisher(for: Foundation.Notification.Name.unitSystemDidChange)) { _ in
                refreshTrigger = UUID()
            }
    }
}

extension View {
    /// Refreshes the view when the unit system changes
    func observesUnitSystem() -> some View {
        modifier(UnitSystemObserver())
    }
}

