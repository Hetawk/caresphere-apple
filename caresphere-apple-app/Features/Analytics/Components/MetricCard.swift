import SwiftUI

/// Metric card component for analytics
struct MetricCard: View {
    @EnvironmentObject private var theme: CareSphereTheme
    let title: String
    let value: String
    let percentage: String
    let icon: String
    let color: CareSphereStatusBadge.StatusColor

    var body: some View {
        CareSphereCard(padding: CareSphereSpacing.md) {
            VStack(alignment: .leading, spacing: CareSphereSpacing.sm) {
                HStack {
                    Text(title)
                        .font(CareSphereTypography.bodySmall)
                        .foregroundColor(theme.colors.onSurface.opacity(0.7))

                    Spacer()

                    Image(systemName: icon)
                        .foregroundColor(color.color(in: theme))
                }

                Text(value)
                    .font(CareSphereTypography.headlineSmall)
                    .foregroundColor(theme.colors.onBackground)

                Text(percentage)
                    .font(CareSphereTypography.caption)
                    .foregroundColor(color.color(in: theme))
            }
        }
    }
}
