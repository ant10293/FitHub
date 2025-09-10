//
//  KeyboardManager.swift
//  FitHub
//
//  Created by Anthony Cantu on 7/11/25.
//

import UIKit
import Combine

/// Simple helper that publishes **`true`** when the keyboard is showing,
/// **`false`** when it’s hidden.  Nothing to instantiate in every view.
final class KeyboardManager: ObservableObject {
    // ---- singleton ------------------------------------------------------
    static let shared = KeyboardManager()          // use .shared everywhere
    @Published private(set) var isVisible = false

    private var willShow: NSObjectProtocol?
    private var willHide: NSObjectProtocol?

    private init() {
        let nc   = NotificationCenter.default
        let q: OperationQueue = .main

        willShow = nc.addObserver(forName: UIResponder.keyboardWillShowNotification,
                                  object: nil, queue: q) { [weak self] _ in
            self?.isVisible = true
        }

        willHide = nc.addObserver(forName: UIResponder.keyboardWillHideNotification,
                                  object: nil, queue: q) { [weak self] _ in
            self?.isVisible = false
        }
    }

    deinit {
        if let s = willShow { NotificationCenter.default.removeObserver(s) }
        if let h = willHide { NotificationCenter.default.removeObserver(h) }
    }
    
    func dismiss() {
        UIApplication.shared
            .sendAction(#selector(UIResponder.resignFirstResponder),
                        to: nil, from: nil, for: nil)

        // Update the published state so any listeners refresh right away.
        isVisible = false
    }
}
