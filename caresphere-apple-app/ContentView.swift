//
//  ContentView.swift
//  CareSphere Apple (iOS & macOS)
//
//  Created by Enoch Kwateh Dongbo on 2025/11/11.
//

import SwiftUI

/// Main app coordinator handling authentication state and app flow
struct ContentView: View {
    @StateObject private var theme = CareSphereTheme.shared
    @StateObject private var authService = AuthenticationService.shared
    @StateObject private var settingsService = SenderSettingsService.shared
    @StateObject private var memberService = MemberService.shared
    @StateObject private var messageService = MessageService.shared
    @StateObject private var analyticsService = AnalyticsService.shared
    @State private var hasLoadedInitialUser = false

    var body: some View {
        Group {
            if authService.isAuthenticated {
                MainAppView()
            } else {
                AuthenticationView()
            }
        }
        .environmentObject(theme)
        .environmentObject(authService)
        .environmentObject(settingsService)
        .environmentObject(memberService)
        .environmentObject(messageService)
        .environmentObject(analyticsService)
        .task {
            guard !hasLoadedInitialUser else { return }
            hasLoadedInitialUser = true
            // Load current user if already authenticated
            if authService.isAuthenticated {
                await authService.loadCurrentUser()
            }
        }
    }
}

#Preview {
    ContentView()
}
