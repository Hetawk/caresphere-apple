import Foundation

// MARK: - Automation Models

/// Automation rule for triggered workflows
struct AutomationRule: Codable, Identifiable, Equatable {
    let id: String
    let organizationId: String
    let name: String
    let description: String?
    let isActive: Bool
    let trigger: AutomationTrigger
    let conditions: [AutomationCondition]
    let actions: [AutomationAction]
    let schedule: AutomationSchedule?
    let executionCount: Int
    let lastExecutedAt: Date?
    let createdBy: String  // User ID
    let createdAt: Date
    let updatedAt: Date
}

/// Trigger types for automation rules
enum AutomationTrigger: Codable, Equatable {
    case memberAdded
    case memberStatusChanged(from: MemberStatus?, to: MemberStatus)
    case memberBirthday(daysBefore: Int)
    case memberAnniversary(type: AnniversaryType, daysBefore: Int)
    case memberInactivity(days: Int)
    case messageReceived(channel: MessageChannel)
    case messageDeliveryFailed(attempts: Int)
    case schedule(cron: String)
    case customEvent(eventType: String)

    var displayName: String {
        switch self {
        case .memberAdded:
            return "Member Added"
        case .memberStatusChanged(let from, let to):
            let fromStr = from?.displayName ?? "Any"
            return "Status Changed from \(fromStr) to \(to.displayName)"
        case .memberBirthday(let daysBefore):
            return "Birthday (\(daysBefore) days before)"
        case .memberAnniversary(let type, let daysBefore):
            return "\(type.displayName) Anniversary (\(daysBefore) days before)"
        case .memberInactivity(let days):
            return "Member Inactive (\(days) days)"
        case .messageReceived(let channel):
            return "Message Received (\(channel.displayName))"
        case .messageDeliveryFailed(let attempts):
            return "Message Delivery Failed (\(attempts) attempts)"
        case .schedule(let cron):
            return "Scheduled (\(cron))"
        case .customEvent(let eventType):
            return "Custom Event (\(eventType))"
        }
    }
}

enum AnniversaryType: String, Codable, CaseIterable {
    case baptism = "baptism"
    case membership = "membership"
    case wedding = "wedding"
    case salvation = "salvation"

    var displayName: String {
        return rawValue.capitalized
    }
}

/// Conditions for automation rule execution
struct AutomationCondition: Codable, Equatable {
    let field: String
    let conditionOperator: ConditionOperator
    let value: String
    let logicalOperator: LogicalOperator?

    enum CodingKeys: String, CodingKey {
        case field
        case conditionOperator = "operator"
        case value
        case logicalOperator
    }
}

enum ConditionOperator: String, Codable, CaseIterable {
    case equals = "equals"
    case notEquals = "not_equals"
    case contains = "contains"
    case notContains = "not_contains"
    case startsWith = "starts_with"
    case endsWith = "ends_with"
    case greaterThan = "greater_than"
    case lessThan = "less_than"
    case greaterThanOrEqual = "greater_than_or_equal"
    case lessThanOrEqual = "less_than_or_equal"
    case isEmpty = "is_empty"
    case isNotEmpty = "is_not_empty"
    case inList = "in_list"
    case notInList = "not_in_list"

    var displayName: String {
        switch self {
        case .equals:
            return "Equals"
        case .notEquals:
            return "Not Equals"
        case .contains:
            return "Contains"
        case .notContains:
            return "Does Not Contain"
        case .startsWith:
            return "Starts With"
        case .endsWith:
            return "Ends With"
        case .greaterThan:
            return "Greater Than"
        case .lessThan:
            return "Less Than"
        case .greaterThanOrEqual:
            return "Greater Than or Equal"
        case .lessThanOrEqual:
            return "Less Than or Equal"
        case .isEmpty:
            return "Is Empty"
        case .isNotEmpty:
            return "Is Not Empty"
        case .inList:
            return "In List"
        case .notInList:
            return "Not In List"
        }
    }
}

enum LogicalOperator: String, Codable, CaseIterable {
    case and = "and"
    case or = "or"

    var displayName: String {
        return rawValue.uppercased()
    }
}

