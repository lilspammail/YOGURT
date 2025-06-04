import Foundation
import BackgroundTasks
import UIKit

final class UploadService {
    static let shared = UploadService()
    private let client = WebhookClient(
        webhookURL: URL(string: "https://wordpressdev.karpovpartners-it.ru/health/index.php")!
    )

    private init() {}

    // MARK: — Планирование фоновых задач
    func scheduleHourly() {
        let request = BGProcessingTaskRequest(identifier: "com.yourcompany.HealthWebhookApp.hourlyUpload")
        request.requiresNetworkConnectivity = true
        request.earliestBeginDate = Date(timeIntervalSinceNow: 3600)
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
