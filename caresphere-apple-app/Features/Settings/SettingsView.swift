import SwiftUI

/// Settings view
struct SettingsView: View {
    @EnvironmentObject private var theme: CareSphereTheme
    @EnvironmentObject private var authService: AuthenticationService
    @StateObject private var organizationService = OrganizationService.shared

    @State private var showingOrganizationSheet = false
    @State private var showingCodeSheet = false
    @State private var isLoadingOrganization = false

    var body: some View {
        NavigationView {
            Form {
                Section("Profile") {
                    HStack {
                        CareSphereAvatar(
                            imageURL: authService.currentUser?.avatarUrl.flatMap {
                                URL(string: $0)
                            },
                            name: authService.currentUser?.fullName ?? "User",
                            size: 50
                        )

                        VStack(alignment: .leading) {
                            Text(authService.currentUser?.fullName ?? "Unknown User")
                                .font(CareSphereTypography.bodyMedium)

                            Text(authService.currentUser?.email ?? "")
                                .font(CareSphereTypography.bodySmall)
                                .foregroundColor(theme.colors.onSurface.opacity(0.7))
                        }

                        Spacer()
                    }
                    .padding(.vertical, CareSphereSpacing.xs)
                }

                // Organization Section
                Section("Organization") {
                    if let organization = organizationService.currentOrganization {
                        VStack(alignment: .leading, spacing: CareSphereSpacing.sm) {
                            HStack {
                                Image(systemName: "building.2.fill")
                                    .foregroundColor(theme.colors.primary)
                                Text(organization.name)
                                    .font(CareSphereTypography.bodyMedium)
                                    .fontWeight(.semibold)
                            }

                            if let code = organization.organizationCode,
                                authService.currentUser?.role == .superAdmin
                                    || authService.currentUser?.role == .admin
                            {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Organization Code")
                                        .font(CareSphereTypography.bodySmall)
                                        .foregroundColor(theme.colors.onSurface.opacity(0.6))
                                    HStack {
                                        Text(code)
                                            .font(CareSphereTypography.titleMedium)
                                            .fontWeight(.bold)
                                            .foregroundColor(theme.colors.primary)

                                        Button(action: {
                                            #if os(iOS)
                                                UIPasteboard.general.string = code
                                            #endif
                                        }) {
                                            Image(systemName: "doc.on.doc")
                                                .foregroundColor(theme.colors.primary)
                                        }
                                    }
                                    Text("Share this code with others to join")
                                        .font(CareSphereTypography.bodySmall)
                                        .foregroundColor(theme.colors.onSurface.opacity(0.5))
                                }
                                .padding(.top, 4)
                            }
                        }
                        .padding(.vertical, CareSphereSpacing.xs)

                        if authService.currentUser?.role == .superAdmin
                            || authService.currentUser?.role == .admin
                        {
                            Button("Regenerate Code") {
                                showingCodeSheet = true
                            }
                            .foregroundColor(theme.colors.primary)
                        }
                    } else {
                        if isLoadingOrganization {
                            HStack {
                                ProgressView()
                                Text("Loading...")
                                    .foregroundColor(theme.colors.onSurface.opacity(0.7))
                            }
                        } else {
                            VStack(alignment: .leading, spacing: CareSphereSpacing.sm) {
                                Text("No Organization")
                                    .font(CareSphereTypography.bodyMedium)
                                    .foregroundColor(theme.colors.onSurface.opacity(0.7))
                                Text("Create or join an organization to collaborate")
                                    .font(CareSphereTypography.bodySmall)
                                    .foregroundColor(theme.colors.onSurface.opacity(0.5))
                            }

                            Button("Setup Organization") {
                                showingOrganizationSheet = true
                            }
                            .foregroundColor(theme.colors.primary)
                        }
                    }
                }

                Section("Appearance") {
                    Picker("Color Scheme", selection: .constant(theme.currentColorScheme)) {
                        Text("Light").tag(ColorScheme.light)
                        Text("Dark").tag(ColorScheme.dark)
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(theme.colors.onSurface.opacity(0.7))
                    }

                    HStack {
                        Text("Build")
                        Spacer()
                        Text("2025.1")
                            .foregroundColor(theme.colors.onSurface.opacity(0.7))
                    }
                }

                Section {
                    Button("Sign Out") {
                        Task {
                            await authService.logout()
                        }
                    }
                    .foregroundColor(CareSphereColors.error)
                }
            }
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
        .sheet(isPresented: $showingOrganizationSheet) {
            OrganizationOnboardingView { option, organizationName, organizationCode in
                showingOrganizationSheet = false
                handleOrganizationSetup(
                    action: option,
                    organizationName: organizationName,
                    organizationCode: organizationCode
                )
            }
            .environmentObject(theme)
        }
        .alert("Regenerate Organization Code", isPresented: $showingCodeSheet) {
            Button("Cancel", role: .cancel) {}
            Button("Regenerate", role: .destructive) {
                Task {
                    try? await organizationService.regenerateCode(
                        reason: "User requested code regeneration")
                }
            }
        } message: {
            Text(
                "This will invalidate the current code. Anyone with the old code won't be able to join anymore."
            )
        }
        .task {
            await loadOrganization()
        }
    }

    private func loadOrganization() async {
        isLoadingOrganization = true
        defer { isLoadingOrganization = false }
        try? await organizationService.loadMyOrganization()
    }

    private func handleOrganizationSetup(
        action: OrganizationOption,
        organizationName: String?,
        organizationCode: String?
    ) {
        Task {
            do {
                switch action {
                case .create:
                    if let name = organizationName {
                        _ = try await organizationService.createOrganization(name: name)
                    }
                case .join:
                    if let code = organizationCode {
                        _ = try await organizationService.joinOrganization(code: code)
                    }
                case .skip:
                    break
                }
            } catch {
                // Handle error - could show alert
                print("Organization setup error: \(error)")
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(CareSphereTheme.shared)
        .environmentObject(AuthenticationService.shared)
}
