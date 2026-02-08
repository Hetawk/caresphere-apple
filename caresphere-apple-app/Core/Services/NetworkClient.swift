import Combine
import Foundation

// MARK: - API Configuration

/// Central configuration for API endpoints and settings
struct APIConfiguration {
    let baseURL: URL
    let timeout: TimeInterval
    let retryAttempts: Int
    let retryDelay: TimeInterval

    static let shared: APIConfiguration = {
        // Read API_BASE_URL from environment (.env file)
        let apiURLString =
            Env.string("API_BASE_URL", default: "https://caresphere.ekddigital.com")
            ?? "https://caresphere.ekddigital.com"
        guard let url = URL(string: apiURLString) else {
            fatalError("Invalid API_BASE_URL in environment: \(apiURLString)")
        }

        return APIConfiguration(
            baseURL: url,
            timeout: 30.0,
            retryAttempts: 3,
            retryDelay: 1.0
        )
    }()
}

// MARK: - API Error Handling

/// Comprehensive API error types
enum APIError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case encodingError(Error)
    case networkError(Error)
    case serverError(statusCode: Int, message: String?)
    case unauthorized
    case forbidden
    case notFound
    case rateLimited
    case timeout
    case noInternetConnection
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serverError(let statusCode, let message):
            return message ?? "Server error (\(statusCode))"
        case .unauthorized:
            return "Unauthorized access"
        case .forbidden:
            return "Access forbidden"
        case .notFound:
            return "Resource not found"
        case .rateLimited:
            return "Too many requests. Please try again later."
        case .timeout:
            return "Request timed out"
        case .noInternetConnection:
            return "No internet connection"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }

    var isRetryable: Bool {
        switch self {
        case .networkError, .timeout:
            return true
        case .serverError(let statusCode, _):
            return statusCode >= 500
        case .noInternetConnection, .rateLimited:
            return true
        default:
            return false
        }
    }
}

// MARK: - HTTP Method

enum HTTPMethod: String, CaseIterable {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case PATCH = "PATCH"
    case DELETE = "DELETE"
}

// MARK: - Request/Response Models

/// Generic API response wrapper
struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let error: APIErrorResponse?
    let metadata: ResponseMetadata?
}

struct APIErrorResponse: Codable {
    let code: String
    let message: String
    let details: [String: String]?
}

struct ResponseMetadata: Codable {
    let timestamp: Date?
    let requestId: String?
    let version: String?
    let pagination: PaginationInfo?
}

// MARK: - Network Client

/// Central networking service with authentication and error handling
@MainActor
class NetworkClient: ObservableObject {
    static let shared = NetworkClient()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private var authToken: String?
    private var refreshToken: String?

    @Published var isOnline = true
    @Published var isLoading = false

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = APIConfiguration.shared.timeout
        config.timeoutIntervalForResource = APIConfiguration.shared.timeout * 2

        self.session = URLSession(configuration: config)

        // Configure JSON decoder with date formatting
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601

        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601

        // Load stored authentication tokens
        loadAuthTokens()

