import SwiftUI

/// Templates view for browsing and managing message templates
struct TemplatesView: View {
    @EnvironmentObject private var theme: CareSphereTheme
    @EnvironmentObject private var messageService: MessageService
    @State private var searchText = ""
    @State private var selectedCategory: TemplateCategory?
    @State private var showingTemplateDetail: MessageTemplate?
    @State private var isLoading = false

    var filteredTemplates: [MessageTemplate] {
        messageService.templates.filter { template in
            let matchesSearch =
                searchText.isEmpty || template.name.localizedCaseInsensitiveContains(searchText)
                || (template.description?.localizedCaseInsensitiveContains(searchText) ?? false)

            let matchesCategory = selectedCategory == nil || template.category == selectedCategory

            return matchesSearch && matchesCategory && template.isActive
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: CareSphereSpacing.md) {
                // Category filter
                categoryFilterSection

                // Templates list
                if isLoading {
                    loadingState
                } else if filteredTemplates.isEmpty {
                    emptyState
                } else {
                    templatesListSection
                }
            }
            .padding(.horizontal, CareSphereSpacing.lg)
            .padding(.top, CareSphereSpacing.sm)
            .padding(.bottom, CareSphereSpacing.md)
        }
        .background(theme.colors.background)
        .searchable(text: $searchText, prompt: "Search templates...")
        .refreshable {
            await loadTemplates()
        }
        .task {
            if messageService.templates.isEmpty {
                await loadTemplatesWithTimeout()
            }
        }
        .sheet(item: $showingTemplateDetail) { template in
            TemplateDetailView(template: template)
                .environmentObject(theme)
                .environmentObject(messageService)
        }
    }

    private func loadTemplatesWithTimeout() async {
        isLoading = true
        defer { isLoading = false }

        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                do {
                    try await self.messageService.loadTemplates()
                } catch {
                    print("Error loading templates: \(error)")
                    // Set error state without crashing
                    await MainActor.run {
                        self.messageService.error = error as? APIError
                    }
                }
            }

            group.addTask {
                try? await Task.sleep(nanoseconds: 10_000_000_000)  // 10 seconds timeout
                await MainActor.run {
                    if self.messageService.isLoading {
                        self.messageService.isLoading = false
                    }
                }
            }
        }
    }

    private func loadTemplates() async {
        do {
            try await messageService.loadTemplates()
        } catch {
            print("Error loading templates: \(error)")
        }
    }

    private var categoryFilterSection: some View {
        CareSphereCard {
            VStack(alignment: .leading, spacing: CareSphereSpacing.md) {
                Text("Category")
                    .font(CareSphereTypography.titleSmall)
                    .foregroundColor(theme.colors.onBackground)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: CareSphereSpacing.sm) {
                        // All categories button
                        if selectedCategory == nil {
                            Button("All") {
                                selectedCategory = nil
                            }
                            .buttonStyle(CareSphereButtonStyle.primary)
                        } else {
                            Button("All") {
                                selectedCategory = nil
                            }
                            .buttonStyle(CareSphereButtonStyle.secondary)
                        }

                        // Individual category buttons
                        ForEach(TemplateCategory.allCases, id: \.rawValue) { category in
                            if selectedCategory == category {
                                Button(category.displayName) {
                                    selectedCategory = category
                                }
                                .buttonStyle(CareSphereButtonStyle.primary)
                            } else {
                                Button(category.displayName) {
                                    selectedCategory = category
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

    private var templatesListSection: some View {
        VStack(alignment: .leading, spacing: CareSphereSpacing.sm) {
            Text("\(filteredTemplates.count) Template\(filteredTemplates.count == 1 ? "" : "s")")
                .font(CareSphereTypography.labelMedium)
                .foregroundColor(theme.colors.onSurface.opacity(0.7))
                .padding(.horizontal, CareSphereSpacing.sm)

            ForEach(filteredTemplates) { template in
                TemplateRow(template: template)
                    .onTapGesture {
                        showingTemplateDetail = template
                    }
            }
        }
    }

    private var loadingState: some View {
        VStack(spacing: CareSphereSpacing.md) {
            ForEach(0..<3, id: \.self) { _ in
                CareSphereCard {
                    VStack(alignment: .leading, spacing: CareSphereSpacing.sm) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(theme.colors.onSurface.opacity(0.1))
                            .frame(height: 20)
                            .frame(maxWidth: 200)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(theme.colors.onSurface.opacity(0.1))
                            .frame(height: 16)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(theme.colors.onSurface.opacity(0.1))
                            .frame(height: 16)
                            .frame(maxWidth: 120)
                    }
                    .padding(CareSphereSpacing.md)
                }
            }
        }
    }

    private var emptyState: some View {
        CareSphereCard {
            VStack(spacing: CareSphereSpacing.md) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.largeTitle)
                    .foregroundColor(theme.colors.onSurface.opacity(0.3))

                Text(searchText.isEmpty ? "No templates available" : "No templates found")
                    .font(CareSphereTypography.bodyMedium)
                    .foregroundColor(theme.colors.onSurface.opacity(0.6))

                if searchText.isEmpty && selectedCategory == nil {
                    Button("Refresh") {
                        Task { await loadTemplatesWithTimeout() }
                    }
                    .buttonStyle(CareSphereButtonStyle.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, CareSphereSpacing.xl)
        }
    }
}

#Preview {
    TemplatesView()
        .environmentObject(CareSphereTheme.shared)
        .environmentObject(MessageService.preview)
}
