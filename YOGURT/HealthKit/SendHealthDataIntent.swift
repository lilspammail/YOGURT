import AppIntents

struct SendHealthDataIntent: AppIntent {
    static var title: LocalizedStringResource = "Отправить данные на сервер"

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            UploadService.shared.debugSendHourlyNow()
        }
        // Suppress the default completion announcement
        return .result(dialog: IntentDialog(""))
    }
}
