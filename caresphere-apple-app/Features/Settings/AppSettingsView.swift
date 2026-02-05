import SwiftUI

/// Main settings view with different settings categories
struct AppSettingsView: View {
    @EnvironmentObject private var authService: AuthenticationService
    @EnvironmentObject private var theme: CareSphereTheme
    
    @State private var showingSenderSettings = false
    @State private var showingProfile = false
    @State private var showingLogoutConfirmation = false
    
    private var rowBackgroundColor: Color {
        theme.currentColorScheme == .dark
            ? theme.colors.surface.opacity(0.98)
            : theme.colors.surface
    }
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(CareSphereTypography.labelSmall)
            .fontWeight(.semibold)
            .foregroundColor(theme.colors.onSurface.opacity(0.7))
            .padding(.top, CareSphereSpacing.sm)
    }
    
    var body: some View {
        NavigationView {
            List {
                // User Profile Section
                if let user = authService.currentUser {
                    Section {
                        ProfileRow(user: user) {
                            showingProfile = true
                        }
                    }
                    .listRowBackground(rowBackgroundColor)
                }
                
                // Appearance Section
                Section(header: sectionHeader("Appearance")) {
                    Toggle(isOn: Binding(
                        get: { theme.currentColorScheme == .dark },
                        set: { theme.setColorScheme($0 ? .dark : .light) }
                    )) {
                        HStack(spacing: CareSphereSpacing.md) {
                            Image(systemName: "moon.fill")
                                .foregroundColor(theme.colors.secondary)
                                .frame(width: 24, height: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Dark Mode")
                                    .font(CareSphereTypography.bodyMedium)
                                    .foregroundColor(theme.colors.onSurface)
                                
                                Text("Use dark appearance")
                                    .font(CareSphereTypography.labelSmall)
                                    .foregroundColor(theme.colors.onSurface.opacity(0.6))
                            }
                        }
                    }
                    .tint(theme.colors.secondary)
                }
                .listRowBackground(rowBackgroundColor)
                
                // Settings Sections
                Section(header: sectionHeader("Message Settings")) {
                    SettingsRow(
                        icon: "person.crop.circle.badge.checkmark",
                        title: "Sender Settings",
                        subtitle: "Configure your sender identity",
                        action: { showingSenderSettings = true }
                    )
                    
                    SettingsRow(
                        icon: "text.bubble",
                        title: "Message Templates",
                        subtitle: "Manage reusable message templates",
                        action: { /* TODO: Navigate to templates */ }
                    )
                }
                .listRowBackground(rowBackgroundColor)
                
                Section(header: sectionHeader("Notifications")) {
                    SettingsRow(
                        icon: "bell",
                        title: "Push Notifications",
                        subtitle: "Configure notification preferences",
                        action: { /* TODO: Navigate to notifications */ }
                    )
                    
                    SettingsRow(
                        icon: "envelope.badge",
                        title: "Email Notifications",
                        subtitle: "Email delivery reports and alerts",
                        action: { /* TODO: Navigate to email settings */ }
                    )
                }
                .listRowBackground(rowBackgroundColor)
                
                Section(header: sectionHeader("Account")) {
                    SettingsRow(
                        icon: "key",
                        title: "Change Password",
                        subtitle: "Update your account password",
                        action: { /* TODO: Navigate to password change */ }
                    )
                    
                    SettingsRow(
                        icon: "shield",
                        title: "Privacy & Security",
                        subtitle: "Manage your privacy settings",
                        action: { /* TODO: Navigate to privacy */ }
                    )
                }
                .listRowBackground(rowBackgroundColor)
                
                Section(header: sectionHeader("Support")) {
                    SettingsRow(
                        icon: "questionmark.circle",
                        title: "Help & Support",
                        subtitle: "Get help and contact support",
                        action: { /* TODO: Navigate to help */ }
                    )
                    
                    SettingsRow(
                        icon: "info.circle",
                        title: "About",
                        subtitle: "App version and information",
                        action: { /* TODO: Navigate to about */ }
                    )
                }
                .listRowBackground(rowBackgroundColor)
                
                Section {
                    Button(action: { showingLogoutConfirmation = true }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(theme.colors.error)
                                .frame(width: 24, height: 24)
                            
                            Text("Sign Out")
                                .foregroundColor(theme.colors.error)
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listRowBackground(rowBackgroundColor)
            }
            .listStyle(.insetGrouped)
            .listSectionSeparator(.hidden)
            .background(theme.colors.background)
            .scrollContentBackground(.hidden)
            .navigationTitle("Settings")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(theme.colors.surface, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(
                theme.currentColorScheme == .dark ? .dark : .light,
                for: .navigationBar
            )
#endif
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $showingSenderSettings) {
            SenderSettingsView()
        }
        .sheet(isPresented: $showingProfile) {
            if let user = authService.currentUser {
                ProfileEditSheet(user: user)
            }
        }
        .confirmationDialog(
            "Sign Out",
            isPresented: $showingLogoutConfirmation
        ) {
            Button("Sign Out", role: .destructive) {
                Task {
                    await authService.logout()
                }
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
}

// MARK: - Profile Components

struct ProfileRow: View {
    @EnvironmentObject private var theme: CareSphereTheme
    
    let user: User
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: CareSphereSpacing.md) {
                // Profile avatar
                ZStack {
                    Circle()
                        .fill(theme.colors.primary.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    if let imageURL = user.avatarUrl {
                        AsyncImage(url: URL(string: imageURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Image(systemName: "person.fill")
                                .foregroundColor(theme.colors.primary)
                                .font(.title2)
                        }
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                    } else {
                        Text(user.firstName.prefix(1) + user.lastName.prefix(1))
                            .font(CareSphereTypography.titleMedium)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.colors.primary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.effectiveDisplayName)
                        .font(CareSphereTypography.titleMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.onSurface)
                    
                    Text(user.email)
                        .font(CareSphereTypography.bodyMedium)
                        .foregroundColor(theme.colors.onSurface.opacity(0.7))
                    
                    HStack {
                        Text(user.role.displayName)
                            .font(CareSphereTypography.labelSmall)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(theme.colors.primary)
                            )
                        
                        Spacer()
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(theme.colors.onSurface.opacity(0.3))
                    .font(.caption)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

struct SettingsRow: View {
    @EnvironmentObject private var theme: CareSphereTheme
    
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: CareSphereSpacing.md) {
                Image(systemName: icon)
                    .foregroundColor(theme.colors.primary)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(CareSphereTypography.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(theme.colors.onSurface)
                    
                    Text(subtitle)
                        .font(CareSphereTypography.bodySmall)
                        .foregroundColor(theme.colors.onSurface.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(theme.colors.onSurface.opacity(0.3))
                    .font(.caption)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Profile Edit Sheet

struct ProfileEditSheet: View {
    @EnvironmentObject private var authService: AuthenticationService
    @EnvironmentObject private var theme: CareSphereTheme
    @Environment(\.dismiss) private var dismiss
    
    let user: User
    
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var phoneNumber: String = ""
    @State private var isUpdating = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: CareSphereSpacing.xl) {
                    // Profile Header
                    VStack(spacing: CareSphereSpacing.md) {
                        ZStack {
                            Circle()
                                .fill(theme.colors.primary.opacity(0.1))
                                .frame(width: 100, height: 100)
                            
                            Text(user.firstName.prefix(1) + user.lastName.prefix(1))
                                .font(CareSphereTypography.displaySmall)
                                .fontWeight(.bold)
                                .foregroundColor(theme.colors.primary)
                        }
                        
                        Text(user.email)
                            .font(CareSphereTypography.bodyLarge)
                            .foregroundColor(theme.colors.onSurface.opacity(0.7))
                    }
                    .padding(.top, CareSphereSpacing.lg)
                    
                    // Form
                    FormCard {
                        VStack(spacing: CareSphereSpacing.lg) {
                            FormField(
                                title: "First Name",
                                placeholder: "Enter first name",
                                text: $firstName,
                                icon: "person.fill",
                                helpText: nil
                            )
                            
                            FormField(
                                title: "Last Name",
                                placeholder: "Enter last name",
                                text: $lastName,
                                icon: "person.fill",
                                helpText: nil
                            )
                            
                            FormField(
                                title: "Phone Number",
                                placeholder: "+1 (555) 123-4567",
                                text: $phoneNumber,
                                icon: "phone.fill",
                                keyboardType: .phonePad,
                                textContentType: .telephoneNumber,
                                helpText: nil
                            )
                        }
                    }
                    
                    Spacer()
                        .frame(height: 100)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await updateProfile()
                        }
                    }
                    .disabled(isUpdating)
                    .fontWeight(.semibold)
                }
            }
        }
        .task {
            loadCurrentValues()
        }
    }
    
    private func loadCurrentValues() {
        firstName = user.firstName
        lastName = user.lastName
        phoneNumber = ""  // Phone number not in current API model
    }
    
    private func updateProfile() async {
        isUpdating = true
        // TODO: Implement profile update API call
        // For now just dismiss
        dismiss()
    }
}

#Preview {
    AppSettingsView()
        .environmentObject(CareSphereTheme.shared)
        .environmentObject(AuthenticationService.preview)
}