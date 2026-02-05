import SwiftUI

// MARK: - Button Component

/// Reusable button component with CareSphere styling
public struct CareSphereButton: View {
    @EnvironmentObject private var theme: CareSphereTheme
    let title: String
    let action: () -> Void
    let style: ButtonStyle
    let isLoading: Bool
    let isDisabled: Bool

    public enum ButtonStyle {
        case primary, secondary, tertiary, destructive
    }

    public init(
        _ title: String,
        action: @escaping () -> Void,
        style: ButtonStyle = .primary,
        isLoading: Bool = false,
        isDisabled: Bool = false
    ) {
        self.title = title
        self.action = action
        self.style = style
        self.isLoading = isLoading
        self.isDisabled = isDisabled
    }

    public var body: some View {
        Group {
            switch style {
            case .primary:
                Button(action: isLoading || isDisabled ? {} : action) {
                    buttonContent
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(isLoading || isDisabled)
            case .secondary:
                Button(action: isLoading || isDisabled ? {} : action) {
                    buttonContent
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(isLoading || isDisabled)
            case .tertiary:
                Button(action: isLoading || isDisabled ? {} : action) {
                    buttonContent
                }
                .buttonStyle(TertiaryButtonStyle())
                .disabled(isLoading || isDisabled)
            case .destructive:
                Button(action: isLoading || isDisabled ? {} : action) {
                    buttonContent
                }
                .buttonStyle(DestructiveButtonStyle())
                .disabled(isLoading || isDisabled)
            }
        }
    }

    @ViewBuilder
    private var buttonContent: some View {
        HStack(spacing: CareSphereSpacing.sm) {
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(textColor)
            } else {
                Text(title)
            }
        }
    }

    private var textColor: Color {
        switch style {
        case .primary, .destructive:
            return .white
        case .secondary, .tertiary:
            return theme.colors.primary
        }
    }
}

// MARK: - Button Styles

/// CareSphere button style system
struct CareSphereButtonStyle {

    /// Primary button style for main actions
    static let primary = PrimaryButtonStyle()

    /// Secondary button style for secondary actions
    static let secondary = SecondaryButtonStyle()

    /// Tertiary button style for subtle actions
    static let tertiary = TertiaryButtonStyle()

    /// Destructive button style for dangerous actions
    static let destructive = DestructiveButtonStyle()
}

struct PrimaryButtonStyle: ButtonStyle {
    @EnvironmentObject private var theme: CareSphereTheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(CareSphereTypography.Buttons.primary)
            .foregroundColor(theme.colors.onPrimary)
            .padding(.horizontal, CareSphereSpacing.lg)
            .padding(.vertical, CareSphereSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: CareSphereRadius.Component.button)
                    .fill(theme.colors.secondary) // Use gold accent
                    .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
                    .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            )
            .careSphereShadow(CareSphereShadow.Component.card)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @EnvironmentObject private var theme: CareSphereTheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(CareSphereTypography.Buttons.secondary)
            .foregroundColor(theme.colors.secondary) // Gold text
            .padding(.horizontal, CareSphereSpacing.lg)
            .padding(.vertical, CareSphereSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: CareSphereRadius.Component.button)
                    .strokeBorder(theme.colors.secondary, lineWidth: 1.5) // Gold border
                    .background(
                        RoundedRectangle(cornerRadius: CareSphereRadius.Component.button)
                            .fill(
                                configuration.isPressed
                                    ? theme.colors.secondary.opacity(0.1) : Color.clear)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct TertiaryButtonStyle: ButtonStyle {
    @EnvironmentObject private var theme: CareSphereTheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(CareSphereTypography.Buttons.tertiary)
            .foregroundColor(theme.colors.secondary) // Gold text for tertiary actions
            .padding(.horizontal, CareSphereSpacing.sm)
            .padding(.vertical, CareSphereSpacing.xs)
            .background(
                RoundedRectangle(cornerRadius: CareSphereRadius.sm)
                    .fill(configuration.isPressed ? theme.colors.secondary.opacity(0.1) : Color.clear)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct DestructiveButtonStyle: ButtonStyle {
    @EnvironmentObject private var theme: CareSphereTheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(CareSphereTypography.Buttons.primary)
            .foregroundColor(.white)
            .padding(.horizontal, CareSphereSpacing.lg)
            .padding(.vertical, CareSphereSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: CareSphereRadius.Component.button)
                    .fill(CareSphereColors.error)
                    .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
                    .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            )
            .careSphereShadow(CareSphereShadow.Component.card)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
    }
}

// MARK: - Text Field Styles

/// CareSphere text field style
struct CareSphereTextFieldStyle: TextFieldStyle {
    @EnvironmentObject private var theme: CareSphereTheme
    @State private var isFocused = false

    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(CareSphereTypography.Forms.input)
            .padding(.horizontal, CareSphereSpacing.md)
            .padding(.vertical, CareSphereSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: CareSphereRadius.Component.input)
                    .strokeBorder(
                        isFocused ? theme.colors.primary : CareSphereColors.borderMedium,
                        lineWidth: isFocused ? 2 : 1
                    )
                    .background(
                        RoundedRectangle(cornerRadius: CareSphereRadius.Component.input)
                            .fill(theme.colors.surface)
                    )
            )
            .onTapGesture {
                isFocused = true
            }
            .onSubmit {
                isFocused = false
            }
    }
}

