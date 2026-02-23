import Foundation

// MARK: - User Management Models

/// Organization role information
struct UserOrganizationRole: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let displayName: String
}

/// Basic organization information for user display
struct UserOrganizationInfo: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let slug: String
    let isActive: Bool
}

/// User's membership in an organization
struct UserOrganizationMembership: Codable, Identifiable, Equatable {
    var id: String { organization.id }  // Use organization ID as identifier
    let organization: UserOrganizationInfo
    let role: UserOrganizationRole?
    let isOwner: Bool
    let isActive: Bool
    let joinedAt: String?
}

/// User model representing authenticated users in the system
struct User: Codable, Identifiable, Equatable {
    let id: String
    let email: String
    let firstName: String
    let lastName: String?
    let phone: String?
    let role: UserRole
    let status: UserStatus
    let createdAt: String?
    let lastLoginAt: String?

    // Computed properties for UI compatibility
    var fullName: String {
        [firstName, lastName].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")
    }

    var displayName: String {
        fullName.isEmpty ? email : fullName
    }

    var effectiveDisplayName: String { displayName }
    var avatarUrl: String? { nil }
    var emailVerified: Bool { status == .active }
    var updatedAt: String? { nil }
    var organizations: [UserOrganizationMembership] { [] }

    var initials: String {
        let parts = fullName.split(separator: " ").prefix(2)
        return parts.map { String($0.prefix(1)).uppercased() }.joined()
    }
}

/// User status enumeration
enum UserStatus: String, Codable, CaseIterable {
    case active = "ACTIVE"
    case inactive = "INACTIVE"
    case suspended = "SUSPENDED"

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
    case kingdomSuperAdmin = "KINGDOM_SUPER_ADMIN"
    case superAdmin = "SUPER_ADMIN"
    case admin = "ADMIN"
    case ministryLeader = "MINISTRY_LEADER"
    case volunteer = "VOLUNTEER"
    case member = "MEMBER"

    var displayName: String {
        switch self {
        case .kingdomSuperAdmin:
            return "Kingdom Super Admin"
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
        case .kingdomSuperAdmin:
            return UserPermissions.all
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

/// Organization type from Prisma schema
enum OrganizationType: String, Codable, CaseIterable {
    case church = "CHURCH"
    case nonprofit = "NONPROFIT"
    case other = "OTHER"

    var displayName: String {
        switch self {
        case .church: return "Church / Faith-based"
        case .nonprofit: return "Non-profit"
        case .other: return "Other"
        }
    }
}

/// Organization/tenant model — matches Prisma Organization model (camelCase API response)
struct Organization: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let slug: String
    let organizationCode: String?
    let organizationType: OrganizationType?
    let domain: String?
    let description: String?
    let logoUrl: String?
    let website: String?
    let phone: String?
    let address: String?
    let city: String?
    let state: String?
    let country: String?
    let timezone: String?
    let bibleEnabled: Bool?
    let isActive: Bool?
    let createdAt: String?
    let updatedAt: String?

    // Backward compat helpers for UI
    var logoURL: String? { logoUrl }
    var primaryColor: String? { nil }
    var secondaryColor: String? { nil }
}

/// Organization creation request
struct CreateOrganizationRequest: Codable {
    let name: String
    let description: String?
}

/// Membership info embedded in OrganizationWithMembership
struct OrgMembershipInfo: Codable, Equatable {
    let isOwner: Bool
    let roleName: String
    let roleDisplayName: String
    let joinedAt: String?
}

/// Organization with the current user's membership info — returned by GET /orgs/all
struct OrganizationWithMembership: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let slug: String
    let organizationCode: String?
    let organizationType: OrganizationType?
    let domain: String?
    let description: String?
    let logoUrl: String?
    let website: String?
    let phone: String?
    let isActive: Bool?
    let membership: OrgMembershipInfo

    var logoURL: String? { logoUrl }
}

/// Join organization request — API /orgs/join expects { code: String }
struct JoinOrganizationRequest: Codable {
    let code: String
}

/// Organization onboarding option
enum OrganizationOption: String, Codable {
    case create = "create"
    case join = "join"
    case skip = "skip"
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
    let firstName: String
    let lastName: String
    let code: String  // Email verification OTP
    let phone: String?
}

/// Registration request with organization onboarding
/// Matches /api/auth/register-org schema
struct RegisterWithOrganizationRequest: Codable {
    let email: String
    let password: String
    let firstName: String
    let lastName: String
    let code: String  // Email verification OTP
    let phone: String?
    let organizationAction: String  // "create" or "join"
    let organizationName: String?
    let organizationCode: String?
}

struct SendVerificationCodeRequest: Codable {
    let email: String
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
        firstName: "Demo",
        lastName: "User",
        phone: nil,
        role: .admin,
        status: .active,
        createdAt: "2025-11-18T00:00:00Z",
        lastLoginAt: nil
    )
}
