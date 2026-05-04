//
//  AppLanguage.swift
//  iOS-NativePhone
//

import SwiftUI

/// Holds the locale imposed by the remote/local JSON config.
/// Inject this as an environment object from NativeApp so every view
/// can react to language changes via `.environment(\.locale, appLanguage.locale)`.
final class AppLanguage: ObservableObject {
    @Published var locale: Locale = .current

    /// Apply a BCP-47 language code from the JSON (e.g. "en", "fr").
    /// Falls back to the system locale if the code is nil or empty.
    func apply(_ languageCode: String?) {
        guard let code = languageCode, !code.isEmpty else {
            locale = .current
            return
        }
        locale = Locale(identifier: code)
    }
}
