import SwiftUI

/// Dashboard view showing key metrics and recent activities
struct DashboardView: View {
    @EnvironmentObject private var theme: CareSphereTheme
    @EnvironmentObject private var authService: AuthenticationService
    @EnvironmentObject private var settingsService: SenderSettingsService
    @EnvironmentObject private var analyticsService: AnalyticsService

    @State private var isLoading = false
    @State private var showingAddMember = false
    @State private var showingComposeMessage = false

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: CareSphereSpacing.md) {
                    // Welcome section
                    welcomeSection

                    // Quick stats
                    quickStatsSection

                    // Recent activities
                    recentActivitiesSection

                    // Quick actions
                    quickActionsSection
                }
                .padding(.horizontal, CareSphereSpacing.md)
                .padding(.top, CareSphereSpacing.sm)
                .padding(.bottom, CareSphereSpacing.lg)
            }
            .background(theme.colors.background.ignoresSafeArea())
            .navigationTitle("Dashboard")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(theme.colors.surface, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarColorScheme(
                    theme.currentColorScheme == .dark ? .dark : .light,
                    for: .navigationBar
                )
            #endif
            .refreshable {
                await loadDashboardData()
            }
            .task {
                await loadDashboardData()
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Dashboard Sections

    private var welcomeSection: some View {
        CareSphereCard {
            HStack {
                VStack(alignment: .leading, spacing: CareSphereSpacing.xs) {
                    Text("Welcome back,")
                        .font(CareSphereTypography.bodyMedium)
                        .foregroundColor(theme.colors.onSurface.opacity(0.7))

                    Text(authService.currentUser?.firstName ?? "User")
                        .font(CareSphereTypography.headlineSmall)
                        .foregroundColor(theme.colors.onBackground)

                    Text("Today is a great day to care for others")
                        .font(CareSphereTypography.bodySmall)
                        .foregroundColor(theme.colors.onSurface.opacity(0.6))
                }

                Spacer()

                CareSphereAvatar(
                    imageURL: authService.currentUser?.avatarUrl.flatMap { URL(string: $0) },
                    name: authService.currentUser?.fullName ?? "User",
                    size: 60
                )
            }
        }
    }

    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: CareSphereSpacing.md) {
            Text("Quick Stats")
                .font(CareSphereTypography.titleMedium)
                .foregroundColor(theme.colors.onBackground)
                .padding(.horizontal, CareSphereSpacing.sm)

            if let analytics = analyticsService.dashboardAnalytics {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible()), count: 2),
                    spacing: CareSphereSpacing.md
                ) {
                    StatCard(
                        title: "Total Members",
                        value: "\(analytics.totalMembers)",
                        icon: "person.3.fill",
                        color: .primary
                    )

                    StatCard(
                        title: "Messages Sent",
                        value: "\(analytics.messagesSentThisMonth)",
                        icon: "envelope.fill",
                        color: .success
                    )

                    StatCard(
                        title: "Active Members",
                        value: "\(analytics.activeMembers)",
                        icon: "person.fill.checkmark",
                        color: .secondary
                    )

                    StatCard(
                        title: "New This Month",
                        value: "\(analytics.newMembersThisMonth)",
                        icon: "person.fill.badge.plus",
                        color: .warning
                    )
                }
            } else {
                // Loading placeholder
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible()), count: 2),
                    spacing: CareSphereSpacing.md
                ) {
                    ForEach(0..<4, id: \.self) { _ in
                        CareSphereCard(padding: CareSphereSpacing.md) {
                            VStack(alignment: .leading, spacing: CareSphereSpacing.sm) {
                                HStack {
                                    Circle()
                                        .fill(theme.colors.onSurface.opacity(0.1))
                                        .frame(width: 24, height: 24)
                                    Spacer()
                                }
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(theme.colors.onSurface.opacity(0.1))
                                    .frame(height: 28)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(theme.colors.onSurface.opacity(0.1))
                                    .frame(height: 16)
                            }
                        }
                    }
                }
            }
        }
    }

    private var recentActivitiesSection: some View {
        VStack(alignment: .leading, spacing: CareSphereSpacing.md) {
            HStack {
                Text("Activity Summary")
                    .font(CareSphereTypography.titleMedium)
                    .foregroundColor(theme.colors.onBackground)

                Spacer()

                Button("View All") {
                    // Navigate to full activities view
                }
                .buttonStyle(CareSphereButtonStyle.tertiary)
            }
            .padding(.horizontal, CareSphereSpacing.sm)

            if let analytics = analyticsService.dashboardAnalytics,
                !analytics.recentActivities.isEmpty
            {
                CareSphereCard {
                    VStack(spacing: CareSphereSpacing.md) {
                        ForEach(analytics.recentActivities) { activity in
                            ActivityMetricRow(activityMetric: activity)

                            if activity.id != analytics.recentActivities.last?.id {
                                Divider()
                                    .background(CareSphereColors.borderLight)
                            }
                        }
                    }
                }
            } else if analyticsService.isLoading {
                CareSphereCard {
                    VStack(spacing: CareSphereSpacing.md) {
                        ForEach(0..<3, id: \.self) { _ in
                            HStack(spacing: CareSphereSpacing.md) {
                                Circle()
                                    .fill(theme.colors.onSurface.opacity(0.1))
                                    .frame(width: 24, height: 24)

                                VStack(alignment: .leading, spacing: 4) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(theme.colors.onSurface.opacity(0.1))
                                        .frame(height: 16)
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(theme.colors.onSurface.opacity(0.1))
                                        .frame(width: 120, height: 14)
                                }

                                Spacer()
                            }
                        }
                    }
                }
            } else {
                CareSphereCard {
                    VStack(spacing: CareSphereSpacing.sm) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.title)
                            .foregroundColor(theme.colors.onSurface.opacity(0.3))
                        Text("No activity data yet")
                            .font(CareSphereTypography.bodyMedium)
                            .foregroundColor(theme.colors.onSurface.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, CareSphereSpacing.md)
                }
            }
        }
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: CareSphereSpacing.md) {
            Text("Quick Actions")
                .font(CareSphereTypography.titleMedium)
                .foregroundColor(theme.colors.onBackground)
                .padding(.horizontal, CareSphereSpacing.sm)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: 2),
                spacing: CareSphereSpacing.md
            ) {
                QuickActionCard(
                    title: "Add Member",
                    icon: "person.fill.badge.plus",
                    color: .primary
                ) {
                    showingAddMember = true
                }

                QuickActionCard(
                    title: "Send Message",
                    icon: "envelope.fill",
                    color: .success
                ) {
                    showingComposeMessage = true
                }

                QuickActionCard(
                    title: "View Analytics",
                    icon: "chart.bar.fill",
                    color: .secondary
                ) {
                    // Navigate via main tab bar - handled by TabView
                }

                QuickActionCard(
                    title: "Create Automation",
                    icon: "gearshape.fill",
                    color: .warning
                ) {
                    // TODO: Add automation view
                }
            }
        }
        .sheet(isPresented: $showingAddMember) {
            AddMemberView()
        }
        .sheet(isPresented: $showingComposeMessage) {
            MessageComposerView()
        }
    }

    // MARK: - Data Loading

    private func loadDashboardData() async {
        isLoading = true
        defer { isLoading = false }

        // Load dashboard analytics from API with timeout
        let success = await withTaskGroup(of: Bool.self) { group in
            group.addTask {
                await self.analyticsService.loadDashboardAnalytics()
            }

            group.addTask {
                try? await Task.sleep(nanoseconds: 10_000_000_000)  // 10 seconds
                return false
            }

            // Return first completed task
            if let result = await group.next() {
                group.cancelAll()
                return result
            }
            return false
        }

        if !success && analyticsService.dashboardAnalytics == nil {
            // Set empty analytics to show empty state instead of infinite loading
            analyticsService.dashboardAnalytics = DashboardAnalytics(
                totalMembers: 0,
                activeMembers: 0,
                newMembersThisMonth: 0,
                messagesSentThisMonth: 0,
                averageOpenRate: 0.0,
                averageClickRate: 0.0,
                automationRulesActive: 0,
                recentActivities: [],
                generatedAt: Date()
            )
        }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    @EnvironmentObject private var theme: CareSphereTheme
    let title: String
    let value: String
    let icon: String
    let color: CareSphereStatusBadge.StatusColor

    var body: some View {
        CareSphereCard(padding: CareSphereSpacing.md) {
            VStack(alignment: .leading, spacing: CareSphereSpacing.sm) {
                HStack {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color.color(in: theme))

                    Spacer()
                }

                Text(value)
                    .font(CareSphereTypography.headlineSmall)
                    .foregroundColor(theme.colors.onBackground)

                Text(title)
                    .font(CareSphereTypography.bodySmall)
                    .foregroundColor(theme.colors.onSurface.opacity(0.7))
            }
        }
    }
}

