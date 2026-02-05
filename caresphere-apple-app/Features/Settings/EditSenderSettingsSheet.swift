import SwiftUI

/// Sheet for editing sender settings at different scopes
struct EditSenderSettingsSheet: View {
    @EnvironmentObject private var settingsService: SenderSettingsService
    @EnvironmentObject private var authService: AuthenticationService
    @EnvironmentObject private var theme: CareSphereTheme
    @Environment(\.dismiss) private var dismiss
    
    let scope: SettingScope
    
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var isSaving = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    private var isEditing: Bool {
        currentSettings != nil
    }
    
    private var currentSettings: SenderSetting? {
        switch scope {
        case .user:
            return settingsService.userSettings
        case .organization:
            return settingsService.organizationSettings
        case .global:
            return settingsService.globalSettings
        }
    }
    
    private var canSave: Bool {
        // At least one field must be filled
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: CareSphereSpacing.xl) {
                    // Header
                    VStack(alignment: .leading, spacing: CareSphereSpacing.md) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(scope.displayName) Sender Settings")
                                    .font(CareSphereTypography.titleLarge)
                                    .fontWeight(.bold)
                                    .foregroundColor(theme.colors.onSurface)
                                
                                Text(scope.description)
                                    .font(CareSphereTypography.bodyMedium)
                                    .foregroundColor(theme.colors.onSurface.opacity(0.7))
                            }
                            
                            Spacer()
                        }
                        
                        ScopeTag(scope: scope)
                    }
                    .padding(.horizontal, CareSphereSpacing.lg)
                    
                    // Form
                    VStack(spacing: CareSphereSpacing.lg) {
                        FormCard {
                            VStack(spacing: CareSphereSpacing.lg) {
                                // Name field
                                FormField(
                                    title: "Sender Name",
                                    placeholder: "Enter sender name",
                                    text: $name,
                                    icon: "person.fill",
                                    helpText: "The name that appears as the message sender"
                                )
                                
                                // Email field
                                FormField(
                                    title: "Email Address",
                                    placeholder: "sender@example.com",
                                    text: $email,
                                    icon: "envelope.fill",
                                    keyboardType: .emailAddress,
                                    textContentType: .emailAddress,
                                    helpText: "Email address for outbound messages"
                                )
                                
                                // Phone field
                                FormField(
                                    title: "Phone Number",
                                    placeholder: "+1 (555) 123-4567",
                                    text: $phone,
                                    icon: "phone.fill",
                                    keyboardType: .phonePad,
                                    textContentType: .telephoneNumber,
                                    helpText: "Phone number for SMS messages"
                                )
                            }
                        }
                        
                        // Priority explanation
                        PriorityExplanationCard(currentScope: scope)
                    }
                    
                    Spacer()
                        .frame(height: 100)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Update" : "Save") {
                        Task {
                            await saveSettings()
                        }
                    }
                    .disabled(!canSave || isSaving)
                    .fontWeight(.semibold)
                }
            }
        }
        .task {
            loadCurrentValues()
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Actions
    
    private func loadCurrentValues() {
        if let settings = currentSettings {
            name = settings.name ?? ""
            email = settings.email ?? ""
            phone = settings.phone ?? ""
        }
    }
    
    private func saveSettings() async {
        isSaving = true
        
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let success = await settingsService.saveSenderSettings(
            scope: scope,
            name: trimmedName.isEmpty ? nil : trimmedName,
            email: trimmedEmail.isEmpty ? nil : trimmedEmail,
            phone: trimmedPhone.isEmpty ? nil : trimmedPhone
        )
        
        isSaving = false
        
        if success {
            dismiss()
        } else if let error = settingsService.error {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

// MARK: - Form Components

struct FormCard<Content: View>: View {
    @EnvironmentObject private var theme: CareSphereTheme
    
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(CareSphereSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: CareSphereRadius.lg)
                    .fill(theme.colors.surface)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
            )
            .padding(.horizontal, CareSphereSpacing.lg)
    }
}

struct FormField: View {
    @EnvironmentObject private var theme: CareSphereTheme
    
    let title: String
    let placeholder: String
    @Binding var text: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    let helpText: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: CareSphereSpacing.sm) {
            Text(title)
                .font(CareSphereTypography.labelMedium)
                .fontWeight(.medium)
                .foregroundColor(theme.colors.onSurface)
            
            HStack(spacing: CareSphereSpacing.sm) {
                Image(systemName: icon)
                    .foregroundColor(theme.colors.onSurface.opacity(0.5))
                    .frame(width: 20)
                
                TextField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .keyboardType(keyboardType)
                    .textContentType(textContentType)
                    .autocapitalization(keyboardType == .emailAddress ? .none : .words)
            }
            .padding(CareSphereSpacing.md)
            .background(theme.colors.background)
            .cornerRadius(CareSphereRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CareSphereRadius.md)
                    .stroke(theme.colors.onSurface.opacity(0.2), lineWidth: 1)
            )
            
            if let helpText = helpText {
                Text(helpText)
                    .font(CareSphereTypography.labelSmall)
                    .foregroundColor(theme.colors.onSurface.opacity(0.6))
            }
        }
    }
}

