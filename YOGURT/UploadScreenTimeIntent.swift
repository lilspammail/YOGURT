import AppIntents

struct UploadScreenTimeIntent: AppIntent {
    static var title: LocalizedStringResource = "Отправить экранное время"

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            ScreenTimeUploadService.shared.uploadTodayStats()
        }
        return .result()
    }
}
