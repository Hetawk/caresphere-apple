import SwiftUI

/// Main authentication view with sign in form
struct AuthenticationView: View {
    @EnvironmentObject private var authService: AuthenticationService
    @EnvironmentObject private var theme: CareSphereTheme

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showingSignUp = false
    @State private var showPassword = false
    @State private var errorMessage = ""
    @State private var showingError = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    theme.colors.primary.opacity(0.1),
                    theme.colors.background,
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: CareSphereSpacing.xl) {
                Spacer()

                // Logo and title
                LogoHeader()

                // Sign in form card
                VStack(spacing: CareSphereSpacing.lg) {
                    SignInForm(
                        email: $email,
                        password: $password,
                        showPassword: $showPassword,
                        isLoading: $isLoading,
                        onSignIn: signIn
                    )

                    // Sign up link
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .font(CareSphereTypography.bodyMedium)
                            .foregroundColor(theme.colors.onSurface.opacity(0.7))

                        Button(action: { showingSignUp = true }) {
                            Text("Sign up")
                                .font(CareSphereTypography.bodyMedium)
                                .fontWeight(.semibold)
                                .foregroundColor(theme.colors.primary)
                        }
                    }
                }
                .padding(CareSphereSpacing.xl)
                .background(
                    RoundedRectangle(cornerRadius: CareSphereRadius.lg)
                        .fill(theme.colors.surface)
                        .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
                )
                .padding(.horizontal, CareSphereSpacing.lg)

                Spacer()
            }
        }
        .sheet(isPresented: $showingSignUp) {
            SignUpView()
        }
        .alert("Sign In Error", isPresented: $showingError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }

    private func signIn() {
        guard !email.isEmpty, !password.isEmpty else { return }

        Task {
            isLoading = true
            let success = await authService.login(email: email, password: password)

            if !success, let error = authService.error {
                errorMessage = error.localizedDescription
                showingError = true
            }

            isLoading = false
        }
    }
}

/// Reusable logo header component
struct LogoHeader: View {
    @EnvironmentObject private var theme: CareSphereTheme

    var body: some View {
        VStack(spacing: CareSphereSpacing.lg) {
            // App icon/logo
            Image("BrandLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 160, height: 160)
                .shadow(color: theme.colors.primary.opacity(0.25), radius: 12, x: 0, y: 6)
                .accessibilityHidden(true)

            Text("CareSphere")
                .font(CareSphereTypography.displayMedium)
                .fontWeight(.bold)
                .foregroundColor(theme.colors.onBackground)

            Text("Connect, Care, Community")
                .font(CareSphereTypography.bodyLarge)
                .foregroundColor(theme.colors.onSurface.opacity(0.7))
        }
    }
}

/// Sign in form component with password visibility toggle
struct SignInForm: View {
    @EnvironmentObject private var theme: CareSphereTheme

    @Binding var email: String
    @Binding var password: String
    @Binding var showPassword: Bool
    @Binding var isLoading: Bool

    let onSignIn: () -> Void

    var body: some View {
        VStack(spacing: CareSphereSpacing.lg) {
            Text("Welcome Back")
                .font(CareSphereTypography.titleLarge)
                .fontWeight(.bold)
                .foregroundColor(theme.colors.onSurface)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: CareSphereSpacing.md) {
                // Email field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(CareSphereTypography.bodySmall)
                        .fontWeight(.medium)
                        .foregroundColor(theme.colors.onSurface.opacity(0.7))

                    HStack {
                        Image(systemName: "envelope")
                            .foregroundColor(theme.colors.onSurface.opacity(0.5))

                        TextField(
                            "",
                            text: $email,
                            prompt: Text("Enter your email")
                                .foregroundColor(theme.colors.onSurface.opacity(0.4))
                                .font(CareSphereTypography.bodyMedium)
                        )
                        .textContentType(.emailAddress)
                        .foregroundColor(theme.colors.onSurface)
                        .tint(theme.colors.secondary)
                        #if os(iOS)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        #endif
                    }
                    .padding()
                    .background(theme.colors.surface)
                    .cornerRadius(CareSphereRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: CareSphereRadius.md)
                            .stroke(theme.colors.onSurface.opacity(0.2), lineWidth: 1)
                    )
                }

                // Password field with visibility toggle
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(CareSphereTypography.bodySmall)
                        .fontWeight(.medium)
                        .foregroundColor(theme.colors.onSurface.opacity(0.7))

                    HStack {
                        Image(systemName: "lock")
                            .foregroundColor(theme.colors.onSurface.opacity(0.5))

                        if showPassword {
                            TextField(
                                "",
                                text: $password,
                                prompt: Text("Enter your password")
                                    .foregroundColor(theme.colors.onSurface.opacity(0.4))
                                    .font(CareSphereTypography.bodyMedium)
                            )
                            .textContentType(.password)
                            .foregroundColor(theme.colors.onSurface)
                            .tint(theme.colors.secondary)
                        } else {
                            SecureField(
                                "",
                                text: $password,
                                prompt: Text("Enter your password")
                                    .foregroundColor(theme.colors.onSurface.opacity(0.4))
                                    .font(CareSphereTypography.bodyMedium)
                            )
                            .textContentType(.password)
                            .foregroundColor(theme.colors.onSurface)
                            .tint(theme.colors.secondary)
                        }

                        Button(action: { showPassword.toggle() }) {
                            Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(theme.colors.onSurface.opacity(0.5))
                        }
                    }
                    .padding()
                    .background(theme.colors.surface)
                    .cornerRadius(CareSphereRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: CareSphereRadius.md)
                            .stroke(theme.colors.onSurface.opacity(0.2), lineWidth: 1)
                    )
                }

                // Forgot password
                Button(action: {}) {
                    Text("Forgot Password?")
                        .font(CareSphereTypography.bodySmall)
                        .foregroundColor(theme.colors.primary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }

                // Sign in button
                CareSphereButton(
                    "Sign In",
                    action: onSignIn,
                    style: .primary,
                    isLoading: isLoading,
                    isDisabled: email.isEmpty || password.isEmpty
                )
                .padding(.top, CareSphereSpacing.sm)
            }
        }
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(CareSphereTheme.shared)
        .environmentObject(AuthenticationService.shared)
}
