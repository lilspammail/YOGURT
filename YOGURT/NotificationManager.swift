//
//  NotificationManager.swift
//  YOGURT
//
//  Created by Влад Соколов on 04.05.2025.
//

import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()

    func setupHourlyReminders() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                self.scheduleHourlyReminders()
            } else {
                print("❌ Notification permission denied: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }

    private func scheduleHourlyReminders() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests() // очищаем старые

        for hour in 10...23 {
            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

            let content = UNMutableNotificationContent()
            content.title = "Пора синхронизировать"
            content.body = "Откройте приложение для синхронизации с сервером"
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: "hourlyReminder_\(hour)_00",
                content: content,
                trigger: trigger
            )

            center.add(request) { error in
                if let error = error {
                    print("❌ Failed to schedule notification: \(error.localizedDescription)")
                }
            }
        }

        // Последнее уведомление в 23:30
        var lastComponents = DateComponents()
        lastComponents.hour = 23
        lastComponents.minute = 30

        let lastTrigger = UNCalendarNotificationTrigger(dateMatching: lastComponents, repeats: true)
        let lastContent = UNMutableNotificationContent()
        lastContent.title = "Последний шанс синхронизации"
        lastContent.body = "Перед сном откройте приложение для финальной отправки данных"
        lastContent.sound = .default

        let lastRequest = UNNotificationRequest(
            identifier: "hourlyReminder_23_30",
            content: lastContent,
            trigger: lastTrigger
        )

        center.add(lastRequest) { error in
            if let error = error {
                print("❌ Failed to schedule 23:30 notification: \(error.localizedDescription)")
            }
        }

        print("✅ Hourly notifications scheduled (10:00–23:30)")
    }
}
