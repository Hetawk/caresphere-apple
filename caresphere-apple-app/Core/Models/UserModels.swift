import Foundation

// MARK: - User Management Models

/// User model representing authenticated users in the system
struct User: Codable, Identifiable, Equatable {
    let id: String
    let email: String
    let fullName: String
    let displayName: String?
    let avatarUrl: String?
    let role: UserRole
    let status: UserStatus
    let emailVerified: Bool
    let lastLoginAt: String?
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, email, role, status
        case fullName = "full_name"
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case emailVerified = "email_verified"
        case lastLoginAt = "last_login_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // Computed properties for backward compatibility
    var firstName: String {
        let components = fullName.split(separator: " ")
        return components.first.map(String.init) ?? fullName
    }

    var lastName: String {
        let components = fullName.split(separator: " ")
        return components.count > 1 ? components.dropFirst().joined(separator: " ") : ""
    }

    var effectiveDisplayName: String {
        return displayName ?? fullName
    }
}

/// User status enumeration
enum UserStatus: String, Codable, CaseIterable {
    case active = "active"
    case inactive = "inactive"
    case suspended = "suspended"

    var displayName: String {
        switch self {
        case .active:
            return "Active"
        case .inactive:
            return "Inactive"
        case .suspended:
            return "Suspended"
        }
    }
}

/// User roles with associated permissions
enum UserRole: String, Codable, CaseIterable {
    case superAdmin = "super_admin"
    case admin = "admin"
    case ministryLeader = "ministry_leader"
    case volunteer = "volunteer"
    case member = "member"

    var displayName: String {
        switch self {
        case .superAdmin:
            return "Super Admin"
        case .admin:
            return "Admin"
        case .ministryLeader:
            return "Ministry Leader"
        case .volunteer:
            return "Volunteer"
        case .member:
            return "Member"
        }
    }

    var permissions: UserPermissions {
        switch self {
        case .superAdmin:
            return UserPermissions.all
        case .admin:
            return UserPermissions.admin
        case .ministryLeader:
            return UserPermissions.ministryLeader
        case .volunteer:
            return UserPermissions.volunteer
        case .member:
            return UserPermissions.member
        }
    }
}

/// Fine-grained permission system
struct UserPermissions: Codable, Equatable {
    let manageUsers: Bool
    let manageMembers: Bool
    let sendMessages: Bool
    let viewAnalytics: Bool
    let manageAutomation: Bool
    let manageTemplates: Bool
    let manageOrganization: Bool
    let manageSettings: Bool
    let exportData: Bool
    let deleteData: Bool

    static let all = UserPermissions(
        manageUsers: true,
        manageMembers: true,
        sendMessages: true,
        viewAnalytics: true,
        manageAutomation: true,
        manageTemplates: true,
        manageOrganization: true,
        manageSettings: true,
        exportData: true,
        deleteData: true
    )

    static let admin = UserPermissions(
        manageUsers: true,
        manageMembers: true,
        sendMessages: true,
        viewAnalytics: true,
        manageAutomation: true,
        manageTemplates: true,
        manageOrganization: false,
        manageSettings: true,
        exportData: true,
        deleteData: true
    )

    static let ministryLeader = UserPermissions(
        manageUsers: false,
        manageMembers: true,
        sendMessages: true,
        viewAnalytics: true,
        manageAutomation: true,
        manageTemplates: true,
        manageOrganization: false,
        manageSettings: false,
        exportData: false,
        deleteData: false
    )

    static let volunteer = UserPermissions(
        manageUsers: false,
        manageMembers: false,
        sendMessages: true,
        viewAnalytics: false,
        manageAutomation: false,
        manageTemplates: true,
        manageOrganization: false,
        manageSettings: false,
        exportData: false,
        deleteData: false
    )

    static let member = UserPermissions(
        manageUsers: false,
        manageMembers: false,
        sendMessages: false,
        viewAnalytics: false,
        manageAutomation: false,
        manageTemplates: false,
        manageOrganization: false,
        manageSettings: false,
        exportData: false,
        deleteData: false
    )
}

// MARK: - Organization Models

/// Organization/tenant model for multi-tenant support
struct Organization: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let slug: String  // Unique identifier for URLs
    let description: String?
    let logoURL: String?
    let website: String?
    let primaryColor: String?
    let secondaryColor: String?
    let settings: OrganizationSettings
    let subscription: SubscriptionPlan
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date
}

