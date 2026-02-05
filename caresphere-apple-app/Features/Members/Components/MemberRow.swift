import SwiftUI

/// Member row component for list display
struct MemberRow: View {
    @EnvironmentObject private var theme: CareSphereTheme
    let member: Member

    var body: some View {
        HStack(spacing: CareSphereSpacing.md) {
            CareSphereAvatar(
                imageURL: member.profileImageURL.flatMap { URL(string: $0) },
                name: member.fullName
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(member.fullName)
                    .font(CareSphereTypography.bodyMedium)
                    .foregroundColor(theme.colors.onBackground)

                if let email = member.email {
                    Text(email)
                        .font(CareSphereTypography.bodySmall)
                        .foregroundColor(theme.colors.onSurface.opacity(0.7))
                }

                if let lastContact = member.lastContactDate {
                    Text("Last contact: \(lastContact, style: .relative)")
                        .font(CareSphereTypography.caption)
                        .foregroundColor(theme.colors.onSurface.opacity(0.6))
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                CareSphereStatusBadge(
                    member.status.displayName,
                    color: statusColor(for: member.status),
                    size: .small
                )

                if !member.tags.isEmpty {
                    Text("\(member.tags.count) tag\(member.tags.count == 1 ? "" : "s")")
                        .font(CareSphereTypography.caption)
                        .foregroundColor(theme.colors.onSurface.opacity(0.6))
                }
            }
        }
        .padding(.vertical, CareSphereSpacing.xs)
    }

    private func statusColor(for status: MemberStatus) -> CareSphereStatusBadge.StatusColor {
        switch status {
        case .active: return .success
        case .inactive: return .secondary
        case .needsFollowUp: return .warning
        case .archived: return .secondary
        case .new: return .primary
        }
    }
}
