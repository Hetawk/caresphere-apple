import Foundation

// MARK: - Message Models

/// Core message model — matches Prisma Message model (camelCase API response)
struct Message: Codable, Identifiable, Equatable {
    let id: String
    let organizationId: String?
    let title: String
    let content: String
    let messageType: MessageChannel  // EMAIL | SMS | PUSH | IN_APP
    let status: MessageStatus
    let scheduledFor: String?
    let sentAt: String?
    let senderName: String?
    let senderEmail: String?
    let senderPhone: String?
    let templateId: String?
    let createdBy: String?
    let recipientCount: Int?
    let openedCount: Int?
    let clickedCount: Int?
    let failedCount: Int?
    let createdAt: String?
    let updatedAt: String?

    // Backward-compat helpers for UI
    var subject: String? { title }
    var senderId: String? { createdBy }
}

/// Message types for categorization
enum MessageType: String, Codable, CaseIterable {
    case broadcast = "broadcast"
    case personal = "personal"
    case automated = "automated"
    case announcement = "announcement"
    case reminder = "reminder"
    case welcome = "welcome"
    case followUp = "follow_up"
    case emergency = "emergency"

    var displayName: String {
        switch self {
        case .broadcast:
            return "Broadcast"
        case .personal:
            return "Personal"
        case .automated:
            return "Automated"
        case .announcement:
            return "Announcement"
        case .reminder:
            return "Reminder"
        case .welcome:
            return "Welcome"
        case .followUp:
            return "Follow-up"
        case .emergency:
            return "Emergency"
        }
    }
}

/// Message priority levels
enum MessagePriority: String, Codable, CaseIterable {
    case low = "low"
    case normal = "normal"
    case high = "high"
    case urgent = "urgent"

    var displayName: String {
        return rawValue.capitalized
    }

    var color: String {
        switch self {
        case .low:
            return "secondary"
        case .normal:
            return "primary"
        case .high:
            return "warning"
        case .urgent:
            return "error"
        }
    }

    var sortOrder: Int {
        switch self {
        case .urgent:
            return 0
        case .high:
            return 1
        case .normal:
            return 2
        case .low:
            return 3
        }
    }
}

/// Communication channels — matches Prisma MessageType enum (uppercase)
enum MessageChannel: String, Codable, CaseIterable {
    case email = "EMAIL"
    case sms = "SMS"
    case push = "PUSH"
    case inApp = "IN_APP"

    var displayName: String {
        switch self {
        case .email:
            return "Email"
        case .sms:
            return "SMS"
        case .push:
            return "Push Notification"
        case .inApp:
            return "In-App"
        }
    }

    var icon: String {
        switch self {
        case .email:
            return "envelope"
        case .sms:
            return "message"
        case .push:
            return "bell"
        case .inApp:
            return "app.badge"
        }
    }

    var requiresContent: Bool { true }
}

/// Message status tracking — matches Prisma MessageStatus enum (uppercase)
enum MessageStatus: String, Codable, CaseIterable {
    case draft = "DRAFT"
    case scheduled = "SCHEDULED"
    case pending = "PENDING"
    case sent = "SENT"
    case failed = "FAILED"

    var displayName: String {
        switch self {
        case .draft:
            return "Draft"
        case .scheduled:
            return "Scheduled"
        case .pending:
            return "Pending"
        case .sent:
            return "Sent"
        case .failed:
            return "Failed"
        }
    }

    var color: String {
        switch self {
        case .draft:
            return "secondary"
        case .scheduled:
            return "info"
        case .pending:
            return "warning"
        case .sent:
            return "success"
        case .failed:
            return "error"
        }
    }
}

// MARK: - Message Recipient Models

/// Individual message recipient with delivery tracking
struct MessageRecipient: Codable, Identifiable, Equatable {
    let id: String
    let messageId: String
    let memberId: String?
    let recipientType: RecipientType
    let contactInfo: ContactInfo
    let deliveryStatus: DeliveryStatus
    let sentAt: Date?
    let deliveredAt: Date?
    let readAt: Date?
    let errorMessage: String?
    let metadata: [String: String]
}

