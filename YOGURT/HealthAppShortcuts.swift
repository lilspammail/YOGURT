import AppIntents

/// The display name used for the app's system shortcuts.
/// This constant is not provided automatically by Xcode, so we define it here
/// to ensure that the shortcut phrases compile correctly.
private let ApplicationShortcutsApplicationName = "Yogurt"

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
