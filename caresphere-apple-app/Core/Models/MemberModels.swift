import Foundation

// MARK: - Member Management Models

/// Core member model — matches Prisma Member model (camelCase API response)
struct Member: Codable, Identifiable, Equatable {
    let id: String
    let organizationId: String?
    let userId: String?
    let firstName: String
    let lastName: String?
    let email: String?
    let phone: String?
    let dateOfBirth: String?  // ISO 8601 string from API
    let gender: String?
    // Flat address fields (Prisma stores address as separate columns)
    let address: String?
    let city: String?
    let state: String?
    let zipCode: String?
    let country: String?
    let memberStatus: MemberStatus?
    let membershipType: String?
    let joinDate: String?  // ISO 8601 string
    let photoUrl: String?
    let notes: String?
    let tags: [String]?
    let customFields: [String: String]?
    let workSchool: String?
    let whatsappNumber: String?
    let wechatId: String?
    let hearAboutUs: String?
    let involvement: String?
    let comments: String?
    let consentGiven: Bool?
    let createdBy: String?
    let createdAt: String?
    let updatedAt: String?

    // Computed properties for backward compat
    var fullName: String {
        [firstName, lastName].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")
    }

    var displayName: String {
        fullName.isEmpty ? email ?? phone ?? "Unknown" : fullName
    }

    // Backward compat aliases used by views / DomainServices
    var phoneNumber: String? { phone }
    var whatsAppNumber: String? { whatsappNumber }
    var weChatID: String? { wechatId }
    var profileImageURL: String? { photoUrl }
    var status: MemberStatus { memberStatus ?? .active }

    var formattedAddress: String? {
        let parts = [address, city, state, zipCode, country]
            .compactMap { $0 }.filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }
}

/// Helper for decoding JSON fields that can be any value (used for customFields)
// Note: AnyCodable is defined in FieldConfigModels.swift

/// Member status categories — matches Prisma MemberStatus enum (uppercase)
enum MemberStatus: String, Codable, CaseIterable {
    case active = "ACTIVE"
    case inactive = "INACTIVE"
    case pending = "PENDING"
    case archived = "ARCHIVED"

    var displayName: String {
        switch self {
        case .active:
            return "Active"
        case .inactive:
            return "Inactive"
        case .pending:
            return "Pending"
        case .archived:
            return "Archived"
        }
    }

    var color: String {
        switch self {
        case .active:
            return "success"
        case .inactive:
            return "secondary"
        case .pending:
            return "warning"
        case .archived:
            return "tertiary"
        }
    }
}

/// Address information
struct Address: Codable, Equatable {
    let street: String?
    let city: String?
    let state: String?
    let postalCode: String?
    let country: String?

    var formattedAddress: String {
        let components = [street, city, state, postalCode, country]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
        return components.joined(separator: ", ")
    }
}

/// Emergency contact information
struct EmergencyContact: Codable, Equatable {
    let name: String
    let relationship: String
    let phoneNumber: String
    let email: String?
}

// MARK: - Member Care Models

/// Care notes for tracking member interactions
struct MemberNote: Codable, Identifiable, Equatable {
    let id: String
    let memberId: String
    let authorId: String  // User who created the note
    let content: String
    let category: NoteCategory
    let isPrivate: Bool
    let tags: [String]
    let createdAt: Date
    let updatedAt: Date
}

enum NoteCategory: String, Codable, CaseIterable {
    case general = "general"
    case prayer = "prayer"
    case pastoral = "pastoral"
    case welfare = "welfare"
    case counseling = "counseling"
    case followUp = "follow_up"
    case celebration = "celebration"
    case concern = "concern"

    var displayName: String {
        switch self {
        case .general:
            return "General"
        case .prayer:
            return "Prayer Request"
        case .pastoral:
            return "Pastoral Care"
        case .welfare:
            return "Welfare Check"
        case .counseling:
            return "Counseling"
        case .followUp:
            return "Follow-up"
        case .celebration:
            return "Celebration"
        case .concern:
            return "Concern"
        }
    }

    var color: String {
        switch self {
        case .general:
            return "secondary"
        case .prayer:
            return "purple"
        case .pastoral:
            return "blue"
        case .welfare:
            return "green"
        case .counseling:
            return "orange"
        case .followUp:
            return "yellow"
        case .celebration:
            return "green"
        case .concern:
            return "red"
        }
    }
}

/// Member activities for tracking engagement
struct MemberActivity: Codable, Identifiable, Equatable {
    let id: String
    let memberId: String
    let activityType: ActivityType
    let title: String
    let description: String?
    let performedBy: String?  // User ID who performed the activity
    let metadata: [String: String]
    let date: Date
    let createdAt: Date
}

enum ActivityType: String, Codable, CaseIterable {
    case messageReceived = "message_received"
    case messageSent = "message_sent"
    case visitScheduled = "visit_scheduled"
    case visitCompleted = "visit_completed"
    case prayerRequested = "prayer_requested"
    case statusChanged = "status_changed"
    case noteAdded = "note_added"
    case tagAdded = "tag_added"
    case tagRemoved = "tag_removed"
    case profileUpdated = "profile_updated"

    var displayName: String {
        switch self {
        case .messageReceived:
            return "Message Received"
        case .messageSent:
            return "Message Sent"
        case .visitScheduled:
            return "Visit Scheduled"
        case .visitCompleted:
            return "Visit Completed"
        case .prayerRequested:
            return "Prayer Requested"
        case .statusChanged:
            return "Status Changed"
        case .noteAdded:
            return "Note Added"
        case .tagAdded:
            return "Tag Added"
        case .tagRemoved:
            return "Tag Removed"
        case .profileUpdated:
            return "Profile Updated"
        }
    }
}