enum RecipientType: String, Codable, CaseIterable {
    case member = "member"
    case user = "user"
    case external = "external"  // Non-member contact

    var displayName: String {
        return rawValue.capitalized
    }
}

struct ContactInfo: Codable, Equatable {
    let email: String?
    let phoneNumber: String?
    let whatsappNumber: String?
    let pushToken: String?
    let name: String?
}

enum DeliveryStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case sent = "sent"
    case delivered = "delivered"
    case read = "read"
    case failed = "failed"
    case bounced = "bounced"
    case unsubscribed = "unsubscribed"

    var displayName: String {
        switch self {
        case .pending:
            return "Pending"
        case .sent:
            return "Sent"
        case .delivered:
            return "Delivered"
        case .read:
            return "Read"
        case .failed:
            return "Failed"
        case .bounced:
            return "Bounced"
        case .unsubscribed:
            return "Unsubscribed"
        }
    }

    var color: String {
        switch self {
        case .pending:
            return "secondary"
        case .sent:
            return "info"
        case .delivered:
            return "success"
        case .read:
            return "success"
        case .failed:
            return "error"
        case .bounced:
            return "warning"
        case .unsubscribed:
            return "tertiary"
        }
    }
}

// MARK: - Message Template Models

/// Reusable message template — matches Prisma Template model
/// API fields: id, name, description, templateType, category, subject, content,
/// variables (JSON string), thumbnailUrl, isActive, usageCount, createdBy, createdAt, updatedAt
struct MessageTemplate: Identifiable, Equatable {
    let id: String
    let name: String
    let description: String?
    let templateType: String?  // "EMAIL" | "SMS" | "PUSH"
    let category: TemplateCategory  // decoded from category string; falls back to .general
    let subject: String?
    let content: String
    let variables: String?  // JSON-encoded array: "[\"firstName\",\"orgName\"]"
    let thumbnailUrl: String?
    let isActive: Bool
    let usageCount: Int
    let createdBy: String?
    let createdAt: String?
    let updatedAt: String?

    // MARK: - Computed UI helpers (backward-compat with views)

    /// Variable names parsed from the JSON `variables` string
    var placeholderNames: [String] {
        guard let vars = variables,
            let arr = try? JSONDecoder().decode([String].self, from: Data(vars.utf8))
        else { return [] }
        return arr
    }

    /// Virtual TemplatePlaceholder objects derived from variable names
    var placeholders: [TemplatePlaceholder] {
        placeholderNames.map { key in
            TemplatePlaceholder(
                name: key,
                displayName:
                    key
                    .replacingOccurrences(
                        of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression
                    )
                    .capitalized,
                type: .memberField,
                isRequired: false,
                defaultValue: nil,
                description: "Insert member's \(key)"
            )
        }
    }

    /// Maps Prisma single templateType to channel array for UI compatibility
    var supportedChannels: [MessageChannel] {
        switch templateType?.uppercased() {
        case "SMS": return [.sms]
        case "PUSH": return [.push]
        default: return [.email]
        }
    }
}

