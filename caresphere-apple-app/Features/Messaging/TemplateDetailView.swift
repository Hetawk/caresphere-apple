import SwiftUI

/// Detail view for a message template
struct TemplateDetailView: View {
    @EnvironmentObject private var theme: CareSphereTheme
    @EnvironmentObject private var messageService: MessageService
    @Environment(\.dismiss) private var dismiss
    @State private var showingComposer = false

    let template: MessageTemplate

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: CareSphereSpacing.lg) {
                    // Header section
                    headerSection

                    // Subject (if available)
                    if let subject = template.subject {
                        subjectSection(subject)
                    }

                    // Content section
                    contentSection

                    // Placeholders section
                    if !template.placeholders.isEmpty {
                        placeholdersSection
                    }

                    // Supported channels section
                    channelsSection

                    // Usage statistics
                    statsSection
                }
                .padding(CareSphereSpacing.lg)
            }
            .background(theme.colors.background)
            .navigationTitle("Template Details")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(theme.colors.surface, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarColorScheme(
                    theme.currentColorScheme == .dark ? .dark : .light, for: .navigationBar
                )
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button("Use Template") {
                            showingComposer = true
                        }
                        .buttonStyle(CareSphereButtonStyle.primary)
                    }
                }
            #endif
            .sheet(isPresented: $showingComposer) {
                MessageComposerView(selectedTemplate: template)
                    .environmentObject(theme)
                    .environmentObject(messageService)
            }
        }
    }

    private var headerSection: some View {
        CareSphereCard {
            VStack(alignment: .leading, spacing: CareSphereSpacing.md) {
                HStack {
                    Text(template.name)
                        .font(CareSphereTypography.titleLarge)
                        .foregroundColor(theme.colors.onBackground)

                    Spacer()

                    // Category badge
                    Text(template.category.displayName)
                        .font(CareSphereTypography.labelMedium)
                        .foregroundColor(.white)
                        .padding(.horizontal, CareSphereSpacing.md)
                        .padding(.vertical, CareSphereSpacing.sm)
                        .background(categoryColor)
                        .cornerRadius(CareSphereRadius.md)
                }

                if let description = template.description {
                    Text(description)
                        .font(CareSphereTypography.bodyMedium)
                        .foregroundColor(theme.colors.onSurface.opacity(0.7))
                }
            }
        }
    }

    private func subjectSection(_ subject: String) -> some View {
        CareSphereCard {
            VStack(alignment: .leading, spacing: CareSphereSpacing.sm) {
                Text("Subject")
                    .font(CareSphereTypography.titleSmall)
                    .foregroundColor(theme.colors.onBackground)

                Text(subject)
                    .font(CareSphereTypography.bodyMedium)
                    .foregroundColor(theme.colors.onSurface.opacity(0.9))
            }
        }
    }

    private var contentSection: some View {
        CareSphereCard {
            VStack(alignment: .leading, spacing: CareSphereSpacing.sm) {
                Text("Content")
                    .font(CareSphereTypography.titleSmall)
                    .foregroundColor(theme.colors.onBackground)

                ScrollView {
                    Text(template.content)
                        .font(CareSphereTypography.bodyMedium)
                        .foregroundColor(theme.colors.onSurface.opacity(0.9))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 300)
            }
        }
    }

    private var placeholdersSection: some View {
        CareSphereCard {
            VStack(alignment: .leading, spacing: CareSphereSpacing.md) {
                Text("Placeholders")
                    .font(CareSphereTypography.titleSmall)
                    .foregroundColor(theme.colors.onBackground)

                VStack(alignment: .leading, spacing: CareSphereSpacing.sm) {
                    ForEach(template.placeholders, id: \.name) { placeholder in
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("{{\(placeholder.name)}}")
                                        .font(CareSphereTypography.labelMedium)
                                        .foregroundColor(theme.colors.primary)
                                        .padding(.horizontal, CareSphereSpacing.sm)
                                        .padding(.vertical, 4)
                                        .background(theme.colors.primary.opacity(0.1))
                                        .cornerRadius(CareSphereRadius.sm)

                                    if placeholder.isRequired {
                                        Text("Required")
                                            .font(CareSphereTypography.labelSmall)
                                            .foregroundColor(theme.colors.error)
                                    }
                                }

                                Text(placeholder.displayName)
                                    .font(CareSphereTypography.bodySmall)
                                    .foregroundColor(theme.colors.onSurface.opacity(0.7))

                                if let description = placeholder.description {
                                    Text(description)
                                        .font(CareSphereTypography.bodySmall)
                                        .foregroundColor(theme.colors.onSurface.opacity(0.5))
                                }
                            }

                            Spacer()
                        }
                        .padding(.vertical, CareSphereSpacing.xs)

                        if placeholder != template.placeholders.last {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private var channelsSection: some View {
        CareSphereCard {
            VStack(alignment: .leading, spacing: CareSphereSpacing.md) {
                Text("Supported Channels")
                    .font(CareSphereTypography.titleSmall)
                    .foregroundColor(theme.colors.onBackground)

                HStack(spacing: CareSphereSpacing.md) {
                    ForEach(template.supportedChannels, id: \.rawValue) { channel in
                        VStack(spacing: CareSphereSpacing.xs) {
                            Image(systemName: channelIcon(for: channel))
                                .font(.title2)
                                .foregroundColor(theme.colors.primary)

                            Text(channel.displayName)
                                .font(CareSphereTypography.labelSmall)
                                .foregroundColor(theme.colors.onSurface.opacity(0.7))
                        }
                    }

                    Spacer()
                }
            }
        }
    }

    private var statsSection: some View {
        CareSphereCard {
            VStack(alignment: .leading, spacing: CareSphereSpacing.md) {
                Text("Statistics")
                    .font(CareSphereTypography.titleSmall)
                    .foregroundColor(theme.colors.onBackground)

                HStack(spacing: CareSphereSpacing.lg) {
                    VStack(alignment: .leading) {
                        Text("Usage Count")
                            .font(CareSphereTypography.labelSmall)
                            .foregroundColor(theme.colors.onSurface.opacity(0.6))
                        Text("\(template.usageCount)")
                            .font(CareSphereTypography.titleMedium)
                            .foregroundColor(theme.colors.onBackground)
                    }

                    Divider()
                        .frame(height: 40)

                    VStack(alignment: .leading) {
                        Text("Created")
                            .font(CareSphereTypography.labelSmall)
                            .foregroundColor(theme.colors.onSurface.opacity(0.6))
                        Text(template.createdAt.formatted(date: .abbreviated, time: .omitted))
                            .font(CareSphereTypography.bodyMedium)
                            .foregroundColor(theme.colors.onBackground)
                    }

                    Spacer()
                }
            }
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
    TemplateDetailView(template: MessageTemplate.preview)
        .environmentObject(CareSphereTheme.shared)
        .environmentObject(MessageService.preview)
}
