import Foundation
import BackgroundTasks
import UIKit

final class UploadService {
    static let shared = UploadService()
    private let client = WebhookClient(
        webhookURL: URL(string: "https://wordpressdev.karpovpartners-it.ru/health/index.php")!
    )

    // Запоминаем последнюю успешную отправку, чтобы избегать дубликатов
    private var lastSentTimestamp: String?

    private init() {}

    // MARK: — Планирование фоновых задач
    func scheduleHourly() {
        let request = BGProcessingTaskRequest(identifier: "com.yourcompany.HealthWebhookApp.hourlyUpload")
        request.requiresNetworkConnectivity = true
        request.earliestBeginDate = Date(timeIntervalSinceNow: 3600)
        try? BGTaskScheduler.shared.submit(request)
    }

    func scheduleDailyMorning() {
        let request = BGProcessingTaskRequest(identifier: "com.yourcompany.HealthWebhookApp.dailyMorningUpload")
        request.requiresNetworkConnectivity = true
        request.earliestBeginDate = Date(timeIntervalSinceNow: 24 * 3600)
        try? BGTaskScheduler.shared.submit(request)
    }

    func scheduleDailyEvening() {
        let request = BGProcessingTaskRequest(identifier: "com.yourcompany.HealthWebhookApp.dailyEveningUpload")
        request.requiresNetworkConnectivity = true
        request.earliestBeginDate = Date(timeIntervalSinceNow: 24 * 3600)
        try? BGTaskScheduler.shared.submit(request)
    }

    // MARK: — Обработка фоновых задач
    func handleHourly(task: BGProcessingTask) {
        scheduleHourly()
        task.expirationHandler = { task.setTaskCompleted(success: false) }
        collectHourlyPayload { payload in
            self.client.send(payload: payload) { result in
                task.setTaskCompleted(success: (try? result.get()) != nil)
            }
        }
    }

    func handleDailyMorning(task: BGProcessingTask) {
        scheduleDailyMorning()
        task.expirationHandler = { task.setTaskCompleted(success: false) }
        collectDailyMorningPayload { payload in
            self.client.send(payload: payload) { result in
                task.setTaskCompleted(success: (try? result.get()) != nil)
            }
        }
    }

    func handleDailyEvening(task: BGProcessingTask) {
        scheduleDailyEvening()
        task.expirationHandler = { task.setTaskCompleted(success: false) }
        collectDailyEveningPayload { payload in
            self.client.send(payload: payload) { result in
                task.setTaskCompleted(success: (try? result.get()) != nil)
            }
        }
    }

    // MARK: — Debug кнопка
    func debugSendHourlyNow() {
        collectHourlyPayload { payload in
            if let data = try? JSONEncoder().encode(payload), let json = String(data: data, encoding: .utf8) {
                print("📤 Debug Hourly Payload:", json)
            }
            self.client.send(payload: payload) { res in
                print("📤 Debug Hourly send:", res)
            }
        }
    }