struct ActivityRow: View {
    @EnvironmentObject private var theme: CareSphereTheme
    let activity: ActivityItem

    var body: some View {
        HStack(spacing: CareSphereSpacing.md) {
            Image(systemName: activity.icon)
                .font(.title3)
                .foregroundColor(theme.colors.primary)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(CareSphereTypography.bodyMedium)
                    .foregroundColor(theme.colors.onBackground)

                Text(activity.subtitle)
                    .font(CareSphereTypography.bodySmall)
                    .foregroundColor(theme.colors.onSurface.opacity(0.7))
            }

            Spacer()

            Text(activity.timeAgo)
                .font(CareSphereTypography.caption)
                .foregroundColor(theme.colors.onSurface.opacity(0.6))
        }
    }
}

struct ActivityMetricRow: View {
    @EnvironmentObject private var theme: CareSphereTheme
    let activityMetric: ActivityMetric

    var body: some View {
        HStack(spacing: CareSphereSpacing.md) {
            Image(systemName: iconForActivity(activityMetric.label))
                .font(.title3)
                .foregroundColor(colorForActivity(activityMetric.label))
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(activityMetric.label)
                    .font(CareSphereTypography.bodyMedium)
                    .foregroundColor(theme.colors.onBackground)

                Text("\(activityMetric.value) occurrences")
                    .font(CareSphereTypography.bodySmall)
                    .foregroundColor(theme.colors.onSurface.opacity(0.7))
            }

            Spacer()

            Text("\(activityMetric.value)")
                .font(CareSphereTypography.titleSmall)
                .foregroundColor(theme.colors.primary)
                .fontWeight(.semibold)
        }
    }

    private func iconForActivity(_ label: String) -> String {
        let lowercased = label.lowercased()
        if lowercased.contains("member") && lowercased.contains("added") {
            return "person.fill.badge.plus"
        } else if lowercased.contains("message") {
            return "envelope.fill"
        } else if lowercased.contains("note") {
            return "note.text"
        } else if lowercased.contains("automation") {
            return "gearshape.fill"
        } else {
            return "circle.fill"
        }
    }

    private func colorForActivity(_ label: String) -> Color {
        let lowercased = label.lowercased()
        if lowercased.contains("member") && lowercased.contains("added") {
            return theme.colors.success
        } else if lowercased.contains("message") {
            return theme.colors.primary
        } else if lowercased.contains("note") {
            return theme.colors.secondary
        } else if lowercased.contains("automation") {
            return theme.colors.warning
        } else {
            return theme.colors.tertiary
        }
    }
}

struct QuickActionCard: View {
    @EnvironmentObject private var theme: CareSphereTheme
    let title: String
    let icon: String
    let color: CareSphereStatusBadge.StatusColor
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            CareSphereCard(padding: CareSphereSpacing.md) {
                VStack(spacing: CareSphereSpacing.sm) {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color.color(in: theme))

                    Text(title)
                        .font(CareSphereTypography.labelMedium)
                        .foregroundColor(theme.colors.onBackground)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    DashboardView()
        .environmentObject(CareSphereTheme.shared)
        .environmentObject(AuthenticationService.preview)
        .environmentObject(SenderSettingsService.shared)
        .environmentObject(AnalyticsService.preview)
}
