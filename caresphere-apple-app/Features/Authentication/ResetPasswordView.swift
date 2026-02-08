import SwiftUI

/// View for resetting password with email reset code
struct ResetPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authService: AuthenticationService
    @EnvironmentObject private var theme: CareSphereTheme

    let email: String

    @State private var resetCode = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var isLoading = false
    @State private var showingSuccess = false
    @State private var showingError = false
    @State private var errorMessage = ""

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

            ScrollView {
                VStack(spacing: CareSphereSpacing.xl) {
                    Spacer()
                        .frame(height: 40)

                    // Header
                    VStack(spacing: CareSphereSpacing.md) {
                        Image(systemName: "checkmark.shield")
                            .font(.system(size: 60))
                            .foregroundColor(theme.colors.primary)
                            .padding(.bottom, CareSphereSpacing.sm)

                        Text("Reset Password")
                            .font(CareSphereTypography.displaySmall)
                            .fontWeight(.bold)
                            .foregroundColor(theme.colors.onBackground)

                        Text("Enter the code we sent to \(email)")
                            .font(CareSphereTypography.bodyMedium)
                            .foregroundColor(theme.colors.onSurface.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // Form card
                    VStack(spacing: CareSphereSpacing.lg) {
                        // Reset code field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Reset Code")
                                .font(CareSphereTypography.bodySmall)
                                .fontWeight(.medium)
                                .foregroundColor(theme.colors.onSurface.opacity(0.7))

                            HStack {
                                Image(systemName: "number")
                                    .foregroundColor(theme.colors.onSurface.opacity(0.5))

                                TextField(
                                    "",
                                    text: $resetCode,
                                    prompt: Text("Enter 6-digit code")
                                        .foregroundColor(theme.colors.onSurface.opacity(0.4))
                                        .font(CareSphereTypography.bodyMedium)
                                )
                                .foregroundColor(theme.colors.onSurface)
                                .tint(theme.colors.secondary)
                                #if os(iOS)
                                    .keyboardType(.numberPad)
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

                        Divider()
                            .padding(.vertical, CareSphereSpacing.sm)

                        // New password field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("New Password")
                                .font(CareSphereTypography.bodySmall)
                                .fontWeight(.medium)
                                .foregroundColor(theme.colors.onSurface.opacity(0.7))

                            HStack {
                                Image(systemName: "lock")
                                    .foregroundColor(theme.colors.onSurface.opacity(0.5))

                                if showPassword {
                                    TextField(
                                        "",
                                        text: $newPassword,
                                        prompt: Text("Enter new password")
                                            .foregroundColor(theme.colors.onSurface.opacity(0.4))
                                            .font(CareSphereTypography.bodyMedium)
                                    )
                                    .textContentType(.newPassword)
                                    .foregroundColor(theme.colors.onSurface)
                                    .tint(theme.colors.secondary)
                                } else {
                                    SecureField(
                                        "",
                                        text: $newPassword,
                                        prompt: Text("Enter new password")
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

                            if !newPassword.isEmpty && newPassword.count < 8 {
                                Text("Password must be at least 8 characters")
                                    .font(CareSphereTypography.bodySmall)
                                    .foregroundColor(theme.colors.error)
                            }
                        }

                        // Confirm password field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(CareSphereTypography.bodySmall)
                                .fontWeight(.medium)
                                .foregroundColor(theme.colors.onSurface.opacity(0.7))

                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(theme.colors.onSurface.opacity(0.5))

                                if showConfirmPassword {
                                    TextField(
                                        "",
                                        text: $confirmPassword,
                                        prompt: Text("Confirm new password")
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
                                        prompt: Text("Confirm new password")
                                            .foregroundColor(theme.colors.onSurface.opacity(0.4))
                                            .font(CareSphereTypography.bodyMedium)
                                    )
                                    .textContentType(.newPassword)
                                    .foregroundColor(theme.colors.onSurface)
                                    .tint(theme.colors.secondary)
                                }

                                Button(action: { showConfirmPassword.toggle() }) {
                                    Image(
                                        systemName: showConfirmPassword
                                            ? "eye.slash.fill" : "eye.fill"
                                    )
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

                            if !confirmPassword.isEmpty && newPassword != confirmPassword {
                                Text("Passwords don't match")
                                    .font(CareSphereTypography.bodySmall)
                                    .foregroundColor(theme.colors.error)
                            }
                        }

                        // Reset password button
                        CareSphereButton(
                            "Reset Password",
                            action: resetPassword,
                            style: .primary,
                            isLoading: isLoading,
                            isDisabled: !isFormValid
                        )

                        // Cancel button
                        Button(action: { dismiss() }) {
                            Text("Cancel")
                                .font(CareSphereTypography.bodyMedium)
                                .fontWeight(.medium)
                                .foregroundColor(theme.colors.primary)
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
        }
        .alert("Password Reset Successful", isPresented: $showingSuccess) {
            Button("OK") {
                // Dismiss all sheets to go back to login
                dismiss()
            }
        } message: {
            Text(
                "Your password has been reset successfully. You can now log in with your new password."
            )
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }

    private var isFormValid: Bool {
        !resetCode.isEmpty && resetCode.count == 6 && !newPassword.isEmpty && newPassword.count >= 8
            && newPassword == confirmPassword
    }

    private func resetPassword() {
        guard isFormValid else { return }

        Task {
            isLoading = true
            defer { isLoading = false }

            let success = await authService.resetPassword(
                email: email,
                token: resetCode,
                newPassword: newPassword
            )

            if success {
                showingSuccess = true
            } else {
                errorMessage =
                    authService.error?.errorDescription
                    ?? "Failed to reset password. Please check your reset code and try again."
                showingError = true
            }
        }
    }
}

#Preview {
    ResetPasswordView(email: "user@example.com")
        .environmentObject(AuthenticationService())
        .environmentObject(CareSphereTheme())
}
