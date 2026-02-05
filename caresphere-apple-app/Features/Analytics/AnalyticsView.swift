import SwiftUI

/// Analytics view with metrics and charts
struct AnalyticsView: View {
    @EnvironmentObject private var theme: CareSphereTheme
    @EnvironmentObject private var analyticsService: AnalyticsService
    @State private var selectedPeriod: AnalyticsPeriod = .last30Days
    @State private var isRefreshing = false

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: CareSphereSpacing.lg) {
                    periodSelector
                    keyMetricsSection
                    chartsSection
                }
                .padding(.horizontal, CareSphereSpacing.lg)
                .padding(.top, CareSphereSpacing.sm)
                .padding(.bottom, CareSphereSpacing.md)
            }
            .background(theme.colors.background)
            .navigationTitle("Analytics")
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
                await loadAnalytics()
            }
            .task {
                if analyticsService.dashboardAnalytics == nil {
                    await loadAnalytics()
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    private func loadAnalytics() async {
        isRefreshing = true
        defer { isRefreshing = false }

        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                _ = await self.analyticsService.loadDashboardAnalytics()
            }

            group.addTask {
                try? await Task.sleep(nanoseconds: 10_000_000_000)  // 10 seconds
            }
        }
    }

    private var periodSelector: some View {
        CareSphereCard {
            VStack(alignment: .leading, spacing: CareSphereSpacing.md) {
                Text("Time Period")
                    .font(CareSphereTypography.titleSmall)
                    .foregroundColor(theme.colors.onBackground)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: CareSphereSpacing.sm) {
                        ForEach(AnalyticsPeriod.allCases.prefix(6), id: \.rawValue) { period in
                            if selectedPeriod == period {
                                Button(period.displayName) {
                                    selectedPeriod = period
                                }
                                .buttonStyle(CareSphereButtonStyle.primary)
                            } else {
                                Button(period.displayName) {
                                    selectedPeriod = period
                                }
                                .buttonStyle(CareSphereButtonStyle.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, CareSphereSpacing.sm)
                }
            }
        }
    }

    private var keyMetricsSection: some View {
        VStack(alignment: .leading, spacing: CareSphereSpacing.md) {
            Text("Key Metrics")
                .font(CareSphereTypography.titleMedium)
                .foregroundColor(theme.colors.onBackground)
                .padding(.horizontal, CareSphereSpacing.sm)

            if let analytics = analyticsService.dashboardAnalytics {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible()), count: 2),
                    spacing: CareSphereSpacing.md
                ) {
                    MetricCard(
                        title: "Total Members",
                        value: "\(analytics.totalMembers)",
                        percentage: "+\(analytics.newMembersThisMonth) this month",
                        icon: "person.3.fill",
                        color: .success
                    )

                    MetricCard(
                        title: "Messages Sent",
                        value: "\(analytics.messagesSentThisMonth)",
                        percentage: "This month",
                        icon: "envelope.fill",
                        color: .primary
                    )

                    MetricCard(
                        title: "Open Rate",
                        value: String(format: "%.1f%%", analytics.averageOpenRate),
                        percentage: "Average",
                        icon: "envelope.open.fill",
                        color: analytics.averageOpenRate >= 50 ? .success : .warning
                    )

                    MetricCard(
                        title: "Click Rate",
                        value: String(format: "%.1f%%", analytics.averageClickRate),
                        percentage: "Average",
                        icon: "hand.tap.fill",
                        color: analytics.averageClickRate >= 20 ? .success : .warning
                    )

                    MetricCard(
                        title: "Active Members",
                        value: "\(analytics.activeMembers)",
                        percentage: analytics.totalMembers > 0
                            ? "\(Int((Double(analytics.activeMembers) / Double(analytics.totalMembers)) * 100))% of total"
                            : "0% of total",
                        icon: "person.fill.checkmark",
                        color: .secondary
                    )

                    MetricCard(
                        title: "Automations",
                        value: "\(analytics.automationRulesActive)",
                        percentage: "Active rules",
                        icon: "gearshape.fill",
                        color: .primary
                    )
                }
            } else if analyticsService.isLoading {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible()), count: 2),
                    spacing: CareSphereSpacing.md
                ) {
                    ForEach(0..<6, id: \.self) { _ in
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
            } else {
                CareSphereCard {
                    VStack(spacing: CareSphereSpacing.sm) {
                        Image(systemName: "chart.bar")
                            .font(.largeTitle)
                            .foregroundColor(theme.colors.onSurface.opacity(0.3))
                        Text("No analytics data available")
                            .font(CareSphereTypography.bodyMedium)
                            .foregroundColor(theme.colors.onSurface.opacity(0.6))
                        Button("Refresh") {
                            Task { await loadAnalytics() }
                        }
                        .buttonStyle(CareSphereButtonStyle.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, CareSphereSpacing.lg)
                }
            }
        }
    }

    private var chartsSection: some View {
        VStack(alignment: .leading, spacing: CareSphereSpacing.md) {
            Text("Trends")
                .font(CareSphereTypography.titleMedium)
                .foregroundColor(theme.colors.onBackground)
                .padding(.horizontal, CareSphereSpacing.sm)

            CareSphereCard {
                VStack(alignment: .leading, spacing: CareSphereSpacing.md) {
                    Text("Member Growth Over Time")
                        .font(CareSphereTypography.titleSmall)
                        .foregroundColor(theme.colors.onBackground)

                    RoundedRectangle(cornerRadius: CareSphereRadius.md)
                        .fill(theme.colors.primary.opacity(0.1))
                        .frame(height: 200)
                        .overlay(
                            Text("Chart Coming Soon")
                                .font(CareSphereTypography.bodyMedium)
                                .foregroundColor(theme.colors.onSurface.opacity(0.7))
                        )
                }
            }

            CareSphereCard {
                VStack(alignment: .leading, spacing: CareSphereSpacing.md) {
                    Text("Message Performance")
                        .font(CareSphereTypography.titleSmall)
                        .foregroundColor(theme.colors.onBackground)

                    RoundedRectangle(cornerRadius: CareSphereRadius.md)
                        .fill(theme.colors.secondary.opacity(0.1))
                        .frame(height: 200)
                        .overlay(
                            Text("Chart Coming Soon")
                                .font(CareSphereTypography.bodyMedium)
                                .foregroundColor(theme.colors.onSurface.opacity(0.7))
                        )
                }
            }
        }
    }
}

#Preview {
    AnalyticsView()
        .environmentObject(CareSphereTheme.shared)
        .environmentObject(AnalyticsService.preview)
}
