//
//  LiquidText.swift
//  NotificationLiquidGlass
//
//  Created by Andres Marin on 17/02/26.
//
//

import SwiftUI

struct LiquidText: View {
    let text: String
    var fontSize: CGFloat = 120

    private var baseFont: Font {
        .system(size: fontSize, weight: .heavy, design: .default)
    }

    private var maskText: some View {
        Text(text)
            .font(baseFont)
            .monospacedDigit() // comportamiento estilo reloj
    }

    var body: some View {
        ZStack {

            // Glass fill
            Rectangle()
                .fill(.ultraThinMaterial)
                .mask(maskText)
                .shadow(color: .black.opacity(0.10), radius: 12, x: 0, y: 10)

            // Subtle rim
            maskText
                .foregroundStyle(.clear)
                .overlay {
                    LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0.35), location: 0.00),
                            .init(color: .white.opacity(0.10), location: 0.35),
                            .init(color: .clear,              location: 0.75)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .mask(
                        maskText
                            .padding(-1.2)
                            .background(Color.black)
                            .compositingGroup()
                            .luminanceToAlpha()
                    )
                }
                .blendMode(.overlay)

            // Soft highlight
            maskText
                .foregroundStyle(
                    LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0.30), location: 0.00),
                            .init(color: .white.opacity(0.10), location: 0.22),
                            .init(color: .clear,              location: 0.50)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .mask(maskText)
                .blendMode(.plusLighter)

            // Subtle bottom lift
            maskText
                .foregroundStyle(
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.16)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .offset(y: 2)
                .blur(radius: 2)
                .mask(maskText)
                .blendMode(.overlay)
        }
        .compositingGroup()
        .accessibilityLabel(Text(text))
    }
}

// MARK: - Preview
struct LiquidTextPreview: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            GeometryReader { geo in
                ZStack {
                    Color.black

                    Circle()
                        .fill(.blue)
                        .frame(width: 300, height: 300)
                        .blur(radius: 60)
                        .offset(x: animate ? -100 : 100, y: animate ? -100 : 50)

                    Circle()
                        .fill(.purple)
                        .frame(width: 300, height: 300)
                        .blur(radius: 60)
                        .offset(x: animate ? 100 : -100, y: animate ? 100 : -50)

                    Circle()
                        .fill(.orange)
                        .frame(width: 200, height: 200)
                        .blur(radius: 50)
                        .offset(y: animate ? 200 : -200)
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .onAppear {
                    withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                        animate.toggle()
                    }
                }
            }
            .ignoresSafeArea()

            VStack(spacing: 40) {
                LiquidText(text: "iOS", fontSize: 120)
                LiquidText(text: "Glass", fontSize: 120)
            }
        }
    }
}

#Preview {
    LiquidTextPreview()
}
