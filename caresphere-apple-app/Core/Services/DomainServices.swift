import Combine
import Foundation

// MARK: - Domain Services
//
// This file contains all domain services for the CareSphere application.
// Each service is a @MainActor class following the singleton pattern.
//
// Quick Navigation (⌘+Click on service name or use ⌘+J to jump to MARK):
// • AuthenticationService  - Lines 1-325    | User authentication, login, permissions
// • MemberService          - Lines 326-528  | Member CRUD, notes, activities
// • MessageService         - Lines 529-738  | Messages, templates, sending
// • SenderSettingsService  - Lines 739-941  | Multi-scope sender settings
// • AnalyticsService       - Lines 942-1005 | Dashboard analytics, metrics
// • FieldConfigService     - Lines 1006-end | Dynamic field configurations
//
// Architecture: All services share NetworkClient and follow consistent patterns:
// - Singleton with .shared property
// - @Published state for SwiftUI reactivity
// - Error handling with APIError
// - Preview support for development
//
// Note: This file is intentionally kept as one unit to:
// 1. Share NetworkClient instance efficiently
// 2. Enable cross-service dependencies (e.g., Member → Auth)
// 3. Maintain single source of truth for domain logic
// 4. Simplify imports (one import gets all services)

// MARK: - ════════════════════════════════════════════════════════════
// MARK: - 1️⃣ Authentication Service (Lines 35-325)
// MARK: - ════════════════════════════════════════════════════════════

/// Service for handling user authentication and session management
@MainActor
class AuthenticationService: ObservableObject {
    @MainActor static let shared = AuthenticationService()

    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var error: APIError?

    var isAuthenticated: Bool {
        return currentUser != nil && networkClient.isAuthenticated
    }

    private let networkClient: NetworkClient
    private var cancellables = Set<AnyCancellable>()

    private init() {
        self.networkClient = NetworkClient.shared

        // Check if user is already authenticated
        if networkClient.isAuthenticated {
            Task {
                await loadCurrentUser()
            }
        }
    }

    // MARK: - Authentication Methods

