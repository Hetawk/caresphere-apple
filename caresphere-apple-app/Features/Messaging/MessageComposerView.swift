import SwiftUI

/// Message composer view with template selection, recipient selection, and channel options
struct MessageComposerView: View {
    @EnvironmentObject private var theme: CareSphereTheme
    @EnvironmentObject private var messageService: MessageService
    @EnvironmentObject private var memberService: MemberService
    @Environment(\.dismiss) private var dismiss

    // Optional pre-selected template
    let selectedTemplate: MessageTemplate?

    // Form state
    @State private var templateId: String?
    @State private var selectedChannel: MessageChannel = .email
    @State private var subject: String = ""
    @State private var content: String = ""
    @State private var selectedMembers: Set<String> = []
    @State private var showingTemplateSelector = false
    @State private var showingMemberSelector = false
    @State private var showTemplateSection = false
    @State private var isSending = false
    @State private var showError = false
    @State private var errorMessage = ""

    init(
        selectedTemplate: MessageTemplate? = nil,
        initialSubject: String = "",
        initialContent: String = "",
        initialMemberIds: Set<String> = []
    ) {
        self.selectedTemplate = selectedTemplate
        self._subject = State(initialValue: initialSubject)
        self._content = State(initialValue: initialContent)
        self._selectedMembers = State(initialValue: initialMemberIds)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: CareSphereSpacing.md) {
                    // Channel selection (moved to top)
                    channelSection

                    // Recipients
                    recipientsSection

                    // Subject (for email)
                    if selectedChannel == .email {
                        subjectSection
                    }

                    // Content (larger area)
                    contentSection

                    // Template selection (optional, collapsed by default)
                    if showTemplateSection {
                        templateSection
                    } else {
                        Button {
                            showTemplateSection = true
                        } label: {
                            HStack {
                                Image(systemName: "doc.text")
                                Text("Use Template (Optional)")
                                Spacer()
                                Image(systemName: "chevron.down")
                            }
                            .foregroundColor(theme.colors.primary)
                            .padding(CareSphereSpacing.md)
                            .background(theme.colors.surface)
                            .cornerRadius(CareSphereRadius.md)
                        }
                    }
                }
                .padding(CareSphereSpacing.md)
            }
            .background(theme.colors.background)
            .navigationTitle("Compose Message")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(theme.colors.surface, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarColorScheme(
                    theme.currentColorScheme == .dark ? .dark : .light, for: .navigationBar
                )
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }

                    ToolbarItem(placement: .primaryAction) {
                        Button(isSending ? "Sending..." : "Send") {
                            Task { await sendMessage() }
                        }
                        .disabled(isSending || selectedMembers.isEmpty || content.isEmpty)
                        .buttonStyle(CareSphereButtonStyle.primary)
                    }
                }
            #endif
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showingMemberSelector) {
                MemberSelectorView(selectedMembers: $selectedMembers)
                    .environmentObject(theme)
                    .environmentObject(memberService)
            }
            .onAppear {
                if let template = selectedTemplate {
                    applyTemplate(template)
                }
            }
        }
    }

    private var templateSection: some View {
        CareSphereCard {
            VStack(alignment: .leading, spacing: CareSphereSpacing.sm) {
                HStack {
                    Text("Template")
                        .font(CareSphereTypography.titleSmall)
                        .foregroundColor(theme.colors.onBackground)

                    Spacer()

                    Button {
                        withAnimation {
                            showTemplateSection = false
                            templateId = nil
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(theme.colors.onSurface.opacity(0.5))
                    }
                }

                if let template = selectedTemplate {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(template.name)
                                .font(CareSphereTypography.bodyMedium)
                                .foregroundColor(theme.colors.onBackground)

                            Text(template.category.displayName)
                                .font(CareSphereTypography.labelSmall)
                                .foregroundColor(theme.colors.onSurface.opacity(0.6))
                        }

                        Spacer()

                        Button("Change") {
                            showingTemplateSelector = true
                        }
                        .buttonStyle(CareSphereButtonStyle.secondary)
                    }
                } else {
                    Button("Select Template") {
                        showingTemplateSelector = true
                    }
                    .buttonStyle(CareSphereButtonStyle.secondary)
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var channelSection: some View {
        VStack(alignment: .leading, spacing: CareSphereSpacing.sm) {
            HStack(spacing: CareSphereSpacing.sm) {
                channelButton(.email, icon: "envelope.fill", label: "Email")
                channelButton(.sms, icon: "message.fill", label: "SMS")
                channelButton(.push, icon: "bell.fill", label: "Push")
            }
        }
        .padding(.horizontal, 2)
    }

    private func channelButton(_ channel: MessageChannel, icon: String, label: String) -> some View
    {
        Button {
            selectedChannel = channel
        } label: {
            VStack(spacing: CareSphereSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                Text(label)
                    .font(CareSphereTypography.labelMedium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, CareSphereSpacing.md)
            .background(
                selectedChannel == channel
                    ? theme.colors.primary
                    : theme.colors.surface
            )
            .foregroundColor(
                selectedChannel == channel
                    ? .white
                    : theme.colors.onSurface.opacity(0.7)
            )
            .cornerRadius(CareSphereRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CareSphereRadius.md)
                    .stroke(
                        selectedChannel == channel
                            ? theme.colors.primary
                            : theme.colors.onSurface.opacity(0.2),
                        lineWidth: selectedChannel == channel ? 2 : 1
                    )
            )
            .shadow(
                color: selectedChannel == channel
                    ? theme.colors.primary.opacity(0.3)
                    : .clear,
                radius: 4,
                x: 0,
                y: 2
            )
        }
    }

    private var recipientsSection: some View {
        Button {
            showingMemberSelector = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recipients")
                        .font(CareSphereTypography.titleSmall)
                        .foregroundColor(theme.colors.onBackground)

                    Text(
                        selectedMembers.isEmpty
                            ? "Tap to select members" : "\(selectedMembers.count) selected"
                    )
                    .font(CareSphereTypography.bodySmall)
                    .foregroundColor(theme.colors.onSurface.opacity(0.6))
                }

                Spacer()

                Image(systemName: selectedMembers.isEmpty ? "person.badge.plus" : "person.2.fill")
                    .font(.title3)
                    .foregroundColor(theme.colors.primary)
            }
            .padding(CareSphereSpacing.md)
            .background(theme.colors.surface)
            .cornerRadius(CareSphereRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CareSphereRadius.md)
                    .stroke(
                        selectedMembers.isEmpty
                            ? theme.colors.onSurface.opacity(0.2)
                            : theme.colors.primary.opacity(0.3),
                        lineWidth: 1
                    )
            )
        }
    }

    private var subjectSection: some View {
        VStack(alignment: .leading, spacing: CareSphereSpacing.sm) {
            TextField("Email Subject", text: $subject)
                .textFieldStyle(CareSphereTextFieldStyle())
                .padding(.horizontal, 2)
        }
    }

    private var contentSection: some View {
        CareSphereCard {
            VStack(alignment: .leading, spacing: CareSphereSpacing.sm) {
                Text("Message Content")
                    .font(CareSphereTypography.titleSmall)
                    .foregroundColor(theme.colors.onBackground)

                TextEditor(text: $content)
                    .frame(minHeight: 250)
                    .padding(CareSphereSpacing.sm)
                    .background(theme.colors.surface)
                    .cornerRadius(CareSphereRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: CareSphereRadius.md)
                            .stroke(theme.colors.onSurface.opacity(0.2), lineWidth: 1)
                    )
                    .overlay(
                        Group {
                            if content.isEmpty {
                                Text("Type your message here...")
                                    .foregroundColor(theme.colors.onSurface.opacity(0.4))
                                    .padding(CareSphereSpacing.md)
                                    .allowsHitTesting(false)
                            }
                        },
                        alignment: .topLeading
                    )
            }
        }
    }

    private func applyTemplate(_ template: MessageTemplate) {
        templateId = template.id
        subject = template.subject ?? ""
        content = template.content
        showTemplateSection = true

        // Set default channel if template supports only one
        if template.supportedChannels.count == 1,
            let channel = template.supportedChannels.first
        {
            selectedChannel = channel
        }
    }

    private func sendMessage() async {
        guard !selectedMembers.isEmpty, !content.isEmpty else { return }

        isSending = true
        defer { isSending = false }

        do {
            // Get selected member objects
            let members = memberService.members.filter { selectedMembers.contains($0.id) }

            // Use MessageService to create and send message
            _ = try await messageService.createAndSendMessage(
                to: members,
                subject: selectedChannel == .email ? subject : nil,
                content: content,
                channel: selectedChannel,
                templateId: templateId
            )

            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Member Selector Sheet
struct MemberSelectorView: View {
    @EnvironmentObject private var theme: CareSphereTheme
    @EnvironmentObject private var memberService: MemberService
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedMembers: Set<String>
    @State private var searchText = ""

    var filteredMembers: [Member] {
        memberService.members.filter { member in
            searchText.isEmpty || member.fullName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(filteredMembers) { member in
                    Button {
                        if selectedMembers.contains(member.id) {
                            selectedMembers.remove(member.id)
                        } else {
                            selectedMembers.insert(member.id)
                        }
                    } label: {
                        HStack {
                            Image(
                                systemName: selectedMembers.contains(member.id)
                                    ? "checkmark.circle.fill" : "circle"
                            )
                            .foregroundColor(
                                selectedMembers.contains(member.id)
                                    ? theme.colors.primary : theme.colors.onSurface.opacity(0.3))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(member.fullName)
                                    .font(CareSphereTypography.bodyMedium)
                                    .foregroundColor(theme.colors.onBackground)

                                if let email = member.email {
                                    Text(email)
                                        .font(CareSphereTypography.bodySmall)
                                        .foregroundColor(theme.colors.onSurface.opacity(0.6))
                                }
                            }
                        }
                    }
                    .listRowBackground(theme.colors.surface)
                }
            }
            .listStyle(PlainListStyle())
            .searchable(text: $searchText, prompt: "Search members...")
            .navigationTitle("Select Recipients")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .disabled(selectedMembers.isEmpty)
                }
            }
        }
    }
}

#Preview {
    MessageComposerView()
        .environmentObject(CareSphereTheme.shared)
        .environmentObject(MessageService.preview)
        .environmentObject(MemberService.preview)
}
