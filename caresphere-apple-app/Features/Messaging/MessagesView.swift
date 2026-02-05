import SwiftUI

/// Messages management view with tabs for Messages and Templates
struct MessagesView: View {
    @EnvironmentObject private var theme: CareSphereTheme
    @EnvironmentObject private var messageService: MessageService
    @State private var selectedTab = 0
    @State private var showingComposer = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Segment control for switching
                Picker("View", selection: $selectedTab) {
                    Text("Messages").tag(0)
                    Text("Templates").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, CareSphereSpacing.lg)
                .padding(.vertical, CareSphereSpacing.sm)
                .background(theme.colors.surface)

                // Content
                if selectedTab == 0 {
                    messagesListTab
                } else {
                    TemplatesView()
                }
            }
            .navigationTitle("Messaging")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(theme.colors.surface, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarColorScheme(
                    theme.currentColorScheme == .dark ? .dark : .light,
                    for: .navigationBar
                )
            #endif
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Compose") {
                        showingComposer = true
                    }
                    .buttonStyle(CareSphereButtonStyle.tertiary)
                }
            }
            .sheet(isPresented: $showingComposer) {
                MessageComposerView()
                    .environmentObject(theme)
                    .environmentObject(messageService)
            }
        }
        .navigationViewStyle(.stack)
    }

    private var messagesListTab: some View {
        VStack {
            if messageService.isLoading {
                CareSphereLoadingView("Loading messages...")
            } else if messageService.messages.isEmpty {
                CareSphereEmptyState(
                    icon: "envelope",
                    title: "No Messages Yet",
                    description: "Send your first message to connect with your community.",
                    actionTitle: "Compose Message"
                ) {
                    showingComposer = true
                }
            } else {
                List {
                    ForEach(messageService.messages) { message in
                        MessageRow(message: message)
                            .listRowBackground(theme.colors.surface)
                    }
                }
                .listStyle(PlainListStyle())
                .scrollContentBackground(.hidden)
                .background(theme.colors.background)
            }
        }
        .padding(.top, CareSphereSpacing.sm)
        .background(theme.colors.background)
        .task {
            if messageService.messages.isEmpty {
                await loadMessagesWithTimeout()
            }
        }
    }

    private func loadMessagesWithTimeout() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                try? await self.messageService.loadMessages()
            }

            group.addTask {
                try? await Task.sleep(nanoseconds: 10_000_000_000)  // 10 seconds
                // If still loading after 10s, stop loading state
                await MainActor.run {
                    if self.messageService.isLoading {
                        self.messageService.isLoading = false
                    }
                }
            }
        }
    }
}

#Preview {
    MessagesView()
        .environmentObject(CareSphereTheme.shared)
        .environmentObject(MessageService.shared)
}
