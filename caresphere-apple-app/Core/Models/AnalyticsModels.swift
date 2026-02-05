//
//  AnalyticsModels.swift
//  CareSphere Apple (iOS & macOS)
//
//  Models for analytics and dashboard metrics
//

import Foundation

// MARK: - Dashboard Analytics

/// Dashboard analytics and metrics
struct DashboardAnalytics: Codable, Equatable {
    let totalMembers: Int
    let activeMembers: Int
    let newMembersThisMonth: Int
    let messagesSentThisMonth: Int
    let averageOpenRate: Double
    let averageClickRate: Double
    let automationRulesActive: Int
    let recentActivities: [ActivityMetric]
    let generatedAt: Date

    enum CodingKeys: String, CodingKey {
        case totalMembers = "totalMembers"
        case activeMembers = "activeMembers"
        case newMembersThisMonth = "newMembersThisMonth"
        case messagesSentThisMonth = "messagesSentThisMonth"
        case averageOpenRate = "averageOpenRate"
        case averageClickRate = "averageClickRate"
        case automationRulesActive = "automationRulesActive"
        case recentActivities = "recentActivities"
        case generatedAt = "generatedAt"
    }
}

/// Activity metric for dashboard
struct ActivityMetric: Codable, Equatable, Identifiable {
    let label: String
    let value: Int

    var id: String { label }
}

// MARK: - Activity Models

/// Activity item for recent activities feed
struct ActivityItem: Codable, Equatable, Identifiable {
    let id: String
    let activityType: String
    let description: String?
    let metadata: [String: String]
    let createdAt: Date
    let createdBy: String?

    enum CodingKeys: String, CodingKey {
        case id
        case activityType = "activity_type"
        case description
        case metadata
        case createdAt = "created_at"
        case createdBy = "created_by"
    }

    // Computed properties for display
    var title: String {
        switch activityType {
        case "member_added":
            return "New member added"
        case "member_updated":
            return "Member updated"
        case "message_sent":
            return "Message sent"
        case "automation_triggered":
            return "Automation triggered"
        case "note_added":
            return "Note added"
        default:
            return activityType.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    var subtitle: String {
        return description ?? "No details available"
    }

    var icon: String {
        switch activityType {
        case "member_added":
            return "person.fill.badge.plus"
        case "member_updated":
            return "person.fill"
        case "message_sent":
            return "envelope.fill"
        case "automation_triggered":
            return "gearshape.fill"
        case "note_added":
            return "note.text"
        default:
            return "circle.fill"
        }
    }

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}

// MARK: - Preview Data

extension DashboardAnalytics {
    static let preview = DashboardAnalytics(
        totalMembers: 156,
        activeMembers: 134,
        newMembersThisMonth: 12,
        messagesSentThisMonth: 89,
        averageOpenRate: 67.5,
        averageClickRate: 23.4,
        automationRulesActive: 5,
        recentActivities: [
            ActivityMetric(label: "Member Added", value: 45),
            ActivityMetric(label: "Message Sent", value: 89),
            ActivityMetric(label: "Note Added", value: 23),
        ],
        generatedAt: Date()
    )
}

extension ActivityItem {
    static let preview = ActivityItem(
        id: UUID().uuidString,
        activityType: "member_added",
        description: "Sarah Johnson joined the community",
        metadata: [:],
        createdAt: Date().addingTimeInterval(-7200),
        createdBy: nil
    )
}