    func login(email: String, password: String, rememberMe: Bool = true) async -> Bool {
        isLoading = true
        error = nil

        do {
            let request = LoginRequest(
                email: email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines),
                password: password,
                rememberMe: rememberMe
            )

            let response: LoginResponse = try await networkClient.request(
                endpoint: Endpoints.Auth.login,
                method: .POST,
                body: request
            )

            // Store authentication tokens
            networkClient.setAuthToken(response.accessToken, refreshToken: response.refreshToken)

            // Set current user
            currentUser = response.user

            isLoading = false
            return true

        } catch let apiError as APIError {
            self.error = apiError
            isLoading = false
            return false
        } catch {
            self.error = .serverError(statusCode: 0, message: error.localizedDescription)
            isLoading = false
            return false
        }
    }

    func register(
        email: String,
        password: String,
        fullName: String,
        verificationCode: String,
        phone: String? = nil
    ) async -> Bool {
        isLoading = true
        error = nil

        do {
            // Split fullName into firstName / lastName for API
            let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
            let nameParts = trimmedName.split(separator: " ", maxSplits: 1)
            let firstName = nameParts.count > 0 ? String(nameParts[0]) : trimmedName
            let lastName = nameParts.count > 1 ? String(nameParts[1]) : ""

            let request = RegisterRequest(
                email: email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines),
                password: password,
                firstName: firstName,
                lastName: lastName,
                code: verificationCode.trimmingCharacters(in: .whitespacesAndNewlines),
                phone: phone
            )

            let response: LoginResponse = try await networkClient.request(
                endpoint: Endpoints.Auth.register,
                method: .POST,
                body: request
            )

            // Store authentication tokens
            networkClient.setAuthToken(response.accessToken, refreshToken: response.refreshToken)

            // Set current user
            currentUser = response.user

            isLoading = false
            return true

        } catch let apiError as APIError {
            self.error = apiError
            isLoading = false
            return false
        } catch {
            self.error = .serverError(statusCode: 0, message: error.localizedDescription)
            isLoading = false
            return false
        }
    }

    func registerWithOrganization(
        email: String,
        password: String,
        fullName: String,
        displayName: String? = nil,
        action: OrganizationOption,
        organizationName: String? = nil,
        organizationCode: String? = nil,
        verificationCode: String
    ) async -> Bool {
        isLoading = true
        error = nil

        do {
            // Split fullName into firstName / lastName for API
            let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
            let nameParts = trimmedName.split(separator: " ", maxSplits: 1)
            let firstName = nameParts.count > 0 ? String(nameParts[0]) : trimmedName
            let lastName = nameParts.count > 1 ? String(nameParts[1]) : nil

            // Map .skip to "create" without an org (backend requires create or join)
            let orgAction: String
            switch action {
            case .create:
                orgAction = "create"
            case .join:
                orgAction = "join"
            case .skip:
                orgAction = "create"
            }

            let request = RegisterWithOrganizationRequest(
                email: email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines),
                password: password,
                firstName: firstName,
                lastName: lastName ?? "",
                code: verificationCode.trimmingCharacters(in: .whitespacesAndNewlines),
                phone: nil,
                organizationAction: orgAction,
                organizationName: action == .skip
                    ? nil : organizationName?.trimmingCharacters(in: .whitespacesAndNewlines),
                organizationCode: organizationCode?.trimmingCharacters(in: .whitespacesAndNewlines)
            )

            let response: LoginResponse = try await networkClient.request(
                endpoint: Endpoints.Auth.registerWithOrganization,
                method: .POST,
                body: request
            )

            // Store authentication tokens
            networkClient.setAuthToken(response.accessToken, refreshToken: response.refreshToken)

            // Set current user
            currentUser = response.user

            isLoading = false
            return true

        } catch let apiError as APIError {
            self.error = apiError
            isLoading = false
            return false
        } catch {
            self.error = .serverError(statusCode: 0, message: error.localizedDescription)
            isLoading = false
            return false
        }
    }

    func sendVerificationCode(email: String) async -> Bool {
        isLoading = true
        error = nil

        do {
            // Validate email format
            let trimmedEmail = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmedEmail.contains("@"), trimmedEmail.contains(".") else {
                self.error = .serverError(
                    statusCode: 400, message: "Please enter a valid email address")
                isLoading = false
                return false
            }

            let request = SendVerificationCodeRequest(
                email: trimmedEmail
            )

            print("[AUTH] Sending verification code to: \(trimmedEmail)")
            let _: MessageResponse = try await networkClient.request(
                endpoint: Endpoints.Auth.sendVerificationCode,
                method: .POST,
                body: request
            )
            print("[AUTH] ✅ Verification code sent successfully")

            isLoading = false
            return true

        } catch let apiError as APIError {
            print(
                "[AUTH] ❌ Verification code error: \(apiError.errorDescription ?? "Unknown error")")
            self.error = apiError
            isLoading = false
            return false
        } catch {
            print("[AUTH] ❌ Unexpected error: \(error.localizedDescription)")
            self.error = .serverError(statusCode: 0, message: error.localizedDescription)
            isLoading = false
            return false
        }
    }

    func logout() async {
        isLoading = true
        defer { isLoading = false }

        // Call logout endpoint (fire and forget)
        do {
            let _: EmptyResponse = try await networkClient.request<EmptyResponse>(
                endpoint: Endpoints.Auth.logout,
                method: .POST
            )
        } catch {
            // We can log this error but don't block logout flow
            #if DEBUG
                print("Logout request failed: \(error)")
            #endif
        }

        // Clear local state
        networkClient.clearAuthTokens()
        currentUser = nil
    }

    func refreshToken() async throws {
        // This would be called automatically by NetworkClient
        // when a 401 response is received
    }

    func checkAuthenticationState() async {
        // Check if we have stored tokens and validate them
        await loadCurrentUser()
    }

    func loadCurrentUser() async {
        guard networkClient.isAuthenticated else {
            currentUser = nil
            return
        }

        do {
            let user: User = try await networkClient.request<User>(endpoint: Endpoints.Auth.profile)
            currentUser = user
        } catch let apiError as APIError {
            // Only clear auth when tokens are invalid
            switch apiError {
            case .unauthorized, .forbidden:
                networkClient.clearAuthTokens()
                currentUser = nil
            default:
                self.error = apiError
            }
        } catch {
            self.error = .unknown(error)
        }
    }

    // MARK: - Password Management

    func changePassword(currentPassword: String, newPassword: String) async -> Bool {
        isLoading = true
        error = nil

        do {
            let request = ChangePasswordRequest(
                currentPassword: currentPassword,
                newPassword: newPassword
            )

            let _: MessageResponse = try await networkClient.request(
                endpoint: Endpoints.Auth.changePassword,
                method: .PATCH,
                body: request
            )

            isLoading = false
            return true

        } catch let apiError as APIError {
            self.error = apiError
            isLoading = false
            return false
        } catch {
            self.error = .serverError(statusCode: 0, message: error.localizedDescription)
            isLoading = false
            return false
        }
    }

    func forgotPassword(email: String) async -> (success: Bool, message: String?) {
        isLoading = true
        error = nil

        do {
            let request = ForgotPasswordRequest(
                email: email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines))

            let response: MessageResponse = try await networkClient.request(
                endpoint: Endpoints.Auth.forgotPassword,
                method: .POST,
                body: request
            )

            isLoading = false
            return (true, response.message)

        } catch let apiError as APIError {
            self.error = apiError
            isLoading = false
            return (false, apiError.errorDescription)
        } catch {
            self.error = .serverError(statusCode: 0, message: error.localizedDescription)
            isLoading = false
            return (false, error.localizedDescription)
        }
    }

    func resetPassword(email: String, token: String, newPassword: String) async -> Bool {
        isLoading = true
        error = nil

        do {
            let request = ResetPasswordRequest(
                email: email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines),
                token: token,
                newPassword: newPassword
            )

            let _: MessageResponse = try await networkClient.request(
                endpoint: Endpoints.Auth.resetPassword,
                method: .POST,
                body: request
            )

            isLoading = false
            return true

        } catch let apiError as APIError {
            self.error = apiError
            isLoading = false
            return false
        } catch {
            self.error = .serverError(statusCode: 0, message: error.localizedDescription)
            isLoading = false
            return false
        }
    }

    func verifyEmail(email: String, token: String) async -> Bool {
        isLoading = true
        error = nil

        do {
            let request = VerifyEmailRequest(
                email: email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines),
                token: token
            )

            let _: MessageResponse = try await networkClient.request(
                endpoint: Endpoints.Auth.verifyEmail,
                method: .POST,
                body: request
            )

            // Reload user to get updated email_verified status
            await loadCurrentUser()

            isLoading = false
            return true

        } catch let apiError as APIError {
            self.error = apiError
            isLoading = false
            return false
        } catch {
            self.error = .serverError(statusCode: 0, message: error.localizedDescription)
            isLoading = false
            return false
        }
    }

    // MARK: - Permission Checking

    func hasPermission(_ permission: KeyPath<UserPermissions, Bool>) -> Bool {
        guard let user = currentUser else { return false }
        return user.role.permissions[keyPath: permission]
    }

    func requiresPermission(_ permission: KeyPath<UserPermissions, Bool>) throws {
        guard hasPermission(permission) else {
            throw APIError.forbidden
        }
    }

    /// Check if current user can manage settings at scope
    func canManageSettingsScope(_ scope: SettingScope) -> Bool {
        return SenderSettingsService.shared.canManageScope(scope, user: currentUser)
    }

    // MARK: - Helper Methods

    // MARK: - Preview Extension

    static let preview: AuthenticationService = {
        let service = AuthenticationService.shared
        Task { @MainActor in
            service.currentUser = User.preview
        }
        return service
    }()
}

