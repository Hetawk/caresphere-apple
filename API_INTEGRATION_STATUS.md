# CareSphere iOS App - API Integration Status

> **Last Updated**: February 5, 2026  
> **API Base URL**: `https://caresphere.ekddigital.com`  
> **iOS App Version**: 1.0.0 (Development)

## Executive Summary

The CareSphere iOS app is a comprehensive church/community care management platform that communicates with the FastAPI backend. This document outlines the current integration status, identifies issues, and provides recommendations for ensuring seamless API connectivity.

## 🎯 Current Status: **READY WITH MINOR UPDATES NEEDED**

### ✅ What's Working Well

1. **Architecture**
   - Clean modular design with proper separation of concerns
   - Centralized NetworkClient with retry logic and error handling
   - Proper authentication flow with JWT tokens stored in Keychain
   - Well-defined domain services (Auth, Members, Messages, Analytics, etc.)

2. **API Configuration**
   - Base URL correctly set to `https://caresphere.ekddigital.com`
   - Environment-based configuration via `Env.swift`
   - Proper endpoint structure matching backend routes

3. **Models & Schemas**
   - Swift models align well with Python Pydantic schemas
   - Proper CodingKeys for snake_case ↔ camelCase conversion
   - Codable conformance for JSON serialization

4. **Brand Identity**
   - Colors defined match the logo gold palette partially
   - Design system in place with spacing, typography, and components

### ⚠️ Issues Identified

#### 1. **Color Mismatch with Updated Brand**
**Problem**: iOS app uses different colors than the updated API dashboard  
**Current iOS Colors**:
- Primary: `#1F1C18` (dark)
- Gold: `#D4AF6A`, `#C8A061`

**API Dashboard Colors** (from logo):
- Gold Gradient: `#E8C589` → `#D4AF6A` → `#C8A061`
- Dark: `#14120F`
- Light BG: `#F7F6F4`

**Impact**: Branding inconsistency across platforms  
**Priority**: Medium

#### 2. **Messages API Endpoint Mismatch**
**Problem**: iOS expects separate message creation and sending  
**Current iOS**: `POST /messages` (create) + `POST /messages/{id}/send` (send)  
**API Reality**: `POST /messages/send` (combined)

**Impact**: Message sending will fail  
**Priority**: HIGH - CRITICAL

#### 3. **Missing Response Wrapper Handling**
**Problem**: API returns `{"success": true, "data": {...}}` but iOS expects direct data  
**Current iOS**: Generic `APIResponse<T>` exists but not consistently used  
**Impact**: Decoding errors on successful responses  
**Priority**: HIGH - CRITICAL

#### 4. **Authentication Endpoints**
**Problem**: Some auth endpoints may not exist on backend  
**iOS Expects**: `/auth/profile`, `/auth/change-password`, `/auth/verify-email`  
**API Has**: `/auth/register`, `/auth/login`, `/auth/refresh`

**Impact**: Profile loading and password management may fail  
**Priority**: Medium

#### 5. **Member Notes & Activities**
**Problem**: iOS has endpoints for member notes/activities that don't exist in API  
**iOS Expects**: `/members/{id}/notes`, `/members/{id}/activities`  
**API Has**: Basic CRUD only

**Impact**: Features won't work, error handling needed  
**Priority**: Low (future features)

#### 6. **Pagination Format**
**Problem**: iOS expects different pagination format  
**iOS Expects**: Metadata with pagination info  
**API Returns**: Custom format (need to verify)

**Impact**: List views may not paginate correctly  
**Priority**: Medium

## 🔧 Recommended Fixes

### 1. Update Brand Colors (Priority: Medium)

Update `CareSphereColors.swift` to match API dashboard:

```swift
// MARK: - Brand Palette (Updated to match logo)
static let brandPrimary = Color(red: 20/255, green: 18/255, blue: 15/255)        // #14120F
static let brandGold = Color(red: 200/255, green: 160/255, blue: 97/255)         // #C8A061
static let brandGoldLight = Color(red: 212/255, green: 175/255, blue: 106/255)   // #D4AF6A
static let brandGoldLighter = Color(red: 232/255, green: 197/255, blue: 137/255) // #E8C589

// MARK: - Background Colors  
static let backgroundPrimary = Color(red: 247/255, green: 246/255, blue: 244/255) // #F7F6F4
```

### 2. Fix Message Endpoints (Priority: HIGH)

Update `NetworkClient.swift` Messages enum:

```swift
enum Messages: APIEndpoint {
    case list
    case send  // Changed: direct send instead of create
    case get(id: String)
    case delete(id: String)

    var path: String {
        switch self {
        case .list: return "/messages"
        case .send: return "/messages/send"  // Updated
        case .get(let id): return "/messages/\(id)"
        case .delete(let id): return "/messages/\(id)"
        }
    }
}
```

Update `MessageService` in `DomainServices.swift`:

```swift
func sendMessage(
    type: MessageType,
    recipients: [String],
    subject: String?,
    content: String,
    templateId: String? = nil
) async -> Bool {
    isLoading = true
    error = nil
    
    do {
        let request = SendMessageRequest(
            type: type.rawValue,
            recipients: recipients,
            subject: subject,
            body: content,
            template_id: templateId
        )
        
        let response: MessageResponse = try await networkClient.request(
            endpoint: Endpoints.Messages.send,  // Updated
            method: .POST,
            body: request
        )
        
        // Refresh messages list
        await fetchMessages()
        
        isLoading = false
        return true
        
    } catch let apiError as APIError {
        self.error = apiError
        isLoading = false
        return false
    }
}
```

### 3. Handle API Response Wrapper (Priority: HIGH)

Update `NetworkClient.swift` to unwrap API responses:

