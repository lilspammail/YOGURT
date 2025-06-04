import AppIntents

struct HealthAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SendHealthDataIntent(),
            phrases: ["Отправить данные с \(ApplicationShortcutsApplicationName)"],
            shortTitle: "Синхронизация",
            systemImageName: "arrow.up.circle.fill"
        )
    }
}