// MARK: - ════════════════════════════════════════════════════════════
// MARK: - 2️⃣ Member Service (Lines 326-528)
// MARK: - ════════════════════════════════════════════════════════════

/// Service for member management operations
@MainActor
class MemberService: ObservableObject {
    @MainActor static let shared = MemberService()

    @Published var members: [Member] = []
    @Published var selectedMember: Member?
    @Published var isLoading = false
    @Published var error: APIError?

    private let networkClient: NetworkClient
    private var authService: AuthenticationService {
        return AuthenticationService.shared
    }

    private init() {
        self.networkClient = NetworkClient.shared
    }

    // MARK: - Member CRUD Operations

    func loadMembers(searchCriteria: MemberSearchCriteria? = nil) async throws {
        try authService.requiresPermission(\.manageMembers)

        isLoading = true
        error = nil
        defer { isLoading = false }

        let response: MemberListResponse

        if let criteria = searchCriteria {
            response =
                try await networkClient.request(
                    endpoint: Endpoints.Members.search,
                    method: .POST,
                    body: criteria
                ) as MemberListResponse
        } else {
            response =
                try await networkClient.request<MemberListResponse>(
                    endpoint: Endpoints.Members.list)
        }

        members = response.members
    }

    func searchMembers(query: String) async throws {
        let criteria = MemberSearchCriteria(
            query: query,
            status: nil,
            tags: nil,
            ageRange: nil,
            lastContactRange: nil,
            joinDateRange: nil,
            hasEmail: nil,
            hasPhone: nil,
            householdId: nil,
            sortBy: .firstName,
            sortOrder: .ascending,
            page: 1,
            pageSize: 50
        )
        try await loadMembers(searchCriteria: criteria)
    }

    func getMember(id: String) async throws -> Member {
        try authService.requiresPermission(\.manageMembers)

        let member: Member = try await networkClient.request<Member>(
            endpoint: Endpoints.Members.get(id: id)
        )

        selectedMember = member
        return member
    }

    func createMember(_ request: CreateMemberRequest) async throws -> Member {
        try authService.requiresPermission(\.manageMembers)

        let member: Member = try await networkClient.request<Member>(
            endpoint: Endpoints.Members.create,
            method: .POST,
            body: request
        )

        // Add to local list if loaded
        if !members.isEmpty {
            members.append(member)
        }

        return member
    }

    func updateMember(id: String, request: UpdateMemberRequest) async throws -> Member {
        try authService.requiresPermission(\.manageMembers)

        let member: Member = try await networkClient.request<Member>(
            endpoint: Endpoints.Members.update(id: id),
            method: .PUT,
            body: request
        )

        // Update local list
        if let index = members.firstIndex(where: { $0.id == id }) {
            members[index] = member
        }

        if selectedMember?.id == id {
            selectedMember = member
        }

        return member
    }

    func deleteMember(id: String) async throws {
        try authService.requiresPermission(\.manageMembers)

        let _: EmptyResponse =
            try await networkClient.request<EmptyResponse>(
                endpoint: Endpoints.Members.delete(id: id),
                method: .DELETE
            )

        // Remove from local list
        members.removeAll { $0.id == id }

        if selectedMember?.id == id {
            selectedMember = nil
        }
    }