// MARK: - Card Components

/// Reusable card component with CareSphere styling
struct CareSphereCard<Content: View>: View {
    @EnvironmentObject private var theme: CareSphereTheme
    let content: Content
    let padding: CGFloat

    init(padding: CGFloat = CareSphereSpacing.lg, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.padding = padding
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: CareSphereRadius.Component.card)
                    .fill(theme.colors.surface)
                    .careSphereShadow(CareSphereShadow.Component.card)
            )
    }
}

// MARK: - Loading Components

/// Loading indicator with CareSphere styling
struct CareSphereLoadingView: View {
    @EnvironmentObject private var theme: CareSphereTheme
    let message: String

    init(_ message: String = "Loading...") {
        self.message = message
    }

    var body: some View {
        VStack(spacing: CareSphereSpacing.md) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: theme.colors.primary))
                .scaleEffect(1.5)

            Text(message)
                .font(CareSphereTypography.bodyMedium)
                .foregroundColor(theme.colors.onSurface.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.colors.background.opacity(0.8))
    }
}

// MARK: - Error Components

/// Error view with retry functionality
struct CareSphereErrorView: View {
    @EnvironmentObject private var theme: CareSphereTheme
    let error: APIError
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: CareSphereSpacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(CareSphereColors.error)

            Text("Something went wrong")
                .font(CareSphereTypography.titleMedium)
                .foregroundColor(theme.colors.onBackground)

            Text(error.errorDescription ?? "Unknown error occurred")
                .font(CareSphereTypography.bodyMedium)
                .foregroundColor(theme.colors.onSurface.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, CareSphereSpacing.xl)

            Button(action: retryAction) {
                Text("Try Again")
                    .font(CareSphereTypography.Buttons.primary)
            }
            .buttonStyle(CareSphereButtonStyle.primary)
        }
        .padding(CareSphereSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.colors.background)
    }
}

// MARK: - Status Badge Component

/// Status badge for member status, message priority, etc.
struct CareSphereStatusBadge: View {
    @EnvironmentObject private var theme: CareSphereTheme
    let text: String
    let color: StatusColor
    let size: BadgeSize

    enum StatusColor {
        case primary
        case success
        case warning
        case error
        case secondary

        func color(in theme: CareSphereTheme) -> Color {
            switch self {
            case .primary:
                return theme.colors.primary
            case .success:
                return CareSphereColors.success
            case .warning:
                return CareSphereColors.warning
            case .error:
                return CareSphereColors.error
            case .secondary:
                return CareSphereColors.textSecondary
            }
        }

        func backgroundColor(in theme: CareSphereTheme) -> Color {
            color(in: theme).opacity(0.1)
        }
    }

