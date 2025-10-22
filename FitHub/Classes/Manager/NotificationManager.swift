import Foundation
import SwiftUI
import Combine
import UserNotifications

final class NotificationManager: ObservableObject {
    // ── singleton (easy to inject) ──────────────────────────────────
    static let shared = NotificationManager()          // ← no @MainActor

    private var bag = Set<AnyCancellable>()

    private init() {
        refreshStatus()
        // Refresh whenever the app becomes active (e.g., after user changes Settings)
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in self?.refreshStatus() }
            .store(in: &bag)
    }
    
    // published so UI toggles can bind to it
    @Published private(set) var isAuthorized: Bool = false

    // MARK: – Public API – schedule templates
    static func scheduleNotification(for workoutTemplate: WorkoutTemplate, user: UserData) -> [String] {
        var notificationIDs: [String] = []
        let now = Date()
        let categories = SplitCategory.concatenateCategories(for: workoutTemplate.categories)

        // Safely unwrap planned date
        guard let workoutDate = workoutTemplate.date else { return notificationIDs }

        // App/user settings gates
        if !user.settings.allowedNotifications || !user.settings.notifyBeforePlannedTime {
            return notificationIDs
        }

        if user.settings.useDateOnly {
            if user.settings.notifications.times.isEmpty {
                // Default: 9 AM & 6 PM of the workout date
                if let morningDate = CalendarUtility.shared.date(bySettingHour: 9, minute: 0, second: 0, of: workoutDate),
                   morningDate > now {
                    notificationIDs.append(schedule(noti: Notification(
                        title: "You have a Workout Today!",
                        body: "You have a \(categories) workout today. Don't forget!",
                        triggerDate: morningDate,
                        workoutName: workoutTemplate.name
                    )))
                } else {
                    print("🕒 Skipped 9 AM notification for \(workoutTemplate.name) – date has passed.")
                }

                if let eveningDate = CalendarUtility.shared.date(bySettingHour: 18, minute: 0, second: 0, of: workoutDate),
                   eveningDate > now {
                    notificationIDs.append(schedule(noti: Notification(
                        title: "Workout Incomplete",
                        body: "There's still time to complete your \(categories) workout. You got this!",
                        triggerDate: eveningDate,
                        workoutName: workoutTemplate.name
                    )))
                } else {
                    print("🕒 Skipped 6 PM notification for \(workoutTemplate.name) – date has passed.")
                }
            } else {
                // User-specific times on the workout date
                for components in user.settings.notifications.times {
                    var merged = CalendarUtility.shared.dateComponents([.year, .month, .day], from: workoutDate)
                    merged.hour = components.hour
                    merged.minute = components.minute

                    if let scheduledDate = CalendarUtility.shared.date(from: merged), scheduledDate > now {
                        notificationIDs.append(schedule(noti: Notification(
                            title: "Workout Reminder",
                            body: "You have a \(categories) workout today at \(Format.formatDate(scheduledDate, dateStyle: .none, timeStyle: .short)).",
                            triggerDate: scheduledDate,
                            workoutName: workoutTemplate.name
                        )))
                    } else {
                        print("🕒 Skipped \(Format.formatTimeComponents(components)) for \(workoutTemplate.name) – date has passed.")
                    }
                }
            }
        } else {
            if user.settings.notifications.intervals.isEmpty {
                // Default: at workout time + one hour before
                if workoutDate > now {
                    notificationIDs.append(schedule(noti: Notification(
                        title: "It's Workout Time!",
                        body: "Your \(categories) workout is now!",
                        triggerDate: workoutDate,
                        workoutName: workoutTemplate.name
                    )))
                } else {
                    print("🕒 Skipped \(Format.formatDate(workoutDate, dateStyle: .none, timeStyle: .short)) notification for \(workoutTemplate.name) – date has passed.")
                }
                
                if let oneHourBeforeDate = CalendarUtility.shared.date(byAdding: .hour, value: -1, to: workoutDate) {
                    if oneHourBeforeDate > now {
                        notificationIDs.append(schedule(noti: Notification(
                            title: "Upcoming Workout Reminder",
                            body: "Your \(categories) workout is in one hour. Get ready!",
                            triggerDate: oneHourBeforeDate,
                            workoutName: workoutTemplate.name)
                        ))
                    } else {
                        print("🕒 Skipped \(Format.formatDate(oneHourBeforeDate, dateStyle: .none, timeStyle: .short)) notification for \(workoutTemplate.name) – date has passed.")
                    }
                }
            } else {
                // Custom intervals before workout time
                for interval in user.settings.notifications.intervals {
                    let notificationDate = workoutDate.addingTimeInterval(-interval)
                    if notificationDate > now {
                        let formatted = Format.formatTimeInterval(interval)
                        notificationIDs.append(schedule(noti: Notification(
                            title: "Upcoming Workout Reminder",
                            body: "Your \(categories) workout is in \(formatted). Get ready!",
                            triggerDate: notificationDate,
                            workoutName: workoutTemplate.name
                        )))
                    } else {
                        print("🕒 Skipped \(Format.formatDate(notificationDate, dateStyle: .none, timeStyle: .short)) notification for \(workoutTemplate.name) – date has passed.")
                    }
                }
            }
        }

        return notificationIDs
    }

    // MARK: – Writable binding for Toggle
    var toggleBinding: Binding<Bool> {
        Binding(
            get: { self.isAuthorized },
            set: { newVal in
                if newVal {
                    self.requestIfNeeded()
                } else {
                    self._removeAllPending()
                    Task { @MainActor in
                        self.isAuthorized = false
                    }
                }
            }
        )
    }

    // MARK: – Public wrappers (no MainActor assumptions)
    static func printAllPendingNotifications() { shared._printAllPendingNotifications() }
    static func schedule(noti: Notification) -> String { shared._schedule(noti: noti) }
    static func remove(ids: [String]) { shared._remove(ids: ids) }
    static func removeAllPending() { shared._removeAllPending() }

    // MARK: – Permission helpers
    /// Ask only if the user hasn’t made a choice yet.
    func requestIfNeeded(onUpdate: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                self.requestPermission(onUpdate: onUpdate)
            } else {
                Task { @MainActor in
                    self.isAuthorized = settings.authorizationStatus == .authorized
                }
            }
        }
    }

    /// Force the system prompt.
    private func requestPermission(onUpdate: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            Task { @MainActor in
                self.isAuthorized = granted
                onUpdate?(granted)
            }
            if let error { print("⚠️ Notification request failed:", error.localizedDescription) }
        }
    }

    // ── INSTANCE HELPERS (no UI touches) ─────────────────────────
    private func _schedule(noti: Notification) -> String {
        let id  = noti.id
        let comps = CalendarUtility.shared.dateComponents([.year, .month, .day, .hour, .minute], from: noti.triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)

        let content = UNMutableNotificationContent()
        content.title = noti.title
        content.body  = noti.body
        content.sound = .default

        let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req) { err in
            if let err {
                print("⚠️ Couldn’t schedule:", err.localizedDescription)
            } else {
                print("✅ Scheduled '\(noti.title)' →", Format.formatDate(noti.triggerDate))
            }
        }
        return id
    }

    private func _remove(ids: [String]) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    private func _removeAllPending() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    /// Prints every pending UNNotificationRequest identifier to Xcode’s console.
    private func _printAllPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let ids = requests.map(\.identifier)
            Task { @MainActor in
                print("🔔 Pending notifications (\(ids.count)):", ids)
            }
        }
    }

    // MARK: – Private
    private func refreshStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
}