    /// Import members from CSV file
    func importMembersFromCSV(csvContent: String) async throws -> BulkImportResult {
        try authService.requiresPermission(\.manageMembers)

        struct ImportRequest: Codable {
            let csvContent: String
        }

        let request = ImportRequest(csvContent: csvContent)

        let result: BulkImportResult = try await networkClient.request<BulkImportResult>(
            endpoint: Endpoints.Bulk.importMembers,
            method: .POST,
            body: request
        )

        // Reload members after successful import
        if result.successCount > 0 {
            try? await loadMembers()
        }

        return result
    }

    // MARK: - Member Notes and Activities

    func loadMemberNotes(memberId: String) async throws -> [MemberNote] {
        try authService.requiresPermission(\.manageMembers)

        return try await networkClient.request<[MemberNote]>(
            endpoint: Endpoints.Members.notes(memberId: memberId)
        )
    }

    func addMemberNote(
        memberId: String, content: String, category: NoteCategory, isPrivate: Bool = false
    ) async throws -> MemberNote {
        try authService.requiresPermission(\.manageMembers)

        let request = CreateMemberNoteRequest(
            content: content,
            category: category,
            isPrivate: isPrivate
        )

        return try await networkClient.request<MemberNote>(
            endpoint: Endpoints.Members.notes(memberId: memberId),
            method: .POST,
            body: request
        )
    }

    func loadMemberActivities(memberId: String) async throws -> [MemberActivity] {
        try authService.requiresPermission(\.manageMembers)

        return try await networkClient.request<[MemberActivity]>(
            endpoint: Endpoints.Members.activities(memberId: memberId)
        )
    }

    // MARK: - Convenience Methods

    func updateMemberStatus(id: String, status: MemberStatus) async throws {
        let request = UpdateMemberRequest(
            firstName: nil,
            lastName: nil,
            email: nil,
            phone: nil,
            whatsappNumber: nil,
            wechatId: nil,
            dateOfBirth: nil,
            gender: nil,
            address: nil,
            city: nil,
            state: nil,
            zipCode: nil,
            country: nil,
            memberStatus: status,
            membershipType: nil,
            joinDate: nil,
            photoUrl: nil,
            notes: nil,
            tags: nil,
            customFields: nil
        )

        _ = try await updateMember(id: id, request: request)
    }

    // MARK: - Preview Extension

    static let preview: MemberService = {
        let service = MemberService.shared
        Task { @MainActor in
            service.members = [Member.preview]
            service.selectedMember = Member.preview
        }
        return service
    }()
}

// MARK: - ════════════════════════════════════════════════════════════
// MARK: - 3️⃣ Message Service (Lines 529-738)
// MARK: - ════════════════════════════════════════════════════════════

/// Service for message management and communication
@MainActor
class MessageService: ObservableObject {
    @MainActor static let shared = MessageService()

    @Published var messages: [Message] = []
    @Published var templates: [MessageTemplate] = []
    @Published var isLoading = false
    @Published var error: APIError?

    private let networkClient: NetworkClient
    private var authService: AuthenticationService {
        return AuthenticationService.shared
    }

    private init() {
        self.networkClient = NetworkClient.shared
    }

    // MARK: - Message Operations

    func loadMessages(searchCriteria: MessageSearchCriteria? = nil) async throws {
        try authService.requiresPermission(\.sendMessages)

        isLoading = true
        error = nil
        defer { isLoading = false }

        let response: MessageListResponse

        if let criteria = searchCriteria {
            // Implementation would use search endpoint
            response =
                try await networkClient.request<MessageListResponse>(
                    endpoint: Endpoints.Messages.list)
        } else {
            response =
                try await networkClient.request<MessageListResponse>(
                    endpoint: Endpoints.Messages.list)
        }

        messages = response.messages
    }

    func createMessage(_ request: CreateMessageRequest) async throws -> Message {
        try authService.requiresPermission(\.sendMessages)

        // Note: Backend uses /messages/send for direct sending
        // This method now sends the message immediately
        let message: Message = try await networkClient.request<Message>(
            endpoint: Endpoints.Messages.send,
            method: .POST,
            body: request
        )

        // Add to local list
        if !messages.isEmpty {
            messages.insert(message, at: 0)
        }

        return message
    }

    func sendMessage(id: String) async throws -> Message {
        // Note: Backend doesn't have a separate send endpoint
        // Messages are sent when created via /messages/send
        // This method fetches the message details for backward compatibility
        try authService.requiresPermission(\.sendMessages)

        let message: Message =
            try await networkClient.request<Message>(
                endpoint: Endpoints.Messages.get(id: id),
                method: .GET
            )

        // Update local list
        if let index = messages.firstIndex(where: { $0.id == id }) {
            messages[index] = message
        }

        return message
    }

    // MARK: - Template Operations

    func loadTemplates() async throws {
        // All authenticated users can browse templates (read-only)
        templates =
            try await networkClient.request<[MessageTemplate]>(endpoint: Endpoints.Templates.list)
    }