extension MessageTemplate: Codable {
    enum CodingKeys: String, CodingKey {
        case id, name, description, subject, content, variables, thumbnailUrl
        case templateType, category, isActive, usageCount
        case createdBy, createdAt, updatedAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        templateType = try c.decodeIfPresent(String.self, forKey: .templateType)
        let catStr = try c.decodeIfPresent(String.self, forKey: .category)
        category = TemplateCategory(rawValue: catStr ?? "") ?? .general
        subject = try c.decodeIfPresent(String.self, forKey: .subject)
        content = try c.decode(String.self, forKey: .content)
        variables = try c.decodeIfPresent(String.self, forKey: .variables)
        thumbnailUrl = try c.decodeIfPresent(String.self, forKey: .thumbnailUrl)
        isActive = (try? c.decodeIfPresent(Bool.self, forKey: .isActive)) ?? true
        usageCount = (try? c.decodeIfPresent(Int.self, forKey: .usageCount)) ?? 0
        createdBy = try c.decodeIfPresent(String.self, forKey: .createdBy)
        createdAt = try c.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try c.decodeIfPresent(String.self, forKey: .updatedAt)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encodeIfPresent(description, forKey: .description)
        try c.encodeIfPresent(templateType, forKey: .templateType)
        try c.encode(category.rawValue, forKey: .category)
        try c.encodeIfPresent(subject, forKey: .subject)
        try c.encode(content, forKey: .content)
        try c.encodeIfPresent(variables, forKey: .variables)
        try c.encodeIfPresent(thumbnailUrl, forKey: .thumbnailUrl)
        try c.encode(isActive, forKey: .isActive)
        try c.encode(usageCount, forKey: .usageCount)
        try c.encodeIfPresent(createdBy, forKey: .createdBy)
        try c.encodeIfPresent(createdAt, forKey: .createdAt)
        try c.encodeIfPresent(updatedAt, forKey: .updatedAt)
    }
}

enum TemplateCategory: String, Codable, CaseIterable {
    case welcome = "welcome"
    case reminder = "reminder"
    case followUp = "follow_up"
    case announcement = "announcement"
    case birthday = "birthday"
    case prayer = "prayer"
    case pastoral = "pastoral"
    case emergency = "emergency"
    case welfare = "welfare"
    case evangelism = "evangelism"
    case general = "general"

    var displayName: String {
        switch self {
        case .welcome:
            return "Welcome"
        case .reminder:
            return "Reminder"
        case .followUp:
            return "Follow-up"
        case .announcement:
            return "Announcement"
        case .birthday:
            return "Birthday"
        case .prayer:
            return "Prayer"
        case .pastoral:
            return "Pastoral Care"
        case .emergency:
            return "Emergency"
        case .welfare:
            return "Welfare Check"
        case .evangelism:
            return "Evangelism"
        case .general:
            return "General"
        }
    }
}

struct TemplatePlaceholder: Codable, Equatable {
    let name: String
    let displayName: String
    let type: PlaceholderType
    let isRequired: Bool
    let defaultValue: String?
    let description: String?
}

enum PlaceholderType: String, Codable, CaseIterable {
    case text = "text"
    case number = "number"
    case date = "date"
    case boolean = "boolean"
    case memberField = "member_field"
    case userField = "user_field"
    case organizationField = "organization_field"

    var displayName: String {
        switch self {
        case .text:
            return "Text"
        case .number:
            return "Number"
        case .date:
            return "Date"
        case .boolean:
            return "Yes/No"
        case .memberField:
            return "Member Field"
        case .userField:
            return "User Field"
        case .organizationField:
            return "Organization Field"
        }
    }
}

// MARK: - Message Request/Response Models

/// Create message request — matches /api/messages POST schema
struct CreateMessageRequest: Codable {
    let title: String
    let content: String
    let messageType: MessageChannel?
    let scheduledFor: String?  // ISO 8601 string
    let senderName: String?
    let senderEmail: String?
    let senderPhone: String?
    let senderWhatsapp: String?
    let channelLabel: String?
    let templateId: String?
    let senderProfileId: String?
    let recipientMemberIds: [String]?
    let recipientGroup: RecipientGroup?  // ALL | ACTIVE | INACTIVE | PENDING
}

/// Recipient group filter for broadcast messages
enum RecipientGroup: String, Codable, CaseIterable {
    case all = "ALL"
    case active = "ACTIVE"
    case inactive = "INACTIVE"
    case pending = "PENDING"
}

/// Paginated message list response — matches API { items, page, limit, total }
struct MessageListResponse: Codable {
    let items: [Message]
    let page: Int?
    let limit: Int?
    let total: Int?

