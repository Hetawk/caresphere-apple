import SwiftUI

/// Row component for displaying a message template
struct TemplateRow: View {
    @EnvironmentObject private var theme: CareSphereTheme
    let template: MessageTemplate

    var body: some View {
        CareSphereCard {
            VStack(alignment: .leading, spacing: CareSphereSpacing.sm) {
                // Header with name and category badge
                HStack {
                    Text(template.name)
                        .font(CareSphereTypography.titleSmall)
                        .foregroundColor(theme.colors.onBackground)

                    Spacer()

                    // Category badge
                    Text(template.category.displayName)
                        .font(CareSphereTypography.labelSmall)
                        .foregroundColor(categoryColor)
                        .padding(.horizontal, CareSphereSpacing.sm)
                        .padding(.vertical, 4)
                        .background(categoryColor.opacity(0.1))
                        .cornerRadius(CareSphereRadius.sm)
                }

                // Description
                if let description = template.description {
                    Text(description)
                        .font(CareSphereTypography.bodyMedium)
                        .foregroundColor(theme.colors.onSurface.opacity(0.7))
                        .lineLimit(2)
                }

                // Supported channels
                HStack(spacing: CareSphereSpacing.sm) {
                    ForEach(template.supportedChannels, id: \.rawValue) { channel in
                        HStack(spacing: 4) {
                            Image(systemName: channelIcon(for: channel))
                                .font(.caption2)
                            Text(channel.displayName)
                                .font(CareSphereTypography.labelSmall)
                        }
                        .foregroundColor(theme.colors.onSurface.opacity(0.6))
                    }

                    Spacer()

                    // Usage count
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right")
                            .font(.caption2)
                        Text("\(template.usageCount) uses")
                            .font(CareSphereTypography.labelSmall)
                    }
                    .foregroundColor(theme.colors.onSurface.opacity(0.5))
                }
            }
            .padding(CareSphereSpacing.md)
        }
    }

    private var categoryColor: Color {
        switch template.category {
        case .welcome:
            return theme.colors.success
        case .reminder:
            return theme.colors.warning
        case .followUp:
            return theme.colors.secondary
        case .announcement:
            return theme.colors.primary
        case .birthday:
            return Color.pink
        case .prayer:
            return Color.purple
        case .pastoral:
            return Color.blue
        case .emergency:
            return theme.colors.error
        case .general:
            return theme.colors.onSurface.opacity(0.5)
        }
    }

    private func channelIcon(for channel: MessageChannel) -> String {
        switch channel {
        case .email:
            return "envelope.fill"
        case .sms:
            return "message.fill"
        case .whatsapp:
            return "bubble.left.and.bubble.right.fill"
        case .push:
            return "bell.fill"
        case .inApp:
            return "app.fill"
        case .voice:
            return "phone.fill"
        }
    }
}

#Preview {
    TemplateRow(template: MessageTemplate.preview)
        .environmentObject(CareSphereTheme.shared)
        .padding()
}
