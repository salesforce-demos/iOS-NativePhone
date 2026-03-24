//
//  RootView.swift
//  NotificationLiquidGlass
//
//  Created by Andres Marin on 13/02/26.
//

import Foundation
import SwiftUI

struct RootView: View {
    @StateObject private var lockVM = LockScreenViewModel()
    @State private var lockScreenOffset: CGFloat = 0
    @State private var isLocked: Bool = true
    @State private var isConfigured: Bool = false
    @State private var chatServiceURL: String = ""
    
    let screenHeight = UIScreen.main.bounds.height
    
    var progress: Double {
        let percentage = -lockScreenOffset / screenHeight
        return max(0, min(percentage, 1))
    }
    
    var body: some View {
        ZStack {
            if !isConfigured {
                // CONFIGURACIÓN INICIAL
                URLConfigurationView(
                    chatServiceURL: $chatServiceURL,
                    isConfigured: $isConfigured
                )
                .transition(.opacity)
                .zIndex(2)
            } else {
                // CHAT
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
            // Cargar URL guardada desde UserDefaults
            if let savedURL = UserDefaults.standard.string(forKey: "chatServiceURL"), !savedURL.isEmpty {
                chatServiceURL = savedURL
                // Opcional: auto-configurar si ya existe una URL guardada
                // isConfigured = true
            }
        }
        .onChange(of: isConfigured) { oldValue, newValue in
            if newValue {
                // Configurar la URL del servicio cuando se confirma
                NetworkService.shared.baseURL = chatServiceURL
            }
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