/// Actions to execute when automation rule triggers
enum AutomationAction: Codable, Equatable {
    case sendMessage(templateId: String, channel: MessageChannel, delay: TimeInterval?)
    case updateMemberStatus(status: MemberStatus)
    case addMemberTag(tag: String)
    case removeMemberTag(tag: String)
    case createNote(category: NoteCategory, content: String, isPrivate: Bool)
    case assignToUser(userId: String)
    case scheduleFollowUp(days: Int, assigneeId: String?)
    case sendNotification(userId: String, message: String)
    case webhook(url: String, payload: [String: String])
    case customAction(actionType: String, parameters: [String: String])

    var displayName: String {
        switch self {
        case .sendMessage(_, let channel, let delay):
            let delayStr = delay.map { " (after \(Int($0/60)) minutes)" } ?? ""
            return "Send \(channel.displayName) Message\(delayStr)"
        case .updateMemberStatus(let status):
            return "Update Status to \(status.displayName)"
        case .addMemberTag(let tag):
            return "Add Tag '\(tag)'"
        case .removeMemberTag(let tag):
            return "Remove Tag '\(tag)'"
        case .createNote(let category, _, _):
            return "Create \(category.displayName) Note"
        case .assignToUser:
            return "Assign to User"
        case .scheduleFollowUp(let days, _):
            return "Schedule Follow-up (\(days) days)"
        case .sendNotification:
            return "Send Notification"
        case .webhook:
            return "Call Webhook"
        case .customAction(let actionType, _):
            return "Custom Action (\(actionType))"
        }
    }
}

/// Scheduling options for automation rules
struct AutomationSchedule: Codable, Equatable {
    let type: ScheduleType
    let cronExpression: String?
    let timezone: String
    let isActive: Bool
}

enum ScheduleType: String, Codable, CaseIterable {
    case once = "once"
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case cron = "cron"

    var displayName: String {
        return rawValue.capitalized
    }
}

// MARK: - Automation Execution Models

/// Log entry for automation rule execution
struct AutomationLog: Codable, Identifiable, Equatable {
    let id: String
    let ruleId: String
    let triggeredBy: AutomationTrigger
    let executionStatus: ExecutionStatus
    let executedActions: [ExecutedAction]
    let errorMessage: String?
    let executionTime: TimeInterval
    let triggeredAt: Date
    let completedAt: Date?
    let metadata: [String: String]
}

enum ExecutionStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case running = "running"
    case completed = "completed"
    case failed = "failed"
    case skipped = "skipped"

    var displayName: String {
        return rawValue.capitalized
    }

    var color: String {
        switch self {
        case .pending:
            return "secondary"
        case .running:
            return "info"
        case .completed:
            return "success"
        case .failed:
            return "error"
        case .skipped:
            return "warning"
        }
    }
}

struct ExecutedAction: Codable, Equatable {
    let action: AutomationAction
    let status: ExecutionStatus
    let result: String?
    let errorMessage: String?
    let executedAt: Date
}

// MARK: - Analytics Models

/// Dashboard metrics and KPIs
struct DashboardMetrics: Codable, Equatable {
    let organizationId: String
    let period: AnalyticsPeriod
    let memberMetrics: MemberMetrics
    let messageMetrics: MessageMetrics
    let automationMetrics: AutomationMetrics
    let engagementMetrics: EngagementMetrics
    let generatedAt: Date
}

enum AnalyticsPeriod: String, Codable, CaseIterable {
    case today = "today"
    case yesterday = "yesterday"
    case last7Days = "last_7_days"
    case last30Days = "last_30_days"
    case last90Days = "last_90_days"
    case thisMonth = "this_month"
    case lastMonth = "last_month"
    case thisYear = "this_year"
    case lastYear = "last_year"
    case custom = "custom"

    var displayName: String {
        switch self {
        case .today:
            return "Today"
        case .yesterday:
            return "Yesterday"
        case .last7Days:
            return "Last 7 Days"
        case .last30Days:
            return "Last 30 Days"
        case .last90Days:
            return "Last 90 Days"
        case .thisMonth:
            return "This Month"
        case .lastMonth:
            return "Last Month"
        case .thisYear:
            return "This Year"
        case .lastYear:
            return "Last Year"
        case .custom:
            return "Custom"
        }
    }
}

/// Member-related analytics
struct MemberMetrics: Codable, Equatable {
    let totalMembers: Int
    let newMembers: Int
    let activeMembers: Int
    let inactiveMembers: Int
    let needFollowUp: Int
    let averageAge: Double?
    let membersByStatus: [MemberStatus: Int]
    let memberGrowthTrend: [TrendPoint]
    let topTags: [TagMetric]
}

