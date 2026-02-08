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
    @State private var showingVerificationCode = false
    @State private var showingOrganizationOnboarding = false
    @State private var registrationData: (String, String, String)?  // email, password, fullName
    @State private var verificationCode = ""

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
                        onSignUp: proceedToOrganizationSetup
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
        .sheet(isPresented: $showingVerificationCode) {
            VerificationCodeView(
                email: email,
                onVerified: { code in
                    verificationCode = code
                    showingVerificationCode = false
                    // Show organization onboarding after verification
                    showingOrganizationOnboarding = true
                },
                onResendCode: {
                    await resendVerificationCode()
                }
            )
            .environmentObject(theme)
        }
        .sheet(isPresented: $showingOrganizationOnboarding) {
            OrganizationOnboardingView { option, organizationName, organizationCode in
                showingOrganizationOnboarding = false
                completeRegistration(
                    action: option,
                    organizationName: organizationName,
                    organizationCode: organizationCode
                )
            }
            .environmentObject(theme)
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

    private func proceedToOrganizationSetup() {
        guard isFormValid else { return }

        // Validate email format
        let emailPattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailPattern)
        guard emailPredicate.evaluate(with: email) else {
            errorMessage = "Please enter a valid email address"
            showingError = true
            return
        }

        // Store registration data for later use
        registrationData = (email, password, fullName)

        print("[SIGNUP] Initiating verification for: \\(email)")

        // Send verification code and show verification view
        Task {
            isLoading = true
            defer { isLoading = false }

            let success = await authService.sendVerificationCode(email: email)
            if success {
                print("[SIGNUP] ✅ Verification code sent, showing input view")
                showingVerificationCode = true
            } else if let error = authService.error {
                let errorMsg = error.errorDescription ?? "Failed to send verification code"
                print("[SIGNUP] ❌ Error: \\(errorMsg)")
                errorMessage = errorMsg
                showingError = true
            }
        }
    }

    private func resendVerificationCode() async {
        let success = await authService.sendVerificationCode(email: email)
        if !success, let error = authService.error {
            errorMessage = error.errorDescription ?? "Failed to resend verification code"
            showingError = true
        }
    }

    private func completeRegistration(
        action: OrganizationOption,
        organizationName: String?,
        organizationCode: String?
    ) {
        guard let (email, password, fullName) = registrationData else {
            errorMessage = "Registration data lost. Please try again."
            showingError = true
            return
        }

        guard !verificationCode.isEmpty else {
            errorMessage = "Verification code missing. Please try again."
            showingError = true
            return
        }

        print("[SIGNUP] Completing registration for: \\(email)")
        print("[SIGNUP] Organization action: \\(action)")

        Task {
            isLoading = true
            defer { isLoading = false }

            let success = await authService.registerWithOrganization(
                email: email,
                password: password,
                fullName: fullName,
                action: action,
                organizationName: organizationName,
                organizationCode: organizationCode,
                verificationCode: verificationCode
            )

            if success {
                print("[SIGNUP] ✅ Registration completed successfully")
                dismiss()
            } else if let error = authService.error {
                let errorMsg = error.errorDescription ?? "Registration failed"
                print("[SIGNUP] ❌ Registration failed: \\(errorMsg)")
                errorMessage = errorMsg
                showingError = true
            }
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
