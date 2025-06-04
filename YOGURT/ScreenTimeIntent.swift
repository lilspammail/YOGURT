import AppIntents

struct StartAppSessionIntent: AppIntent {
    static var title: LocalizedStringResource = "Начать сессию"

    @Parameter(title: "Приложение")
    var appName: String

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            SessionMemory.shared.start(app: appName)
        }
        return .result()
    }
}

struct StopAppSessionIntent: AppIntent {
    static var title: LocalizedStringResource = "Закончить сессию"

    @Parameter(title: "Приложение")
    var appName: String

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            SessionMemory.shared.stop(app: appName)
        }
        return .result()
    }
}
