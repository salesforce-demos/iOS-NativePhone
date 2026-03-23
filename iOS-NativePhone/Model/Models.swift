//
//  Models.swift
//  NotificationLiquidGlass
//
//  Created by Andres Marin on 13/02/26.
//

import Foundation

// MARK: - Root Model
struct AppConfig: Codable {
    let configName: String
    let statusBar: StatusBarConfig?
    let notifications: [NotificationConfig]?
    let contacts: [ContactConfig]?
}

// MARK: - Contact Config
struct ContactConfig: Codable, Identifiable {
    let id: Int
    let name: String
    let avatar: String?
    let imageURL: String?
}

// MARK: - StatusBar Config
struct StatusBarConfig: Codable {
    let lockscreen: StatusBarSettings?
    let chatview: StatusBarSettings?
}

struct StatusBarSettings: Codable {
    let carrier: String?
    let signalBars: Int?
    let wifiStrength: Int?
    let showWifi: Bool?
    let levelBattery: Double?
    let isCharging: Bool?
}

// MARK: - Notification Config
struct NotificationConfig: Codable, Identifiable {
    let id: UUID
    let appName: String?
    let iconName: String?
    let iconColor: String?
    let title: String?
    let message: String?
    let timeAgo: String?
    
    // CodingKeys para excluir 'id' del JSON
    enum CodingKeys: String, CodingKey {
        case appName, iconName, iconColor, title, message, timeAgo
    }
    
    // Decoder personalizado para generar el ID
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.appName = try container.decodeIfPresent(String.self, forKey: .appName)
        self.iconName = try container.decodeIfPresent(String.self, forKey: .iconName)
        self.iconColor = try container.decodeIfPresent(String.self, forKey: .iconColor)
        self.title = try container.decodeIfPresent(String.self, forKey: .title)
        self.message = try container.decodeIfPresent(String.self, forKey: .message)
        self.timeAgo = try container.decodeIfPresent(String.self, forKey: .timeAgo)
    }
    
    // Encoder personalizado
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(appName, forKey: .appName)
        try container.encodeIfPresent(iconName, forKey: .iconName)
        try container.encodeIfPresent(iconColor, forKey: .iconColor)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(message, forKey: .message)
        try container.encodeIfPresent(timeAgo, forKey: .timeAgo)
    }
}

struct DailyMessages: Codable {
    let day: String?
    let messages: [JSONMessage]?
    let shown: Bool?
}

// MARK: - Message Model
struct JSONMessage: Codable, Identifiable {
    var id: UUID { UUID() } // Generado localmente
    
    let replaceByNextMessage: Bool?
    let component: String?
    let day: String?
    let sendTime: String?
    let imageURL: String?
    let imageSource: String?
    let messageShown: Bool?
    let order: Int?
    let text: String?
    let sendAutimatically: Bool? // Nota: en el JSON dice "sendAutimatically"
    let sender: String? // "Agent", "Customer", "Bot"
    let options: [MessageOption]?
    let actions: [MessageAction]?
    
    // Helpers
    var isCurrentUser: Bool {
        return sender == "Customer"
    }
    
    var contentText: String {
        return text ?? ""
    }
    
    var shouldAutoSend: Bool {
        return sendAutimatically ?? false
    }
    
    var hasOptions: Bool {
        return !(options?.isEmpty ?? true)
    }
    
    var hasActions: Bool {
        return !(actions?.isEmpty ?? true)
    }
}

// MARK: - Message Options (para las opciones seleccionables)
struct MessageOption: Codable, Identifiable, Equatable {
    var id: UUID { UUID() }
    
    let text: String?
    let order: Int?
    let imageURL: String?
    let isSelectable: Bool?
    let selected: Bool?
    
    var displayText: String {
        return text ?? ""
    }
    
    // Conformidad a Equatable (comparación sin el id)
    static func == (lhs: MessageOption, rhs: MessageOption) -> Bool {
        return lhs.text == rhs.text &&
               lhs.order == rhs.order &&
               lhs.imageURL == rhs.imageURL &&
               lhs.isSelectable == rhs.isSelectable &&
               lhs.selected == rhs.selected
    }
}

// MARK: - Message Actions
struct MessageAction: Codable, Identifiable, Equatable {
    var id: UUID { UUID() }
    
    let name: String?
    let delayMS: Int?
    let actionType: String? // "Send Chat Item", etc.
    let parameter: String?
    let showSpinner: Bool?
    
    // Conformidad a Equatable (comparación sin el id)
    static func == (lhs: MessageAction, rhs: MessageAction) -> Bool {
        return lhs.name == rhs.name &&
               lhs.delayMS == rhs.delayMS &&
               lhs.actionType == rhs.actionType &&
               lhs.parameter == rhs.parameter &&
               lhs.showSpinner == rhs.showSpinner
    }
}

// Modelo interno para la UI del Chat
struct UIMessage: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let isCurrentUser: Bool
    let timestamp: Date
    let imageURL: String?
    let options: [MessageOption]?
    
    // Inicializador con valores por defecto
    init(text: String, isCurrentUser: Bool, timestamp: Date = Date(), imageURL: String? = nil, options: [MessageOption]? = nil) {
        self.text = text
        self.isCurrentUser = isCurrentUser
        self.timestamp = timestamp
        self.imageURL = imageURL
        self.options = options
    }
    
    // Conformidad a Equatable (comparación sin el id)
    static func == (lhs: UIMessage, rhs: UIMessage) -> Bool {
        return lhs.text == rhs.text &&
               lhs.isCurrentUser == rhs.isCurrentUser &&
               lhs.timestamp == rhs.timestamp &&
               lhs.imageURL == rhs.imageURL &&
               lhs.options == rhs.options
    }
}