struct PriorityExplanationCard: View {
    @EnvironmentObject private var theme: CareSphereTheme
    
    let currentScope: SettingScope
    
    var body: some View {
        VStack(alignment: .leading, spacing: CareSphereSpacing.md) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(theme.colors.primary)
                
                Text("Settings Priority")
                    .font(CareSphereTypography.titleSmall)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.onSurface)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: CareSphereSpacing.sm) {
                Text("Settings are applied in the following order of priority:")
                    .font(CareSphereTypography.bodyMedium)
                    .foregroundColor(theme.colors.onSurface.opacity(0.8))
                
                VStack(alignment: .leading, spacing: 4) {
                    PriorityRow(
                        number: 1,
                        scope: .user,
                        isCurrent: currentScope == .user
                    )
                    
                    PriorityRow(
                        number: 2,
                        scope: .organization,
                        isCurrent: currentScope == .organization
                    )
                    
                    PriorityRow(
                        number: 3,
                        scope: .global,
                        isCurrent: currentScope == .global
                    )
                    
                    HStack {
                        Text("4.")
                            .font(CareSphereTypography.labelSmall)
                            .foregroundColor(theme.colors.onSurface.opacity(0.6))
                            .frame(width: 20)
                        
                        Text("Environment defaults")
                            .font(CareSphereTypography.bodySmall)
                            .foregroundColor(theme.colors.onSurface.opacity(0.6))
                    }
                }
            }
        }
        .padding(CareSphereSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: CareSphereRadius.lg)
                .fill(theme.colors.primary.opacity(0.1))
                .stroke(theme.colors.primary.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, CareSphereSpacing.lg)
    }
}

struct PriorityRow: View {
    @EnvironmentObject private var theme: CareSphereTheme
    
    let number: Int
    let scope: SettingScope
    let isCurrent: Bool
    
    var body: some View {
        HStack {
            Text("\(number).")
                .font(CareSphereTypography.labelSmall)
                .foregroundColor(isCurrent ? theme.colors.primary : theme.colors.onSurface.opacity(0.6))
                .fontWeight(isCurrent ? .semibold : .regular)
                .frame(width: 20)
            
            Text(scope.displayName)
                .font(CareSphereTypography.bodySmall)
                .foregroundColor(isCurrent ? theme.colors.primary : theme.colors.onSurface.opacity(0.6))
                .fontWeight(isCurrent ? .semibold : .regular)
            
            if isCurrent {
                Text("(current)")
                    .font(CareSphereTypography.labelSmall)
                    .foregroundColor(theme.colors.primary)
                    .italic()
            }
        }
    }
}

#Preview {
    EditSenderSettingsSheet(scope: .user)
        .environmentObject(CareSphereTheme.shared)
        .environmentObject(AuthenticationService.preview)
        .environmentObject(SenderSettingsService.preview)
}