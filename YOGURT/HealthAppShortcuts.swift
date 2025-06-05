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
            ),
            AppShortcut(
                intent: StartAppSessionIntent(),
                phrases: [
                    AppShortcutPhrase("Начать сессию в ${applicationName}")
                ],
                shortTitle: "Начать сессию",
                systemImageName: "play.circle.fill"
            ),
            AppShortcut(
                intent: StopAppSessionIntent(),
                phrases: [
                    AppShortcutPhrase("Закончить сессию в ${applicationName}")
                ],
                shortTitle: "Закончить сессию",
                systemImageName: "stop.circle.fill"
            ),
            AppShortcut(
                intent: UploadScreenTimeIntent(),
                phrases: [
                    AppShortcutPhrase("Отправить экранное время с ${applicationName}")
                ],
                shortTitle: "Экранное время",
                systemImageName: "clock.arrow.circlepath"
            )
        ]
    }
}
