import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    private(set) var isAuthorized: Bool = false

    func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            if let error = error {
                print("Notification authorization request error: \(error.localizedDescription)")
            }
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                completion?(granted)
            }
        }
    }

    func scheduleNotification(id: String, title: String, body: String, timeInterval: TimeInterval = 1, repeats: Bool = false) {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: repeats)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification \(id): \(error.localizedDescription)")
            }
        }
    }

    func scheduleProximityNotification(id: String, title: String, body: String) {
        scheduleNotification(id: id, title: title, body: body, timeInterval: 1, repeats: false)
    }

    func cancelNotification(id: String) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [id])
        center.removeDeliveredNotifications(withIdentifiers: [id])
    }

    func cancelAll() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }
}
