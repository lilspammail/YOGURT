// HealthKitManager.swift
// YOGURT

import Foundation
import HealthKit

    //MARK: словарь

private let rawLabelMapping: [String: String] = [
    "raw_1": "изумление",
    "raw_5": "стыд",
    "raw_6": "храбрость",
    "raw_8": "удовлетворенность",
    "raw_10": "уныние",
    "raw_16": "вина",
    "raw_20": "зависть",
    "raw_21": "радость",
    "raw_23": "энтузиазм",
    "raw_24": "умиротворенность",
    "raw_26": "облегчение",
    "raw_28": "страх",
    "raw_34": "измотанность",
    "raw_36": "Безразличие",
    "raw_37": "переизбыток чувств"
]

private let rawAssociationMapping: [String: String] = [
    "raw_1": "сообщество",
    "raw_2": "текущие события",
    "raw_3": "свидания и личная жизнь",
    "raw_4": "образование",
    "raw_6": "фитнес",
    "raw_9": "хобби и увлечения",
    "raw_10": "личность и самоопределение",
    "raw_12": "партнер",
    "raw_13": "забота о себе",
    "raw_14": "духовная жизнь",
    "raw_15": "задачи",
    "raw_16": "путешествия",
    "raw_18": "погода"
]

final class HealthKitManager {
    static let shared = HealthKitManager()
    private let store = HKHealthStore()
    private init() {}

