import SwiftUI

// MARK: - Birthday Marquee Ticker
// Scrolling horizontal ticker showing upcoming birthday announcements.
// Loops through all upcoming birthdays as continuous moving text.

struct BirthdayMarqueeTicker: View {
    let birthdays: [BirthdayMember]

    @State private var offset: CGFloat = 0
    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @EnvironmentObject private var theme: CareSphereTheme

    private var marqueeText: String {
        guard !birthdays.isEmpty else { return "" }
        return
            birthdays
            .map { $0.marqueeText }
            .joined(separator: "   •   ")
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.orange.opacity(0.85),
                        Color.pink.opacity(0.75),
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .cornerRadius(8)

                HStack(spacing: 0) {
                    // Leading birthday icon
                    Text("🎂")
                        .font(.system(size: 14))
                        .padding(.leading, 8)

                    // Scrolling text
                    Text(marqueeText)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .fixedSize()
                        .offset(x: offset)
                        .animation(
                            .linear(duration: Double(max(marqueeText.count, 20)) * 0.12)
                                .repeatForever(autoreverses: false),
                            value: offset
                        )
                        .background(
                            GeometryReader { textGeo in
                                Color.clear.onAppear {
                                    textWidth = textGeo.size.width
                                    containerWidth = geo.size.width
                                    startScrolling()
                                }
                            }
                        )
                }
                .clipped()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 32)
        }
        .frame(height: 32)
    }

    private func startScrolling() {
        offset = containerWidth
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            offset = -(textWidth + 32)
        }
    }
}

// MARK: - Birthday Banner Card
// Dashboard card showing today's birthdays prominently + upcoming list

struct BirthdayBannerCard: View {
    let response: UpcomingBirthdaysResponse
    let onSendMessage: (BirthdayMember) -> Void

    @EnvironmentObject private var theme: CareSphereTheme

    var body: some View {
        CareSphereCard {
            VStack(alignment: .leading, spacing: CareSphereSpacing.sm) {
                // Header
                HStack {
                    Image(systemName: "birthday.cake.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.orange)
                    Text("Birthdays")
                        .font(CareSphereTypography.titleMedium)
                        .foregroundColor(theme.colors.onBackground)
                    Spacer()
                    if response.total > 0 {
                        Text("\(response.total)")
                            .font(CareSphereTypography.labelSmall)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.orange)
                            .clipShape(Capsule())
                    }
                }

                // Marquee ticker (shown when there are upcoming birthdays)
                if !response.allSorted.isEmpty {
                    BirthdayMarqueeTicker(birthdays: response.allSorted)
                }

                // Today's birthdays — highlighted
                if !response.today.isEmpty {
                    VStack(alignment: .leading, spacing: CareSphereSpacing.xs) {
                        Text("TODAY")
                            .font(CareSphereTypography.labelSmall)
                            .foregroundColor(.orange)
                            .fontWeight(.bold)

                        ForEach(response.today) { member in
                            BirthdayMemberRow(
                                member: member,
                                onSendMessage: { onSendMessage(member) }
                            )
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.orange.opacity(0.08))
                            )
                        }
                    }
                }

                // Upcoming birthdays
                if !response.upcoming.isEmpty {
                    VStack(alignment: .leading, spacing: CareSphereSpacing.xs) {
                        if !response.today.isEmpty {
                            Text("UPCOMING")
                                .font(CareSphereTypography.labelSmall)
                                .foregroundColor(theme.colors.onSurface.opacity(0.5))
                                .fontWeight(.bold)
                        }

                        ForEach(response.upcoming.prefix(5)) { member in
                            BirthdayMemberRow(
                                member: member,
                                onSendMessage: { onSendMessage(member) }
                            )
                        }

                        if response.upcoming.count > 5 {
                            Text("+ \(response.upcoming.count - 5) more upcoming birthdays")
                                .font(CareSphereTypography.bodySmall)
                                .foregroundColor(theme.colors.onSurface.opacity(0.5))
                                .padding(.top, 2)
                        }
                    }
                }

                // Empty state
                if response.total == 0 {
                    HStack {
                        Image(systemName: "calendar.badge.checkmark")
                            .foregroundColor(theme.colors.onSurface.opacity(0.4))
                        Text("No birthdays in the next 30 days")
                            .font(CareSphereTypography.bodySmall)
                            .foregroundColor(theme.colors.onSurface.opacity(0.5))
                    }
                    .padding(.vertical, CareSphereSpacing.xs)
                }
            }
        }
    }
}

// MARK: - Birthday Member Row

struct BirthdayMemberRow: View {
    let member: BirthdayMember
    let onSendMessage: () -> Void

    @EnvironmentObject private var theme: CareSphereTheme

    var badgeColor: Color {
        switch member.daysUntil {
        case 0: return .orange
        case 1...3: return .pink
        case 4...7: return .blue
        default: return theme.colors.primary
        }
    }

    var body: some View {
        HStack(spacing: CareSphereSpacing.sm) {
            // Avatar / initials
            CareSphereAvatar(
                imageURL: member.photoUrl.flatMap { URL(string: $0) },
                name: member.fullName,
                size: 38
            )

            // Name + date
            VStack(alignment: .leading, spacing: 2) {
                Text(member.fullName)
                    .font(CareSphereTypography.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.onBackground)

                HStack(spacing: 4) {
                    Text(member.birthdayDate)
                        .font(CareSphereTypography.bodySmall)
                        .foregroundColor(theme.colors.onSurface.opacity(0.6))
                    if let age = member.age {
                        Text("· turning \(age)")
                            .font(CareSphereTypography.bodySmall)
                            .foregroundColor(theme.colors.onSurface.opacity(0.45))
                    }
                }
            }

            Spacer()

            // Countdown badge
            Text(member.countdownLabel)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(badgeColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(badgeColor.opacity(0.12))
                .clipShape(Capsule())

            // Send message button
            Button(action: onSendMessage) {
                Image(systemName: "message.fill")
                    .font(.system(size: 14))
                    .foregroundColor(theme.colors.primary)
                    .padding(8)
                    .background(theme.colors.primary.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
    }
}

// MARK: - Small Notification Dot (for use in nav/toolbar)

struct BirthdayNotificationBadge: View {
    let count: Int

    var body: some View {
        if count > 0 {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "birthday.cake")
                    .font(.system(size: 20))
                    .foregroundColor(.orange)
                Circle()
                    .fill(Color.red)
                    .frame(width: 16, height: 16)
                    .overlay(
                        Text("\(min(count, 9))")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .offset(x: 6, y: -6)
            }
        }
    }
}

// MARK: - Previews

#Preview("Birthday Banner") {
    ScrollView {
        BirthdayBannerCard(
            response: .preview,
            onSendMessage: { _ in }
        )
        .padding()
    }
    .environmentObject(CareSphereTheme())
}

#Preview("Marquee Ticker") {
    VStack {
        BirthdayMarqueeTicker(birthdays: UpcomingBirthdaysResponse.preview.allSorted)
            .padding()
        Spacer()
    }
    .environmentObject(CareSphereTheme())
}
