import Foundation
import SwiftUI
import Combine
import UserNotifications

final class NotificationManager: ObservableObject {

    // ── singleton (easy to inject) ──────────────────────────────────
    @MainActor static let shared = NotificationManager()
    private init() { refreshStatus() }

    // published so UI toggles can bind to it
    @Published private(set) var isAuthorized: Bool = false

    
    // MARK: – Writable binding for Toggle
    var toggleBinding: Binding<Bool> {
        Binding(
            get: { self.isAuthorized },
            set: { newVal in
                if newVal {
                    self.requestIfNeeded()
                } else {
                    self._removeAllPending()
                    Task { @MainActor in self.isAuthorized = false }
                }
            }
        )
    }
    
    
    
    // MARK: – Public API ––––––––––––––––––––––––––––––––––––––––––––

    /// Ask only if the user hasn’t made a choice yet.
    func requestIfNeeded() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                self.requestPermission()
            } else {
                Task { @MainActor in
                    self.isAuthorized = settings.authorizationStatus == .authorized
                }
            }
        }
    }

    /// Force the system prompt.
    func requestPermission() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                Task { @MainActor in self.isAuthorized = granted }
                if let error { print("⚠️ Notification request failed:", error.localizedDescription) }
            }
    }

    static func schedule(noti: Notification) -> String
    {
        MainActor.assumeIsolated {
            shared._schedule(noti: noti)
        }
    }

    static func remove(ids: [String]) {
        MainActor.assumeIsolated { shared._remove(ids: ids) }
    }

    static func removeAllPending() {
        MainActor.assumeIsolated { shared._removeAllPending() }
    }

    // ── INSTANCE HELPERS (no UI touches) ─────────────────────────
    // keep them private so the rest of the app must go through
    // the static wrappers
    private func _schedule(noti: Notification) -> String
    {
        let id  = noti.id
        let cal = Calendar.current
        let trg = UNCalendarNotificationTrigger(dateMatching: cal.dateComponents([.year,.month,.day,.hour,.minute], from: noti.triggerDate), repeats: false)

        let content = UNMutableNotificationContent()
        content.title = noti.title
        content.body  = noti.body
        content.sound = .default

        let req = UNNotificationRequest(identifier: id,
                                        content: content,
                                        trigger: trg)
        UNUserNotificationCenter.current().add(req) { err in
            if let err {
                print("⚠️ Couldn’t schedule:", err.localizedDescription)
            } else {
                print("✅ Scheduled '\(noti.title)' →", noti.triggerDate)
            }
        }
        return id
    }

    private func _remove(ids: [String]) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ids)
    }

    private func _removeAllPending() {
        UNUserNotificationCenter.current()
            .removeAllPendingNotificationRequests()
    }

    // MARK: – Private ––––––––––––––––––––––––––––––––––––––––––––––––
    private func refreshStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
}

