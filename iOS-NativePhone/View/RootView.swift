//
//  RootView.swift
//  NotificationLiquidGlass
//
//  Created by Andres Marin on 13/02/26.
//

import Foundation
import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appLanguage: AppLanguage
    @StateObject private var lockVM = LockScreenViewModel()
    @State private var lockScreenOffset: CGFloat = 0
    @State private var isLocked: Bool = true
    @State private var isConfigured: Bool = false
    @State private var chatServiceURL: String = ""
    
    // Direct call mode
    @State private var isDirectCall: Bool = false
    @State private var directCallContact: ContactConfig? = nil
    @State private var directCallStatusBar: StatusBarSettings? = nil
    @State private var directCallBackground: UIImage? = nil
    @State private var directCallNotifications: [NotificationConfig] = []
    @State private var directCallNotifImages: [String: UIImage] = [:]
    
    let screenHeight = UIScreen.main.bounds.height
    
    var progress: Double {
        let percentage = -lockScreenOffset / screenHeight
        return max(0, min(percentage, 1))
    }
    
    var body: some View {
        ZStack {
            if isDirectCall, let contact = directCallContact {
                // DIRECT CALL — skip LockScreen and PhoneView
                if #available(iOS 26.0, *) {
                    CallView(
                        contact: contact,
                        preloadedBackground: directCallBackground,
                        onEnd: {
                            isDirectCall = false
                            isLocked = false
                        },
                        statusBarPhoneView: directCallStatusBar,
                        waitForTap: true,
                        callNotifications: directCallNotifications,
                        notificationImages: directCallNotifImages
                    )
                    .transition(.opacity)
                    .zIndex(3)
                    .statusBarHidden(true)
                }
            } else if !isConfigured {
                // CONFIGURACIÓN INICIAL (pantalla Google)
                URLConfigurationView(
                    chatServiceURL: $chatServiceURL,
                    isConfigured: $isConfigured,
                    onConfirm: { url in
                        await handleConfirm(url: url)
                    }
                )
                .environment(\.locale, .init(identifier: "en")) // Always English — language comes from JSON
                .transition(.opacity)
                .zIndex(2)
            } else {
                // PHONE VIEW
                PhoneView(isLocked: $isLocked, onLockAction: { lockPhone() })
                    .scaleEffect(isLocked ? 0.94 + (0.06 * progress) : 1.0)
                    .blur(radius: isLocked ? (1.0 - progress) * 3 : 0)
                    .overlay(Color.black.opacity(isLocked ? 0.3 - (0.3 * progress) : 0).ignoresSafeArea().allowsHitTesting(false))
                    .zIndex(0)
                    .statusBarHidden(true)
                
                // LOCKSCREEN
                if isLocked {
                    LockScreenView(viewModel: lockVM, offset: $lockScreenOffset, opacity: .constant(1.0 - (progress * 1.5)))
                        .offset(y: lockScreenOffset)
                        .clipShape(RoundedRectangle(cornerRadius: pow(progress, 0.4) * 54, style: .continuous))
                        .scaleEffect(1 - progress * 0.04)
                        .gesture(
                            DragGesture()
                                .onChanged { value in if value.translation.height < 0 { lockScreenOffset = value.translation.height } }
                                .onEnded { value in
                                    if value.translation.height < -150 || value.velocity.height < -800 { unlockPhone() }
                                    else { withAnimation(.interpolatingSpring(stiffness: 250, damping: 25)) { lockScreenOffset = 0 } }
                                }
                        )
                        .zIndex(1)
                        .transition(.identity)
                        .statusBarHidden(true)
                }
            }
        }
        .background(Color.black).ignoresSafeArea()
        .onAppear {
            if let savedURL = UserDefaults.standard.string(forKey: "chatServiceURL"), !savedURL.isEmpty {
                chatServiceURL = savedURL
            }
        }
    }
    
    // MARK: - Confirm handler: fetch config + image, then transition
    @MainActor
    private func handleConfirm(url: String) async {
        NetworkService.shared.baseURL = url
        
        // Fetch config
        let config: AppConfig? = await withCheckedContinuation { continuation in
            NetworkService.shared.fetchChatConfig { result in
                switch result {
                case .success(let c): continuation.resume(returning: c)
                case .failure: continuation.resume(returning: nil)
                }
            }
        }
        
        print("[RootView] language field from JSON: \(config?.language ?? "nil")")

        guard let config, config.directCall == true,
              let firstContact = config.contacts?.first else {
            // No directCall: ir al flujo normal — aplicar idioma antes de mostrar PhoneView
            appLanguage.apply(config?.language)
            withAnimation(.easeInOut(duration: 0.3)) { isConfigured = true }
            return
        }
        
        // Descargar imagen mientras el usuario sigue viendo la pantalla de Google
        directCallContact = firstContact
        directCallStatusBar = config.statusBar?.chatview
        directCallNotifications = config.callNotifications ?? []

        // Descargar en paralelo: imagen de fondo + imágenes de documentIcon de notificaciones
        async let bgFetch: Void = fetchDirectCallBackground(for: firstContact)
        async let notifFetch: Void = fetchNotificationImages(for: config.callNotifications ?? [])
        _ = await (bgFetch, notifFetch)

        // Todo listo: aplicar idioma y hacer transición directa a CallView
        appLanguage.apply(config.language)
        isConfigured = true
        withAnimation(.easeIn(duration: 0.3)) {
            isDirectCall = true
        }
    }
    
    private func fetchNotificationImages(for notifications: [NotificationConfig]) async {
        await withTaskGroup(of: (String, UIImage)?.self) { group in
            for notif in notifications {
                guard let urlStr = notif.documentIcon,
                      let url = URL(string: urlStr),
                      url.scheme == "https" || url.scheme == "http" else { continue }
                group.addTask {
                    guard let (data, _) = try? await URLSession.shared.data(from: url),
                          let img = UIImage(data: data) else { return nil }
                    return (urlStr, img)
                }
            }
            for await result in group {
                if let (key, img) = result {
                    directCallNotifImages[key] = img
                }
            }
        }
    }

    private func fetchDirectCallBackground(for contact: ContactConfig) async {
        guard let urlStr = contact.imageURL,
              let url = URL(string: urlStr) else { return }
        if let (data, _) = try? await URLSession.shared.data(from: url),
           let img = UIImage(data: data) {
            directCallBackground = img
        }
    }
    
    func unlockPhone() {
        let generator = UIImpactFeedbackGenerator(style: .medium); generator.impactOccurred()
        withAnimation(.interpolatingSpring(stiffness: 180, damping: 20)) { lockScreenOffset = -screenHeight }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { isLocked = false; lockScreenOffset = 0 }
    }
    
    func lockPhone() {
        lockScreenOffset = -screenHeight; isLocked = true
        let generator = UIImpactFeedbackGenerator(style: .heavy); generator.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.interpolatingSpring(stiffness: 180, damping: 20)) { lockScreenOffset = 0 }
        }
    }
}
