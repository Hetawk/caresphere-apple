# CareSphere Apple

> **Connect, Care, Community** - Modern member care and communication platform for iOS and macOS

[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20macOS-blue.svg)](https://developer.apple.com)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

## Features

**👥 Member Management** - Comprehensive profiles, search, status tracking, and care history  
**💬 Multi-Channel Messaging** - Email, SMS, push, in-app with templates and automation  
**📊 Analytics & Insights** - Engagement metrics, trends, and customizable dashboards  
**🤖 Smart Automation** - Workflow builder with event triggers and follow-ups  
**🎨 Design System** - Consistent UI with centralized theming and branding

## Quick Start

### Prerequisites

- Xcode 15.0+
- iOS 17.0+ / macOS 14.0+
- Swift 5.9+

### Setup

```bash
git clone https://github.com/Hetawk/caresphere-apple.git
cd caresphere-apple
cp .env.example .env
open caresphere-apple.xcodeproj
```

### Environment Configuration

Edit `.env` file with your settings:

```env
API_BASE_URL=https://api.caresphere.app
ENABLE_PUSH_NOTIFICATIONS=true
DEBUG_MODE=true
```

## Architecture

### Clean Modular Design

```
caresphere-apple/
├── Core/                   # 🔧 Shared architecture
│   ├── DesignSystem/       # 🎨 Theme, colors, components
│   ├── Models/             # 📋 Data structures
│   └── Services/           # 🌐 API & business logic
├── Features/               # 🏠 Feature modules
│   ├── Authentication/     # 🔐 Login & session
│   ├── Dashboard/          # 📊 Main overview
│   ├── Members/            # 👥 Member management
│   └── Messages/           # 💬 Communication
└── Platform/               # 📱 iOS & macOS specific
```

### Design Principles

- **DRY**: Single source of truth for styling and logic
- **Modular**: Clear feature boundaries and reusable components
- **Reactive**: SwiftUI state management with @ObservableObject
- **Testable**: Dependency injection for clean testing

## Development

```bash
TestMail: admin@jinanicf.com
TestPWD: admin123

```

### Design System Usage

```swift
// Consistent styling
Text("Welcome")
    .font(CareSphereTypography.titleLarge)
    .foregroundColor(theme.colors.primary)

// Reusable components
CareSphereButton("Save", action: save, style: .primary)
CareSphereCard { /* content */ }
```

### Adding Features

1. Create module in `Features/YourFeature/`
2. Use `CareSphere` prefixed components
3. Follow established patterns and naming
4. Add tests for new functionality

## Contributing

1. Fork and create feature branch: `git checkout -b feature/amazing-feature`
2. Follow existing code patterns and use SwiftLint
3. Add tests and documentation
4. Submit pull request with clear description

## Deployment

**iOS/macOS App Store**: Archive → Upload to App Store Connect → Submit  
**Enterprise**: Configure certificates → Build with enterprise profile → Distribute

## Support

- 🐛 **Issues**: [GitHub Issues](https://github.com/Hetawk/caresphere-apple/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/Hetawk/caresphere-apple/discussions)
- 📚 **Docs**: [docs.caresphere.app](https://docs.caresphere.app)

---

<p align="center">
  <strong>CareSphere</strong> - Empowering organizations to build stronger communities
</p>


## Build and lunch
```bash
cd swift/caresphere-apple
xcodebuild -scheme caresphere-apple -configuration Debug \
  -derivedDataPath /tmp/caresphere-build \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

xcrun simctl install "iPhone 17 Pro" \
  /tmp/caresphere-build/Build/Products/Debug-iphonesimulator/caresphere-apple.app

xcrun simctl launch "iPhone 17 Pro" ekddigital.caresphere-apple
```
