import SwiftUI

/// Organization onboarding view for new user registration
/// Allows users to create, join, or skip organization setup
struct OrganizationOnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var theme: CareSphereTheme

    @State private var selectedOption: OrganizationOption = .skip
    @State private var organizationName = ""
    @State private var organizationCode = ""
    @State private var isValidCode = true

    let onComplete: (OrganizationOption, String?, String?) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: CareSphereSpacing.xl) {
                // Header
                VStack(spacing: CareSphereSpacing.md) {
                    Image(systemName: "building.2")
                        .font(.system(size: 64))
                        .foregroundColor(theme.colors.primary)

                    Text("Organization Setup")
                        .font(CareSphereTypography.displaySmall)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.onBackground)

                    Text("Choose how you want to get started")
                        .font(CareSphereTypography.bodyLarge)
                        .foregroundColor(theme.colors.onSurface.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, CareSphereSpacing.xl)

                // Options
                VStack(spacing: CareSphereSpacing.lg) {
                    // Create Organization Option
                    OptionCard(
                        icon: "plus.circle.fill",
                        title: "Create Organization",
                        description: "Start fresh with your own organization",
                        isSelected: selectedOption == .create,
                        action: { selectedOption = .create }
                    )

                    if selectedOption == .create {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Organization Name")
                                .font(CareSphereTypography.bodySmall)
                                .fontWeight(.medium)
                                .foregroundColor(theme.colors.onSurface.opacity(0.7))

                            TextField(
                                "",
                                text: $organizationName,
                                prompt: Text("Enter organization name")
                                    .foregroundColor(theme.colors.onSurface.opacity(0.4))
                            )
                            .textFieldStyle(CareSphereTextFieldStyle())
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // Join Organization Option
                    OptionCard(
                        icon: "person.2.fill",
                        title: "Join Organization",
                        description: "Enter the organization code to join an existing organization",
                        isSelected: selectedOption == .join,
                        action: { selectedOption = .join }
                    )

                    if selectedOption == .join {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Organization Code")
                                .font(CareSphereTypography.bodySmall)
                                .fontWeight(.medium)
                                .foregroundColor(theme.colors.onSurface.opacity(0.7))

                            TextField(
                                "",
                                text: $organizationCode,
                                prompt: Text("Enter organization code")
                                    .foregroundColor(theme.colors.onSurface.opacity(0.4))
                            )
                            .textFieldStyle(CareSphereTextFieldStyle())
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .onChange(of: organizationCode) { _, newValue in
                                // Limit to 20 characters
                                if newValue.count > 20 {
                                    organizationCode = String(newValue.prefix(20))
                                }
                                validateCode()
                            }

                            if !isValidCode && !organizationCode.isEmpty {
                                Text("Code must be 4-20 alphanumeric characters")
                                    .font(CareSphereTypography.bodySmall)
                                    .foregroundColor(theme.colors.error)
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // Skip Option
                    OptionCard(
                        icon: "arrow.right.circle",
                        title: "Skip for Now",
                        description: "You can set up your organization later",
                        isSelected: selectedOption == .skip,
                        action: { selectedOption = .skip }
                    )
                }
                .padding(.horizontal, CareSphereSpacing.lg)

                // Continue Button
                CareSphereButton(
                    "Continue",
                    action: handleContinue,
                    style: .primary,
                    isDisabled: !isFormValid
                )
                .padding(.horizontal, CareSphereSpacing.lg)
                .padding(.top, CareSphereSpacing.md)
            }
            .padding(.bottom, CareSphereSpacing.xl)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    theme.colors.primary.opacity(0.05),
                    theme.colors.background,
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedOption)
    }

    private var isFormValid: Bool {
        switch selectedOption {
        case .create:
            return !organizationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .join:
            return isValidCode && organizationCode.count >= 4
        case .skip:
            return true
        }
    }

    private func validateCode() {
        let code = organizationCode
        isValidCode =
            code.isEmpty
            || (code.count >= 4 && code.count <= 20
                && code.allSatisfy { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" })
    }

    private func handleContinue() {
        switch selectedOption {
        case .create:
            onComplete(.create, organizationName, nil)
        case .join:
            onComplete(.join, nil, organizationCode)
        case .skip:
            onComplete(.skip, nil, nil)
        }
    }
}

/// Reusable option card component
struct OptionCard: View {
    @EnvironmentObject private var theme: CareSphereTheme

    let icon: String
    let title: String
    let description: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: CareSphereSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(
                        isSelected ? theme.colors.primary : theme.colors.onSurface.opacity(0.5)
                    )
                    .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(CareSphereTypography.titleMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.onSurface)

                    Text(description)
                        .font(CareSphereTypography.bodySmall)
                        .foregroundColor(theme.colors.onSurface.opacity(0.7))
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(
                        isSelected ? theme.colors.primary : theme.colors.onSurface.opacity(0.3))
            }
            .padding(CareSphereSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: CareSphereRadius.md)
                    .fill(theme.colors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: CareSphereRadius.md)
                            .stroke(
                                isSelected
                                    ? theme.colors.primary : theme.colors.onSurface.opacity(0.2),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    OrganizationOnboardingView { option, name, code in
        print("Selected: \(option), Name: \(name ?? "nil"), Code: \(code ?? "nil")")
    }
    .environmentObject(CareSphereTheme.shared)
}
