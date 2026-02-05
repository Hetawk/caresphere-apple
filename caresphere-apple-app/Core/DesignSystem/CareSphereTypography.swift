import SwiftUI

/// CareSphere Design System - Typography
/// Single source of truth for all typography styles used across the application
struct CareSphereTypography {
    
    // MARK: - Font Families
    static let primaryFontFamily = "SF Pro"  // System font on Apple platforms
    static let secondaryFontFamily = "SF Pro Rounded"  // For special emphasis
    
    // MARK: - Font Weights
    struct FontWeights {
        static let thin: Font.Weight = .thin
        static let light: Font.Weight = .light
        static let regular: Font.Weight = .regular
        static let medium: Font.Weight = .medium
        static let semibold: Font.Weight = .semibold
        static let bold: Font.Weight = .bold
        static let heavy: Font.Weight = .heavy
    }
    
    // MARK: - Display Styles (Large headings)
    static let displayLarge = Font.system(size: 57, weight: .regular, design: .default)
    static let displayMedium = Font.system(size: 45, weight: .regular, design: .default)
    static let displaySmall = Font.system(size: 36, weight: .regular, design: .default)
    
    // MARK: - Headline Styles
    static let headlineLarge = Font.system(size: 32, weight: .regular, design: .default)
    static let headlineMedium = Font.system(size: 28, weight: .regular, design: .default)
    static let headlineSmall = Font.system(size: 24, weight: .regular, design: .default)
    
    // MARK: - Title Styles
    static let titleLarge = Font.system(size: 22, weight: .regular, design: .default)
    static let titleMedium = Font.system(size: 16, weight: .medium, design: .default)
    static let titleSmall = Font.system(size: 14, weight: .medium, design: .default)
    
    // MARK: - Label Styles
    static let labelLarge = Font.system(size: 14, weight: .medium, design: .default)
    static let labelMedium = Font.system(size: 12, weight: .medium, design: .default)
    static let labelSmall = Font.system(size: 11, weight: .medium, design: .default)
    
    // MARK: - Body Styles
    static let bodyLarge = Font.system(size: 16, weight: .regular, design: .default)
    static let bodyMedium = Font.system(size: 14, weight: .regular, design: .default)
    static let bodySmall = Font.system(size: 12, weight: .regular, design: .default)
    
    // MARK: - Caption Styles
    static let caption = Font.system(size: 12, weight: .regular, design: .default)
    static let captionEmphasis = Font.system(size: 12, weight: .medium, design: .default)
    static let overline = Font.system(size: 10, weight: .medium, design: .default).uppercaseSmallCaps()
}

// MARK: - Typography Styles for Specific Components
extension CareSphereTypography {
    
    /// Navigation and UI element typography
    struct Navigation {
        static let tabBarLabel = CareSphereTypography.labelMedium
        static let navigationTitle = CareSphereTypography.titleLarge
        static let navigationAction = CareSphereTypography.bodyMedium
        static let breadcrumb = CareSphereTypography.labelSmall
    }
    
    /// Button typography styles
    struct Buttons {
        static let primary = CareSphereTypography.labelLarge
        static let secondary = CareSphereTypography.labelMedium
        static let tertiary = CareSphereTypography.labelMedium
        static let link = CareSphereTypography.bodyMedium
    }
    
    /// Form and input typography
    struct Forms {
        static let label = CareSphereTypography.labelMedium
        static let input = CareSphereTypography.bodyMedium
        static let placeholder = CareSphereTypography.bodyMedium
        static let helperText = CareSphereTypography.caption
        static let errorText = CareSphereTypography.caption
    }
    
    /// Card and list typography
    struct Cards {
        static let title = CareSphereTypography.titleMedium
        static let subtitle = CareSphereTypography.bodySmall
        static let body = CareSphereTypography.bodyMedium
        static let metadata = CareSphereTypography.caption
    }
    
    /// Dashboard and analytics typography
    struct Dashboard {
        static let sectionTitle = CareSphereTypography.headlineSmall
        static let metricValue = CareSphereTypography.displaySmall
        static let metricLabel = CareSphereTypography.labelMedium
        static let chartLabel = CareSphereTypography.bodySmall
    }
}

// MARK: - Line Height and Spacing
extension CareSphereTypography {
    
    /// Standard line heights for different typography styles
    struct LineHeight {
        static let tight: CGFloat = 1.1
        static let normal: CGFloat = 1.4
        static let relaxed: CGFloat = 1.6
        static let loose: CGFloat = 1.8
    }
    
    /// Letter spacing values
    struct LetterSpacing {
        static let tight: CGFloat = -0.5
        static let normal: CGFloat = 0
        static let wide: CGFloat = 0.5
        static let wider: CGFloat = 1.0
    }
}