    // MARK: — Запрос разрешений
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void = { _,_ in }) {
        var read: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .bodyMassIndex)!,
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        ]

        var write: Set<HKSampleType> = []

        if #available(iOS 14.0, *) {
            if let standType = HKQuantityType.quantityType(
                forIdentifier: HKQuantityTypeIdentifier(rawValue: "appleStandHour")
            ) {
                read.insert(standType)
            }
        }

        if #available(iOS 15.0, *) {
            if let mindful = HKObjectType.categoryType(forIdentifier: .mindfulSession) {
                read.insert(mindful)
            }
        }

        if #available(iOS 18.0, *) {
            let stateOfMindType = HKSampleType.stateOfMindType()
            read.insert(stateOfMindType)
            // Если хочешь писать mood, добавь сюда:
            // write.insert(stateOfMindType)
        }

        store.requestAuthorization(toShare: write, read: read) { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }
    
    // MARK: — Helper для статистики

    private func fetchQuantity(
        identifier: HKQuantityTypeIdentifier,
        start: Date,
        end: Date,
        options: HKStatisticsOptions,
        unit: HKUnit,
        completion: @escaping (HKStatistics?) -> Void
    ) {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else {
            completion(nil)
            return
        }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [])
        let query = HKStatisticsQuery(
            quantityType: type,
            quantitySamplePredicate: predicate,
            options: options
        ) { _, stats, _ in
            completion(stats)
        }
        store.execute(query)
    }

    // MARK: — Ежечасные метрики

    func collectHourlyMetrics(completion: @escaping ([HourlyMetric]) -> Void) {
        let now = Date()
        let start = Calendar.current.startOfDay(for: now)
        let group = DispatchGroup()
        var results: [HourlyMetric] = []

        // 1. Шаги
        group.enter()
        fetchQuantity(
            identifier: .stepCount,
            start: start, end: now,
            options: .cumulativeSum,
            unit: .count()
        ) { stats in
            let val = stats?.sumQuantity()?.doubleValue(for: .count()) ?? 0
            results.append(HourlyMetric(
                metricType: "stepCount",
                value: .single(val),
                interval: Interval(start: start.isoString, end: now.isoString)
            ))
            group.leave()
        }

        // 2. Расстояние
        group.enter()
        fetchQuantity(
            identifier: .distanceWalkingRunning,
            start: start, end: now,
            options: .cumulativeSum,
            unit: .meter()
        ) { stats in
            let val = stats?.sumQuantity()?.doubleValue(for: .meter()) ?? 0
            results.append(HourlyMetric(
                metricType: "distanceWalkingRunning",
                value: .single(val),
                interval: Interval(start: start.isoString, end: now.isoString)
            ))
            group.leave()
        }

        // 3. Активные калории
        group.enter()
        fetchQuantity(
            identifier: .activeEnergyBurned,
            start: start, end: now,
            options: .cumulativeSum,
            unit: .kilocalorie()
        ) { stats in
            let val = stats?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
            results.append(HourlyMetric(
                metricType: "activeEnergyBurned",
                value: .single(val),
                interval: Interval(start: start.isoString, end: now.isoString)
            ))
            group.leave()
        }

        // 4. Минуты упражнений
        group.enter()
        fetchQuantity(
            identifier: .appleExerciseTime,
            start: start, end: now,
            options: .cumulativeSum,
            unit: .minute()
        ) { stats in
            let val = stats?.sumQuantity()?.doubleValue(for: .minute()) ?? 0
            results.append(HourlyMetric(
                metricType: "appleExerciseTime",
                value: .single(val),
                interval: Interval(start: start.isoString, end: now.isoString)
            ))
            group.leave()
        }

        // 5. Часы стояния
        if #available(iOS 14.0, *) {
            group.enter()
            if let standType = HKQuantityType.quantityType(
                forIdentifier: HKQuantityTypeIdentifier(rawValue: "appleStandHour")
            ) {
                let pred = HKQuery.predicateForSamples(withStart: start, end: now, options: [])
                let q = HKStatisticsQuery(
                    quantityType: standType,
                    quantitySamplePredicate: pred,
                    options: .discreteAverage
                ) { _, stats, _ in
                    let val = stats?.averageQuantity()?.doubleValue(for: .count()) ?? 0
                    results.append(HourlyMetric(
                        metricType: "appleStandHour",
                        value: .single(val),
                        interval: Interval(start: start.isoString, end: now.isoString)
                    ))
                    group.leave()
                }
                store.execute(q)
            } else {
                group.leave()
            }
        }

        // 6. Пульс
        group.enter()
        fetchQuantity(
            identifier: .heartRate,
            start: start, end: now,
            options: [.discreteMin, .discreteAverage, .discreteMax],
            unit: .count().unitDivided(by: .minute())
        ) { stats in
            let minV = stats?.minimumQuantity()?.doubleValue(for: .count().unitDivided(by: .minute())) ?? 0
            let avgV = stats?.averageQuantity()?.doubleValue(for: .count().unitDivided(by: .minute())) ?? 0
            let maxV = stats?.maximumQuantity()?.doubleValue(for: .count().unitDivided(by: .minute())) ?? 0
            results.append(HourlyMetric(
                metricType: "heartRate",
                value: .triple(min: minV, avg: avgV, max: maxV),
                interval: Interval(start: start.isoString, end: now.isoString)
            ))
            group.leave()
        }

        // 7. Кислород
        group.enter()
        fetchQuantity(
            identifier: .oxygenSaturation,
            start: start, end: now,
            options: .discreteAverage,
            unit: .percent()
        ) { stats in
            let val = stats?.averageQuantity()?.doubleValue(for: .percent()) ?? 0
            results.append(HourlyMetric(
                metricType: "oxygenSaturation",
                value: .single(val),
                interval: Interval(start: start.isoString, end: now.isoString)
            ))
            group.leave()
        }

        group.notify(queue: .main) { completion(results) }
    }

    // MARK: — Утренние метрики

    func collectDailyMorningMetrics(completion: @escaping (DailyMorning) -> Void) {
        let cal = Calendar.current
        let now = Date()
        let startToday = cal.startOfDay(for: now)
        let startYesterday = cal.date(byAdding: .day, value: -1, to: startToday)!

        // СНО
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let sleepPred = HKQuery.predicateForSamples(withStart: startYesterday, end: startToday, options: [])
        let sleepQ = HKSampleQuery(
            sampleType: sleepType,
            predicate: sleepPred,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ) { _, samples, _ in
            var inBed: TimeInterval = 0, deep: TimeInterval = 0, light: TimeInterval = 0, rem: TimeInterval = 0
            for s in (samples as? [HKCategorySample] ?? []) {
                let dur = s.endDate.timeIntervalSince(s.startDate)
                switch s.value {
                case HKCategoryValueSleepAnalysis.inBed.rawValue: inBed += dur
                case HKCategoryValueSleepAnalysis.asleepDeep.rawValue: deep += dur
                case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue: light += dur
                case HKCategoryValueSleepAnalysis.asleepREM.rawValue: rem += dur
                default: break
                }
            }
            let analysis = SleepAnalysis(
                timeInBed: Int(inBed/60),
                stages: SleepStages(deep: Int(deep/60), light: Int(light/60), rem: Int(rem/60))
            )

            // Пульс покоя
            let rhrType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!
            let rhrQ = HKStatisticsQuery(quantityType: rhrType, quantitySamplePredicate: sleepPred, options: .discreteMin) { _, rhrStats, _ in
                let rhr = rhrStats?.minimumQuantity()?.doubleValue(for: .count().unitDivided(by: .minute())) ?? 0

                // HRV
                let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
                let hrvQ = HKStatisticsQuery(quantityType: hrvType, quantitySamplePredicate: sleepPred, options: .discreteAverage) { _, hrvStats, _ in
                    let hrv = hrvStats?.averageQuantity()?.doubleValue(for: .secondUnit(with: .milli)) ?? 0
                    DispatchQueue.main.async {
                        completion(DailyMorning(
                            sleepAnalysis: analysis,
                            restingHeartRate: rhr,
                            heartRateVariability: hrv
                        ))
                    }
                }
                self.store.execute(hrvQ)
            }
            self.store.execute(rhrQ)
        }
        store.execute(sleepQ)
    }
    
    // MARK: — Вечерние метрики

    func collectDailyEveningMetrics(completion: @escaping (DailyEvening) -> Void) {
        let cal = Calendar.current
        let now = Date()
        let startToday = cal.startOfDay( for: now)
        let group = DispatchGroup()
        var steps = 0, calories = 0.0, weight = 0.0, bmi = 0.0
        var sleepToday: SleepAnalysis? = nil

        // Шаги
        group.enter()
        fetchQuantity(
            identifier: .stepCount,
            start: startToday, end: now,
            options: .cumulativeSum,
            unit: .count()
        ) { stats in
            steps = Int(stats?.sumQuantity()?.doubleValue(for: .count()) ?? 0)
            group.leave()
        }

        // Калории
        group.enter()
        fetchQuantity(
            identifier: .activeEnergyBurned,
            start: startToday, end: now,
            options: .cumulativeSum,
            unit: .kilocalorie()
        ) { stats in
            calories = stats?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
            group.leave()
        }

        // Вес & BMI
        group.enter()
        let pred = HKQuery.predicateForSamples(withStart: startToday, end: now, options: [])
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let wQ = HKSampleQuery(
            sampleType: HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            predicate: pred,
            limit: 1,
            sortDescriptors: [sort]
        ) { _, samples, _ in
            if let s = (samples as? [HKQuantitySample])?.first {
                weight = s.quantity.doubleValue(for: .gramUnit(with: .kilo))
            }
            let bQ = HKSampleQuery(
                sampleType: HKObjectType.quantityType(forIdentifier: .bodyMassIndex)!,
                predicate: pred,
                limit: 1,
                sortDescriptors: [sort]
            ) { _, samples, _ in
                if let s = (samples as? [HKQuantitySample])?.first {
                    bmi = s.quantity.doubleValue(for: .count())
                }
                group.leave()
            }
            self.store.execute(bQ)
        }
        store.execute(wQ)

        // Сон
        group.enter()
        let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
        let sQ = HKSampleQuery(
            sampleType: sleepType,
            predicate: pred,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ) { _, samples, _ in
            var inBed: TimeInterval = 0, deep: TimeInterval = 0, light: TimeInterval = 0, rem: TimeInterval = 0
            for s in (samples as? [HKCategorySample] ?? []) {
                let dur = s.endDate.timeIntervalSince(s.startDate)
                switch s.value {
                case HKCategoryValueSleepAnalysis.inBed.rawValue: inBed += dur
                case HKCategoryValueSleepAnalysis.asleepDeep.rawValue: deep += dur
                case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue: light += dur
                case HKCategoryValueSleepAnalysis.asleepREM.rawValue: rem += dur
                default: break
                }
            }
            sleepToday = SleepAnalysis(
                timeInBed: Int(inBed/60),
                stages: SleepStages(deep: Int(deep/60), light: Int(light/60), rem: Int(rem/60))
            )
            group.leave()
        }
        store.execute(sQ)

        // Завершение
        group.notify(queue: .main) {
            completion(DailyEvening(
                stressScore: 0,
                totalSteps: steps,
                totalCalories: calories,
                weight: weight,
                bmi: bmi,
                sleepAnalysis: sleepToday
            ))
        }
    }

    func collectSleepEvents(completion: @escaping ([HealthEvent]) -> Void) {
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let start = Calendar.current.startOfDay(for: Date())
        let end = Date()

        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [])
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let query = HKSampleQuery(
            sampleType: sleepType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, error in
            guard error == nil, let categorySamples = samples as? [HKCategorySample] else {
                print("❌ Error fetching sleep events: \(error?.localizedDescription ?? "unknown error")")
                completion([])
                return
            }

            let events = categorySamples.map { sample in
                HealthEvent(
                    sessionType: "sleep",
                    start: sample.startDate.isoString,
                    end: sample.endDate.isoString,
                    details: ["categoryValue": AnyCodable(sample.value)]
                )
            }

            DispatchQueue.main.async {
                completion(events)
            }
        }

        store.execute(query)
    }
    
    
    // MARK: — Реaltime workout

    func startObservingWorkouts() {
        let type = HKObjectType.workoutType()
        let observer = HKObserverQuery(
            sampleType: type, predicate: nil
        ) { [weak self] _, completion, error in
            guard error == nil else { completion(); return }
            self?.fetchRecentWorkouts { sessions in
                    //sessions.forEach { UploadService.shared.handleWorkoutEvent($0) }
                completion()
            }
        }
        store.execute(observer)
        store.enableBackgroundDelivery(for: type, frequency: .immediate) { _,_ in }
    }

    private func fetchRecentWorkouts(completion: @escaping ([WorkoutSession]) -> Void) {
        let pred = HKQuery.predicateForSamples(
            withStart: Date(timeIntervalSinceNow: -86400),
            end: Date(),
            options: []
        )
        
        func collectDailyWorkoutSessions(completion: @escaping ([WorkoutSession]) -> Void) {
            let startOfDay = Calendar.current.startOfDay(for: Date())
            let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: [])
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
            
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sort]
            ) { _, samples, _ in
                let workouts = (samples as? [HKWorkout]) ?? []
                let sessions = workouts.map { w in
                    WorkoutSession(
                        type: String(describing: w.workoutActivityType),
                        start: w.startDate.isoString,
                        end: w.endDate.isoString,
                        calories: w.totalEnergyBurned?.doubleValue(for: .kilocalorie())
                    )
                }
                DispatchQueue.main.async {
                    completion(sessions)
                }
            }
            store.execute(query)
        }
        
        let sort = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: false
        )
        let query = HKSampleQuery(
            sampleType: HKObjectType.workoutType(),
            predicate: pred,
            limit: 10,
            sortDescriptors: [sort]
        ) { _, samples, _ in
            let workouts = (samples as? [HKWorkout]) ?? []
            let sessions = workouts.map { w in
                WorkoutSession(
                    type: String(describing: w.workoutActivityType),
                    start: w.startDate.isoString,
                    end: w.endDate.isoString,
                    calories: w.totalEnergyBurned?.doubleValue(for: .kilocalorie())
                )
            }
            completion(sessions)
        }
        store.execute(query)
    }

    // MARK: — Mood-сессии (iOS 18+)
    @available(iOS 18.0, *)
    func collectFullMoodData(
        from start: Date,
        to end: Date,
        completion: @escaping ([MoodSessionFull]) -> Void
    ) {
        let moodType = HKSampleType.stateOfMindType()
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [])
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let query = HKSampleQuery(
            sampleType: moodType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sort]
        ) { _, samples, error in
            if let error = error {
                print("❌ Error fetching moods: \(error)")
                completion([])
                return
            }
            
            let moodSessions = (samples as? [HKStateOfMind])?.map { sample -> MoodSessionFull in
                let safeLabels = sample.labels.map { label in
                    let rawValue = label.name
                    if rawValue.starts(with: "raw_") {
                        return rawLabelMapping[rawValue] ?? rawValue
                    }
                    return rawValue
                }

                let safeAssociations = sample.associations.map { assoc in
                    let rawValue = assoc.name
                    if rawValue.starts(with: "raw_") {
                        return rawAssociationMapping[rawValue] ?? rawValue
                    }
                    return rawValue
                }
                let meta = sample.metadata?.toStringMap() ?? [:]
                let shortDesc = meta["HKMetadataKeyAppleMoodSessionShortDescription"]
                let longDesc = meta["HKMetadataKeyAppleMoodSessionDescription"]

                return MoodSessionFull(
                    start: sample.startDate.isoString,
                    end: sample.endDate.isoString,
                    valence: sample.valence,
                    valenceDescription: sample.valence.valenceDescription,
                    kind: sample.kind.name,
                    labels: safeLabels,
                    associations: safeAssociations,
                    shortDescription: shortDesc,
                    longDescription: longDesc,
                    rawMetadata: meta
                )
            } ?? []

            DispatchQueue.main.async {
                completion(moodSessions)
            }
        }

        store.execute(query)
    }
    
    func collectCombinedSleepAnalysis(completion: @escaping (SleepAnalysis?) -> Void) {
        let cal = Calendar.current
        let now = Date()
        let startYesterday20 = cal.date(bySettingHour: 20, minute: 0, second: 0, of: cal.date(byAdding: .day, value: -1, to: now)!)!
        let nowTime = now

        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let pred = HKQuery.predicateForSamples(withStart: startYesterday20, end: nowTime, options: [])
        let query = HKSampleQuery(
            sampleType: sleepType,
            predicate: pred,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ) { _, samples, _ in
            var inBed: TimeInterval = 0, deep: TimeInterval = 0, light: TimeInterval = 0, rem: TimeInterval = 0
            for s in (samples as? [HKCategorySample] ?? []) {
                let dur = s.endDate.timeIntervalSince(s.startDate)
                switch s.value {
                case HKCategoryValueSleepAnalysis.inBed.rawValue: inBed += dur
                case HKCategoryValueSleepAnalysis.asleepDeep.rawValue: deep += dur
                case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue: light += dur
                case HKCategoryValueSleepAnalysis.asleepREM.rawValue: rem += dur
                default: break
                }
            }
            let analysis = SleepAnalysis(
                timeInBed: Int(inBed / 60),
                stages: SleepStages(deep: Int(deep / 60), light: Int(light / 60), rem: Int(rem / 60))
            )
            DispatchQueue.main.async {
                completion(analysis)
            }
        }
        self.store.execute(query)
    }
}


