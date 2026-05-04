//
//  NativeApp.swift
//  NativeApp
//
//  Created by Andres Marinn on 13/02/26.
//

import SwiftUI

@main
struct NativeApp: App {
    @StateObject private var appLanguage = AppLanguage()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appLanguage)
                .environment(\.locale, appLanguage.locale)
                .environment(\.localizationBundle, appLanguage.bundle)
        }
    }
}
