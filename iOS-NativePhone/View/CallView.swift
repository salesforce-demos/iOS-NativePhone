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

    @StateObject private var callManager = CallManager()
    @State private var isSpeaker  = false
    @State private var isMuted    = false
    @State private var isFaceTime = false
    @State private var fetchedImage: UIImage? = nil
    
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
                    .frame(height: 70)
                    .background(Color.clear)
                    Spacer()
                }
                .frame(width: w, height: h, alignment: .top)

                // MARK: Contact info — top centered
                VStack(spacing: 3) {
                    callStatusText
                        .font(.system(size: 24, weight: .regular))
                        .foregroundStyle(.white.opacity(0.65))
                    Text(contact.name)
                        .font(.system(size: 68, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .padding(.top, safeTop - 300)
                .frame(maxWidth: .infinity, alignment: .top)
                
                // MARK: Controls — always at bottom
                VStack(spacing: 14) {
                    // Row 1
                    HStack(spacing: 0) {
                        callButton(
                            icon: isSpeaker ? "speaker.wave.3.fill" : "speaker.wave.2.fill",
                            label: "Audio",
                            active: isSpeaker,
                            width: w / 3
                        ) {
                            isSpeaker.toggle()
                            try? AVAudioSession.sharedInstance()
                                .overrideOutputAudioPort(isSpeaker ? .speaker : .none)
                        }
                        callButton(icon: "video.fill", label: "FaceTime", active: isFaceTime, width: w / 3) {
                            isFaceTime.toggle()
                        }
                        callButton(icon: "mic.slash.fill", label: "Mute", active: isMuted, width: w / 3) {
                            isMuted.toggle()
                        }
                    }

                    // Row 2
                    HStack(spacing: 0) {
                        callButton(icon: "ellipsis", label: "More", width: w / 3) {}

                        // End — red glass
                        Button {
                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                            callManager.endCall()
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: "phone.down.fill")
                                    .font(.system(size: 26, weight: .medium))
                                    .foregroundStyle(.white)
                                    .frame(width: 72, height: 72)
                                    .glassEffect(.regular.tint(.red).interactive(), in: Circle())
                                Text("End")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.white.opacity(0.75))
                            }
                        }
                        .frame(width: w / 3)

                        callButton(icon: "circle.grid.3x3.fill", label: "Keypad", width: w / 3) {}
                    }
                }
                .frame(width: w)
                .position(x: w / 2, y: h - safeBot - 130)
            }
            .frame(width: w, height: h)
        }
        .ignoresSafeArea()
        .task {
            callManager.startCall()
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
                // Show "Llamada finalizada" briefly before dismissing
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
        case .ringing:   Text("Calling mobile...")
        case .connected: Text(callManager.timerString)
        case .ended:     Text("Call ended")
        }
    }

    // MARK: - Generic call control button
    @ViewBuilder
    private func callButton(icon: String, label: String, active: Bool = false, width: CGFloat, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(active ? Color.black : .white)
                    .frame(width: 72, height: 72)
                    .glassEffect(
                        active ? .regular.tint(.white).interactive() : .regular.interactive(),
                        in: Circle()
                    )
                Text(label)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.75))
            }
        }
        .frame(width: width)
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
