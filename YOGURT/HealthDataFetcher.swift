import Foundation

final class HealthDataFetcher {
    static let shared = HealthDataFetcher()
    private init() {}

    func fetchAllHealthData(completion: @escaping (FullHealthData) -> Void) {
        HealthKitManager.shared.collectHourlyMetrics { metrics in
            let stamp = metrics.last?.interval.end ?? ISO8601DateFormatter().string(from: Date())
            let metricsPayload = HealthMetricsPayload(timestamp: stamp, metrics: metrics)
            HealthKitManager.shared.collectCombinedSleepAnalysis { sleep in
                let sleepData = sleep ?? SleepAnalysis(
                    timestamp: stamp,
                    timeInBed: 0,
                    stages: SleepStages(deep: 0, light: 0, rem: 0)
                )
                completion(FullHealthData(metrics: metricsPayload, sleep: sleepData))
            }
        }
    }
}
