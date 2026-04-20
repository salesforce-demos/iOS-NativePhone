//
//  StatusBar.swift
//  NotificationLiquidGlass
//
//  Created by Andres Marin on 2/03/26.
//

import SwiftUI

// MARK: - StatusBar View
struct StatusBar: View {
    var carrier: String = "T-Mobile"
    var signalBars: Int = 4
    var wifiStrength: Int = 3
    var showWifi: Bool = true
    var foregroundColor: Color? = nil
    var isLockScreen: Bool = false
    var levelBattery: Double = 0.8
    var isCharging: Bool = false

    @Environment(\.colorScheme) private var colorScheme

    private var resolvedColor: Color {
        foregroundColor ?? (colorScheme == .dark ? .white : .black)
    }

    var body: some View {
        HStack(alignment: .center) {
            if !isLockScreen {
                HStack(spacing: 4) {
                    Spacer().frame(width: 15)
                    Text(carrier)
                        .font(.system(size: 15, weight: .semibold))
                    CellularSignalView(bars: signalBars, color: resolvedColor)
                }
                Spacer()
            } else {
                Spacer().frame(width: 15)
                HStack(spacing: 4) {
                    Text(carrier)
                        .font(.system(size: 15, weight: .semibold))
                }
                Spacer()
            }

            HStack {
                if isLockScreen {
                    CellularSignalView(bars: signalBars, color: resolvedColor)
                }
                if showWifi {
                    WifiSignalView(strength: wifiStrength)
                }
                BatteryView(level: levelBattery, isCharging: isCharging, color: resolvedColor)
            }
        }
        .foregroundColor(resolvedColor)
        .padding(.horizontal, 30)
        .frame(height: 40)
        .padding(.top, -13)
    }
}


// MARK: - Cellular Signal
struct CellularSignalView: View {
    var bars: Int  // 0-4
    var color: Color

    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(0..<4) { index in
                RoundedRectangle(cornerRadius: 1)
                    .frame(width: 3, height: CGFloat(5 + index * 3))
                    .opacity(index < bars ? 1.0 : 0.3)
            }
        }
        .foregroundColor(color)
    }
}


// MARK: - Battery
struct BatteryView: View {
    var level: CGFloat = 0.8    // 0.0 ... 1.0
    var isCharging: Bool = false
    var color: Color

    private let bodyWidth: CGFloat = 25
    private let bodyHeight: CGFloat = 12
    private let cornerRadius: CGFloat = 3.5
    private let pinWidth: CGFloat = 2.5
    private let pinHeight: CGFloat = 5
    private let inset: CGFloat = 1.5

    private var fillColor: Color {
        if isCharging { return .green }
        if level <= 0.2 { return .red }
        return color
    }

    var body: some View {
        HStack(spacing: 1) {
            ZStack(alignment: .leading) {
                // Outline
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(color.opacity(isCharging ? 0.4 : 1), lineWidth: 1.2)
                    .frame(width: bodyWidth, height: bodyHeight)

                // Fill bar
                RoundedRectangle(cornerRadius: cornerRadius - 1)
                    .fill(fillColor)
                    .frame(
                        width: max(0, (bodyWidth - inset * 2) * clampedLevel),
                        height: bodyHeight - inset * 2
                    )
                    .padding(.leading, inset)

                // Bolt icon when charging — split contrast
                if isCharging {
                    boltView
                }
            }

            // Battery pin (nub)
            RoundedRectangle(cornerRadius: 1)
                .fill(color.opacity(isCharging ? 0.4 : 1))
                .frame(width: pinWidth, height: pinHeight)
        }
    }

    private var clampedLevel: CGFloat {
        max(0, min(level, 1))
    }

    private var boltView: some View {
        let fillWidth = (bodyWidth - inset * 2) * clampedLevel + inset

        return ZStack {
            Image(systemName: "bolt.fill")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white)
                .frame(width: bodyWidth, height: bodyHeight)
 
            Image(systemName: "bolt.fill")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white)
                .frame(width: bodyWidth, height: bodyHeight)
                .clipShape(
                    Rectangle()
                        .offset(x: -(bodyWidth - fillWidth) / 2)
                        .size(width: fillWidth, height: bodyHeight)
                )
        }
    }
}



// MARK: Wifi Signal
struct WifiSignalView: View {
    var strength: Int  // 0-3

    private let size: CGFloat = 15

    var body: some View {
        Canvas { ctx, canvasSize in
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height - 1)

            let startAngle = Angle.degrees(225)
            let endAngle = Angle.degrees(315)
            let lineWidth: CGFloat = 2.8
            let style = StrokeStyle(lineWidth: lineWidth, lineCap: .round)

            let radii: [CGFloat] = [5.5, 10.5]
            for (index, radius) in radii.enumerated() {
                let arc = arcPath(center: center, radius: radius, start: startAngle, end: endAngle)
                let active = strength > (index + 1)
                ctx.opacity = active ? 1.0 : 0.3
                ctx.stroke(arc, with: .foreground, style: style)
                ctx.opacity = 1.0
            }

            let dotRadius: CGFloat = 1.8
            let dotRect = CGRect(
                x: center.x - dotRadius,
                y: center.y - dotRadius,
                width: dotRadius * 2,
                height: dotRadius * 2
            )
            ctx.opacity = strength >= 1 ? 1.0 : 0.3
            ctx.fill(Path(ellipseIn: dotRect), with: .foreground)
            ctx.opacity = 1.0
        }
        .frame(width: size, height: size)
        .foregroundStyle(.primary)
    }

    private func arcPath(center: CGPoint, radius: CGFloat, start: Angle, end: Angle) -> Path {
        var path = Path()
        path.addArc(center: center, radius: radius, startAngle: start, endAngle: end, clockwise: false)
        return path
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 0) {
        StatusBar(carrier: "CLARO", signalBars: 2, wifiStrength: 3, levelBattery: 0.3, isCharging: false)
            .background(Color.clear)

        Divider()

        StatusBar(carrier: "T-Mobile", signalBars: 2, wifiStrength: 2, foregroundColor: .white, levelBattery: 0.5, isCharging: true)
            .background(Color.black)

        Divider()

        StatusBar(carrier: "MOVISTAR", signalBars: 3, showWifi: false, levelBattery: 0.8, isCharging: true)
            .background(Color(UIColor.systemGray6))

        Divider()

        StatusBar(carrier: "MOVISTAR", signalBars: 3, wifiStrength: 1, isLockScreen: true, levelBattery: 0.15)
            .background(Color(UIColor.systemGray5))
    }
}

