//
//  CallView.swift
//  iOS-NativePhone
//

import SwiftUI
import AVFoundation

@available(iOS 26.0, *)
struct CallView: View {
    let contact: ContactConfig
    var preloadedBackground: UIImage? = nil
    var onEnd: () -> Void
    let statusBarPhoneView: StatusBarSettings?
    /// Si true, la llamada no inicia automáticamente; espera tap en el nombre del contacto.
    var waitForTap: Bool = false
    var callNotifications: [NotificationConfig] = []
    var notificationImages: [String: UIImage] = [:]

    @Environment(\.localizationBundle) private var bundle

    @StateObject private var callManager = CallManager()
    @State private var isSpeaker  = false
    @State private var isMuted    = false
    @State private var isFaceTime = false
    @State private var fetchedImage: UIImage? = nil
    @State private var callStarted: Bool = false

    // In-call notification
    @State private var activeNotification: NotificationConfig? = nil
    @State private var notifVisible: Bool = false
    @State private var notifIndex: Int = 0
    @State private var dismissTask: Task<Void, Never>? = nil
    @Namespace private var notifNS
    
    // Propiedades para el StatusBar
    @State private var currentTime = Date()
    private let clock = Timer.publish(every: 1, tolerance: 0.1, on: .main, in: .common).autoconnect()

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: currentTime)
    }

    private var bgImage: UIImage? { preloadedBackground ?? fetchedImage }

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            let safeTop = proxy.safeAreaInsets.top
            let safeBot = proxy.safeAreaInsets.bottom

            ZStack {
                // MARK: Background
                Group {
                    if let img = bgImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: w, height: h)
                            .clipped()
                    } else {
                        Color(red: 0.12, green: 0.10, blue: 0.10)
                    }
                }
                .frame(width: w, height: h)

                // MARK: Status Bar
                VStack {
                    StatusBar(
                        carrier: timeString,
                        signalBars: statusBarPhoneView?.signalBars ?? 4,
                        wifiStrength: statusBarPhoneView?.wifiStrength ?? 3,
                        showWifi: statusBarPhoneView?.showWifi ?? true,
                        foregroundColor: .white,
                        isLockScreen: true,
                        levelBattery: statusBarPhoneView?.levelBattery ?? 0.8,
                        isCharging: statusBarPhoneView?.isCharging ?? false
                    )
                    .frame(height: 75)
                    .background(Color.clear)
                    Spacer()
                }
                .frame(width: w, height: h, alignment: .top)

                // MARK: Contact info — top centered
                VStack(spacing: 3) {
    
                    callStatusText
                        .font(.system(size: 24, weight: .regular))
                        .foregroundStyle(.white.opacity(0.65))
                
                    if waitForTap && !callStarted {
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            callStarted = true
                            callManager.startCall()
                        } label: {
                            Text(contact.name)
                                .font(.system(size: 52, weight: .semibold))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                                .padding(.horizontal, 40)
                                .padding(.vertical, 20)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(NoFeedbackButtonStyle())
                    } else {
                        Text(contact.name)
                            .font(.system(size: 52, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 20)
                            .contentShape(Rectangle())
                    }
                }
                .padding(.top, safeTop - 330)
                .frame(maxWidth: .infinity, alignment: .top)
                
                // MARK: Controls — always at bottom
                GlassEffectContainer(spacing: 20) {
                    VStack(spacing: 14) {
                        // Row 1
                        HStack(spacing: 0) {
                            callButton(
                                icon: isSpeaker ? "speaker.wave.3.fill" : "speaker.wave.2.fill",
                                label: String(localized: "Audio", bundle: bundle),
                                active: isSpeaker,
                                width: w / 3
                            ) {
                                isSpeaker.toggle()
                                try? AVAudioSession.sharedInstance()
                                    .overrideOutputAudioPort(isSpeaker ? .speaker : .none)
                            }
                            callButton(icon: "video.fill", label: String(localized: "FaceTime", bundle: bundle), active: isFaceTime, width: w / 3) {
                                isFaceTime.toggle()
                            }
                            callButton(icon: "mic.slash.fill", label: String(localized: "Mute", bundle: bundle), active: isMuted, width: w / 3) {
                                isMuted.toggle()
                            }
                        }

                        // Row 2
                        HStack(spacing: 0) {
                            callButton(icon: "ellipsis", label: String(localized: "More", bundle: bundle), width: w / 3, silent: true) {
                                showNextNotification()
                            }

                            // End — red glass
                            Button {
                                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                                callManager.endCall()
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: "phone.down.fill")
                                        .font(.system(size: 26, weight: .medium))
                                        .foregroundStyle(.white)
                                        .frame(width: 85, height: 85)
                                        .glassEffect(.clear.tint(.red).interactive(), in: Circle())
                                    Text(String(localized: "End", bundle: bundle))
                                        .font(.system(size: 13))
                                        .foregroundStyle(.white.opacity(0.75))
                                }
                            }
                            .frame(width: w / 3)

                            callButton(icon: "circle.grid.3x3.fill", label: String(localized: "Keypad", bundle: bundle), width: w / 3) {}
                        }
                    }
                }
                .frame(width: w)
                .position(x: w / 2, y: h - safeBot - 160)

                // MARK: In-call notification banner — siempre en el árbol
                VStack {
                    GlassEffectContainer(spacing: 0) {
                        HStack(alignment: .center, spacing: 12) {
                            // Ícono app
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(parseNotifColor(activeNotification?.iconColor ?? "#25D366"))
                                .frame(width: 40, height: 40)
                                .overlay {
                                    if let imgName = activeNotification?.imageName,
                                       let uiImg = UIImage(named: imgName) {
                                        Image(uiImage: uiImg)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 40, height: 40)
                                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    } else {
                                        Image(systemName: activeNotification?.iconName ?? "bell.fill")
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundStyle(.white)
                                    }
                                }

                            // Texto central
                            VStack(alignment: .leading, spacing: 2) {
                                Text(activeNotification?.title ?? "")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                                Text(activeNotification?.message ?? "")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.white.opacity(0.85))
                                    .lineLimit(2)
                            }

                            // Hora + miniatura de documento (solo si documentIcon tiene valor)
                            if let docValue = activeNotification?.documentIcon, !docValue.isEmpty {
                                VStack(alignment: .trailing, spacing: 6) {
                                    Text(activeNotification?.timeAgo ?? "now")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.white.opacity(0.55))
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(Color.white.opacity(0.15))
                                        .frame(width: 44, height: 44)
                                        .overlay {
                                            if let url = URL(string: docValue),
                                               url.scheme == "https" || url.scheme == "http" {
                                                if let cached = notificationImages[docValue] {
                                                    Image(uiImage: cached)
                                                        .resizable().scaledToFill()
                                                        .frame(width: 44, height: 44)
                                                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                                } else {
                                                    Image(systemName: "photo")
                                                        .font(.system(size: 18))
                                                        .foregroundStyle(.white.opacity(0.5))
                                                        .frame(width: 44, height: 44)
                                                }
                                            } else {
                                                Image(systemName: docValue)
                                                    .font(.system(size: 20))
                                                    .foregroundStyle(.white.opacity(0.7))
                                            }
                                        }
                                }
                            } else {
                                Text(activeNotification?.timeAgo ?? "now")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.white.opacity(0.55))
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .glassEffect(.clear.tint(.black.opacity(0.35)), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    }
                    .environment(\.colorScheme, .dark)
                    .padding(.horizontal, 16)
                    .padding(.top, 75)
                    Spacer()
                }
                .opacity(notifVisible ? 1 : 0)
                .offset(y: notifVisible ? 0 : -120)
                .zIndex(10)
            }
            .frame(width: w, height: h)
        }
        .ignoresSafeArea()
        .task {
            if !waitForTap {
                callManager.startCall()
            }
            guard preloadedBackground == nil,
                  let urlStr = contact.imageURL,
                  let url = URL(string: urlStr) else { return }
            if let (data, _) = try? await URLSession.shared.data(from: url),
               let img = UIImage(data: data) {
                fetchedImage = img
            }
        }
        .onChange(of: callManager.state) { _, state in
            if state == .ended {
                Task {
                    try? await Task.sleep(nanoseconds: 1_300_000_000)
                    onEnd()
                }
            }
        }
        .onReceive(clock) { date in
            let nextSecond = Calendar.current.date(bySetting: .nanosecond, value: 0, of: date) ?? date
            currentTime = nextSecond
        }
    }

    // MARK: - Status text
    @ViewBuilder
    private var callStatusText: some View {
        switch callManager.state {
        case .ringing:   Text(String(localized: "Calling mobile...", bundle: bundle))
        case .connected: Text(callManager.timerString)
        case .ended:     Text(String(localized: "Call ended", bundle: bundle))
        }
    }

    // MARK: - Show in-call notification
    private func showNextNotification() {
        guard !callNotifications.isEmpty else { return }
        // Cancel any pending auto-dismiss before transitioning
        dismissTask?.cancel()
        dismissTask = nil

        if notifVisible {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.85)) { notifVisible = false }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) { triggerNotif() }
        } else {
            triggerNotif()
        }
    }

    private func triggerNotif() {
        let notif = callNotifications[notifIndex % callNotifications.count]
        notifIndex += 1
        activeNotification = notif
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) { notifVisible = true }
        // Store the Task so it can be cancelled if More is tapped again
        dismissTask = Task {
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.85)) { notifVisible = false }
            }
        }
    }

    /// UILabel-backed text view that renders emojis correctly inside glassEffect contexts

    private func parseNotifColor(_ hex: String) -> Color {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: h).scanHexInt64(&rgb)
        return Color(
            red:   Double((rgb & 0xFF0000) >> 16) / 255,
            green: Double((rgb & 0x00FF00) >>  8) / 255,
            blue:  Double( rgb & 0x0000FF       ) / 255
        )
    }

    // MARK: - Generic call control button
    @ViewBuilder
    private func callButton(icon: String, label: String, active: Bool = false, width: CGFloat, silent: Bool = false, action: @escaping () -> Void) -> some View {
        let content = VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(active ? Color.black : .white)
                .frame(width: 85, height: 85)
                .contentShape(Circle())
                .glassEffect(
                    silent ? .clear : (active ? .clear.interactive() : .clear.interactive()),
                    in: Circle()
                )
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.75))
        }
        if silent {
            Button { action() } label: { content }
                .buttonStyle(NoFeedbackButtonStyle())
                .frame(width: width)
        } else {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                action()
            } label: { content }
                .frame(width: width)
        }
    }
}

// MARK: - No visual feedback button style
private struct NoFeedbackButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

// MARK: - Preview
@available(iOS 26.0, *)
#Preview("Call Screen") {
    CallView(
        contact: ContactConfig(
            id: 1,
            name: "AARP",
            avatar: "https://ui-avatars.com/api/?name=AARP&background=E11B22&color=fff&bold=true",
            imageURL: "https://images.unsplash.com/photo-1579546929518-9e396f3cc809?auto=format&fit=crop&w=800&q=80"
        ),
        onEnd: {},
        statusBarPhoneView: StatusBarSettings(
            carrier: "T-Mobile",
            signalBars: 4,
            wifiStrength: 3,
            showWifi: true,
            levelBattery: 0.8,
            isCharging: false
        )
    )
}
