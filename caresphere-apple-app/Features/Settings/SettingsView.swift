import SwiftUI

/// Settings view
struct SettingsView: View {
    @EnvironmentObject private var theme: CareSphereTheme
    @EnvironmentObject private var authService: AuthenticationService

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
    }
}

#Preview {
    SettingsView()
        .environmentObject(CareSphereTheme.shared)
        .environmentObject(AuthenticationService.shared)
}
