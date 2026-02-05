import SwiftUI
import Combine

/// CareSphere Design System - Theme Manager
/// Central coordinator for all theming across the application
/// Supports light/dark modes and organization-specific branding
@MainActor
class CareSphereTheme: ObservableObject {
    
    // MARK: - Singleton Instance
    static let shared = CareSphereTheme()
    
    // MARK: - Published Properties
    @Published var currentColorScheme: ColorScheme = .light
    @Published var organizationBranding: OrganizationBranding?
    @Published var accessibilitySettings: AccessibilitySettings = AccessibilitySettings()
    
    // MARK: - Initialization
    private init() {
        // Load saved theme preferences
        loadThemePreferences()
        
        // Listen for system color scheme changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(systemColorSchemeChanged),
            name: NSNotification.Name("NSSystemColorsDidChangeNotification"),
            object: nil
        )
    }
    
    // MARK: - Color Accessors
    var colors: CareSphereColorPalette {
        switch currentColorScheme {
        case .light:
            return lightColorPalette
        case .dark:
            return darkColorPalette
        @unknown default:
            return lightColorPalette
        }
    }
    
    // MARK: - Typography Accessors
    var typography: CareSphereTypographyTheme {
        return CareSphereTypographyTheme(
            scaleFactor: accessibilitySettings.textSizeScale
        )
    }
    
    // MARK: - Spacing Accessors
    var spacing: CareSphereSpacingTheme {
        return CareSphereSpacingTheme(
            scaleFactor: accessibilitySettings.spacingScale
        )
    }
    
    // MARK: - Theme Management Methods
    func setColorScheme(_ scheme: ColorScheme) {
        // Only update if different to avoid unnecessary view updates
        guard currentColorScheme != scheme else { return }
        currentColorScheme = scheme
        // Save asynchronously to avoid triggering logout
        Task {
            await MainActor.run {
                saveThemePreferences()
            }
        }
    }
    
    func setOrganizationBranding(_ branding: OrganizationBranding?) {
        organizationBranding = branding
        saveThemePreferences()
    }
    
    func updateAccessibilitySettings(_ settings: AccessibilitySettings) {
        accessibilitySettings = settings
        saveThemePreferences()
    }
    
    // MARK: - Private Methods
    private func loadThemePreferences() {
        // Load from UserDefaults or configuration
        if let colorSchemeRaw = UserDefaults.standard.object(forKey: "CareSphereColorScheme") as? String {
            currentColorScheme = colorSchemeRaw == "dark" ? .dark : .light
        }
        
        // Load organization branding if available
        if let brandingData = UserDefaults.standard.data(forKey: "CareSphereOrganizationBranding"),
           let branding = try? JSONDecoder().decode(OrganizationBranding.self, from: brandingData) {
            organizationBranding = branding
        }
        
        // Load accessibility settings
        if let accessibilityData = UserDefaults.standard.data(forKey: "CareSphereAccessibilitySettings"),
           let settings = try? JSONDecoder().decode(AccessibilitySettings.self, from: accessibilityData) {
            accessibilitySettings = settings
        }
    }
    
    private func saveThemePreferences() {
        UserDefaults.standard.set(currentColorScheme == .dark ? "dark" : "light", forKey: "CareSphereColorScheme")
        
        if let branding = organizationBranding,
           let brandingData = try? JSONEncoder().encode(branding) {
            UserDefaults.standard.set(brandingData, forKey: "CareSphereOrganizationBranding")
        }
        
        if let accessibilityData = try? JSONEncoder().encode(accessibilitySettings) {
            UserDefaults.standard.set(accessibilityData, forKey: "CareSphereAccessibilitySettings")
        }
    }
    
    @objc private func systemColorSchemeChanged() {
        // Optional: Auto-sync with system if user hasn't set a preference
        if UserDefaults.standard.object(forKey: "CareSphereColorScheme") == nil {
            // Use system preference
        }
    }
}

// MARK: - Supporting Data Structures

/// Organization-specific branding customizations
struct OrganizationBranding: Codable {
    let primaryColor: String        // Hex color code
    let secondaryColor: String?     // Optional secondary color
    let logoURL: String?           // Organization logo
    let organizationName: String   // Organization display name
    