    // MARK: — Сбор payload
    private func collectHourlyPayload(completion: @escaping (HealthPayload) -> Void) {
        HealthKitManager.shared.collectHourlyMetrics { metrics in
            let now = Date()
            if #available(iOS 18.0, *) {
                let start = Calendar.current.startOfDay(for: now)
                HealthKitManager.shared.collectFullMoodData(from: start, to: now) { moods in
                    HealthKitManager.shared.collectCombinedSleepAnalysis { sleep in
                        HealthKitManager.shared.collectSleepEvents { sleepEvents in
                            let moodSessions = moods.map { $0.toMoodSession() }
                            completion(self.buildPayload(
                                metrics: metrics,
                                sleepAnalysis: sleep,
                                moodSessions: moodSessions,
                                healthEvents: sleepEvents    // ← добавлено
                            ))
                        }
                    }
                }
            } else {
                HealthKitManager.shared.collectCombinedSleepAnalysis { sleep in
                    HealthKitManager.shared.collectSleepEvents { sleepEvents in
                        completion(self.buildPayload(
                            metrics: metrics,
                            sleepAnalysis: sleep,
                            moodSessions: nil,
                            healthEvents: sleepEvents     // ← добавлено
                        ))
                    }
                }
            }
        }
    }

    private func collectDailyMorningPayload(completion: @escaping (HealthPayload) -> Void) {
        HealthKitManager.shared.collectDailyMorningMetrics { morning in
            let payload = HealthPayload(
                deviceId: UIDevice.current.identifierForVendor?.uuidString ?? "unknown",
                timestamp: ISO8601DateFormatter().string(from: Date()),
                hourlyMetrics: nil,
                workoutSessions: nil,
                dailyMorning: morning,
                dailyEvening: nil,
                sleepAnalysis: nil,
                moodSessions: nil,
                healthEvents: nil
            )
            completion(payload)
        }
    }

    private func collectDailyEveningPayload(completion: @escaping (HealthPayload) -> Void) {
        HealthKitManager.shared.collectDailyEveningMetrics { evening in
            let payload = HealthPayload(
                deviceId: UIDevice.current.identifierForVendor?.uuidString ?? "unknown",
                timestamp: ISO8601DateFormatter().string(from: Date()),
                hourlyMetrics: nil,
                workoutSessions: nil,
                dailyMorning: nil,
                dailyEvening: evening,
                sleepAnalysis: nil,
                moodSessions: nil,
                healthEvents: nil
            )
            completion(payload)
        }
    }

    func handleWorkoutEvent(_ session: WorkoutSession) {
        let payload = HealthPayload(
            deviceId: UIDevice.current.identifierForVendor?.uuidString ?? "unknown",
            timestamp: ISO8601DateFormatter().string(from: Date()),
            hourlyMetrics: nil,
            workoutSessions: [session],
            dailyMorning: nil,
            dailyEvening: nil,
            sleepAnalysis: nil,
            moodSessions: nil
        )
        client.send(payload: payload) { result in
            print("📤 Workout event sent:", result)
        }
    }

    // Отправка обновленных метрик по наблюдателям
    func uploadHourlyMetrics(_ metrics: [HourlyMetric]) {
        let payload = buildPayload(metrics: metrics)
        client.send(payload: payload) { result in
            print("📤 Metrics update sent:", result)
        }
    }

    /// Безопасная отправка метрик, предотвращающая дубли
    func uploadHourlyMetricsOnce(_ metrics: [HourlyMetric]) {
        guard let stamp = metrics.first?.interval.end else { return }
        if stamp == lastSentTimestamp {
            print("⛔️ Duplicate metrics. Skipping upload.")
            return
        }
        lastSentTimestamp = stamp
        uploadHourlyMetrics(metrics)
    }

    // Отправка новой информации о сне
    func uploadSleepAnalysis(_ analysis: SleepAnalysis) {
        let payload = buildPayload(sleepAnalysis: analysis)
        client.send(payload: payload) { result in
            print("📤 Sleep analysis sent:", result)
        }
    }

    // MARK: — Payload constructor
    private func buildPayload(
        metrics: [HourlyMetric]? = nil,
        sleepAnalysis: SleepAnalysis? = nil,
        moodSessions: [MoodSession]? = nil,
        healthEvents: [HealthEvent]? = nil     // ← добавлено
    ) -> HealthPayload {
        return HealthPayload(
            deviceId: UIDevice.current.identifierForVendor?.uuidString ?? "unknown",
            timestamp: ISO8601DateFormatter().string(from: Date()),
            hourlyMetrics: metrics,
            workoutSessions: nil,
            dailyMorning: nil,
            dailyEvening: nil,
            sleepAnalysis: sleepAnalysis,
            moodSessions: moodSessions,
            healthEvents: healthEvents          // ← добавлено
        )
    }
}

// MARK: — MoodSession mapper (ВНЕ КЛАССА!)
extension MoodSessionFull {
    func toMoodSession() -> MoodSession {
        return MoodSession(
            start: self.start,
            end: self.end,
            type: self.kind,
            valence: self.valence,
            valenceDescription: self.valenceDescription,
            tags: self.labels,
            associations: self.associations,
            shortDescription: self.shortDescription,
            description: self.longDescription
        )
    }
}
