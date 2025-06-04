//
//  ScreenTimeUploadService.swift
//  YoGurt
//
//  Created by Влад Соколов on 05.06.2025.
//

import Foundation

struct AppSession: Codable {
    let appName: String
    let start: Date
    let stop: Date
}

final class ScreenTimeTracker {
    static let shared = ScreenTimeTracker()
    private let storageKey = "screenTimeSessions"
    private let userDefaults = UserDefaults.standard
    
    func addSession(appName: String, start: Date, stop: Date) {
        guard stop > start else { return }
        var sessions = loadSessions()
        sessions.append(AppSession(appName: appName, start: start, stop: stop))
        saveSessions(sessions)
    }

    func loadSessions() -> [AppSession] {
        guard let data = userDefaults.data(forKey: storageKey),
              let sessions = try? JSONDecoder().decode([AppSession].self, from: data)
        else { return [] }
        return sessions
    }
    
    func reset() {
        userDefaults.removeObject(forKey: storageKey)
    }
    
    private func saveSessions(_ sessions: [AppSession]) {
        if let data = try? JSONEncoder().encode(sessions) {
            userDefaults.set(data, forKey: storageKey)
        }
    }
}

final class SessionMemory {
    static let shared = SessionMemory()
    private var activeSessions: [String: Date] = [:]
    
    func start(app: String) {
        activeSessions[app] = Date()
    }
    
    func stop(app: String) {
        guard let start = activeSessions[app] else { return }
        let stop = Date()
        activeSessions.removeValue(forKey: app)
        ScreenTimeTracker.shared.addSession(appName: app, start: start, stop: stop)
    }
}

final class ScreenTimeUploadService {
    static let shared = ScreenTimeUploadService()
    private init() {}

    private let endpoint = URL(string: "https://wordpressdev.karpovpartners-it.ru/st/ios_json.php")!

    func uploadTodayStats() {
        let sessions = ScreenTimeTracker.shared.loadSessions()
        let today = Calendar.current.startOfDay(for: Date())
        var secondsPerApp: [String: Int] = [:]

        for session in sessions {
            guard session.start >= today else { continue }
            let duration = Int(session.stop.timeIntervalSince(session.start))
            secondsPerApp[session.appName, default: 0] += duration
        }

        let minutesPerApp = secondsPerApp.mapValues { Int(ceil(Double($0) / 60.0)) }
        let formattedPerApp = minutesPerApp.mapValues { formatMinutes($0) }

        let totalMin = minutesPerApp.values.reduce(0, +)
        var formatted = formattedPerApp
        formatted["Всего"] = formatMinutes(totalMin)

        let payload: [String: Any] = [
            "date": isoDate(today),
            "apps": minutesPerApp,
            "formatted": formatted,
            "total": totalMin,
            "formatted_total": formatMinutes(totalMin)
        ]

        postJSON(payload)
        ScreenTimeTracker.shared.reset()
    }

    private func postJSON(_ payload: [String: Any]) {
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: payload, options: [])

        URLSession.shared.dataTask(with: req) { _, res, err in
            if let err = err {
                print("❌ ScreenTime send failed: \(err)")
            } else if let http = res as? HTTPURLResponse {
                print("📤 ScreenTime sent: HTTP \(http.statusCode)")
            }
        }.resume()
    }

    private func isoDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func formatMinutes(_ min: Int) -> String {
        return min >= 60 ? "\(min / 60) ч \(min % 60) мин" : "\(min) мин"
    }
}
