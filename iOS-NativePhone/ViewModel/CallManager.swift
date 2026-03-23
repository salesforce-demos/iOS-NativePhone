//
//  CallManager.swift
//  NotificationLiquidGlass
//
//  Created by Andres Marin on 20/03/26.
//

import SwiftUI
import AVFoundation

// MARK: - Call State
enum CallState {
    case ringing   // Playing ringtone
    case connected // Timer running
    case ended     // Dismissed
}

// MARK: - CallManager
@MainActor
class CallManager: ObservableObject {
    @Published var state: CallState = .ringing
    @Published var elapsedSeconds: Int = 0

    private var audioPlayer: AVAudioPlayer?
    private var timerTask: Task<Void, Never>?

    // MARK: Start call
    func startCall() {
        state = .ringing
        elapsedSeconds = 0
        playRingtone()
    }

    // MARK: End call
    func endCall() {
        stopRingtone()
        timerTask?.cancel()
        timerTask = nil
        state = .ended
    }

    // MARK: Formatted timer
    var timerString: String {
        let m = elapsedSeconds / 60
        let s = elapsedSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    // MARK: - Play ringtone from bundle
    private func playRingtone() {
        guard let url = Bundle.main.url(forResource: "ringing", withExtension: "m4a") else {
            print("CallManager: ringing.m4a not found in bundle, connecting immediately")
            state = .connected
            timerTask = Task { await startTimer() }
            return
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = 0
            audioPlayer?.volume = 1.0
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()

            let ringDuration = audioPlayer?.duration ?? 2.0
            timerTask = Task {
                try? await Task.sleep(nanoseconds: UInt64(ringDuration * 1_000_000_000))
                guard !Task.isCancelled else { return }
                stopRingtone()
                state = .connected
                await startTimer()
            }
        } catch {
            print("CallManager audio error: \(error)")
            state = .connected
            timerTask = Task { await startTimer() }
        }
    }

    private func stopRingtone() {
        audioPlayer?.stop()
        audioPlayer = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func startTimer() async {
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard !Task.isCancelled else { break }
            elapsedSeconds += 1
        }
    }
}
