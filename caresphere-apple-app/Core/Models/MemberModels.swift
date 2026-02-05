import Foundation

// MARK: - Member Management Models

/// Core member model representing individuals in the care system
struct Member: Codable, Identifiable, Equatable {
    let id: String
    let organizationId: String
    let firstName: String
    let lastName: String
    let email: String?
    let phoneNumber: String?
    let whatsAppNumber: String?
    let weChatID: String?
    let dateOfBirth: Date?
    let address: Address?
    let status: MemberStatus
    let tags: [String]
    let customFields: [String: String]
    let profileImageURL: String?
    let emergencyContact: EmergencyContact?
    let householdId: String?
    let joinDate: Date
    let lastContactDate: Date?
    let createdAt: Date
    let updatedAt: Date
    let createdBy: String  // User ID who added this member
    
    // Computed properties
    var fullName: String {
        return "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }
    
    var displayName: String {
        return fullName.isEmpty ? email ?? phoneNumber ?? "Unknown" : fullName
    }
    
    var age: Int? {
        guard let dateOfBirth = dateOfBirth else { return nil }
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: Date())
        return ageComponents.year
    }
    
    var preferredContactMethod: ContactMethod? {
        if whatsAppNumber != nil { return .whatsApp }
        if email != nil { return .email }
        if phoneNumber != nil { return .sms }
        return nil
    }
}

/// Member status categories
enum MemberStatus: String, Codable, CaseIterable {
    case active = "active"
    case inactive = "inactive"
    case needsFollowUp = "needs_follow_up"
    case archived = "archived"
    case new = "new"
    
    var displayName: String {
        switch self {
        case .active:
            return "Active"
        case .inactive:
            return "Inactive"
        case .needsFollowUp:
            return "Needs Follow-up"
        case .archived:
            return "Archived"
        case .new:
            return "New"
        }
    }
    
    var color: String {
        switch self {
        case .active:
            return "success"
        case .inactive:
            return "secondary"
        case .needsFollowUp:
            return "warning"
        case .archived:
            return "tertiary"
        case .new:
            return "info"
        }
    }
}

/// Contact methods for multi-channel communication
enum ContactMethod: String, Codable, CaseIterable {
    case email = "email"
    case sms = "sms"
    case whatsApp = "whatsapp"
    case voice = "voice"
    case inApp = "in_app"
    
    var displayName: String {
        switch self {
        case .email:
            return "Email"
        case .sms:
            return "SMS"
        case .whatsApp:
            return "WhatsApp"
        case .voice:
            return "Voice Call"
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
        case .whatsApp:
            return "phone.bubble"
        case .voice:
            return "phone"
        case .inApp:
            return "bell"
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

struct CreateMemberRequest: Codable {
    let firstName: String
    let lastName: String
    let email: String?
    let phoneNumber: String?
    let whatsAppNumber: String?
    let weChatID: String?
    let dateOfBirth: Date?
    let address: Address?
    let tags: [String]
    let customFields: [String: String]
    let emergencyContact: EmergencyContact?
    let householdId: String?
}

struct UpdateMemberRequest: Codable {
    let firstName: String?
    let lastName: String?
    let email: String?
    let phoneNumber: String?
    let whatsAppNumber: String?
    let weChatID: String?
    let dateOfBirth: Date?
    let address: Address?
    let status: MemberStatus?
    let tags: [String]?
    let customFields: [String: String]?
    let emergencyContact: EmergencyContact?
    let householdId: String?
}

struct MemberListResponse: Codable {
    let members: [Member]
    let pagination: PaginationInfo
    let totalCount: Int
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
        firstName: "John",
        lastName: "Doe",
        email: "john.doe@example.com",
        phoneNumber: "+1-555-0123",
        whatsAppNumber: nil,
        weChatID: nil,
        dateOfBirth: Calendar.current.date(byAdding: .year, value: -30, to: Date()),
        address: Address(
            street: "123 Main St",
            city: "Anytown",
            state: "CA",
            postalCode: "12345",
            country: "USA"
        ),
        status: .active,
        tags: ["vip", "regular"],
        customFields: [:],
        profileImageURL: nil,
        emergencyContact: EmergencyContact(
            name: "Jane Doe",
            relationship: "Spouse",
            phoneNumber: "+1-555-0456",
            email: "jane.doe@example.com"
        ),
        householdId: nil,
        joinDate: Date(),
        lastContactDate: Date(),
        createdAt: Date(),
        updatedAt: Date(),
        createdBy: "preview-user-id"
    )
}