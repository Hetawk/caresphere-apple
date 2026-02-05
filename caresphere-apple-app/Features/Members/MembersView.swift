import SwiftUI

/// Members management view
struct MembersView: View {
    @EnvironmentObject private var theme: CareSphereTheme
    @EnvironmentObject private var memberService: MemberService

    @State private var searchText = ""
    @State private var selectedMember: Member?
    @State private var showingAddMember = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                CareSphereSearchBar(
                    text: $searchText,
                    placeholder: "Search members..."
                ) {
                    Task {
                        await searchMembers()
                    }
                }
                .padding(CareSphereSpacing.md)

                // Members list
                if memberService.isLoading {
                    CareSphereLoadingView("Loading members...")
                } else if memberService.members.isEmpty {
                    CareSphereEmptyState(
                        icon: "person.3",
                        title: "No Members Yet",
                        description: "Add your first member to start building your community.",
                        actionTitle: "Add Member"
                    ) {
                        showingAddMember = true
                    }
                } else {
                    List {
                        ForEach(filteredMembers) { member in
                            MemberRow(member: member)
                                .onTapGesture {
                                    selectedMember = member
                                }
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
            .navigationTitle("Members")
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
                    Button("Add") {
                        showingAddMember = true
                    }
                    .buttonStyle(CareSphereButtonStyle.tertiary)
                }
            }
            .sheet(isPresented: $showingAddMember) {
                AddMemberView()
            }
            .sheet(item: $selectedMember) { member in
                MemberDetailView(member: member)
            }
            .task {
                if memberService.members.isEmpty {
                    await loadMembersWithTimeout()
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    private var filteredMembers: [Member] {
        if searchText.isEmpty {
            return memberService.members
        } else {
            return memberService.members.filter { member in
                member.fullName.localizedCaseInsensitiveContains(searchText)
                    || member.email?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }

    private func searchMembers() async {
        guard !searchText.isEmpty else {
            try? await memberService.loadMembers()
            return
        }

        try? await memberService.searchMembers(query: searchText)
    }

    private func loadMembersWithTimeout() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                try? await self.memberService.loadMembers()
            }

            group.addTask {
                try? await Task.sleep(nanoseconds: 10_000_000_000)  // 10 seconds
                // If still loading after 10s, stop loading state
                await MainActor.run {
                    if self.memberService.isLoading {
                        self.memberService.isLoading = false
                    }
                }
            }
        }
    }
}

#Preview {
    MembersView()
        .environmentObject(CareSphereTheme.shared)
        .environmentObject(MemberService.shared)
}