    func createTemplate(_ request: CreateTemplateRequest) async throws -> MessageTemplate {
        try authService.requiresPermission(\.manageTemplates)

        let template: MessageTemplate =
            try await networkClient.request<MessageTemplate>(
                endpoint: Endpoints.Templates.create,
                method: .POST,
                body: request
            )

        templates.append(template)
        return template
    }

    // MARK: - Convenience Methods

    func createAndSendMessage(
        to members: [Member],
        subject: String?,
        content: String,
        channel: MessageChannel,
        templateId: String? = nil
    ) async throws -> Message {

        let request = CreateMessageRequest(
            title: subject ?? "Message",
            content: content,
            messageType: channel,
            scheduledFor: nil,
            senderName: nil,
            senderEmail: nil,
            senderPhone: nil,
            senderWhatsapp: nil,
            channelLabel: nil,
            templateId: templateId,
            senderProfileId: nil,
            recipientMemberIds: members.map { $0.id },
            recipientGroup: nil
        )

        let message = try await createMessage(request)
        return message
    }

    // MARK: - Preview Extension

    static let preview: MessageService = {
        let service = MessageService.shared
        Task { @MainActor in
            service.messages = [Message.preview]
            service.templates = [MessageTemplate.preview]
        }
        return service
    }()
}

// MARK: - Supporting Models

struct EmptyResponse: Codable {
    // Used for endpoints that don't return data
}

struct CreateMemberNoteRequest: Codable {
    let content: String
    let category: NoteCategory
    let isPrivate: Bool
}

struct CreateTemplateRequest: Codable {
    let name: String
    let description: String?
    let category: TemplateCategory
    let subject: String?
    let content: String
    let placeholders: [TemplatePlaceholder]
    let supportedChannels: [MessageChannel]
}

// MARK: - Sender Settings Request Types

struct SenderSettingRequest: Codable {
    let name: String?
    let email: String?
    let phone: String?
}

// MARK: - ════════════════════════════════════════════════════════════
// MARK: - 4️⃣ Sender Settings Service (Lines 739-941)
// MARK: - ════════════════════════════════════════════════════════════

/// Service for managing sender settings with multi-scope support
@MainActor
class SenderSettingsService: ObservableObject {
    @MainActor static let shared = SenderSettingsService()

    private let networkClient = NetworkClient.shared

    @Published var resolvedSettings: ResolvedSenderSettings?
    @Published var userSettings: SenderSetting?
    @Published var organizationSettings: SenderSetting?
    @Published var globalSettings: SenderSetting?
    @Published var isLoading = false
    @Published var error: APIError?

    private var cancellables = Set<AnyCancellable>()

    private init() {
        // Load settings if already authenticated
        if networkClient.isAuthenticated {
            Task {
                await loadResolvedSettings()
            }
        }
    }

    // MARK: - Public Methods

    /// Load the effective sender settings for the current user
    func loadResolvedSettings() async {
        guard networkClient.isAuthenticated else { return }

        isLoading = true
        error = nil

        do {
            let settings: ResolvedSenderSettings = try await networkClient.request(
                endpoint: Endpoints.Settings.senderResolved,
                method: .GET
            )

            resolvedSettings = settings
        } catch {
            self.error = error as? APIError ?? .unknown(error)
            print("Failed to load resolved sender settings: \(error)")
        }

        isLoading = false
    }

    /// Load sender settings for a specific scope
    func loadSettings(for scope: SettingScope, referenceId: String? = nil) async -> SenderSetting? {
        guard networkClient.isAuthenticated else { return nil }

        do {
            let settings: [SenderSetting] = try await networkClient.request(
                endpoint: Endpoints.Settings.senderList(
                    scope: scope.rawValue,
                    referenceId: referenceId
                ),
                method: .GET
            )

            return settings.first
        } catch {
            self.error = error as? APIError ?? .unknown(error)
            print("Failed to load \(scope) sender settings: \(error)")
            return nil
        }
    }

    /// Load all available sender settings for the current user
    func loadAllUserSettings() async {
        guard networkClient.isAuthenticated else { return }

        isLoading = true

        // Load user-specific settings
        userSettings = await loadSettings(for: .user)

        // Load organization settings (if user has access)
        organizationSettings = await loadSettings(for: .organization)

        // Load global settings (if user has access)
        globalSettings = await loadSettings(for: .global)

        isLoading = false
    }

    /// Create or update sender settings
    func saveSenderSettings(
        scope: SettingScope,
        name: String?,
        email: String?,
        phone: String?,
        referenceId: String? = nil
    ) async -> Bool {
        guard networkClient.isAuthenticated else { return false }

        isLoading = true
        error = nil

        do {
            let request = SenderSettingRequest(
                name: name?.isEmpty == true ? nil : name,
                email: email?.isEmpty == true ? nil : email,
                phone: phone?.isEmpty == true ? nil : phone
            )

            let _: SenderSetting = try await networkClient.request(
                endpoint: Endpoints.Settings.senderUpdate(
                    scope: scope.rawValue,
                    referenceId: referenceId
                ),
                method: .PUT,
                body: request
            )

            // Refresh resolved settings and specific scope settings
            await loadResolvedSettings()
            await loadAllUserSettings()

            isLoading = false
            return true

        } catch {
            self.error = error as? APIError ?? .unknown(error)
            print("Failed to save sender settings: \(error)")
            isLoading = false
            return false
        }
    }