struct TagMetric: Codable, Equatable {
    let tag: String
    let count: Int
}

/// Message-related analytics
struct MessageMetrics: Codable, Equatable {
    let totalMessages: Int
    let messagesSent: Int
    let deliveryRate: Double
    let readRate: Double
    let messagesByChannel: [MessageChannel: ChannelMetrics]
    let messagesByType: [MessageType: Int]
    let messageTrend: [TrendPoint]
    let topTemplates: [TemplateMetric]
}

struct TemplateMetric: Codable, Equatable {
    let templateId: String
    let templateName: String
    let usageCount: Int
    let deliveryRate: Double
}

/// Automation-related analytics
struct AutomationMetrics: Codable, Equatable {
    let totalRules: Int
    let activeRules: Int
    let totalExecutions: Int
    let successfulExecutions: Int
    let failedExecutions: Int
    let successRate: Double
    let rulesByTrigger: [String: Int]
    let executionTrend: [TrendPoint]
    let topPerformingRules: [RuleMetric]
}

struct RuleMetric: Codable, Equatable {
    let ruleId: String
    let ruleName: String
    let executionCount: Int
    let successRate: Double
}

/// Engagement-related analytics
struct EngagementMetrics: Codable, Equatable {
    let totalInteractions: Int
    let averageResponseTime: TimeInterval?
    let memberEngagementScore: Double
    let engagementByChannel: [MessageChannel: Double]
    let engagementTrend: [TrendPoint]
    let topEngagedMembers: [MemberEngagement]
    let lowEngagementMembers: [MemberEngagement]
}

struct MemberEngagement: Codable, Equatable {
    let memberId: String
    let memberName: String
    let engagementScore: Double
    let lastInteraction: Date?
    let interactionCount: Int
}

/// Time series data point for trends
struct TrendPoint: Codable, Equatable {
    let date: Date
    let value: Double
    let label: String?
}

// MARK: - Request/Response Models for Analytics

struct AnalyticsRequest: Codable {
    let period: AnalyticsPeriod
    let startDate: Date?
    let endDate: Date?
    let memberIds: [String]?
    let includeComparisons: Bool
    let granularity: AnalyticsGranularity?
}

enum AnalyticsGranularity: String, Codable, CaseIterable {
    case hour = "hour"
    case day = "day"
    case week = "week"
    case month = "month"
    case year = "year"

    var displayName: String {
        return rawValue.capitalized
    }
}

struct AutomationRuleRequest: Codable {
    let name: String
    let description: String?
    let trigger: AutomationTrigger
    let conditions: [AutomationCondition]
    let actions: [AutomationAction]
    let schedule: AutomationSchedule?
    let isActive: Bool
}

struct AutomationRuleResponse: Codable {
    let rule: AutomationRule
    let recentLogs: [AutomationLog]
    let metrics: RuleMetric
}

// MARK: - Report Models

struct ReportRequest: Codable {
    let reportType: ReportType
    let period: AnalyticsPeriod
    let startDate: Date?
    let endDate: Date?
    let filters: ReportFilters?
    let format: ReportFormat
}

enum ReportType: String, Codable, CaseIterable {
    case memberGrowth = "member_growth"
    case messagePerformance = "message_performance"
    case automationEffectiveness = "automation_effectiveness"
    case engagementSummary = "engagement_summary"
    case careActivities = "care_activities"
    case comprehensive = "comprehensive"

    var displayName: String {
        switch self {
        case .memberGrowth:
            return "Member Growth Report"
        case .messagePerformance:
            return "Message Performance Report"
        case .automationEffectiveness:
            return "Automation Effectiveness Report"
        case .engagementSummary:
            return "Engagement Summary Report"
        case .careActivities:
            return "Care Activities Report"
        case .comprehensive:
            return "Comprehensive Report"
        }
    }
}

enum ReportFormat: String, Codable, CaseIterable {
    case pdf = "pdf"
    case excel = "excel"
    case csv = "csv"
    case json = "json"

    var mimeType: String {
        switch self {
        case .pdf:
            return "application/pdf"
        case .excel:
            return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        case .csv:
            return "text/csv"
        case .json:
            return "application/json"
        }
    }
}

struct ReportFilters: Codable {
    let memberIds: [String]?
    let userIds: [String]?
    let tags: [String]?
    let messageTypes: [MessageType]?
    let channels: [MessageChannel]?
    let automationRuleIds: [String]?
}
