import SwiftUI

/// View for requesting a password reset via email
struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authService: AuthenticationService
    @EnvironmentObject private var theme: CareSphereTheme

    @State private var email = ""
    @State private var isLoading = false
    @State private var showingSuccess = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingResetView = false

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
                        Image(systemName: "lock.rotation")
                            .font(.system(size: 60))
                            .foregroundColor(theme.colors.primary)
                            .padding(.bottom, CareSphereSpacing.sm)

                        Text("Forgot Password?")
                            .font(CareSphereTypography.displaySmall)
                            .fontWeight(.bold)
                            .foregroundColor(theme.colors.onBackground)

                        Text(
                            "Enter your email address and we'll send you a code to reset your password"
                        )
                        .font(CareSphereTypography.bodyMedium)
                        .foregroundColor(theme.colors.onSurface.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    }

                    // Form card
                    VStack(spacing: CareSphereSpacing.lg) {
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

                        // Send reset code button
                        CareSphereButton(
                            "Send Reset Code",
                            action: sendResetCode,
                            style: .primary,
                            isLoading: isLoading,
                            isDisabled: email.isEmpty || !isValidEmail
                        )

                        // Back to login button
                        Button(action: { dismiss() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.left")
                                    .font(.system(size: 14))
                                Text("Back to Login")
                                    .font(CareSphereTypography.bodyMedium)
                                    .fontWeight(.medium)
                            }
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
        .sheet(isPresented: $showingResetView) {
            ResetPasswordView(email: email)
                .environmentObject(authService)
                .environmentObject(theme)
        }
        .alert("Reset Code Sent", isPresented: $showingSuccess) {
            Button("Enter Code") {
                showingResetView = true
            }
            Button("OK") {}
        } message: {
            Text("We've sent a password reset code to \(email). Please check your email.")
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }

    private var isValidEmail: Bool {
        email.contains("@") && email.contains(".")
    }

    private func sendResetCode() {
        guard !email.isEmpty, isValidEmail else { return }

        Task {
            isLoading = true
            defer { isLoading = false }

            let result = await authService.forgotPassword(email: email)

            if result.success {
                showingSuccess = true
            } else {
                errorMessage = result.message ?? "Failed to send reset code. Please try again."
                showingError = true
            }
        }
    }
}

#Preview {
    ForgotPasswordView()
        .environmentObject(AuthenticationService())
        .environmentObject(CareSphereTheme())
}