    /// Delete sender settings for a specific scope
    func deleteSenderSettings(
        scope: SettingScope,
        referenceId: String? = nil
    ) async -> Bool {
        guard networkClient.isAuthenticated else { return false }

        isLoading = true
        error = nil

        do {
            let _: EmptyResponse = try await networkClient.request(
                endpoint: Endpoints.Settings.senderDelete(
                    scope: scope.rawValue,
                    referenceId: referenceId
                ),
                method: .DELETE
            )

            // Refresh settings
            await loadResolvedSettings()
            await loadAllUserSettings()

            isLoading = false
            return true

        } catch {
            self.error = error as? APIError ?? .unknown(error)
            print("Failed to delete sender settings: \(error)")
            isLoading = false
            return false
        }
    }

    /// Check if user has permission to manage settings at a specific scope
    func canManageScope(_ scope: SettingScope, user: User?) -> Bool {
        guard let user = user else { return false }

        switch scope {
        case .global:
            return user.role == .superAdmin
        case .organization:
            return user.role == .superAdmin || user.role == .admin
        case .user:
            return true  // Users can always manage their own settings
        }
    }

    /// Clear all cached settings
    func clearCache() {
        resolvedSettings = nil
        userSettings = nil
        organizationSettings = nil
        globalSettings = nil
        error = nil
    }

    // MARK: - Preview Extension

    static let preview: SenderSettingsService = {
        let service = SenderSettingsService.shared
        Task { @MainActor in
            service.resolvedSettings = ResolvedSenderSettings.preview
            service.userSettings = SenderSetting.preview
        }
        return service
    }()
}

// MARK: - ════════════════════════════════════════════════════════════
// MARK: - 5️⃣ Analytics Service (Lines 942-1005)
// MARK: - ════════════════════════════════════════════════════════════

/// Service for fetching analytics and dashboard metrics
@MainActor
class AnalyticsService: ObservableObject {
    @MainActor static let shared = AnalyticsService()

    @Published var dashboardAnalytics: DashboardAnalytics?
    @Published var isLoading = false
    @Published var error: APIError?

    private let networkClient: NetworkClient

    private init() {
        self.networkClient = NetworkClient.shared
    }

    // MARK: - Dashboard Analytics

    /// Fetch dashboard analytics and metrics
    func loadDashboardAnalytics() async -> Bool {
        isLoading = true
        error = nil

        do {
            let response: DashboardAnalytics = try await networkClient.request(
                endpoint: Endpoints.Analytics.dashboard,
                method: .GET
            )

            self.dashboardAnalytics = response
            isLoading = false
            return true

        } catch {
            self.error = error as? APIError ?? .unknown(error)
            print("Failed to load dashboard analytics: \(error)")
            isLoading = false
            return false
        }
    }

    /// Refresh dashboard analytics
    func refreshDashboard() async {
        await loadDashboardAnalytics()
    }

    /// Clear cached analytics
    func clearCache() {
        dashboardAnalytics = nil
        error = nil
    }

    // MARK: - Preview Extension

    static let preview: AnalyticsService = {
        let service = AnalyticsService.shared
        Task { @MainActor in
            service.dashboardAnalytics = DashboardAnalytics.preview
        }
        return service
    }()
}

// MARK: - ════════════════════════════════════════════════════════════
// MARK: - 6️⃣ Field Configuration Service (Lines 1006-end)
// MARK: - ════════════════════════════════════════════════════════════

/// Service for managing field configurations and values
@MainActor
class FieldConfigService: ObservableObject {
    @MainActor static let shared = FieldConfigService()

    @Published var memberConfigs: [FieldConfig] = []
    @Published var isLoading = false
    @Published var error: APIError?

    private let networkClient: NetworkClient
    private var authService: AuthenticationService {
        return AuthenticationService.shared
    }

    private init() {
        self.networkClient = NetworkClient.shared
    }

    // MARK: - Field Configuration Operations

