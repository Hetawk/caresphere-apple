import SwiftUI

/// CareSphere Design System - Spacing and Layout
/// Single source of truth for all spacing, padding, and layout dimensions
struct CareSphereSpacing {
    
    // MARK: - Base Spacing Scale (8pt grid system)
    static let xs: CGFloat = 4      // Extra small
    static let sm: CGFloat = 8      // Small
    static let md: CGFloat = 16     // Medium
    static let lg: CGFloat = 24     // Large
    static let xl: CGFloat = 32     // Extra large
    static let xxl: CGFloat = 48    // 2x Extra large
    static let xxxl: CGFloat = 64   // 3x Extra large
    
    // MARK: - Semantic Spacing
    static let none: CGFloat = 0
    static let hairline: CGFloat = 1
    static let minimal: CGFloat = 2
    
    // MARK: - Component-Specific Spacing
    struct Padding {
        static let button = CareSphereSpacing.md
        static let card = CareSphereSpacing.lg
        static let screen = CareSphereSpacing.lg
        static let section = CareSphereSpacing.xl
        static let input = CareSphereSpacing.md
        static let list = CareSphereSpacing.sm
        static let modal = CareSphereSpacing.xl
    }
    
    struct Margin {
        static let element = CareSphereSpacing.md
        static let section = CareSphereSpacing.xl
        static let component = CareSphereSpacing.lg
    }
    
    struct Gap {
        static let text = CareSphereSpacing.xs
        static let elements = CareSphereSpacing.sm
        static let cards = CareSphereSpacing.md
        static let sections = CareSphereSpacing.xl
    }
}

/// CareSphere Design System - Border Radius and Elevation
struct CareSphereRadius {
    
    // MARK: - Border Radius Scale
    static let none: CGFloat = 0
    static let sm: CGFloat = 4
    static let md: CGFloat = 8
    static let lg: CGFloat = 12
    static let xl: CGFloat = 16
    static let xxl: CGFloat = 24
    static let full: CGFloat = 9999  // Fully rounded
    
    // MARK: - Component-Specific Radius
    struct Component {
        static let button = CareSphereRadius.md
        static let card = CareSphereRadius.lg
        static let input = CareSphereRadius.md
        static let modal = CareSphereRadius.xl
        static let badge = CareSphereRadius.full
        static let avatar = CareSphereRadius.full
        static let image = CareSphereRadius.md
    }
}

/// CareSphere Design System - Shadows and Elevation
struct CareSphereShadow {
    
    // MARK: - Shadow Definitions
    static let none = Shadow(color: .clear, radius: 0, x: 0, y: 0)
    
    static let sm = Shadow(
        color: CareSphereColors.shadowPrimary,
        radius: 2,
        x: 0,
        y: 1
    )
    
    static let md = Shadow(
        color: CareSphereColors.shadowPrimary,
        radius: 4,
        x: 0,
        y: 2
    )
    
    static let lg = Shadow(
        color: CareSphereColors.shadowPrimary,
        radius: 8,
        x: 0,
        y: 4
    )
    
    static let xl = Shadow(
        color: CareSphereColors.shadowPrimary,
        radius: 16,
        x: 0,
        y: 8
    )
    
    // MARK: - Component-Specific Shadows
    struct Component {
        static let card = CareSphereShadow.sm
        static let modal = CareSphereShadow.lg
        static let dropdown = CareSphereShadow.md
        static let tooltip = CareSphereShadow.sm
        static let fab = CareSphereShadow.md  // Floating Action Button
    }
}

/// Helper struct for consistent shadow application
struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - View Extension for Easy Shadow Application
extension View {
    func careSphereShadow(_ shadow: Shadow) -> some View {
        self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }
}

/// CareSphere Design System - Layout Breakpoints
struct CareSphereBreakpoints {
    
    // MARK: - Screen Size Breakpoints
    static let xs: CGFloat = 320    // iPhone SE
    static let sm: CGFloat = 375    // iPhone standard
    static let md: CGFloat = 414    // iPhone Plus
    static let lg: CGFloat = 768    // iPad portrait
    static let xl: CGFloat = 1024   // iPad landscape
    static let xxl: CGFloat = 1366  // Large desktop
    
    // MARK: - Platform-Specific Breakpoints
    struct iOS {
        static let compact: CGFloat = 414
        static let regular: CGFloat = 768
    }
    
    struct macOS {
        static let minimum: CGFloat = 800
        static let standard: CGFloat = 1024
        static let large: CGFloat = 1440
    }
    
    // MARK: - Responsive Helpers
    static func isCompact(width: CGFloat) -> Bool {
        return width < md
    }
    
    static func isRegular(width: CGFloat) -> Bool {
        return width >= md
    }
    
    static func isDesktop(width: CGFloat) -> Bool {
        return width >= lg
    }
}