@available(iOS 18.0, *)
private extension HKStateOfMind.Label {
    var name: String {
        switch self {
        case .angry: return "Злость"
        case .annoyed: return "Раздраженность"
        case .anxious: return "Озабоченность"
        case .calm: return "Безразличие"
        case .confident: return "Уверенность"
        case .disappointed: return "Разочарованность"
        case .disgusted: return "Отвращение"
        case .embarrassed: return "Смущение"
        case .excited: return "Приятное волнение"
        case .frustrated: return "Раздражение"
        case .grateful: return "Благодарность"
        case .happy: return "Счастье"
        case .hopeful: return "Надежда"
        case .lonely: return "Одиночество"
        case .proud: return "Гордость"
        case .sad: return "Грусть"
        case .satisfied: return "Удовлетворение"
        case .stressed: return "Стресс"
        case .surprised: return "Удивление"
        @unknown default: return "raw_\(self.rawValue)"
        }
    }
}


@available(iOS 18.0, *)
private extension HKStateOfMind.Kind {
    var name: String {
        String(describing: self)
    }
}

@available(iOS 18.0, *)
private extension HKStateOfMind.Association {
    var name: String {
        switch self {
        case .family: return "Семья"
        case .friends: return "Друзья"
        case .health: return "Здоровье"
        case .money: return "Деньги"
        case .work: return "Работа"
        @unknown default: return "raw_\(self.rawValue)"
        }
    }
}
// MARK: — конверт метаданных
extension Dictionary where Key == String, Value == Any {
    func toStringMap() -> [String: String] {
        var result: [String: String] = [:]
        for (key, value) in self {
            if let str = value as? String {
                result[key] = str
            } else if let num = value as? NSNumber {
                result[key] = num.stringValue
            } else if let date = value as? Date {
                result[key] = ISO8601DateFormatter().string(from: date)
            } else {
                result[key] = "\(value)"
            }
        }
        return result
    }
}

private extension Double {
    var valenceDescription: String {
        if self < -0.5 { return "strongly negative" }
        else if self < 0 { return "negative" }
        else if self == 0 { return "neutral" }
        else if self < 0.5 { return "positive" }
        else { return "strongly positive" }
    }
}

// MARK: — Date Helper (Файл-скоуп)
private extension Date {
    var isoString: String {
        ISO8601DateFormatter().string(from: self)
    }
}
