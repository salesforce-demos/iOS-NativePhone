//
//  LockScreenButton.swift
//  NotificationLiquidGlass
//
//  Created by Andres Marin on 17/02/26.
//


import SwiftUI

struct LockScreenButton: View {
    let icon: String
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // Acción simulada con vibración
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
            
            // Lógica de animación "Flash"
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation { isPressed = false }
            }
        }) {
            ZStack {
                     
                // CAPA 2: Gradiente "Líquido" (Da el volumen)
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.2), .white.opacity(0.0)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // CAPA 3: Borde de cristal (El reflejo en el borde)
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.5), .white.opacity(0.1), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                
                // Efecto de presion (Flash blanco)
                Circle()
                    .fill(.white)
                    .opacity(isPressed ? 1.0 : 0.0)
                
                // CAPA 5: Icono
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold)) // Un poco más grueso para legibilidad
                    .foregroundColor(isPressed ? .black : .white)
                    .shadow(radius: isPressed ? 0 : 2) // Sombra sutil en el icono para que flote
            }
            .frame(width: 50, height: 50)
            // Pequeña escala al presionar para dar sensación táctil física
            .scaleEffect(isPressed ? 0.92 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

struct LockScreenPreview: View {
    var body: some View {
        ZStack {
            Image("iOS26").resizable().scaledToFill().ignoresSafeArea()
            
            HStack(spacing: 50) {
                LockScreenButton(icon: "flashlight.off.fill")
                LockScreenButton(icon: "camera.fill")
            }
        }
    }
}

#Preview {
    LockScreenPreview()
}