// MARK: - Household Models

/// Household grouping for family/relationship management
struct Household: Codable, Identifiable, Equatable {
    let id: String
    let organizationId: String
    let name: String
    let address: Address?
    let primaryContactId: String?  // Member ID of primary contact
    let members: [String]  // Array of Member IDs
    let householdType: HouseholdType
    let notes: String?
    let createdAt: Date
    let updatedAt: Date
}

enum HouseholdType: String, Codable, CaseIterable {
    case family = "family"
    case individual = "individual"
    case couple = "couple"
    case community = "community"
    case other = "other"

    var displayName: String {
        return rawValue.capitalized
    }
}

// MARK: - Member Request/Response Models

/// Create member request — matches /api/members POST schema
struct CreateMemberRequest: Codable {
    let firstName: String
    let lastName: String?
    let email: String?
    let phone: String?
    let whatsappNumber: String?
    let wechatId: String?
    let dateOfBirth: String?  // ISO 8601 string
    let gender: String?  // MALE | FEMALE | ORGANIZATION
    let address: String?
    let city: String?
    let state: String?
    let zipCode: String?
    let country: String?
    let memberStatus: MemberStatus?
    let membershipType: String?
    let joinDate: String?  // ISO 8601 string
    let photoUrl: String?
    let notes: String?
    let tags: [String]?
    let customFields: [String: String]?
    let workSchool: String?
    let hearAboutUs: String?
    let involvement: String?
    let comments: String?
    let consentGiven: Bool?
}

/// Update member request — matches /api/members/[id] PUT schema (same fields, all optional)
struct UpdateMemberRequest: Codable {
    let firstName: String?
    let lastName: String?
    let email: String?
    let phone: String?
    let whatsappNumber: String?
    let wechatId: String?
    let dateOfBirth: String?  // ISO 8601 string
    let gender: String?  // MALE | FEMALE | ORGANIZATION
    let address: String?
    let city: String?
    let state: String?
    let zipCode: String?
    let country: String?
    let memberStatus: MemberStatus?
    let membershipType: String?
    let joinDate: String?  // ISO 8601 string
    let photoUrl: String?
    let notes: String?
    let tags: [String]?
    let customFields: [String: String]?
}

/// Paginated member list response — matches API { items, page, limit, total }
struct MemberListResponse: Codable {
    let items: [Member]
    let page: Int?
    let limit: Int?
    let total: Int?

    var members: [Member] { items }
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

struct PaginationInfo: Codable {
    let page: Int
    let pageSize: Int
    let hasNext: Bool
    let hasPrevious: Bool
}

// MARK: - Member Search and Filter Models

struct MemberSearchCriteria: Codable {
    let query: String?
    let status: [MemberStatus]?
    let tags: [String]?
    let ageRange: AgeRange?
    let lastContactRange: DateRange?
    let joinDateRange: DateRange?
    let hasEmail: Bool?
    let hasPhone: Bool?
    let householdId: String?
    let sortBy: MemberSortField?
    let sortOrder: SortOrder?
    let page: Int
    let pageSize: Int
}

struct AgeRange: Codable {
    let min: Int?
    let max: Int?
}

struct DateRange: Codable {
    let start: Date?
    let end: Date?
}

enum MemberSortField: String, Codable, CaseIterable {
    case firstName = "first_name"
    case lastName = "last_name"
    case joinDate = "join_date"
    case lastContact = "last_contact"
    case status = "status"
    case createdAt = "created_at"

    var displayName: String {
        switch self {
        case .firstName:
            return "First Name"
        case .lastName:
            return "Last Name"
        case .joinDate:
            return "Join Date"
        case .lastContact:
            return "Last Contact"
        case .status:
            return "Status"
        case .createdAt:
            return "Date Added"
        }
    }
}

enum SortOrder: String, Codable, CaseIterable {
    case ascending = "asc"
    case descending = "desc"

    var displayName: String {
        switch self {
        case .ascending:
            return "Ascending"
        case .descending:
            return "Descending"
        }
    }
}

// MARK: - Preview Extensions

extension Member {
    static let preview = Member(
        id: "preview-member-id",
        organizationId: "preview-org-id",
        userId: nil,
        firstName: "John",
        lastName: "Doe",
        email: "john.doe@example.com",
        phone: "+1-555-0123",
        dateOfBirth: "1994-11-18T00:00:00Z",
        gender: nil,
        address: "123 Main St",
        city: "Anytown",
        state: "CA",
        zipCode: "12345",
        country: "USA",
        memberStatus: .active,
        membershipType: nil,
        joinDate: "2025-01-01T00:00:00Z",
        photoUrl: nil,
        notes: nil,
        tags: ["vip", "regular"],
        customFields: nil,
        workSchool: nil,
        whatsappNumber: nil,
        wechatId: nil,
        hearAboutUs: nil,
        involvement: nil,
        comments: nil,
        consentGiven: false,
        createdBy: "preview-user-id",
        createdAt: "2025-11-18T00:00:00Z",
        updatedAt: "2025-11-18T00:00:00Z"
    )
}
// MARK: - Bulk Import Models

/// Result of a bulk member import operation
struct BulkImportResult: Codable {
    let successCount: Int
    let failureCount: Int
    let errors: [ImportError]

    struct ImportError: Codable {
        let row: Int
        let message: String
    }
}
