// HealthWebhookApp.swift
// YOGURT

import SwiftUI
import BackgroundTasks

@main
struct HealthWebhookApp: App {
    // Мост к UIKit-делегату для регистрации BG-задач и HealthKit-авторизации
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

    class AppDelegate: UIResponder, UIApplicationDelegate {
        func application(
            _ application: UIApplication,
            didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
        ) -> Bool {
            // 1️⃣ Регистрируем идентификаторы фоновых задач
            BGTaskScheduler.shared.register(
                forTaskWithIdentifier: "com.yourcompany.HealthWebhookApp.hourlyUpload",
                using: nil
            ) { task in
                UploadService.shared.handleHourly(task: task as! BGProcessingTask)
            }

            // 2️⃣ Запрашиваем права HealthKit и запускаем задачи + уведомления
            HealthKitManager.shared.requestAuthorization { success, error in
                guard success else {
                    print("❌ HealthKit auth failed:", error ?? "Unknown")
                    return
                }
                print("✅ HealthKit auth granted")
                UploadService.shared.scheduleHourly()

                NotificationManager.shared.setupHourlyReminders()
            }

            return true
        }

        func applicationDidBecomeActive(_ application: UIApplication) {
            print("🔔 App became active — forcing data sync")
            UploadService.shared.debugSendHourlyNow()
        }
    }
    
}
