import SwiftUI

/// View for entering email verification code during registration
struct VerificationCodeView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var theme: CareSphereTheme

    let email: String
    let onVerified: (String) -> Void
    let onResendCode: () async -> Void

    @State private var code = ""
    @State private var isVerifying = false
    @State private var errorMessage = ""
    @State private var showingError = false
    @State private var isResending = false
    @State private var showResendSuccess = false

    private let codeLength = 6

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
                        Image(systemName: "envelope.badge.shield.half.filled")
                            .font(.system(size: 60))
                            .foregroundColor(theme.colors.primary)
                            .padding(.top, CareSphereSpacing.xl)

                        Text("Verify Your Email")
                            .font(CareSphereTypography.displaySmall)
                            .fontWeight(.bold)
                            .foregroundColor(theme.colors.onBackground)

                        Text("Enter the 6-digit code sent to")
                            .font(CareSphereTypography.bodyMedium)
                            .foregroundColor(theme.colors.onSurface.opacity(0.7))

                        Text(email)
                            .font(CareSphereTypography.bodyMedium)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.colors.primary)
                    }
                    .padding(.horizontal)

                    // Code Input
                    VStack(spacing: CareSphereSpacing.lg) {
                        CodeInputField(
                            code: $code,
                            length: codeLength,
                            onComplete: verifyCode
                        )
                        .padding(.horizontal, CareSphereSpacing.xl)

                        if !code.isEmpty && code.count < codeLength {
                            Text("Enter all \(codeLength) digits")
                                .font(CareSphereTypography.bodySmall)
                                .foregroundColor(theme.colors.onSurface.opacity(0.6))
                        }
                    }

                    // Verify Button
                    CareSphereButton(
                        "Verify Code",
                        action: verifyCode,
                        style: .primary,
                        isLoading: isVerifying,
                        isDisabled: code.count != codeLength
                    )
                    .padding(.horizontal)

                    // Resend Code
                    VStack(spacing: CareSphereSpacing.sm) {
                        Text("Didn't receive the code?")
                            .font(CareSphereTypography.bodySmall)
                            .foregroundColor(theme.colors.onSurface.opacity(0.7))

                        Button(action: resendCode) {
                            if isResending {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Text("Resend Code")
                                    .font(CareSphereTypography.labelLarge)
                                    .fontWeight(.semibold)
                            }
                        }
                        .foregroundColor(theme.colors.primary)
                        .disabled(isResending)

                        if showResendSuccess {
                            Text("✓ Code sent successfully")
                                .font(CareSphereTypography.bodySmall)
                                .foregroundColor(theme.colors.success)
                                .transition(.opacity)
                        }
                    }
                    .padding(.top, CareSphereSpacing.md)
                }
                .padding(.vertical, CareSphereSpacing.xl)
            }

            // Back button
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(theme.colors.onSurface.opacity(0.5))
                    }
                    Spacer()
                }
                .padding()
                Spacer()
            }
        }
        .alert("Verification Error", isPresented: $showingError) {
            Button("OK") {
                code = ""  // Clear code on error
            }
        } message: {
            Text(errorMessage)
        }
    }

    private func verifyCode() {
        guard code.count == codeLength else { return }

        isVerifying = true
        // Pass the code to parent for actual verification
        onVerified(code)
        isVerifying = false
    }

    private func resendCode() {
        isResending = true
        showResendSuccess = false

        Task {
            await onResendCode()
            isResending = false
            showResendSuccess = true

            // Hide success message after 3 seconds
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            showResendSuccess = false
        }
    }
}

/// Custom code input field that shows individual boxes for each digit
struct CodeInputField: View {
    @Binding var code: String
    let length: Int
    let onComplete: () -> Void

    @EnvironmentObject private var theme: CareSphereTheme
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<length, id: \.self) { index in
                CodeDigitBox(
                    digit: digitAt(index: index),
                    isFocused: isFocused && index == code.count
                )
            }
        }
        .background(
            // Hidden TextField for keyboard input
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .focused($isFocused)
                .opacity(0)
                .frame(width: 1, height: 1)
                .onChange(of: code) { oldValue, newValue in
                    // Only allow numbers and limit length
                    let filtered = newValue.filter { $0.isNumber }
                    if filtered.count <= length {
                        code = filtered
                        if filtered.count == length {
                            isFocused = false
                            onComplete()
                        }
                    } else {
                        code = String(filtered.prefix(length))
                    }
                }
        )
        .onTapGesture {
            isFocused = true
        }
        .onAppear {
            // Auto-focus when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isFocused = true
            }
        }
    }

    private func digitAt(index: Int) -> String? {
        guard index < code.count else { return nil }
        return String(code[code.index(code.startIndex, offsetBy: index)])
    }
}

/// Single digit box in the code input
struct CodeDigitBox: View {
    let digit: String?
    let isFocused: Bool

    @EnvironmentObject private var theme: CareSphereTheme

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isFocused ? theme.colors.primary : theme.colors.onSurface.opacity(0.2),
                    lineWidth: isFocused ? 2 : 1
                )
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.colors.surface)
                )

            if let digit = digit {
                Text(digit)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundColor(theme.colors.onSurface)
            } else if isFocused {
                Rectangle()
                    .fill(theme.colors.primary)
                    .frame(width: 2, height: 24)
                    .animation(
                        .easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                        value: isFocused)
            }
        }
        .frame(width: 50, height: 60)
    }
}

// MARK: - Preview

#Preview("Verification Code View") {
    VerificationCodeView(
        email: "user@example.com",
        onVerified: { code in
            print("Code verified: \(code)")
        },
        onResendCode: {
            print("Resending code...")
        }
    )
    .environmentObject(CareSphereTheme.shared)
}
