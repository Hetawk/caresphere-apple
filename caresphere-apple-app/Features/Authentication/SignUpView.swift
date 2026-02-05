import SwiftUI

/// Sign up view for new user registration
struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authService: AuthenticationService
    @EnvironmentObject private var theme: CareSphereTheme

    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingError = false

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    theme.colors.primary.opacity(0.1),
                    theme.colors.background,
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: CareSphereSpacing.xl) {
                    // Header
                    VStack(spacing: CareSphereSpacing.md) {
                        Text("Create Account")
                            .font(CareSphereTypography.displaySmall)
                            .fontWeight(.bold)
                            .foregroundColor(theme.colors.onBackground)

                        Text("Join our community")
                            .font(CareSphereTypography.bodyLarge)
                            .foregroundColor(theme.colors.onSurface.opacity(0.7))
                    }
                    .padding(.top, CareSphereSpacing.xl)

                    SignUpForm(
                        fullName: $fullName,
                        email: $email,
                        password: $password,
                        confirmPassword: $confirmPassword,
                        showPassword: $showPassword,
                        showConfirmPassword: $showConfirmPassword,
                        isLoading: $isLoading,
                        isFormValid: isFormValid,
                        onSignUp: signUp
                    )
                }
                .padding(.bottom, CareSphereSpacing.xl)
            }

            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(theme.colors.onSurface.opacity(0.5))
                    }
                    .padding()
                }
                Spacer()
            }
        }
        .alert("Registration Error", isPresented: $showingError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }

    private var isFormValid: Bool {
        !fullName.isEmpty && !email.isEmpty && !password.isEmpty && password == confirmPassword
            && password.count >= 8
    }

    private func signUp() {
        guard isFormValid else { return }

        Task {
            isLoading = true
            do {
                _ = await authService.register(
                    email: email,
                    password: password,
                    fullName: fullName
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
            isLoading = false
        }
    }
}

/// Sign up form component
struct SignUpForm: View {
    @EnvironmentObject private var theme: CareSphereTheme

    @Binding var fullName: String
    @Binding var email: String
    @Binding var password: String
    @Binding var confirmPassword: String
    @Binding var showPassword: Bool
    @Binding var showConfirmPassword: Bool
    @Binding var isLoading: Bool

    let isFormValid: Bool
    let onSignUp: () -> Void

    var body: some View {
        VStack(spacing: CareSphereSpacing.lg) {
            // Full name field
            VStack(alignment: .leading, spacing: 8) {
                Text("Full Name")
                    .font(CareSphereTypography.bodySmall)
                    .fontWeight(.medium)
                    .foregroundColor(theme.colors.onSurface.opacity(0.7))

                HStack {
                    Image(systemName: "person")
                        .foregroundColor(theme.colors.onSurface.opacity(0.5))

                    TextField(
                        "",
                        text: $fullName,
                        prompt: Text("Enter your full name")
                            .foregroundColor(theme.colors.onSurface.opacity(0.4))
                            .font(CareSphereTypography.bodyMedium)
                    )
                    .textContentType(.name)
                    .foregroundColor(theme.colors.onSurface)
                    .tint(theme.colors.secondary)
                }
                .padding()
                .background(theme.colors.surface)
                .cornerRadius(CareSphereRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: CareSphereRadius.md)
                        .stroke(theme.colors.onSurface.opacity(0.2), lineWidth: 1)
                )
            }

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
                        .textContentType(.newPassword)
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
                        .textContentType(.newPassword)
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

            // Confirm password field with visibility toggle
            VStack(alignment: .leading, spacing: 8) {
                Text("Confirm Password")
                    .font(CareSphereTypography.bodySmall)
                    .fontWeight(.medium)
                    .foregroundColor(theme.colors.onSurface.opacity(0.7))

                HStack {
                    Image(systemName: "lock")
                        .foregroundColor(theme.colors.onSurface.opacity(0.5))

                    if showConfirmPassword {
                        TextField(
                            "",
                            text: $confirmPassword,
                            prompt: Text("Confirm your password")
                                .foregroundColor(theme.colors.onSurface.opacity(0.4))
                                .font(CareSphereTypography.bodyMedium)
                        )
                        .textContentType(.newPassword)
                        .foregroundColor(theme.colors.onSurface)
                        .tint(theme.colors.secondary)
                    } else {
                        SecureField(
                            "",
                            text: $confirmPassword,
                            prompt: Text("Confirm your password")
                                .foregroundColor(theme.colors.onSurface.opacity(0.4))
                                .font(CareSphereTypography.bodyMedium)
                        )
                        .textContentType(.newPassword)
                        .foregroundColor(theme.colors.onSurface)
                        .tint(theme.colors.secondary)
                    }

                    Button(action: { showConfirmPassword.toggle() }) {
                        Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
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

            // Password requirements
            if !password.isEmpty {
                VStack(alignment: .leading, spacing: CareSphereSpacing.xs) {
                    HStack(spacing: 8) {
                        Image(
                            systemName: password.count >= 8
                                ? "checkmark.circle.fill" : "xmark.circle"
                        )
                        .foregroundColor(
                            password.count >= 8 ? theme.colors.primary : theme.colors.error)
                        Text("At least 8 characters")
                            .font(CareSphereTypography.bodySmall)
                            .foregroundColor(theme.colors.onSurface.opacity(0.7))
                    }

                    if !confirmPassword.isEmpty {
                        HStack(spacing: 8) {
                            Image(
                                systemName: password == confirmPassword
                                    ? "checkmark.circle.fill" : "xmark.circle"
                            )
                            .foregroundColor(
                                password == confirmPassword
                                    ? theme.colors.primary : theme.colors.error)
                            Text("Passwords match")
                                .font(CareSphereTypography.bodySmall)
                                .foregroundColor(theme.colors.onSurface.opacity(0.7))
                        }
                    }
                }
                .padding()
                .background(theme.colors.surface.opacity(0.5))
                .cornerRadius(CareSphereRadius.sm)
            }

            // Create account button
            CareSphereButton(
                "Create Account",
                action: onSignUp,
                style: .primary,
                isLoading: isLoading,
                isDisabled: !isFormValid
            )
            .padding(.top, CareSphereSpacing.sm)
        }
        .padding(CareSphereSpacing.xl)
        .background(theme.colors.surface)
        .cornerRadius(CareSphereRadius.xl)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding(.horizontal, CareSphereSpacing.xl)
    }
}

#Preview {
    SignUpView()
        .environmentObject(CareSphereTheme.shared)
        .environmentObject(AuthenticationService.shared)
}
