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
    @Published var showingSaveConfirmation: Bool = false
    @Published var isTapped: Bool = false

    /// Shows the blue “Saved!” banner for `duration` seconds, then hides it.
    /// - Parameters:
    ///   - duration:  How long the banner stays visible (seconds).  Default = 1.
    ///   - completion: Optional closure to run *after* the banner disappears.
    func showSaveConfirmation(duration: Double = 1.0, completion: (() -> Void)? = nil) {
        showingSaveConfirmation = true

        Task { @MainActor in
            let ns = UInt64(duration * 1_000_000_000)     // convert sec → nanoseconds
            try? await Task.sleep(nanoseconds: ns)

            showingSaveConfirmation = false
            completion?()
        }
    }

    func manageTap(duration: Double = 0.1, completion: (() -> Void)? = nil) {
        isTapped = true

        Task { @MainActor in
            let ns = UInt64(duration * 1_000_000_000)     // convert sec → nanoseconds
            try? await Task.sleep(nanoseconds: ns)

            isTapped = false
            completion?()
        }
    }
}
