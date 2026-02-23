import Foundation
import SwiftUI

// MARK: - Birthday Member

/// A member with an upcoming or today birthday, returned by GET /api/birthdays/upcoming
struct BirthdayMember: Identifiable, Codable, Equatable {
    let id: String
    let firstName: String
    let lastName: String?
    let fullName: String
    let email: String?
    let phone: String?
    let whatsappNumber: String?
    let photoUrl: String?
    let dateOfBirth: String  // ISO string
    let daysUntil: Int  // 0 = today
    let birthdayDate: String  // "January 15"
    let age: Int?  // age they will turn

    var isToday: Bool { daysUntil == 0 }
    var isSoon: Bool { daysUntil <= 7 }

    /// Human-readable countdown label
    var countdownLabel: String {
        switch daysUntil {
        case 0: return "🎂 Today!"
        case 1: return "🎁 Tomorrow"
        case 2...7: return "⏰ \(daysUntil) days away"
        default: return "\(daysUntil) days away"
        }
    }

    /// Marquee-style ticker text
    var marqueeText: String {
        switch daysUntil {
        case 0:
            let agePart = age != nil ? " (turning \(age!))" : ""
            return "🎂 Today is \(firstName)'s birthday\(agePart)! Wish them well!"
        case 1:
            return
                "🎁 Tomorrow is \(firstName)'s birthday\(age != nil ? " — turning \(age!)" : ""). Prepare a message!"
        case 2...3:
            return
                "⏰ \(daysUntil) days to \(firstName)'s birthday on \(birthdayDate). Send them a message soon!"
        case 4...7:
            return
                "📅 \(daysUntil) more days to \(firstName)'s birthday (\(birthdayDate)). Prepare to celebrate!"
        default:
            return "🗓 \(firstName)'s birthday is on \(birthdayDate) — \(daysUntil) days away."
        }
    }
}

// MARK: - Upcoming Birthdays Response

struct UpcomingBirthdaysResponse: Codable {
    let today: [BirthdayMember]
    let upcoming: [BirthdayMember]
    let total: Int

    var allSorted: [BirthdayMember] {
        (today + upcoming).sorted { $0.daysUntil < $1.daysUntil }
    }
}

// MARK: - Generated Birthday Message

struct GeneratedBirthdayMessage: Codable {
    let subject: String
    let body: String
}

// MARK: - Preview Data

extension BirthdayMember {
    static let todayPreview = BirthdayMember(
        id: "bday-1",
        firstName: "Enoch",
        lastName: "Mensah",
        fullName: "Enoch Mensah",
        email: "enoch@example.com",
        phone: "+1-555-0101",
        whatsappNumber: nil,
        photoUrl: nil,
        dateOfBirth: "1990-02-23T00:00:00Z",
        daysUntil: 0,
        birthdayDate: "February 23",
        age: 35
    )

    static let soonPreview = BirthdayMember(
        id: "bday-2",
        firstName: "Grace",
        lastName: "Otieno",
        fullName: "Grace Otieno",
        email: "grace@example.com",
        phone: "+1-555-0102",
        whatsappNumber: nil,
        photoUrl: nil,
        dateOfBirth: "1988-03-02T00:00:00Z",
        daysUntil: 3,
        birthdayDate: "March 2",
        age: 38
    )

    static let upcomingPreview = BirthdayMember(
        id: "bday-3",
        firstName: "Samuel",
        lastName: "Adeyemi",
        fullName: "Samuel Adeyemi",
        email: nil,
        phone: nil,
        whatsappNumber: nil,
        photoUrl: nil,
        dateOfBirth: "1995-03-09T00:00:00Z",
        daysUntil: 7,
        birthdayDate: "March 9",
        age: 31
    )
}

extension UpcomingBirthdaysResponse {
    static let preview = UpcomingBirthdaysResponse(
        today: [.todayPreview],
        upcoming: [.soonPreview, .upcomingPreview],
        total: 3
    )
}
