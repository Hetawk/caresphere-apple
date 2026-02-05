import SwiftUI

/// View for managing sender settings across different scopes
struct SenderSettingsView: View {
    @EnvironmentObject private var settingsService: SenderSettingsService
    @EnvironmentObject private var authService: AuthenticationService
    @EnvironmentObject private var theme: CareSphereTheme
    
    @State private var isLoading = false
    @State private var showingDeleteConfirmation = false
    @State private var scopeToDelete: SettingScope?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: CareSphereSpacing.lg) {
                    // Current effective settings card
                    if let resolved = settingsService.resolvedSettings {
                        EffectiveSettingsCard(settings: resolved)
                    }
                    
                    // Settings management sections
                    VStack(spacing: CareSphereSpacing.md) {
                        // Personal settings
                        PersonalSettingsSection(
                            onDeleteRequested: { requestDelete(.user) }
                        )
                        
                        // Organization settings (if user has access)
                        if authService.canManageSettingsScope(.organization) {
                            OrganizationSettingsSection(
                                onDeleteRequested: { requestDelete(.organization) }
                            )
                        }
                        
                        // Global settings (if user has access)
                        if authService.canManageSettingsScope(.global) {
                            GlobalSettingsSection(
                                onDeleteRequested: { requestDelete(.global) }
                            )
                        }
                    }
                    .padding(.horizontal, CareSphereSpacing.lg)
                    
                    Spacer()
                        .frame(height: 100)
                }
            }
            .refreshable {
                await refresh()
            }
            .navigationTitle("Sender Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if settingsService.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
        }
        .task {
            await loadSettings()
        }
        .confirmationDialog(
            "Delete Settings",
            isPresented: $showingDeleteConfirmation,
            presenting: scopeToDelete
        ) { scope in
            Button("Delete \(scope.displayName) Settings", role: .destructive) {
                Task {
                    await deleteSettings(scope)
                }
            }
        } message: { scope in
            Text("This will delete your \(scope.displayName.lowercased()) sender settings. This action cannot be undone.")
        }
    }
    
    // MARK: - Actions
    
    private func loadSettings() async {
        await settingsService.loadResolvedSettings()
        await settingsService.loadAllUserSettings()
    }
    
    private func refresh() async {
        await loadSettings()
    }
    
    private func requestDelete(_ scope: SettingScope) {
        scopeToDelete = scope
        showingDeleteConfirmation = true
    }
    
    private func deleteSettings(_ scope: SettingScope) async {
        await settingsService.deleteSenderSettings(scope: scope)
    }
}

// MARK: - Effective Settings Card

struct EffectiveSettingsCard: View {
    @EnvironmentObject private var theme: CareSphereTheme
    
    let settings: ResolvedSenderSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: CareSphereSpacing.md) {
            HStack {
                Text("Current Sender Identity")
                    .font(CareSphereTypography.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.onSurface)
                
                Spacer()
                
                if let source = settings.effectiveSource {
                    ScopeTag(scope: source)
                }
            }
            
            VStack(alignment: .leading, spacing: CareSphereSpacing.sm) {
                if let name = settings.name {
                    SettingRow(
                        icon: "person.fill",
                        label: "Name",
                        value: name
                    )
                }
                
                if let email = settings.email {
                    SettingRow(
                        icon: "envelope.fill",
                        label: "Email",
                        value: email
                    )
                }
                
                if let phone = settings.phone {
                    SettingRow(
                        icon: "phone.fill",
                        label: "Phone",
                        value: phone
                    )
                }
                
                if settings.name == nil && settings.email == nil && settings.phone == nil {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(theme.colors.warning)
                        
                        Text("No sender identity configured")
                            .font(CareSphereTypography.bodyMedium)
                            .foregroundColor(theme.colors.onSurface.opacity(0.7))
                    }
                }
            }
        }
        .padding(CareSphereSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: CareSphereRadius.lg)
                .fill(theme.colors.surface)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal, CareSphereSpacing.lg)
    }
}

// MARK: - Settings Sections

struct PersonalSettingsSection: View {
    @EnvironmentObject private var settingsService: SenderSettingsService
    @EnvironmentObject private var theme: CareSphereTheme
    
    @State private var showingEditSheet = false
    
    let onDeleteRequested: () -> Void
    
    var body: some View {
        SettingsSection(
            title: "Personal Settings",
            description: "Your personal sender identity overrides all other settings",
            scope: .user,
            settings: settingsService.userSettings,
            onEdit: { showingEditSheet = true },
            onDelete: onDeleteRequested
        )
        .sheet(isPresented: $showingEditSheet) {
            EditSenderSettingsSheet(scope: .user)
        }
    }
}

