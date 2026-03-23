//
//  PhoneViewModel.swift
//  NotificationLiquidGlass
//
//  Created by Andres Marin on 13/02/26.
//

import SwiftUI

class PhoneViewModel: ObservableObject {
    @Published var statusBarChatView: StatusBarSettings? = nil
    @Published var contacts: [ContactConfig] = []
    @Published var contactImages: [Int: UIImage] = [:]

    private var isDataLoaded = false

    func loadData() {
        guard !isDataLoaded else { return }

        NetworkService.shared.fetchChatConfig { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success(let config):
                    self.statusBarChatView = config.statusBar?.chatview
                    self.contacts = config.contacts ?? []
                    self.isDataLoaded = true
                    // Preload background images immediately after contacts load
                    Task { await self.preloadImages(for: self.contacts) }
                case .failure(let error):
                    print("Error loading phone view config: \(error.localizedDescription)")
                }
            }
        }
    }

    @MainActor
    private func preloadImages(for contacts: [ContactConfig]) async {
        for contact in contacts {
            guard let urlStr = contact.imageURL,
                  let url = URL(string: urlStr),
                  contactImages[contact.id] == nil else { continue }
            if let (data, _) = try? await URLSession.shared.data(from: url),
               let img = UIImage(data: data) {
                contactImages[contact.id] = img
            }
        }
    }
}