    /// Load field configurations for a specific entity type
    func loadConfigs(for entityType: EntityType) async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }

        let response: FieldConfigsResponse = try await networkClient.request(
            endpoint: Endpoints.Fields.configs(entityType: entityType.rawValue),
            method: .GET
        )

        switch entityType {
        case .member:
            memberConfigs = response.configs
        default:
            break
        }
    }

    /// Get field configurations and values for a specific entity instance
    func getEntityFields(entityType: EntityType, entityId: String) async throws
        -> EntityFieldsResponse
    {
        isLoading = true
        error = nil
        defer { isLoading = false }

        return try await networkClient.request(
            endpoint: Endpoints.Fields.entityFields(
                entityType: entityType.rawValue, entityId: entityId),
            method: .GET
        )
    }

    /// Save field values for an entity
    func saveEntityFields(entityType: EntityType, entityId: String, values: [String: Any])
        async throws
    {
        isLoading = true
        error = nil
        defer { isLoading = false }

        let request = BulkFieldValuesUpdate(
            entityType: entityType,
            entityId: entityId,
            values: values.mapValues { AnyCodable($0) }
        )

        let _: EntityFieldsResponse = try await networkClient.request(
            endpoint: Endpoints.Fields.saveValues,
            method: .POST,
            body: request
        )
    }

    /// Initialize default member field configurations
    func initializeDefaultMemberFields() async throws {
        try authService.requiresPermission(\.manageSettings)

        isLoading = true
        error = nil
        defer { isLoading = false }

        let _: MessageResponse = try await networkClient.request(
            endpoint: Endpoints.Fields.initializeMembers,
            method: .POST
        )

        // Reload member configs after initialization
        try await loadConfigs(for: .member)
    }

    /// Create a new field configuration
    func createConfig(_ config: FieldConfigCreate) async throws -> FieldConfig {
        try authService.requiresPermission(\.manageSettings)

        isLoading = true
        error = nil
        defer { isLoading = false }

        return try await networkClient.request(
            endpoint: Endpoints.Fields.createConfig,
            method: .POST,
            body: config
        )
    }

    /// Update a field configuration
    func updateConfig(id: String, update: FieldConfigUpdate) async throws -> FieldConfig {
        try authService.requiresPermission(\.manageSettings)

        isLoading = true
        error = nil
        defer { isLoading = false }

        return try await networkClient.request(
            endpoint: Endpoints.Fields.updateConfig(id: id),
            method: .PUT,
            body: update
        )
    }

    /// Delete a field configuration
    func deleteConfig(id: String) async throws {
        try authService.requiresPermission(\.manageSettings)

        isLoading = true
        error = nil
        defer { isLoading = false }

        let _: MessageResponse = try await networkClient.request(
            endpoint: Endpoints.Fields.deleteConfig(id: id),
            method: .DELETE
        )
    }

    // MARK: - Convenience Methods

    /// Get grouped field configurations for easier UI rendering
    func getGroupedConfigs(for entityType: EntityType) -> [GroupedFieldConfigs] {
        switch entityType {
        case .member:
            return memberConfigs.grouped()
        default:
            return []
        }
    }

    /// Clear cached configurations
    func clearCache() {
        memberConfigs = []
        error = nil
    }

    // MARK: - Preview Extension

    static let preview: FieldConfigService = {
        let service = FieldConfigService.shared
        Task { @MainActor in
            // Add preview data if needed
        }
        return service
    }()
}

// MARK: - ════════════════════════════════════════════════════════════
// MARK: - 7️⃣ Organization Service
// MARK: - ════════════════════════════════════════════════════════════

/// Service for managing organization membership and codes
@MainActor
class OrganizationService: ObservableObject {
    @MainActor static let shared = OrganizationService()

    @Published var currentOrganization: Organization?
    @Published var allOrganizations: [OrganizationWithMembership] = []
    @Published var isLoading = false
    @Published var error: APIError?

    private let networkClient: NetworkClient
    private let authService: AuthenticationService

    private init() {
        self.networkClient = NetworkClient.shared
        self.authService = AuthenticationService.shared
    }

    // MARK: - Organization Operations