struct OrganizationSettingsSection: View {
    @EnvironmentObject private var settingsService: SenderSettingsService
    @EnvironmentObject private var theme: CareSphereTheme
    
    @State private var showingEditSheet = false
    
    let onDeleteRequested: () -> Void
    
    var body: some View {
        SettingsSection(
            title: "Organization Settings",
            description: "Shared sender identity for your organization",
            scope: .organization,
            settings: settingsService.organizationSettings,
            onEdit: { showingEditSheet = true },
            onDelete: onDeleteRequested
        )
        .sheet(isPresented: $showingEditSheet) {
            EditSenderSettingsSheet(scope: .organization)
        }
    }
}

struct GlobalSettingsSection: View {
    @EnvironmentObject private var settingsService: SenderSettingsService
    @EnvironmentObject private var theme: CareSphereTheme
    
    @State private var showingEditSheet = false
    
    let onDeleteRequested: () -> Void
    
    var body: some View {
        SettingsSection(
            title: "Global Settings",
            description: "System-wide default sender identity",
            scope: .global,
            settings: settingsService.globalSettings,
            onEdit: { showingEditSheet = true },
            onDelete: onDeleteRequested
        )
        .sheet(isPresented: $showingEditSheet) {
            EditSenderSettingsSheet(scope: .global)
        }
    }
}

// MARK: - Reusable Components

struct SettingsSection: View {
    @EnvironmentObject private var theme: CareSphereTheme
    
    let title: String
    let description: String
    let scope: SettingScope
    let settings: SenderSetting?
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: CareSphereSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(CareSphereTypography.titleSmall)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.onSurface)
                    
                    Text(description)
                        .font(CareSphereTypography.bodySmall)
                        .foregroundColor(theme.colors.onSurface.opacity(0.7))
                }
                
                Spacer()
                
                ScopeTag(scope: scope)
            }
            
            if let settings = settings {
                VStack(alignment: .leading, spacing: CareSphereSpacing.sm) {
                    if let name = settings.name {
                        SettingRow(icon: "person.fill", label: "Name", value: name)
                    }
                    if let email = settings.email {
                        SettingRow(icon: "envelope.fill", label: "Email", value: email)
                    }
                    if let phone = settings.phone {
                        SettingRow(icon: "phone.fill", label: "Phone", value: phone)
                    }
                }
                
                HStack {
                    Button("Edit", action: onEdit)
                        .buttonStyle(.borderedProminent)
                        .tint(theme.colors.primary)
                    
                    Button("Delete", action: onDelete)
                        .buttonStyle(.bordered)
                        .tint(theme.colors.error)
                }
            } else {
                VStack(alignment: .leading, spacing: CareSphereSpacing.sm) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(theme.colors.onSurface.opacity(0.5))
                        
                        Text("No custom settings configured")
                            .font(CareSphereTypography.bodyMedium)
                            .foregroundColor(theme.colors.onSurface.opacity(0.7))
                    }
                    
                    Button("Configure", action: onEdit)
                        .buttonStyle(.borderedProminent)
                        .tint(theme.colors.primary)
                }
            }
        }
        .padding(CareSphereSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: CareSphereRadius.lg)
                .fill(theme.colors.surface)
                .stroke(theme.colors.onSurface.opacity(0.1), lineWidth: 1)
        )
    }
}

struct ScopeTag: View {
    @EnvironmentObject private var theme: CareSphereTheme
    
    let scope: SettingScope
    
    private var tagColor: Color {
        switch scope {
        case .user:
            return theme.colors.primary
        case .organization:
            return theme.colors.secondary
        case .global:
            return theme.colors.tertiary
        }
    }
    
    var body: some View {
        Text(scope.displayName)
            .font(CareSphereTypography.labelSmall)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, CareSphereSpacing.sm)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: CareSphereRadius.sm)
                    .fill(tagColor)
            )
    }
}

struct SettingRow: View {
    @EnvironmentObject private var theme: CareSphereTheme
    
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: CareSphereSpacing.sm) {
            Image(systemName: icon)
                .foregroundColor(theme.colors.onSurface.opacity(0.6))
                .frame(width: 16)
            
            Text(label)
                .font(CareSphereTypography.bodySmall)
                .foregroundColor(theme.colors.onSurface.opacity(0.7))
                .frame(width: 60, alignment: .leading)
            
            Text(value)
                .font(CareSphereTypography.bodyMedium)
                .foregroundColor(theme.colors.onSurface)
        }
    }
}

#Preview {
    SenderSettingsView()
        .environmentObject(CareSphereTheme.shared)
        .environmentObject(AuthenticationService.preview)
        .environmentObject(SenderSettingsService.preview)
}