```swift
private func requestWithBody<T: Codable, Body: Codable>(
    endpoint: APIEndpoint,
    method: HTTPMethod,
    body: Body?,
    headers: [String: String]
) async throws -> T {
    // ... existing request code ...
    
    do {
        // Try to decode as API response wrapper first
        let apiResponse = try decoder.decode(APIResponse<T>.self, from: data)
        
        if apiResponse.success, let responseData = apiResponse.data {
            return responseData
        } else if let error = apiResponse.error {
            throw APIError.serverError(
                statusCode: httpResponse.statusCode,
                message: error.message
            )
        } else {
            throw APIError.noData
        }
    } catch {
        // Fallback: try direct decoding for non-wrapped responses
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
}
```

### 4. Add Missing Auth Profile Endpoint (Priority: Medium)

Since `/auth/profile` doesn't exist, use user data from login response:

Update `AuthenticationService`:

```swift
func login(email: String, password: String, rememberMe: Bool = true) async -> Bool {
    // ... existing code ...
    
    // Store user data directly from login response
    currentUser = response.user
    
    // No need to call loadCurrentUser() separately
    
    isLoading = false
    return true
}

func loadCurrentUser() async {
    // For now, keep the user from login response
    // Backend should add /auth/me or /auth/profile endpoint
    guard networkClient.isAuthenticated, currentUser == nil else {
        return
    }
    
    // TODO: Once backend adds profile endpoint, implement:
    // let user: User = try await networkClient.request(endpoint: Endpoints.Auth.profile)
    // currentUser = user
}
```

### 5. Remove Unsupported Endpoints (Priority: Low)

Comment out unsupported endpoints until backend implements them:

```swift
enum Members: APIEndpoint {
    case list
    case create
    case get(id: String)
    case update(id: String)
    case delete(id: String)
    case search
    // case notes(memberId: String)       // TODO: Backend not implemented
    // case activities(memberId: String)  // TODO: Backend not implemented

    var path: String {
        switch self {
        // ... existing cases ...
        // case .notes(let memberId): return "/members/\(memberId)/notes"
        // case .activities(let memberId): return "/members/\(memberId)/activities"
        }
    }
}
```

## 📋 Testing Checklist

After implementing fixes, test these critical flows:

- [ ] **Authentication**
  - [ ] Register new account
  - [ ] Login with credentials
  - [ ] Token refresh on 401
  - [ ] Logout

- [ ] **Members**
  - [ ] List members with pagination
  - [ ] Create new member
  - [ ] View member details
  - [ ] Update member info
  - [ ] Delete member

- [ ] **Messages**
  - [ ] Send email message
  - [ ] Send SMS message
  - [ ] List sent messages
  - [ ] View message details

- [ ] **Templates**
  - [ ] List templates
  - [ ] View template details
  - [ ] Create template
  - [ ] Use template to send message

- [ ] **Settings**
  - [ ] View sender settings
  - [ ] Update sender settings

## 🚀 Deployment Notes

### Environment Variables

The app reads from `ProcessInfo.processInfo.environment`, which means:

**For Xcode Development**:
1. Edit scheme → Run → Arguments → Environment Variables
2. Add: `API_BASE_URL = https://caresphere.ekddigital.com`

**For Production**:
- No environment files needed
- Hardcoded default in `APIConfiguration.shared`

### Build Configuration

Current default: `https://caresphere.ekddigital.com`

For different environments:
```swift
#if DEBUG
let defaultURL = "http://localhost:8000"
#else
let defaultURL = "https://caresphere.ekddigital.com"
#endif
```

## 📊 API Compatibility Matrix

| Feature | iOS Endpoint | API Endpoint | Status |
|---------|-------------|--------------|--------|
| Login | `POST /auth/login` | `POST /auth/login` | ✅ Match |
| Register | `POST /auth/register` | `POST /auth/register` | ✅ Match |
| Refresh Token | `POST /auth/refresh` | `POST /auth/refresh` | ✅ Match |
| Get Profile | `GET /auth/profile` | ❌ Not Implemented | ⚠️ Needs backend |
| List Members | `GET /members` | `GET /members` | ✅ Match |
| Create Member | `POST /members` | `POST /members` | ✅ Match |
| Update Member | `PATCH /members/{id}` | `PATCH /members/{id}` | ✅ Match |
| Send Message | `POST /messages/{id}/send` | `POST /messages/send` | ❌ Mismatch |
| List Messages | `GET /messages` | `GET /messages` | ✅ Match |
| List Templates | `GET /templates` | `GET /templates` | ✅ Match |
| Analytics | `GET /analytics/*` | `GET /analytics/*` | ✅ Match |
| Sender Settings | `GET /settings/sender` | `GET /settings/sender` | ✅ Match |

## 🎯 Next Steps

1. **Immediate** (Must fix before testing):
   - [ ] Fix message sending endpoint
   - [ ] Handle API response wrapper
   - [ ] Update brand colors for consistency

2. **Short-term** (1-2 weeks):
   - [ ] Add error recovery for unsupported endpoints
   - [ ] Implement proper pagination handling
   - [ ] Add integration tests

3. **Long-term** (Backend improvements):
   - [ ] Add `/auth/profile` or `/auth/me` endpoint
   - [ ] Add member notes endpoints
   - [ ] Add member activities endpoints
   - [ ] Standardize pagination format

## 📞 Support

For API-related questions:
- **Backend Repo**: `Hetawk/caresphere-api`
- **API Docs**: `https://caresphere.ekddigital.com/docs`
- **Dashboard**: `https://caresphere.ekddigital.com/dashboard`

For iOS app issues:
- **iOS Repo**: `Hetawk/caresphere-apple`
- **Architecture**: See `ARCHITECTURE.md`
