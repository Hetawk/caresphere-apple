import SwiftUI

/// CareSphere Design System - Color Tokens
/// Single source of truth for all colors used across the application
struct CareSphereColors {
    
    // MARK: - Brand Palette (EKD Digital)
    static let brandPrimary = Color(red: 31/255, green: 28/255, blue: 24/255)              // #1F1C18
    static let brandPrimaryMuted = Color(red: 26/255, green: 26/255, blue: 26/255)         // #1A1A1A
    static let brandPrimaryLight = Color(red: 212/255, green: 175/255, blue: 106/255)      // #D4AF6A
    static let accentGold = Color(red: 200/255, green: 160/255, blue: 97/255)              // #C8A061
    static let accentMaroon = Color(red: 142/255, green: 14/255, blue: 0/255)              // #8E0E00
    static let accentNavy = Color(red: 24/255, green: 46/255, blue: 95/255)                // #182E5F
    static let foregroundLight = Color(red: 230/255, green: 230/255, blue: 230/255)        // #E6E6E6
    
    // MARK: - Semantic Colors
    static let success = brandPrimaryLight
    static let warning = accentGold
    static let error = accentMaroon
    static let info = accentNavy
    
    // MARK: - Text Colors
    static let textPrimary = brandPrimaryMuted
    static let textSecondary = Color(red: 26/255, green: 26/255, blue: 26/255, opacity: 0.6)
    static let textTertiary = Color(red: 26/255, green: 26/255, blue: 26/255, opacity: 0.35)
    static let textOnPrimary = foregroundLight
    
    // MARK: - Background Colors
    static let backgroundPrimary = Color(red: 0.97, green: 0.95, blue: 0.93)       // soft parchment
    static let backgroundSecondary = Color(red: 0.94, green: 0.90, blue: 0.86)     // warm neutral
    static let backgroundTertiary = Color(red: 0.99, green: 0.98, blue: 0.96)
    static let backgroundCard = Color(red: 1.0, green: 0.99, blue: 0.97)
    
    // MARK: - Border Colors
    static let borderLight = Color(red: 0.89, green: 0.83, blue: 0.76)
    static let borderMedium = Color(red: 0.74, green: 0.66, blue: 0.57)
    static let borderDark = Color(red: 0.54, green: 0.47, blue: 0.38)
    
    // MARK: - Surface Colors
    static let surfaceElevated = Color(red: 1.0, green: 0.99, blue: 0.98)
    static let surfacePressed = Color(red: 0.91, green: 0.86, blue: 0.79)
    static let surfaceHover = Color(red: 0.95, green: 0.90, blue: 0.83)
    
    // MARK: - Shadow Colors
    static let shadowPrimary = Color.black.opacity(0.12)
    static let shadowSecondary = Color.black.opacity(0.06)
    
    // MARK: - Dark Mode Support (Future)
    // TODO: Implement dark mode color variants
    // These will be added when dark mode support is implemented
}

// MARK: - Semantic Color Extensions
extension CareSphereColors {
    /// Colors for different user roles
    struct UserRoles {
        static let superAdmin = CareSphereColors.brandPrimary
        static let admin = CareSphereColors.accentNavy
        static let ministryLeader = CareSphereColors.accentMaroon
        static let volunteer = CareSphereColors.brandPrimaryLight
        static let member = CareSphereColors.textSecondary
    }
    
    /// Colors for different message priorities
    struct MessagePriority {
        static let urgent = CareSphereColors.error
        static let high = CareSphereColors.warning
        static let normal = CareSphereColors.brandPrimary
        static let low = CareSphereColors.textSecondary
    }
    
    /// Colors for different member status
    struct MemberStatus {
        static let active = CareSphereColors.success
        static let inactive = CareSphereColors.textSecondary
        static let needsFollowUp = CareSphereColors.warning
        static let archived = CareSphereColors.borderMedium
    }
}