    /// Get the current user's organization
    func loadMyOrganization() async throws -> Organization? {
        guard authService.isAuthenticated else {
            return nil
        }

        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let org: Organization = try await networkClient.request(
                endpoint: Endpoints.Organizations.myOrganization
            )
            currentOrganization = org
            return org
        } catch let apiError as APIError {
            // Handle not found (user may not be in an organization yet)
            if case .serverError(let code, _) = apiError, code == 404 {
                currentOrganization = nil
                return nil
            }
            self.error = apiError
            throw apiError
        } catch {
            let apiError = APIError.unknown(error)
            self.error = apiError
            throw apiError
        }
    }

    /// Create a new organization
    func createOrganization(name: String, description: String? = nil) async throws -> Organization {
        try authService.requiresPermission(\.manageOrganization)

        isLoading = true
        error = nil
        defer { isLoading = false }

        let request = CreateOrganizationRequest(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description?.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        do {
            let org: Organization = try await networkClient.request(
                endpoint: Endpoints.Organizations.create,
                method: .POST,
                body: request
            )
            currentOrganization = org
            return org
        } catch let apiError as APIError {
            self.error = apiError
            throw apiError
        } catch {
            let apiError = APIError.unknown(error)
            self.error = apiError
            throw apiError
        }
    }

    /// Join an organization using a 7-character alphanumeric code
    func joinOrganization(code: String) async throws -> Organization {
        isLoading = true
        error = nil
        defer { isLoading = false }

        let request = JoinOrganizationRequest(
            code: code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        )

        do {
            let org: Organization = try await networkClient.request(
                endpoint: Endpoints.Organizations.join,
                method: .POST,
                body: request
            )
            currentOrganization = org
            return org
        } catch let apiError as APIError {
            self.error = apiError
            throw apiError
        } catch {
            let apiError = APIError.unknown(error)
            self.error = apiError
            throw apiError
        }
    }

    /// Regenerate organization code (admin only)
    func regenerateCode(reason: String? = nil) async throws -> Organization {
        try authService.requiresPermission(\.manageOrganization)

        isLoading = true
        error = nil
        defer { isLoading = false }

        struct RegenerateRequest: Codable {
            let reason: String?
        }

        let request = RegenerateRequest(reason: reason)

        do {
            let org: Organization = try await networkClient.request(
                endpoint: Endpoints.Organizations.regenerateCode,
                method: .POST,
                body: request
            )
            currentOrganization = org
            return org
        } catch let apiError as APIError {
            self.error = apiError
            throw apiError
        } catch {
            let apiError = APIError.unknown(error)
            self.error = apiError
            throw apiError
        }
    }

    /// Load all organizations the user belongs to
    func loadAllOrganizations() async throws -> [OrganizationWithMembership] {
        guard authService.isAuthenticated else { return [] }

        do {
            let orgs: [OrganizationWithMembership] = try await networkClient.request(
                endpoint: Endpoints.Organizations.allOrganizations
            )
            allOrganizations = orgs
            return orgs
        } catch let apiError as APIError {
            self.error = apiError
            throw apiError
        } catch {
            let apiError = APIError.unknown(error)
            self.error = apiError
            throw apiError
        }
    }

    /// Switch the active organization
    func switchOrganization(to organizationId: String) async throws -> Organization {
        isLoading = true
        error = nil
        defer { isLoading = false }

        struct SwitchRequest: Codable { let organizationId: String }

        do {
            let org: Organization = try await networkClient.request(
                endpoint: Endpoints.Organizations.switchOrg,
                method: .POST,
                body: SwitchRequest(organizationId: organizationId)
            )
            currentOrganization = org
            // Refresh the full list so active state updates
            try? await loadAllOrganizations()
            return org
        } catch let apiError as APIError {
            self.error = apiError
            throw apiError
        } catch {
            let apiError = APIError.unknown(error)
            self.error = apiError
            throw apiError
        }
    }

    // MARK: - Validation

    /// Validate organization code format (7-character alphanumeric)
    func isValidCode(_ code: String) -> Bool {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        return trimmed.count == 7 && trimmed.allSatisfy { $0.isLetter || $0.isNumber }
    }

    // MARK: - Preview Extension

    static let preview: OrganizationService = {
        let service = OrganizationService.shared
        return service
    }()
}

// MARK: - ════════════════════════════════════════════════════════════
// MARK: - 8️⃣ Birthday Service
// MARK: - ════════════════════════════════════════════════════════════

@MainActor
class BirthdayService: ObservableObject {

    static let shared = BirthdayService()
    private init() {}

    // MARK: - Dependencies
    private let networkClient = NetworkClient.shared
    private let authService = AuthenticationService.shared

    // MARK: - Published State
    @Published var upcomingBirthdays: UpcomingBirthdaysResponse?
    @Published var isLoading = false
    @Published var lastFetchedAt: Date?

    // MARK: - Load

    /// Fetch members with birthdays in the next `days` days (default 30).
    /// Lightweight — any authenticated user can call this.
    func loadUpcomingBirthdays(days: Int = 30) async throws {
        isLoading = true
        defer { isLoading = false }

        let response: UpcomingBirthdaysResponse = try await networkClient.request(
            endpoint: Endpoints.Birthdays.upcoming(days: days)
        )
        upcomingBirthdays = response
        lastFetchedAt = Date()
    }

    /// Refresh if data is stale (older than 1 hour) or absent.
    func refreshIfNeeded() async {
        if let last = lastFetchedAt, Date().timeIntervalSince(last) < 3600 { return }
        try? await loadUpcomingBirthdays()
    }

    // MARK: - Generate Birthday Message

    struct BirthdayMessageRequest: Codable {
        let recipientName: String
        let channel: String
        let age: Int?
    }

    /// Generate an org-type-aware birthday message for a member.
    /// Used in the compose flow when selecting "Birthday" template.
    func generateBirthdayMessage(
        for member: BirthdayMember,
        channel: String = "EMAIL"
    ) async throws -> GeneratedBirthdayMessage {
        let body = BirthdayMessageRequest(
            recipientName: member.fullName,
            channel: channel,
            age: member.age
        )
        return try await networkClient.request(
            endpoint: Endpoints.Birthdays.generateMessage,
            method: .POST,
            body: body
        )
    }

    // MARK: - Convenience

    /// All birthdays sorted: today first, then ascending by days.
    var allSorted: [BirthdayMember] { upcomingBirthdays?.allSorted ?? [] }

    /// Birthday members whose day is today.
    var todayBirthdays: [BirthdayMember] { upcomingBirthdays?.today ?? [] }

    /// Birthday members within the next 7 days (excluding today).
    var thisWeek: [BirthdayMember] {
        (upcomingBirthdays?.upcoming ?? []).filter { $0.daysUntil <= 7 }
    }

    /// Count for notification badge.
    var todayCount: Int { todayBirthdays.count }

    /// True if any birthday is today or within 3 days.
    var hasUrgent: Bool {
        allSorted.contains { $0.daysUntil <= 3 }
    }
}
