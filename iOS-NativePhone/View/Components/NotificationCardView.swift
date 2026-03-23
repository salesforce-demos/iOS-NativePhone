//
//  NotificationCardView.swift
//  NotificationLiquidGlass
//
//  Created by Andres Marin on 19/02/26.
//


import SwiftUI

@available(iOS 26.0, *)
public struct NotificationCardView: View {

    let notif: LockScreenNotification

    public var body: some View {
        HStack(alignment: .center, spacing: 12) {

            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(notif.iconColor)
                .frame(width: 38, height: 38)
                .overlay(
                    Image(systemName: notif.iconName)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.white)
                )

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline) {
                    Text(notif.appName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(notif.timeAgo)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
                Text(notif.message)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(2)
            }

        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(nil, value: notif.id)
        .glassEffect(.clear.interactive(), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .glassEffectTransition(.matchedGeometry)
        .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
    }
}
