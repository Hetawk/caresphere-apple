# CareSphere Brand Assets

This directory contains the official CareSphere logo files in SVG format, optimized for use across the application.

## Logo Files

### Light Mode

- **File:** `logo-caresphere-light.svg`
- **Usage:** Use on light backgrounds, navigation bars, and light theme contexts
- **Primary Color:** `#1F1C18` (Dark Brown)
- **Accent Colors:** `#C8A061` (Gold), `#D4AF6A` (Light Gold)
- **Background:** Transparent for versatile placement

### Dark Mode

- **File:** `logo-caresphere-dark.svg`
- **Usage:** Use on dark backgrounds, dark theme navigation, and dark mode contexts
- **Primary Color:** `#C8A061` (Gold) - promoted for dark mode visibility
- **Accent Colors:** `#E8C589` (Bright Gold), `#F7F6F4` (Near White)
- **Background:** Transparent for versatile placement

## Design Philosophy

The CareSphere logo embodies three core values:

1. **Care** - Represented by the heart symbol at the center
2. **Community** - Shown through connecting orbital dots
3. **Connection** - Visualized by the circular 'C' shape and sphere metaphor

## Technical Specifications

- **Format:** SVG (Scalable Vector Graphics)
- **Dimensions:** 1024×1024px (1:1 aspect ratio)
- **Color Space:** sRGB
- **Transparency:** Yes (transparent background)
- **Scalability:** Infinite (vector format)

## Usage Guidelines

### In SwiftUI

```swift
// Light mode
Image("logo-caresphere-light")
    .resizable()
    .aspectRatio(contentMode: .fit)

// Dark mode - use environment color scheme
Image(theme.currentColorScheme == .dark
    ? "logo-caresphere-dark"
    : "logo-caresphere-light")
    .resizable()
    .aspectRatio(contentMode: .fit)
```

### As App Icon

Both SVG files can be converted to PNG at required sizes for app icon sets:

- 1024×1024 (App Store)
- 512×512, 256×256, 128×128, 64×64, 32×32, 16×16 (macOS)
- Various iOS sizes (see Assets.xcassets/AppIcon.appiconset)

### Minimum Size

- Recommended minimum display size: 32×32px
- For smaller contexts, consider using a simplified icon variant

## Color Reference

### Light Mode Palette

- Primary: `#1F1C18` (rgb(31, 28, 24))
- Gold Accent: `#C8A061` (rgb(200, 160, 97))
- Light Gold: `#D4AF6A` (rgb(212, 175, 106))
- On-Primary: `#F7F6F4` (rgb(247, 246, 244))

### Dark Mode Palette

- Primary: `#C8A061` (rgb(200, 160, 97))
- Bright Gold: `#E8C589` (rgb(232, 197, 137))
- Light Gold: `#D4AF6A` (rgb(212, 175, 106))
- On-Primary: `#14120F` (rgb(20, 18, 15))
- Surface: `#F7F6F4` (rgb(247, 246, 244))

## Exporting for Production

To generate PNG assets from SVG:

```bash
# Using ImageMagick or similar tool
convert -background none -density 300 logo-caresphere-light.svg -resize 1024x1024 logo-light-1024.png

# Or use Xcode asset catalog to automatically generate all sizes
```

## Notes

- The transparent background allows flexible placement over any surface
- Both logos maintain consistent visual weight across light/dark contexts
- SVG format ensures crisp rendering at any size
- Gradients and filters are optimized for modern rendering engines

---

**Last Updated:** November 18, 2025  
**Designer:** EKD Digital  
**Project:** CareSphere / JICF Connect
