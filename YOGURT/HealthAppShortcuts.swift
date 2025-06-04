import AppIntents

struct HealthAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        [
            AppShortcut(
                intent: SendHealthDataIntent(),
                phrases: [
                    AppShortcutPhrase("Отправить данные с ${applicationName}")
                ],
                shortTitle: "Синхронизация",
                systemImageName: "arrow.up.circle.fill"
            )
        ]
    }
}