        // Monitor network connectivity
        startNetworkMonitoring()
    }

    // MARK: - Authentication

    func setAuthToken(_ token: String, refreshToken: String? = nil) {
        self.authToken = token
        self.refreshToken = refreshToken
        saveAuthTokens()
    }

    func clearAuthTokens() {
        self.authToken = nil
        self.refreshToken = nil
        clearStoredTokens()
    }

    var isAuthenticated: Bool {
        return authToken != nil
    }

    private func loadAuthTokens() {
        self.authToken = KeychainHelper.load(service: "CareSphereAuth", account: "accessToken")
        self.refreshToken = KeychainHelper.load(service: "CareSphereAuth", account: "refreshToken")
    }

    private func saveAuthTokens() {
        if let authToken = authToken {
            KeychainHelper.save(service: "CareSphereAuth", account: "accessToken", data: authToken)
        }
        if let refreshToken = refreshToken {
            KeychainHelper.save(
                service: "CareSphereAuth", account: "refreshToken", data: refreshToken)
        }
    }

    private func clearStoredTokens() {
        KeychainHelper.delete(service: "CareSphereAuth", account: "accessToken")
        KeychainHelper.delete(service: "CareSphereAuth", account: "refreshToken")
    }

    // MARK: - Network Requests

    // Request without body
    func request<T: Codable>(
        endpoint: APIEndpoint,
        method: HTTPMethod = .GET,
        headers: [String: String] = [:]
    ) async throws -> T {
        return try await requestWithBody(
            endpoint: endpoint, method: method, body: EmptyBody?.none, headers: headers)
    }

    // Request with body
    func request<T: Codable, Body: Codable>(
        endpoint: APIEndpoint,
        method: HTTPMethod,
        body: Body,
        headers: [String: String] = [:]
    ) async throws -> T {
        return try await requestWithBody(
            endpoint: endpoint, method: method, body: body, headers: headers)
    }

    private struct EmptyBody: Codable {}

    private func requestWithBody<T: Codable, Body: Codable>(
        endpoint: APIEndpoint,
        method: HTTPMethod,
        body: Body?,
        headers: [String: String]
    ) async throws -> T {

        guard isOnline else {
            throw APIError.noInternetConnection
        }

        let url = APIConfiguration.shared.baseURL.appendingPathComponent(endpoint.path)
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        // Set default headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Add authentication header
        if let authToken = authToken {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }

        // Add custom headers
        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        // Encode request body
        if let body = body {
            do {
                request.httpBody = try encoder.encode(body)
            } catch {
                throw APIError.encodingError(error)
            }
        }

        // Perform request with retry logic
        return try await performRequestWithRetry(request: request)
    }

    private func performRequestWithRetry<T: Codable>(
        request: URLRequest,
        attempt: Int = 1
    ) async throws -> T {

        isLoading = true
        defer { isLoading = false }

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.unknown(NSError(domain: "Invalid response", code: 0))
            }

            // Handle different HTTP status codes
            switch httpResponse.statusCode {
            case 200...299:
                return try handleSuccessResponse(data: data)
            case 401:
                // Try to refresh token if available
                if refreshToken != nil, attempt == 1 {
                    try await refreshAuthToken()
                    var refreshedRequest = request
                    if let authToken = authToken {
                        refreshedRequest.setValue(
                            "Bearer \(authToken)",
                            forHTTPHeaderField: "Authorization"
                        )
                    }
                    return try await performRequestWithRetry(
                        request: refreshedRequest,
                        attempt: attempt + 1
                    )
                }
                throw APIError.unauthorized
            case 403:
                throw APIError.forbidden
            case 404:
                throw APIError.notFound
            case 429:
                throw APIError.rateLimited
            case 500...599:
                let errorMessage = try? extractErrorMessage(from: data)
                throw APIError.serverError(
                    statusCode: httpResponse.statusCode, message: errorMessage)
            default:
                let errorMessage = try? extractErrorMessage(from: data)
                throw APIError.serverError(
                    statusCode: httpResponse.statusCode, message: errorMessage)
            }

        } catch let error as APIError {
            throw error
        } catch {
            // Check if this is a retryable error and we haven't exceeded retry attempts
            if attempt < APIConfiguration.shared.retryAttempts && isRetryableError(error) {
                try await Task.sleep(
                    nanoseconds: UInt64(APIConfiguration.shared.retryDelay * 1_000_000_000))
                return try await performRequestWithRetry(request: request, attempt: attempt + 1)
            }

            throw mapNetworkError(error)
        }
    }

    private func handleSuccessResponse<T: Codable>(data: Data) throws -> T {
        // If T is Data, return raw data
        if T.self == Data.self {
            return data as! T
        }

        // Try to decode as APIResponse<T> first
        do {
            let apiResponse = try decoder.decode(APIResponse<T>.self, from: data)
            if apiResponse.success, let responseData = apiResponse.data {
                return responseData
            } else if let error = apiResponse.error {
                throw APIError.serverError(statusCode: 400, message: error.message)
            } else {
                throw APIError.noData
            }
        } catch {
            // If that fails, try to decode T directly
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingError(error)
            }
        }
    }

    private func extractErrorMessage(from data: Data) throws -> String? {
        let errorResponse = try decoder.decode(APIErrorResponse.self, from: data)
        return errorResponse.message
    }

    private func isRetryableError(_ error: Error) -> Bool {
        if let apiError = error as? APIError {
            return apiError.isRetryable
        }

        let nsError = error as NSError
        return nsError.domain == NSURLErrorDomain
            && [
                NSURLErrorTimedOut,
                NSURLErrorCannotConnectToHost,
                NSURLErrorNetworkConnectionLost,
                NSURLErrorNotConnectedToInternet,
            ].contains(nsError.code)
    }

    private func mapNetworkError(_ error: Error) -> APIError {
        let nsError = error as NSError

        switch nsError.domain {
        case NSURLErrorDomain:
            switch nsError.code {
            case NSURLErrorTimedOut:
                return .timeout
            case NSURLErrorNotConnectedToInternet,
                NSURLErrorNetworkConnectionLost:
                return .noInternetConnection
            default:
                return .networkError(error)
            }
        default:
            return .unknown(error)
        }
    }

    private func refreshAuthToken() async throws {
        guard let refreshToken = refreshToken else {
            throw APIError.unauthorized
        }

        let url = APIConfiguration.shared.baseURL.appendingPathComponent(
            Endpoints.Auth.refresh.path
        )
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.POST.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = RefreshTokenRequest(refreshToken: refreshToken)
        request.httpBody = try encoder.encode(payload)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown(NSError(domain: "Invalid response", code: 0))
        }

        switch httpResponse.statusCode {
        case 200...299:
            let refreshResponse = try decoder.decode(RefreshTokenResponse.self, from: data)
            let newRefreshToken = refreshResponse.refreshToken ?? refreshToken
            setAuthToken(refreshResponse.accessToken, refreshToken: newRefreshToken)
        case 401:
            throw APIError.unauthorized
        default:
            let message = try? extractErrorMessage(from: data)
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: message)
        }
    }

    // MARK: - Network Monitoring

    private func startNetworkMonitoring() {
        // Implementation would use Network framework to monitor connectivity
        // For now, assume we're online
        isOnline = true
    }
}

