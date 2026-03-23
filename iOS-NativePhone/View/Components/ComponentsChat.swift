//
//  ComponentsChat.swift
//  NotificationLiquidGlass
//
//  Created by Andres Marin on 13/02/26.
//
import SwiftUI

struct MessageBubble: View {
    let message: UIMessage
    var isLastInGroup: Bool = true
    var onOptionSelected: ((MessageOption) -> Void)? = nil

    private var bubbleColor: Color {
        message.isCurrentUser
            ? Color(red: 0.059, green: 0.561, blue: 0.996)
            : Color(red: 0.914, green: 0.914, blue: 0.918)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            if message.isCurrentUser { Spacer(minLength: 60) }

            VStack(alignment: message.isCurrentUser ? .trailing : .leading, spacing: 4) {
                if let imageURL = message.imageURL, !imageURL.isEmpty {
                    AsyncImage(url: resolveImageURL(rawPath: imageURL)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView().frame(width: 200, height: 150)
                        case .success(let image):
                            image.resizable().scaledToFill()
                                .frame(maxWidth: 240, maxHeight: 240)
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                        case .failure:
                            Image(systemName: "photo")
                                .font(.system(size: 40)).foregroundColor(.gray)
                                .frame(width: 200, height: 150)
                                .background(Color.gray.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                        @unknown default: EmptyView()
                        }
                    }
                }

                if !message.text.isEmpty {
                    Text(message.text)
                        .foregroundColor(message.isCurrentUser ? .white : .black)
                        .font(.system(size: 18))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(bubbleColor)
                        .clipShape(
                            MessageBubbleShape(
                                isCurrentUser: message.isCurrentUser,
                                showTail: isLastInGroup
                            )
                        )
                }

                if let options = message.options, !options.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(options) { option in
                            MessageOptionView(option: option) {
                                onOptionSelected?(option)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }

            if !message.isCurrentUser { Spacer(minLength: 60) }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
    }

    private func resolveImageURL(rawPath: String) -> URL? {
        if rawPath.hasPrefix("http") { return URL(string: rawPath) }
        var cleanPath = rawPath
        if cleanPath.hasPrefix("..") { cleanPath = String(cleanPath.dropFirst(2)) }
        if !cleanPath.hasPrefix("/") { cleanPath = "/" + cleanPath }
        let baseURL = NetworkService.shared.baseURL
        if let url = URL(string: baseURL) {
            let scheme = url.scheme ?? "https"
            let host = url.host ?? ""
            let pathComponents = url.pathComponents.filter { $0 != "/" }
            var basePath = ""
            for component in pathComponents {
                if component.lowercased() == "resource" || component.contains(".json") { break }
                basePath += "/\(component)"
            }
            return URL(string: "\(scheme)://\(host)\(basePath)\(cleanPath)")
        }
        return URL(string: rawPath)
    }
}

struct MessageBubbleShape: Shape {
    let isCurrentUser: Bool
    let showTail: Bool

    func path(in rect: CGRect) -> Path {
        var p = bubblePath(in: rect)
        if !isCurrentUser {
            p = p.applying(CGAffineTransform(scaleX: -1, y: 1).concatenating(
                CGAffineTransform(translationX: rect.width, y: 0)
            ))
        }
        return p
    }

    private func bubblePath(in rect: CGRect) -> Path {
        let cornerRadius: CGFloat = 18
        let tailWidth: CGFloat = 8
        let tailHeight = cornerRadius
        let bubbleWidth = rect.width - tailWidth
        let tailEndpointX = (bubbleWidth - cornerRadius) + cornerRadius * cos(.pi / 4)
        let tailEndpointY = (rect.height - cornerRadius) + cornerRadius * sin(.pi / 4)

        var p = Path()

        p.move(to: CGPoint(x: cornerRadius, y: rect.minY))
        p.addLine(to: CGPoint(x: bubbleWidth - cornerRadius, y: rect.minY))
        p.addArc(
            center: CGPoint(x: bubbleWidth - cornerRadius, y: cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(-90),
            endAngle: .degrees(0),
            clockwise: false
        )
        p.addLine(to: CGPoint(x: bubbleWidth, y: rect.height - cornerRadius))

        if showTail {
            p.addQuadCurve(
                to: CGPoint(x: rect.width, y: rect.height),
                control: CGPoint(x: bubbleWidth, y: rect.height - tailHeight / 2)
            )
            p.addQuadCurve(
                to: CGPoint(x: tailEndpointX, y: tailEndpointY),
                control: CGPoint(x: bubbleWidth, y: rect.height)
            )
            p.addArc(
                center: CGPoint(x: bubbleWidth - cornerRadius, y: rect.height - cornerRadius),
                radius: cornerRadius,
                startAngle: .degrees(45),
                endAngle: .degrees(90),
                clockwise: false
            )
        } else {
            p.addArc(
                center: CGPoint(x: bubbleWidth - cornerRadius, y: rect.height - cornerRadius),
                radius: cornerRadius,
                startAngle: .degrees(0),
                endAngle: .degrees(90),
                clockwise: false
            )
        }

        p.addLine(to: CGPoint(x: cornerRadius, y: rect.height))
        p.addArc(
            center: CGPoint(x: cornerRadius, y: rect.height - cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(90),
            endAngle: .degrees(180),
            clockwise: false
        )
        p.addLine(to: CGPoint(x: rect.minX, y: cornerRadius))
        p.addArc(
            center: CGPoint(x: cornerRadius, y: cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(180),
            endAngle: .degrees(270),
            clockwise: false
        )
        p.closeSubpath()
        return p
    }
}

struct MessageOptionView: View {
    let option: MessageOption
    let onTap: () -> Void
    @State private var isSelected = false
    
    var body: some View {
        Button(action: {
            if option.isSelectable == true {
                withAnimation {
                    isSelected.toggle()
                    onTap()
                }
            }
        }) {
            HStack(spacing: 8) {
                if let imageURL = option.imageURL, !imageURL.isEmpty {
                    AsyncImage(url: URL(string: imageURL)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                                .cornerRadius(8)
                        default:
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 40, height: 40)
                                .cornerRadius(8)
                        }
                    }
                }
                
                Text(option.displayText)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(isSelected ? .white : .black)
                
                Spacer()
                
                if option.isSelectable == true {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .white : .gray)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color.gray.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
    }
}


struct TypingBubbleView: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            HStack(spacing: 6) {
                ForEach(0..<3) { index in
                    Circle()
                        .frame(width: 8, height: 8)
                        .foregroundColor(Color.gray.opacity(0.7))
                        .scaleEffect(isAnimating ? 1.0 : 0.5)
                        .opacity(isAnimating ? 1.0 : 0.4)
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(0.2 * Double(index)),
                            value: isAnimating
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(red: 0.914, green: 0.914, blue: 0.918))
            .clipShape(
                MessageBubbleShape(isCurrentUser: false, showTail: true)
            )
            
            Spacer(minLength: 60)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 1)
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview("MessageBubble Preview") {
    ScrollView {
        VStack(spacing: 10) {

            MessageBubble(
                message: UIMessage(
                    text: "Hola, ¿cómo estás?",
                    isCurrentUser: false,
                    timestamp: Date().addingTimeInterval(-120)
                )
            )
            MessageBubble(
                message: UIMessage(
                    text: "Estoy muy bien, gracias por preguntar. ¿Qué tal tu día? Espero que todo esté saliendo como lo planeaste.",
                    isCurrentUser: false,
                    timestamp: Date().addingTimeInterval(-60)
                ),
                isLastInGroup: false
            )
            MessageBubble(
                message: UIMessage(
                    text: "Aquí te dejo una foto.",
                    isCurrentUser: false,
                    timestamp: Date().addingTimeInterval(-30),
                    imageURL: "https://picsum.photos/id/237/200/200"
                )
            )

            MessageBubble(
                message: UIMessage(
                    text: "¿Qué opción prefieres?",
                    isCurrentUser: false,
                    timestamp: Date(),
                    options: [
                        MessageOption(text: "Opción A", order: nil, imageURL: nil, isSelectable: true, selected: false),
                        MessageOption(text: "Opción B", order: nil, imageURL: nil, isSelectable: true, selected: true),
                        MessageOption(text: "Opción C", order: nil, imageURL: nil, isSelectable: false, selected: nil)
                    ]
                )
            ) { selectedOption in
                print("Selected: \(selectedOption.displayText)")
            }

            MessageBubble(
                message: UIMessage(
                    text: "¡Hola! Estoy genial, ¿y tú?",
                    isCurrentUser: true,
                    timestamp: Date().addingTimeInterval(-150)
                )
            )

            MessageBubble(
                message: UIMessage(
                    text: "Todo va muy bien por aquí. Justo terminando un proyecto importante.",
                    isCurrentUser: true,
                    timestamp: Date().addingTimeInterval(-90)
                ),
                isLastInGroup: false
            )
            MessageBubble(
                message: UIMessage(
                    text: "Te mando un saludo.",
                    isCurrentUser: true,
                    timestamp: Date().addingTimeInterval(-45)
                )
            )

            MessageBubble(
                message: UIMessage(
                    text: "Mira esta imagen que tomé hoy.",
                    isCurrentUser: true,
                    timestamp: Date().addingTimeInterval(-10),
                    imageURL: "https://picsum.photos/id/1040/200/200"
                )
            )

            TypingBubbleView()
                .padding(.top, 20)
        }
        .background(Color.gray.opacity(0.1))
    }
}

