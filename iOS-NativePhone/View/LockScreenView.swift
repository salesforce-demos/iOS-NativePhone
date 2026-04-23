//
//  LockScreenView.swift
//  NotificationLiquidGlass
//
//  Created by Andres Marin on 13/02/26.
//

import SwiftUI

@available(iOS 26.0, *)
struct LockScreenView: View {

    @ObservedObject var viewModel: LockScreenViewModel
    @Binding var offset:  CGFloat
    @Binding var opacity: Double

    @State private var isFlashlightOn  = false
    @State private var dateTapScale: CGFloat = 1.0
    @Namespace private var ns

    private let clock = Timer.publish(every: 1, tolerance: 0.1, on: .main, in: .common).autoconnect()
    @State private var currentTime = Date()

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: currentTime)
    }
    private var dateString: String {
        currentTime.formatted(.dateTime.weekday(.wide).day().month()).capitalized
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            content
            
            StatusBar(
                carrier: viewModel.statusBarLockScreen?.carrier ?? "T-Mobile",
                signalBars: viewModel.statusBarLockScreen?.signalBars ?? 2,
                wifiStrength: viewModel.statusBarLockScreen?.wifiStrength ?? 3,
                showWifi: viewModel.statusBarLockScreen?.showWifi ?? true,
                foregroundColor: .white,
                isLockScreen: true,
                levelBattery: viewModel.statusBarLockScreen?.levelBattery ?? 0.4,
                isCharging: viewModel.statusBarLockScreen?.isCharging ?? true
            )
            .frame(height: 70)
            .background(Color.clear)
        }
        .ignoresSafeArea(edges: .top)
        .onAppear {
            viewModel.loadData()
        }
    }

    var content: some View {
        ZStack {

            // MARK: Wallpaper
            Group {
               if UIImage(named: "iOS26") != nil {
                Image("iOS26").resizable().scaledToFill()
                } else {
                    LinearGradient(
                        colors: [.indigo, Color(red: 0.4, green: 0.1, blue: 0.7), .blue],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                }
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {

                // ── Botón candado
                Button(action: { viewModel.addNotification() }) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                        .padding(20)
                        .contentShape(Rectangle())
                }
                .padding(.top, 40)
                .opacity(opacity)

                // Reloj
                VStack(spacing: -60) {
                    Button(action: { bounceDate(); viewModel.addNotification() }) {
                        Text(dateString)
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 7)
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.clear.interactive(), in: Capsule(style: .continuous))
                    .glassEffectID("date", in: ns)
                    .scaleEffect(dateTapScale)

                    Rectangle()
                        .fill(.clear)
                        .glassEffect(
                            .regular,
                            in: TextShape(
                                text: AttributedString(
                                    timeString,
                                    attributes: .init().font(.systemFont(ofSize: 110, weight: .semibold))
                                )
                            )
                        )
                        .environment(\.colorScheme, .light)
                    
                }
                .padding(.bottom, 20)
                .opacity(opacity)

               
                ScrollView(showsIndicators: false) {
                    GlassEffectContainer(spacing: 10) {
                        VStack(spacing: 10) {
                            ForEach(viewModel.notifications.reversed()) { notif in
                                NotificationCardView(notif: notif)
                                    .glassEffectID(notif.id.uuidString, in: ns)
                            }
                        }
                        .padding(.horizontal, 10)
                    }
                }
                .defaultScrollAnchor(.bottom)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .opacity(opacity)

                Spacer().frame(height: 20)

                // Botones inferiores
                GlassEffectContainer(spacing: 200) {
                    HStack {
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                                isFlashlightOn.toggle()
                            }
                        } label: {
                            Image(systemName: isFlashlightOn
                                  ? "flashlight.on.fill" : "flashlight.off.fill")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundStyle(.white)
                                .frame(width: 58, height: 58)
                                .contentTransition(.symbolEffect(.replace))
                        }
                        .buttonStyle(.plain)
                        .glassEffect(
                            isFlashlightOn
                                ? .clear.tint(.yellow.opacity(0.5)).interactive()
                                : .clear.interactive(),
                            in: Circle()
                        )
                        .glassEffectID("flashlight", in: ns)

                        Spacer()

                        Button { } label: {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundStyle(.white)
                                .frame(width: 58, height: 58)
                        }
                        .buttonStyle(.plain)
                        .glassEffect(.clear.interactive(), in: Circle())
                        .glassEffectID("camera", in: ns)
                    }
                    .padding(.horizontal, 46)
                }
                .padding(.bottom, 50)
                .opacity(opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onReceive(clock) { date in
            
            // Align to the start of each second for better precision
            let nextSecond = Calendar.current.date(bySetting: .nanosecond, value: 0, of: date) ?? date
            currentTime = nextSecond
        }
    }

    private func bounceDate() {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.45)) { dateTapScale = 0.88 }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.55).delay(0.12)) { dateTapScale = 1.0 }
    }
}

 
@available(iOS 26.0, *)
#Preview("Lock Screen") {
    LockScreenView(
        viewModel: LockScreenViewModel(),
        offset:  .constant(0),
        opacity: .constant(1.0)
    )
}
