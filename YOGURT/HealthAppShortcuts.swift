import AppIntents
import Foundation

/// Apple's AppShortcuts framework normally exposes `ApplicationShortcutsApplicationName`
/// for constructing phrases that contain the application's display name. The constant
/// isn't available when building outside of Xcode, so we provide a fallback using the
/// bundle information. This mirrors the behavior of the original constant and keeps the
/// project building when the symbol isn't present.
private let ApplicationShortcutsApplicationName: String = {
    let info = Bundle.main
    // Try the localized display name first, then the bundle name, and finally a
    // sensible default.
    if let displayName = info.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String {
        return displayName
    }
    if let bundleName = info.object(forInfoDictionaryKey: "CFBundleName") as? String {
        return bundleName
    }
    return "YOGURT"
}()

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