    // Convenience accessors
    var messages: [Message] { items }
    var totalCount: Int { total ?? items.count }
    var pagination: PaginationInfo {
        PaginationInfo(
            page: page ?? 1,
            pageSize: limit ?? items.count,
            hasNext: (total ?? 0) > (page ?? 1) * (limit ?? items.count),
            hasPrevious: (page ?? 1) > 1
        )
    }
}

struct MessageAnalytics: Codable {
    let messageId: String
    let totalRecipients: Int
    let sentCount: Int
    let deliveredCount: Int
    let readCount: Int
    let failedCount: Int
    let bouncedCount: Int
    let unsubscribedCount: Int
    let deliveryRate: Double
    let readRate: Double
    let engagementMetrics: [String: Double]
    let channelBreakdown: [MessageChannel: ChannelMetrics]
}

struct ChannelMetrics: Codable, Equatable {
    let recipientCount: Int
    let deliveredCount: Int
    let readCount: Int
    let failedCount: Int
    let deliveryRate: Double
    let readRate: Double
}

// MARK: - Message Search and Filter Models

struct MessageSearchCriteria: Codable {
    let query: String?
    let messageType: [MessageType]?
    let priority: [MessagePriority]?
    let channel: [MessageChannel]?
    let status: [MessageStatus]?
    let senderId: String?
    let templateId: String?
    let dateRange: DateRange?
    let recipientId: String?
    let sortBy: MessageSortField?
    let sortOrder: SortOrder?
    let page: Int
    let pageSize: Int
}

enum MessageSortField: String, Codable, CaseIterable {
    case createdAt = "created_at"
    case sentAt = "sent_at"
    case subject = "subject"
    case priority = "priority"
    case recipientCount = "recipient_count"
    case deliveryRate = "delivery_rate"

    var displayName: String {
        switch self {
        case .createdAt:
            return "Created"
        case .sentAt:
            return "Sent"
        case .subject:
            return "Subject"
        case .priority:
            return "Priority"
        case .recipientCount:
            return "Recipients"
        case .deliveryRate:
            return "Delivery Rate"
        }
    }
}

// MARK: - Sender Settings Models

/// Sender identity settings for messages
struct SenderSetting: Codable, Identifiable, Equatable {
    let id: String
    let scope: SettingScope
    let referenceId: String?
    let name: String?
    let email: String?
    let phone: String?
    let createdAt: Date
    let updatedAt: Date

    var displayIdentity: String {
        var parts: [String] = []
        if let name = name, !name.isEmpty {
            parts.append(name)
        }
        if let email = email, !email.isEmpty {
            parts.append("<\(email)>")
        }
        return parts.isEmpty ? "No sender configured" : parts.joined(separator: " ")
    }
}

/// Scope levels for sender settings
enum SettingScope: String, Codable, CaseIterable {
    case global = "GLOBAL"
    case organization = "ORGANIZATION"
    case user = "USER"

    var displayName: String {
        switch self {
        case .global:
            return "System Default"
        case .organization:
            return "Organization"
        case .user:
            return "Personal"
        }
    }

    var description: String {
        switch self {
        case .global:
            return "System-wide default sender settings"
        case .organization:
            return "Shared settings for your organization"
        case .user:
            return "Personal sender settings that override others"
        }
    }

    var priority: Int {
        switch self {
        case .user:
            return 0  // Highest priority
        case .organization:
            return 1
        case .global:
            return 2  // Lowest priority
        }
    }
}

/// Resolved sender settings with cascade information
struct ResolvedSenderSettings: Codable, Equatable {
    let name: String?
    let email: String?
    let phone: String?
    let layers: SettingsLayers

    var displayIdentity: String {
        var parts: [String] = []
        if let name = name, !name.isEmpty {
            parts.append(name)
        }
        if let email = email, !email.isEmpty {
            parts.append("<\(email)>")
        }
        return parts.isEmpty ? "No sender configured" : parts.joined(separator: " ")
    }

