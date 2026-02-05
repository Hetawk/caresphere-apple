import SwiftUI

/// Main app coordinator managing tab navigation and service dependencies
struct MainAppView: View {
    @EnvironmentObject private var theme: CareSphereTheme
    @EnvironmentObject private var authService: AuthenticationService
    @EnvironmentObject private var settingsService: SenderSettingsService
    
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    TabItemView(icon: "house", text: "Dashboard")
                }
            
            MembersView()
                .tabItem {
                    TabItemView(icon: "person.2", text: "Members")
                }
            
            MessagesView()
                .tabItem {
                    TabItemView(icon: "envelope", text: "Messages")
                }
            
            AnalyticsView()
                .tabItem {
                    TabItemView(icon: "chart.bar", text: "Analytics")
                }
            
            AppSettingsView()
                .tabItem {
                    TabItemView(icon: "gear", text: "Settings")
                }
        }
        .accentColor(theme.colors.secondary)
        .onAppear {
            updateTabAppearance()
            updateNavigationAppearance()
        }
        .onReceive(theme.$currentColorScheme) { _ in
            updateTabAppearance()
            updateNavigationAppearance()
        }
    }

    private func updateTabAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = UIColor(theme.colors.surface)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().tintColor = UIColor(theme.colors.secondary)
    }

    private func updateNavigationAppearance() {
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(theme.colors.surface)
        let titleColor = UIColor(theme.colors.onSurface)
        navAppearance.titleTextAttributes = [.foregroundColor: titleColor]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: titleColor]

        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().tintColor = UIColor(theme.colors.secondary)
    }
}

/// Tab item view component for consistent tab styling
struct TabItemView: View {
    let icon: String
    let text: String
    
    var body: some View {
        VStack {
            Image(systemName: icon)
            Text(text)
        }
    }
}

#Preview {
    MainAppView()
        .environmentObject(CareSphereTheme.shared)
        .environmentObject(AuthenticationService.shared)
        .environmentObject(SenderSettingsService.shared)
}