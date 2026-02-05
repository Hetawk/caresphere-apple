import SwiftUI

/// Message row component for list display
struct MessageRow: View {
    @EnvironmentObject private var theme: CareSphereTheme
    let message: Message

    var body: some View {
        VStack(alignment: .leading, spacing: CareSphereSpacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    if let subject = message.subject {
                        Text(subject)
                            .font(CareSphereTypography.bodyMedium)
                            .foregroundColor(theme.colors.onBackground)
                    }

                    Text(message.content)
                        .font(CareSphereTypography.bodySmall)
                        .foregroundColor(theme.colors.onSurface.opacity(0.7))
                        .lineLimit(2)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    CareSphereStatusBadge(
                        message.status.displayName,
                        color: statusColor(for: message.status),
                        size: .small
                    )

                    Text("\(message.recipientCount) recipients")
                        .font(CareSphereTypography.caption)
                        .foregroundColor(theme.colors.onSurface.opacity(0.6))
                }
            }

            HStack {
                Image(systemName: message.channel.icon)
                    .foregroundColor(theme.colors.primary)

                Text(message.channel.displayName)
                    .font(CareSphereTypography.caption)
                    .foregroundColor(theme.colors.onSurface.opacity(0.6))

                Spacer()

                if let sentAt = message.sentAt {
                    Text(sentAt, style: .relative)
                        .font(CareSphereTypography.caption)
                        .foregroundColor(theme.colors.onSurface.opacity(0.6))
                } else {
                    Text(message.createdAt, style: .relative)
                        .font(CareSphereTypography.caption)
                        .foregroundColor(theme.colors.onSurface.opacity(0.6))
                }
            }
        }
        .padding(.vertical, CareSphereSpacing.xs)
    }

    private func statusColor(for status: MessageStatus) -> CareSphereStatusBadge.StatusColor {
        switch status {
        case .sent: return .success
        case .failed: return .error
        case .scheduled: return .primary
        case .sending: return .warning
        case .draft: return .secondary
        case .cancelled: return .secondary
        }
    }
}