/// Organization-specific settings and preferences
struct OrganizationSettings: Codable, Equatable {
    let defaultLanguage: String
    let defaultTimeZone: String
    let dateFormat: String
    let enabledFeatures: [String]
    let customFields: [String: String]
    let integrationSettings: IntegrationSettings
    let notificationSettings: NotificationSettings
}

/// Third-party integration settings
struct IntegrationSettings: Codable, Equatable {
    let emailProvider: EmailProvider?
    let smsProvider: SMSProvider?
    let whatsappEnabled: Bool
    let googleWorkspaceEnabled: Bool
    let microsoftOfficeEnabled: Bool
    let webhookURL: String?
}

/// Notification preferences
struct NotificationSettings: Codable, Equatable {
    let emailNotifications: Bool
    let pushNotifications: Bool
    let smsNotifications: Bool
    let digestFrequency: DigestFrequency
    let quietHours: QuietHours?
}

enum DigestFrequency: String, Codable, CaseIterable {
    case disabled = "disabled"
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
}

struct QuietHours: Codable, Equatable {
    let startTime: String  // HH:mm format
    let endTime: String  // HH:mm format
    let timeZone: String
}

/// Subscription plan information
enum SubscriptionPlan: String, Codable, CaseIterable {
    case free = "free"
    case starter = "starter"
    case professional = "professional"
    case enterprise = "enterprise"

    var displayName: String {
        return rawValue.capitalized
    }

    var maxUsers: Int {
        switch self {
        case .free:
            return 5
        case .starter:
            return 25
        case .professional:
            return 100
        case .enterprise:
            return Int.max
        }
    }

    var maxMembers: Int {
        switch self {
        case .free:
            return 100
        case .starter:
            return 500
        case .professional:
            return 2500
        case .enterprise:
            return Int.max
        }
    }
}

// MARK: - Provider Enums

enum EmailProvider: String, Codable, CaseIterable {
    case sendgrid = "sendgrid"
    case mailgun = "mailgun"
    case amazonSES = "amazon_ses"
    case smtp = "smtp"
}

enum SMSProvider: String, Codable, CaseIterable {
    case twilio = "twilio"
    case vonage = "vonage"
    case amazonSNS = "amazon_sns"
}

// MARK: - Authentication Models

/// Authentication request/response models
struct LoginRequest: Codable {
    let email: String
    let password: String
    let rememberMe: Bool
}

struct LoginResponse: Codable {
    let user: User
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
}

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let fullName: String
    let displayName: String?
}

struct RefreshTokenRequest: Codable {
    let refreshToken: String
}

struct RefreshTokenResponse: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int?
}

/// Change password request for authenticated users
struct ChangePasswordRequest: Codable {
    let currentPassword: String
    let newPassword: String
}

/// Forgot password request to initiate reset flow
struct ForgotPasswordRequest: Codable {
    let email: String
}

/// Reset password with token from email
struct ResetPasswordRequest: Codable {
    let email: String
    let token: String
    let newPassword: String
}

/// Verify email with token
struct VerifyEmailRequest: Codable {
    let email: String
    let token: String
}

/// Generic message response
struct MessageResponse: Codable {
    let message: String
}

struct AuthenticationError: Error, LocalizedError {
    let code: String
    let message: String

    var errorDescription: String? {
        return message
    }

    static let invalidCredentials = AuthenticationError(
        code: "INVALID_CREDENTIALS",
        message: "Invalid email or password"
    )

    static let userNotFound = AuthenticationError(
        code: "USER_NOT_FOUND",
        message: "User not found"
    )

    static let userInactive = AuthenticationError(
        code: "USER_INACTIVE",
        message: "Account is inactive"
    )

    static let organizationInactive = AuthenticationError(
        code: "ORGANIZATION_INACTIVE",
        message: "Organization is inactive"
    )
}

// MARK: - Preview Extensions

extension User {
    static let preview = User(
        id: "preview-user-id",
        email: "demo@caresphere.com",
        fullName: "Demo User",
        displayName: "Demo",
        avatarUrl: nil,
        role: .admin,
        status: .active,
        emailVerified: true,
        lastLoginAt: nil,
        createdAt: "2025-11-18T00:00:00",
        updatedAt: "2025-11-18T00:00:00"
    )
}
