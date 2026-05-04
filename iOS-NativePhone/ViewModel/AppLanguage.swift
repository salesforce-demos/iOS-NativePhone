//
//  AppLanguage.swift
//  iOS-NativePhone
//

import SwiftUI

// MARK: - Bundle helper

/// A Bundle subclass that forces a specific language by pointing to the
/// matching .lproj directory inside the main bundle.
final class LanguageBundle: Bundle, @unchecked Sendable {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        // Delegate to the inner language-specific bundle if available
        return innerBundle?.localizedString(forKey: key, value: value, table: tableName)
            ?? super.localizedString(forKey: key, value: value, table: tableName)
    }

    private var innerBundle: Bundle?

    convenience init?(languageCode: String) {
        self.init(path: Bundle.main.path(forResource: languageCode, ofType: "lproj") ?? "")
        guard let lprojPath = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
              let inner = Bundle(path: lprojPath) else { return nil }
        self.innerBundle = inner
    }
}

// MARK: - Environment key

struct LocalizationBundleKey: EnvironmentKey {
    static let defaultValue: Bundle = .main
}

extension EnvironmentValues {
    var localizationBundle: Bundle {
        get { self[LocalizationBundleKey.self] }
        set { self[LocalizationBundleKey.self] = newValue }
    }
}

// MARK: - AppLanguage

/// Holds the locale and bundle driven by the JSON config.
/// Inject via `.environmentObject(appLanguage)` in NativeApp.
final class AppLanguage: ObservableObject {
    @Published var locale: Locale = Locale(identifier: "en")
    @Published var bundle: Bundle = .main

    /// Apply a BCP-47 language code from the JSON (e.g. "en", "fr").
    func apply(_ languageCode: String?) {
        guard let code = languageCode, !code.isEmpty else {
            print("[AppLanguage] No language in config, using system locale: \(Locale.current.identifier)")
            locale = .current
            bundle = .main
            return
        }
        print("[AppLanguage] Language applied from JSON: \(code)")
        locale = Locale(identifier: code)
        bundle = Bundle.main.path(forResource: code, ofType: "lproj")
            .flatMap { Bundle(path: $0) } ?? .main
    }
}