    var effectiveSource: SettingScope? {
        if layers.user.name != nil || layers.user.email != nil || layers.user.phone != nil {
            return .user
        }
        if layers.organization.name != nil || layers.organization.email != nil
            || layers.organization.phone != nil
        {
            return .organization
        }
        if layers.global.name != nil || layers.global.email != nil || layers.global.phone != nil {
            return .global
        }
        if layers.environment.name != nil || layers.environment.email != nil
            || layers.environment.phone != nil
        {
            return nil  // Environment fallback
        }
        return nil
    }
}

struct SettingsLayers: Codable, Equatable {
    let user: SettingsLayer
    let organization: SettingsLayer
    let global: SettingsLayer
    let environment: SettingsLayer
}

struct SettingsLayer: Codable, Equatable {
    let name: String?
    let email: String?
    let phone: String?
}

// MARK: - Preview Extensions

extension Message {
    static let preview = Message(
        id: "preview-message-id",
        organizationId: "preview-org-id",
        title: "Preview Message",
        content: "This is a preview message for testing purposes.",
        messageType: .email,
        status: .sent,
        scheduledFor: nil,
        sentAt: "2025-11-18T00:00:00Z",
        senderName: "Demo User",
        senderEmail: "demo@caresphere.com",
        senderPhone: nil,
        templateId: nil,
        createdBy: "preview-user-id",
        recipientCount: 10,
        openedCount: 5,
        clickedCount: 2,
        failedCount: 0,
        createdAt: "2025-11-18T00:00:00Z",
        updatedAt: "2025-11-18T00:00:00Z"
    )
}

extension MessageRecipient {
    static let preview = MessageRecipient(
        id: "preview-recipient-id",
        messageId: "preview-message-id",
        memberId: "preview-member-id",
        recipientType: .member,
        contactInfo: ContactInfo(
            email: "john.doe@example.com",
            phoneNumber: "+1-555-0123",
            whatsappNumber: nil,
            pushToken: nil,
            name: "John Doe"
        ),
        deliveryStatus: .delivered,
        sentAt: Date(),
        deliveredAt: Date(),
        readAt: Date(),
        errorMessage: nil,
        metadata: [:]
    )
}

extension MessageTemplate {
    static let preview = MessageTemplate(
        id: "preview-template-id",
        name: "Welcome to {{organizationName}}",
        description: "Welcome message for new members",
        templateType: "EMAIL",
        category: .welcome,
        subject: "Welcome to {{organizationName}}!",
        content:
            "Dear {{firstName}},\n\nWelcome to {{organizationName}}! We're so glad you're here. Our community is a place of faith, growth, and genuine care for one another.\n\nIf you have any questions, please don't hesitate to reach out.\n\nBlessings,\n{{senderName}}",
        variables: "[\"firstName\",\"organizationName\",\"senderName\"]",
        thumbnailUrl: nil,
        isActive: true,
        usageCount: 5,
        createdBy: "preview-user-id",
        createdAt: "2025-11-18T00:00:00Z",
        updatedAt: "2025-11-18T00:00:00Z"
    )
}

extension ResolvedSenderSettings {
    static let preview = ResolvedSenderSettings(
        name: "Demo User",
        email: "demo@caresphere.com",
        phone: "+1-555-0123",
        layers: SettingsLayers(
            user: SettingsLayer(
                name: "Demo User",
                email: "demo@caresphere.com",
                phone: "+1-555-0123"
            ),
            organization: SettingsLayer(
                name: "CareSphere Support",
                email: "support@caresphere.com",
                phone: "+1-800-CARE"
            ),
            global: SettingsLayer(
                name: "System Default",
                email: "noreply@caresphere.com",
                phone: nil
            ),
            environment: SettingsLayer(
                name: nil,
                email: nil,
                phone: nil
            )
        )
    )
}

extension SenderSetting {
    static let preview = SenderSetting(
        id: "preview-sender-id",
        scope: .user,
        referenceId: "preview-user-id",
        name: "Demo User",
        email: "demo@caresphere.com",
        phone: "+1-555-0123",
        createdAt: Date(),
        updatedAt: Date()
    )
}
