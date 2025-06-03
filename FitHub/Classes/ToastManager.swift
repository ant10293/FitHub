//
//  ToastManager.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/6/25.
//

import Foundation

// MARK: - 2️⃣  UI toast / banner feedback
@MainActor
final class ToastManager: ObservableObject {
    @Published var showingSaveConfirmation = false          // was var

    /// Show for 1 second on main queue
    func showSaveConfirmation() {
        showingSaveConfirmation = true
        Task { @MainActor in                                 // newer async syntax
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            showingSaveConfirmation = false
        }
    }
}