// MARK: - API Endpoints

protocol APIEndpoint {
    var path: String { get }
}

enum Endpoints {
    // Authentication
    enum Auth: APIEndpoint {
        case login
        case register
        case registerWithOrganization
        case sendVerificationCode
        case refresh
        case logout
        case profile
        case changePassword
        case forgotPassword
        case resetPassword
        case verifyEmail

        var path: String {
            switch self {
            case .login: return "/auth/login"
            case .register: return "/auth/register"
            case .registerWithOrganization: return "/auth/register-with-organization"
            case .sendVerificationCode: return "/auth/send-verification-code"
            case .refresh: return "/auth/refresh"
            case .logout: return "/auth/logout"
            case .profile: return "/auth/profile"
            case .changePassword: return "/auth/change-password"
            case .forgotPassword: return "/auth/forgot-password"
            case .resetPassword: return "/auth/reset-password"
            case .verifyEmail: return "/auth/verify-email"
            }
        }
    }

    // Organizations
    enum Organizations: APIEndpoint {
        case myOrganization
        case create
        case join
        case regenerateCode

        var path: String {
            switch self {
            case .myOrganization: return "/organizations/my-organization"
            case .create: return "/organizations/create"
            case .join: return "/organizations/join"
            case .regenerateCode: return "/organizations/regenerate-code"
            }
        }
    }

    // Members
    enum Members: APIEndpoint {
        case list
        case create
        case get(id: String)
        case update(id: String)
        case delete(id: String)
        case search
        case notes(memberId: String)
        case activities(memberId: String)

        var path: String {
            switch self {
            case .list: return "/members"
            case .create: return "/members"
            case .get(let id): return "/members/\(id)"
            case .update(let id): return "/members/\(id)"
            case .delete(let id): return "/members/\(id)"
            case .search: return "/members/search"
            case .notes(let memberId): return "/members/\(memberId)/notes"
            case .activities(let memberId): return "/members/\(memberId)/activities"
            }
        }
    }

    // Messages
    enum Messages: APIEndpoint {
        case list
        case send  // Direct send (POST /messages/send)
        case get(id: String)
        case delete(id: String)

        var path: String {
            switch self {
            case .list: return "/messages"
            case .send: return "/messages/send"  // Updated to match backend
            case .get(let id): return "/messages/\(id)"
            case .delete(let id): return "/messages/\(id)"
            }
        }
    }

    // Templates
    enum Templates: APIEndpoint {
        case list
        case create
        case get(id: String)
        case update(id: String)
        case delete(id: String)

        var path: String {
            switch self {
            case .list: return "/templates"
            case .create: return "/templates"
            case .get(let id): return "/templates/\(id)"
            case .update(let id): return "/templates/\(id)"
            case .delete(let id): return "/templates/\(id)"
            }
        }
    }

    // Automation
    enum Automation: APIEndpoint {
        case rules
        case createRule
        case getRule(id: String)
        case updateRule(id: String)
        case deleteRule(id: String)
        case logs(ruleId: String?)
        case execute(ruleId: String)