    // Convert hex to Color
    var primarySwiftUIColor: Color {
        return Color(hex: primaryColor) ?? CareSphereColors.brandPrimary
    }
    
    var secondarySwiftUIColor: Color? {
        guard let secondary = secondaryColor else { return nil }
        return Color(hex: secondary)
    }
}

/// Accessibility-related theme settings
struct AccessibilitySettings: Codable {
    var textSizeScale: CGFloat = 1.0        // 0.8 to 2.0
    var spacingScale: CGFloat = 1.0         // 0.8 to 1.5
    var highContrastMode: Bool = false      // For better visibility
    var reduceMotion: Bool = false          // Disable animations
    var boldText: Bool = false              // Use bolder font weights
}

/// Theme-aware color palette
struct CareSphereColorPalette {
    let primary: Color
    let primaryVariant: Color
    let secondary: Color
    let secondaryVariant: Color
    let tertiary: Color
    let surface: Color
    let background: Color
    let error: Color
    let warning: Color
    let success: Color
    let onPrimary: Color
    let onSecondary: Color
    let onSurface: Color
    let onBackground: Color
    let onError: Color
}

/// Theme-aware typography
struct CareSphereTypographyTheme {
    let scaleFactor: CGFloat
    
    var headlineLarge: Font {
        return CareSphereTypography.headlineLarge.with(scale: scaleFactor)
    }
    
    var titleMedium: Font {
        return CareSphereTypography.titleMedium.with(scale: scaleFactor)
    }
    
    var bodyMedium: Font {
        return CareSphereTypography.bodyMedium.with(scale: scaleFactor)
    }
    
    // Add more typography variations as needed
}

/// Theme-aware spacing
struct CareSphereSpacingTheme {
    let scaleFactor: CGFloat
    
    var small: CGFloat {
        return CareSphereSpacing.sm * scaleFactor
    }
    
    var medium: CGFloat {
        return CareSphereSpacing.md * scaleFactor
    }
    
    var large: CGFloat {
        return CareSphereSpacing.lg * scaleFactor
    }
}

// MARK: - Light and Dark Color Palettes

private let lightColorPalette = CareSphereColorPalette(
    primary: CareSphereColors.brandPrimary,
    primaryVariant: CareSphereColors.brandPrimaryMuted,
    secondary: CareSphereColors.accentGold,
    secondaryVariant: CareSphereColors.accentMaroon,
    tertiary: CareSphereColors.accentNavy,
    surface: CareSphereColors.backgroundCard,
    background: CareSphereColors.backgroundPrimary,
    error: CareSphereColors.error,
    warning: CareSphereColors.warning,
    success: CareSphereColors.success,
    onPrimary: CareSphereColors.textOnPrimary,
    onSecondary: Color(red: 0.08, green: 0.07, blue: 0.06),  // Dark text on gold
    onSurface: CareSphereColors.textPrimary,
    onBackground: CareSphereColors.textPrimary,
    onError: CareSphereColors.textOnPrimary
)

private let darkColorPalette = CareSphereColorPalette(
    primary: CareSphereColors.accentGold,  // Gold stands out better in dark mode
    primaryVariant: CareSphereColors.brandPrimaryMuted,
    secondary: CareSphereColors.accentGold,
    secondaryVariant: CareSphereColors.accentMaroon,
    tertiary: CareSphereColors.accentNavy,
    surface: Color(red: 0.14, green: 0.12, blue: 0.10),  // Dark brown surface
    background: Color(red: 0.08, green: 0.07, blue: 0.06),  // Darker background
    error: CareSphereColors.error,
    warning: CareSphereColors.warning,
    success: CareSphereColors.success,
    onPrimary: Color(red: 0.08, green: 0.07, blue: 0.06),  // Dark text on gold
    onSecondary: Color(red: 0.08, green: 0.07, blue: 0.06),  // Dark text on gold
    onSurface: Color(red: 0.95, green: 0.95, blue: 0.95),  // Light gray text on dark surface
    onBackground: Color(red: 0.98, green: 0.98, blue: 0.98),  // Almost white text on dark background
    onError: CareSphereColors.foregroundLight
)

// MARK: - Helper Extensions

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension Font {
    func with(scale: CGFloat) -> Font {
        // This is a simplified implementation
        // In a real app, you'd need more sophisticated font scaling
        return self
    }
}