    enum BadgeSize {
        case small
        case medium
        case large

        var font: Font {
            switch self {
            case .small:
                return CareSphereTypography.caption
            case .medium:
                return CareSphereTypography.labelSmall
            case .large:
                return CareSphereTypography.labelMedium
            }
        }

        var padding: EdgeInsets {
            switch self {
            case .small:
                return EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6)
            case .medium:
                return EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
            case .large:
                return EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
            }
        }
    }

    init(_ text: String, color: StatusColor = .primary, size: BadgeSize = .medium) {
        self.text = text
        self.color = color
        self.size = size
    }

    var body: some View {
        Text(text)
            .font(size.font)
            .foregroundColor(color.color(in: theme))
            .padding(size.padding)
            .background(
                Capsule()
                    .fill(color.backgroundColor(in: theme))
            )
    }
}

// MARK: - Avatar Component

/// User/member avatar component
struct CareSphereAvatar: View {
    @EnvironmentObject private var theme: CareSphereTheme
    let imageURL: URL?
    let name: String
    let size: CGFloat

    init(imageURL: URL? = nil, name: String, size: CGFloat = 40) {
        self.imageURL = imageURL
        self.name = name
        self.size = size
    }

    var body: some View {
        Group {
            if let imageURL = imageURL {
                AsyncImage(url: imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    avatarPlaceholder
                }
            } else {
                avatarPlaceholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var avatarPlaceholder: some View {
        ZStack {
            Circle()
                .fill(theme.colors.primary.opacity(0.1))

            Text(initials)
                .font(.system(size: size * 0.4, weight: .medium))
                .foregroundColor(theme.colors.primary)
        }
    }

    private var initials: String {
        let components = name.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1)) + String(components[1].prefix(1))
        } else if let first = components.first {
            return String(first.prefix(2))
        }
        return "?"
    }
}

// MARK: - Empty State Component

/// Empty state view for lists and collections
struct CareSphereEmptyState: View {
    @EnvironmentObject private var theme: CareSphereTheme
    let icon: String
    let title: String
    let description: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        icon: String,
        title: String,
        description: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.description = description
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: CareSphereSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(theme.colors.onSurface.opacity(0.3))

            VStack(spacing: CareSphereSpacing.sm) {
                Text(title)
                    .font(CareSphereTypography.titleMedium)
                    .foregroundColor(theme.colors.onBackground)

                Text(description)
                    .font(CareSphereTypography.bodyMedium)
                    .foregroundColor(theme.colors.onSurface.opacity(0.7))
                    .multilineTextAlignment(.center)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                }
                .buttonStyle(CareSphereButtonStyle.primary)
            }
        }
        .padding(CareSphereSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Search Bar Component

/// Search bar with CareSphere styling
struct CareSphereSearchBar: View {
    @EnvironmentObject private var theme: CareSphereTheme
    @Binding var text: String
    let placeholder: String
    let onSearchButtonClicked: (() -> Void)?

    init(
        text: Binding<String>,
        placeholder: String = "Search...",
        onSearchButtonClicked: (() -> Void)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.onSearchButtonClicked = onSearchButtonClicked
    }

    var body: some View {
        HStack(spacing: CareSphereSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(theme.colors.onSurface.opacity(0.6))

            TextField(
                "",
                text: $text,
                prompt: Text(placeholder)
                    .foregroundColor(theme.colors.onSurface.opacity(0.4))
                    .font(CareSphereTypography.bodyMedium)
            )
            .foregroundColor(theme.colors.onSurface)
            .tint(theme.colors.secondary)
            .onSubmit {
                onSearchButtonClicked?()
            }

            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(theme.colors.onSurface.opacity(0.6))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, CareSphereSpacing.md)
        .padding(.vertical, CareSphereSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CareSphereRadius.Component.input)
                .fill(theme.colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: CareSphereRadius.Component.input)
                        .strokeBorder(CareSphereColors.borderLight)
                )
        )
    }
}