        var path: String {
            switch self {
            case .rules: return "/automation/rules"
            case .createRule: return "/automation/rules"
            case .getRule(let id): return "/automation/rules/\(id)"
            case .updateRule(let id): return "/automation/rules/\(id)"
            case .deleteRule(let id): return "/automation/rules/\(id)"
            case .logs(let ruleId):
                return ruleId.map { "/automation/rules/\($0)/logs" } ?? "/automation/logs"
            case .execute(let ruleId): return "/automation/rules/\(ruleId)/execute"
            }
        }
    }

    // Analytics
    enum Analytics: APIEndpoint {
        case dashboard
        case members
        case messages
        case automation
        case engagement
        case reports

        var path: String {
            switch self {
            case .dashboard: return "/analytics/dashboard"
            case .members: return "/analytics/members"
            case .messages: return "/analytics/messages"
            case .automation: return "/analytics/automation"
            case .engagement: return "/analytics/engagement"
            case .reports: return "/analytics/reports"
            }
        }
    }

    // Settings
    enum Settings: APIEndpoint {
        case senderResolved
        case senderList(scope: String?, referenceId: String?)
        case senderCreate(scope: String, referenceId: String?)
        case senderUpdate(scope: String, referenceId: String?)
        case senderDelete(scope: String, referenceId: String?)

        var path: String {
            switch self {
            case .senderResolved:
                return "/settings/senders/resolved"
            case .senderList(let scope, let referenceId):
                var path = "/settings/senders"
                var params: [String] = []
                if let scope = scope { params.append("scope=\(scope)") }
                if let referenceId = referenceId { params.append("reference_id=\(referenceId)") }
                if !params.isEmpty { path += "?" + params.joined(separator: "&") }
                return path
            case .senderCreate(let scope, let referenceId):
                var path = "/settings/senders?scope=\(scope)"
                if let referenceId = referenceId { path += "&reference_id=\(referenceId)" }
                return path
            case .senderUpdate(let scope, let referenceId):
                var path = "/settings/senders?scope=\(scope)"
                if let referenceId = referenceId { path += "&reference_id=\(referenceId)" }
                return path
            case .senderDelete(let scope, let referenceId):
                var path = "/settings/senders?scope=\(scope)"
                if let referenceId = referenceId { path += "&reference_id=\(referenceId)" }
                return path
            }
        }
    }

    // Bulk Operations
    enum Bulk: APIEndpoint {
        case importMembers

        var path: String {
            switch self {
            case .importMembers: return "/bulk/members/import"
            }
        }
    }

    // Field Configurations
    enum Fields: APIEndpoint {
        case configs(entityType: String?)
        case getConfig(id: String)
        case createConfig
        case updateConfig(id: String)
        case deleteConfig(id: String)
        case entityFields(entityType: String, entityId: String)
        case saveValues
        case initializeMembers

        var path: String {
            switch self {
            case .configs(let entityType):
                var path = "/fields/configs"
                if let entityType = entityType {
                    path += "?entity_type=\(entityType)"
                }
                return path
            case .getConfig(let id):
                return "/fields/configs/\(id)"
            case .createConfig:
                return "/fields/configs"
            case .updateConfig(let id):
                return "/fields/configs/\(id)"
            case .deleteConfig(let id):
                return "/fields/configs/\(id)"
            case .entityFields(let entityType, let entityId):
                return "/fields/entities/\(entityType)/\(entityId)"
            case .saveValues:
                return "/fields/entities/values"
            case .initializeMembers:
                return "/fields/initialize/members"
            }
        }
    }
}

// MARK: - Keychain Helper

/// Simple keychain wrapper for secure token storage
enum KeychainHelper {
    static func save(service: String, account: String, data: String) {
        let data = Data(data.utf8)

        let query =
            [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: service,
                kSecAttrAccount: account,
                kSecValueData: data,
            ] as CFDictionary

        SecItemDelete(query)
        SecItemAdd(query, nil)
    }

    static func load(service: String, account: String) -> String? {
        let query =
            [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: service,
                kSecAttrAccount: account,
                kSecReturnData: true,
                kSecMatchLimit: kSecMatchLimitOne,
            ] as CFDictionary

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query, &dataTypeRef)

        if status == errSecSuccess,
            let data = dataTypeRef as? Data,
            let string = String(data: data, encoding: .utf8)
        {
            return string
        }

        return nil
    }

    static func delete(service: String, account: String) {
        let query =
            [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: service,
                kSecAttrAccount: account,
            ] as CFDictionary

        SecItemDelete(query)
    }
}
