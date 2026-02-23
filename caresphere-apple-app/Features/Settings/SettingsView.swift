import SwiftUI

/// Settings view
struct SettingsView: View {
    @EnvironmentObject private var theme: CareSphereTheme
    @EnvironmentObject private var authService: AuthenticationService
    @StateObject private var organizationService = OrganizationService.shared

    @State private var showingOrganizationSheet = false
    @State private var showingJoinSheet = false
    @State private var showingCodeSheet = false
    @State private var isLoadingOrganization = false
    @State private var switchError: String?

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

                // Organization Section — shows all orgs with switcher
                Section("Organizations") {
                    if isLoadingOrganization && organizationService.allOrganizations.isEmpty {
                        HStack {
                            ProgressView()
                            Text("Loading...")
                                .foregroundColor(theme.colors.onSurface.opacity(0.7))
                        }
                    } else if organizationService.allOrganizations.isEmpty {
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
                    } else {
                        ForEach(organizationService.allOrganizations) { org in
                            OrgRowView(
                                org: org,
                                isActive: org.id == organizationService.currentOrganization?.id,
                                onSwitch: {
                                    Task { await switchTo(org) }
                                }
                            )
                        }

                        // Share / code actions for the active org
                        if let current = organizationService.currentOrganization {
                            if let code = current.organizationCode,
                                authService.currentUser?.role == .superAdmin
                                    || authService.currentUser?.role == .admin
                            {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Join Code")
                                            .font(CareSphereTypography.bodySmall)
                                            .foregroundColor(theme.colors.onSurface.opacity(0.6))
                                        Text(code)
                                            .font(.system(.title3, design: .monospaced))
                                            .fontWeight(.bold)
                                            .foregroundColor(theme.colors.primary)
                                    }
                                    Spacer()
                                    // Copy
                                    Button {
                                        #if os(iOS)
                                            UIPasteboard.general.string = code
                                        #endif
                                    } label: {
                                        Image(systemName: "doc.on.doc")
                                            .foregroundColor(theme.colors.primary)
                                    }
                                    // Share link
                                    ShareLink(item: joinURL(for: code)) {
                                        Image(systemName: "square.and.arrow.up")
                                            .foregroundColor(theme.colors.primary)
                                    }
                                }

                                Button("Regenerate Code") {
                                    showingCodeSheet = true
                                }
                                .foregroundColor(CareSphereColors.warning)
                            }
                        }

                        // Join another org
                        Button {
                            showingJoinSheet = true
                        } label: {
                            Label("Join Another Organization", systemImage: "person.badge.plus")
                                .foregroundColor(theme.colors.primary)
                        }
                    }

                    if let err = switchError {
                        Text(err)
                            .font(CareSphereTypography.bodySmall)
                            .foregroundColor(CareSphereColors.error)
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
        // Full org setup (create / join / skip) for brand-new users
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
        // Quick join sheet for existing users adding another org
        .sheet(isPresented: $showingJoinSheet) {
            JoinOrganizationSheet { code in
                showingJoinSheet = false
                Task {
                    do {
                        _ = try await organizationService.joinOrganization(code: code)
                        try? await organizationService.loadAllOrganizations()
                    } catch {
                        switchError = "Could not join: \(error.localizedDescription)"
                    }
                }
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
            await loadOrganizations()
        }
    }

    // MARK: - Helpers

    private func loadOrganizations() async {
        isLoadingOrganization = true
        defer { isLoadingOrganization = false }
        async let _ = try? organizationService.loadMyOrganization()
        async let _ = try? organizationService.loadAllOrganizations()
    }

    private func switchTo(_ org: OrganizationWithMembership) async {
        switchError = nil
        do {
            _ = try await organizationService.switchOrganization(to: org.id)
        } catch {
            switchError = "Could not switch: \(error.localizedDescription)"
        }
    }

    private func joinURL(for code: String) -> URL {
        URL(string: "https://caresphere.ekddigital.com/join?code=\(code)")!
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
                try? await organizationService.loadAllOrganizations()
            } catch {
                print("Organization setup error: \(error)")
            }
        }
    }
}

// MARK: - Org Row

private struct OrgRowView: View {
    @EnvironmentObject private var theme: CareSphereTheme
    let org: OrganizationWithMembership
    let isActive: Bool
    let onSwitch: () -> Void

    var body: some View {
        HStack(spacing: CareSphereSpacing.sm) {
            Image(systemName: isActive ? "building.2.fill" : "building.2")
                .foregroundColor(isActive ? theme.colors.primary : theme.colors.onSurface.opacity(0.4))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(org.name)
                    .font(CareSphereTypography.bodyMedium)
                    .fontWeight(isActive ? .semibold : .regular)
                    .foregroundColor(theme.colors.onSurface)
                Text(org.membership.roleDisplayName)
                    .font(CareSphereTypography.bodySmall)
                    .foregroundColor(theme.colors.onSurface.opacity(0.6))
            }

            Spacer()

            if isActive {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(theme.colors.primary)
            } else {
                Button("Switch", action: onSwitch)
                    .font(CareSphereTypography.bodySmall)
                    .foregroundColor(theme.colors.primary)
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Quick Join Sheet

struct JoinOrganizationSheet: View {
    @EnvironmentObject private var theme: CareSphereTheme
    @Environment(\.dismiss) private var dismiss

    @State private var code = ""
    @State private var isValid = true

    let onJoin: (String) -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: CareSphereSpacing.xl) {
                VStack(spacing: CareSphereSpacing.sm) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 52))
                        .foregroundColor(theme.colors.primary)

                    Text("Join an Organization")
                        .font(CareSphereTypography.displaySmall)
                        .fontWeight(.bold)

                    Text("Ask your organization admin for the 7-character join code, then enter it below.")
                        .font(CareSphereTypography.bodyMedium)
                        .foregroundColor(theme.colors.onSurface.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, CareSphereSpacing.xl)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Organization Code")
                        .font(CareSphereTypography.bodySmall)
                        .fontWeight(.medium)
                        .foregroundColor(theme.colors.onSurface.opacity(0.7))

                    TextField(
                        "",
                        text: $code,
                        prompt: Text("e.g. 08GUM51")
                            .foregroundColor(theme.colors.onSurface.opacity(0.4))
                    )
                    .textFieldStyle(CareSphereTextFieldStyle())
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.characters)
                    .font(.system(.title3, design: .monospaced))
                    .onChange(of: code) { _, new in
                        code = String(new.uppercased().prefix(7))
                        isValid = code.isEmpty || (code.count == 7 && code.allSatisfy { $0.isLetter || $0.isNumber })
                    }

                    if !isValid && !code.isEmpty {
                        Text("Code must be exactly 7 letters/digits")
                            .font(CareSphereTypography.bodySmall)
                            .foregroundColor(theme.colors.error)
                    }
                }
                .padding(.horizontal, CareSphereSpacing.lg)

                CareSphereButton(
                    "Join Organization",
                    action: { onJoin(code) },
                    style: .primary,
                    isDisabled: !(code.count == 7 && code.allSatisfy { $0.isLetter || $0.isNumber })
                )
                .padding(.horizontal, CareSphereSpacing.lg)

                Spacer()
            }
            .background(theme.colors.background.ignoresSafeArea())
            .navigationTitle("Join Organization")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(CareSphereTheme.shared)
        .environmentObject(AuthenticationService.shared)
}
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
