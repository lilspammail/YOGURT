//
//  Models.swift
//  YOGURT
//

import Foundation

// MARK: — Mood session (iOS 17+)
public struct MoodSession: Codable {
    public let start: String
    public let end: String
    public let type: String
    public let valence: Double
    public let valenceDescription: String
    public let tags: [String]
    public let associations: [String]
    public let shortDescription: String?
    public let description: String?
}

// MARK: — Payload
public struct HealthPayload: Codable {
    public let deviceId: String
    public let timestamp: String

    public let hourlyMetrics: [HourlyMetric]?
    public let workoutSessions: [WorkoutSession]?
    public let dailyMorning: DailyMorning?
    public let dailyEvening: DailyEvening?
    public let sleepAnalysis: SleepAnalysis?      // ← добавлено
    public let moodSessions: [MoodSession]?
    public let healthEvents: [HealthEvent]?   // ← новое поле

    public init(
        deviceId: String,
        timestamp: String,
        hourlyMetrics: [HourlyMetric]?,
        workoutSessions: [WorkoutSession]?,
        dailyMorning: DailyMorning?,
        dailyEvening: DailyEvening?,
        sleepAnalysis: SleepAnalysis?,
        moodSessions: [MoodSession]? = nil,
        healthEvents: [HealthEvent]? = nil      // ← добавляем сюда
    ) {
        self.deviceId = deviceId
        self.timestamp = timestamp
        self.hourlyMetrics = hourlyMetrics
        self.workoutSessions = workoutSessions
        self.dailyMorning = dailyMorning
        self.dailyEvening = dailyEvening
        self.sleepAnalysis = sleepAnalysis
        self.moodSessions = moodSessions
        self.healthEvents = healthEvents        // ← добавляем сюда
    }
}

// MARK: — Hourly
public struct HourlyMetric: Codable {
    public let metricType: String
    public let value: MetricValue
    public let interval: Interval
}

public enum MetricValue: Codable {
    case single(Double)
    case triple(min: Double, avg: Double, max: Double)

    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let num = try? c.decode(Double.self) {
            self = .single(num)
        } else {
            let d = try c.decode([String: Double].self)
            self = .triple(
                min: d["min"] ?? 0,
                avg: d["avg"] ?? 0,
                max: d["max"] ?? 0
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .single(let v):
            try c.encode(v)
        case .triple(let minV, let avgV, let maxV):
            try c.encode(["min": minV, "avg": avgV, "max": maxV])
        }
    }
}

public struct Interval: Codable {
    public let start: String
    public let end: String
}

// MARK: — Workout realtime
public struct WorkoutSession: Codable {
    public let type: String
    public let start: String
    public let end: String
    public let calories: Double?
}

// MARK: — Daily morning
public struct DailyMorning: Codable {
    public let sleepAnalysis: SleepAnalysis
    public let restingHeartRate: Double
    public let heartRateVariability: Double
}

// MARK: — Daily evening
public struct DailyEvening: Codable {
    public let stressScore: Double
    public let totalSteps: Int
    public let totalCalories: Double
    public let weight: Double
    public let bmi: Double
    public let sleepAnalysis: SleepAnalysis?
}

// MARK: — Sleep
public struct SleepAnalysis: Codable {
    public let timestamp: String
    public let timeInBed: Int
    public let stages: SleepStages

    public init(timestamp: String, timeInBed: Int, stages: SleepStages) {
        self.timestamp = timestamp
        self.timeInBed = timeInBed
        self.stages = stages
    }
}

public struct SleepStages: Codable {
    public let deep: Int
    public let light: Int
    public let rem: Int
}

// MARK: — Helper payloads
public struct HealthMetricsPayload {
    public let timestamp: String
    public let metrics: [HourlyMetric]

    public init(timestamp: String, metrics: [HourlyMetric]) {
        self.timestamp = timestamp
        self.metrics = metrics
    }
}

public struct FullHealthData {
    public let metrics: HealthMetricsPayload
    public let sleep: SleepAnalysis

    public init(metrics: HealthMetricsPayload, sleep: SleepAnalysis) {
        self.metrics = metrics
        self.sleep = sleep
    }
}

// MARK: — Event-based sessions (e.g., sleep segments)
public struct HealthEvent: Codable {
    public let sessionType: String   // например: "sleep"
    public let start: String         // ISO8601 string
    public let end: String           // ISO8601 string
    public let details: [String: AnyCodable]
}

public struct AnyCodable: Codable {
    public let value: Any

    public init(_ value: Any) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported type")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let bool as Bool:
            try container.encode(bool)
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: container.codingPath, debugDescription: "Unsupported type"))
        }
    }
}
