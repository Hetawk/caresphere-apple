import Foundation

// MARK: - Message Models

/// Core message model for multi-channel communication
struct Message: Codable, Identifiable, Equatable {
    let id: String
    let organizationId: String
    let senderId: String  // User ID who sent the message
    let subject: String?
    let content: String
    let messageType: MessageType
    let priority: MessagePriority
    let channel: MessageChannel
    let templateId: String?
    let recipients: [MessageRecipient]
    let scheduledAt: Date?
    let sentAt: Date?
    let status: MessageStatus
    let metadata: [String: String]
    let createdAt: Date
    let updatedAt: Date

    // Computed properties
    var recipientCount: Int {
        return recipients.count
    }

    var successfulDeliveries: Int {
        return recipients.filter { $0.deliveryStatus == .delivered }.count
    }

    var failedDeliveries: Int {
        return recipients.filter { $0.deliveryStatus == .failed }.count
    }

    var deliveryRate: Double {
        guard recipientCount > 0 else { return 0 }
        return Double(successfulDeliveries) / Double(recipientCount)
    }
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

/// Communication channels
enum MessageChannel: String, Codable, CaseIterable {
    case email = "email"
    case sms = "sms"
    case whatsapp = "whatsapp"
    case push = "push"
    case inApp = "in_app"
    case voice = "voice"

    var displayName: String {
        switch self {
        case .email:
            return "Email"
        case .sms:
            return "SMS"
        case .whatsapp:
            return "WhatsApp"
        case .push:
            return "Push Notification"
        case .inApp:
            return "In-App"
        case .voice:
            return "Voice"
        }
    }

    var icon: String {
        switch self {
        case .email:
            return "envelope"
        case .sms:
            return "message"
        case .whatsapp:
            return "phone.bubble"
        case .push:
            return "bell"
        case .inApp:
            return "app.badge"
        case .voice:
            return "phone"
        }
    }

    var requiresContent: Bool {
        switch self {
        case .email, .sms, .whatsapp, .inApp:
            return true
        case .push:
            return true
        case .voice:
            return false  // Voice might use TTS from content or pre-recorded
        }
    }
}

/// Message status tracking
enum MessageStatus: String, Codable, CaseIterable {
    case draft = "draft"
    case scheduled = "scheduled"
    case sending = "sending"
    case sent = "sent"
    case failed = "failed"
    case cancelled = "cancelled"

    var displayName: String {
        switch self {
        case .draft:
            return "Draft"
        case .scheduled:
            return "Scheduled"
        case .sending:
            return "Sending"
        case .sent:
            return "Sent"
        case .failed:
            return "Failed"
        case .cancelled:
            return "Cancelled"
        }
    }

    var color: String {
        switch self {
        case .draft:
            return "secondary"
        case .scheduled:
            return "info"
        case .sending:
            return "warning"
        case .sent:
            return "success"
        case .failed:
            return "error"
        case .cancelled:
            return "tertiary"
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

/// Reusable message templates
struct MessageTemplate: Codable, Identifiable, Equatable {
    let id: String
    let organizationId: String
    let name: String
    let description: String?
    let category: TemplateCategory
    let subject: String?
    let content: String
    let placeholders: [TemplatePlaceholder]
    let supportedChannels: [MessageChannel]
    let isActive: Bool
    let usageCount: Int
    let createdBy: String  // User ID
    let createdAt: Date
    let updatedAt: Date

    // Computed properties
    var placeholderNames: [String] {
        return placeholders.map { $0.name }
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

struct CreateMessageRequest: Codable {
    let subject: String?
    let content: String
    let messageType: MessageType
    let priority: MessagePriority
    let channel: MessageChannel
    let templateId: String?
    let recipients: [RecipientRequest]
    let scheduledAt: Date?
    let templateVariables: [String: String]?
}

struct RecipientRequest: Codable {
    let memberId: String?
    let recipientType: RecipientType
    let contactInfo: ContactInfo
}

struct MessageListResponse: Codable {
    let messages: [Message]
    let pagination: PaginationInfo
    let totalCount: Int
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
        if layers.organization.name != nil || layers.organization.email != nil || layers.organization.phone != nil {
            return .organization
        }
        if layers.global.name != nil || layers.global.email != nil || layers.global.phone != nil {
            return .global
        }
        if layers.environment.name != nil || layers.environment.email != nil || layers.environment.phone != nil {
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
        senderId: "preview-sender-id",
        subject: "Preview Message",
        content: "This is a preview message for testing purposes.",
        messageType: .personal,
        priority: .normal,
        channel: .email,
        templateId: nil,
        recipients: [MessageRecipient.preview],
        scheduledAt: nil,
        sentAt: Date(),
        status: .sent,
        metadata: [:],
        createdAt: Date(),
        updatedAt: Date()
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
        organizationId: "preview-org-id",
        name: "Welcome Message",
        description: "Welcome message for new members",
        category: .welcome,
        subject: "Welcome to CareSphere",
        content: "Welcome {{firstName}}! We're excited to have you join our community.",
        placeholders: [
            TemplatePlaceholder(
                name: "firstName",
                displayName: "First Name",
                type: .text,
                isRequired: true,
                defaultValue: nil,
                description: "Member's first name"
            )
        ],
        supportedChannels: [.email, .sms],
        isActive: true,
        usageCount: 5,
        createdBy: "preview-user-id",
        createdAt: Date(),
        updatedAt: Date()
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


