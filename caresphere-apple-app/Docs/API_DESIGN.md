# CareSphere API - Complete Design Specification

**Repository:** https://github.com/Hetawk/caresphere-api.git  
**Technology Stack:** Python + FastAPI + MySQL  
**Database:** MySQL (configured in `.env`)  
**Authentication:** JWT (JSON Web Tokens)  

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Technology Stack](#technology-stack)
3. [Database Schema](#database-schema)
4. [API Endpoints](#api-endpoints)
5. [Authentication Flow](#authentication-flow)
6. [Request/Response Format](#requestresponse-format)
7. [Error Handling](#error-handling)
8. [Security](#security)
9. [Deployment](#deployment)

---

## 🎯 Overview

CareSphere API is a RESTful backend service for the CareSphere church/community management platform. It provides endpoints for:

- **Authentication** - User registration, login, profile management
- **Member Management** - CRUD operations for community members
- **Messaging** - Create, send, and track messages
- **Templates** - Message template management
- **Automation** - Automated messaging rules and workflows
- **Analytics** - Dashboard metrics and engagement tracking

---

## 🛠 Technology Stack

### Core Framework
- **FastAPI** - Modern, fast Python web framework
- **Uvicorn** - ASGI server
- **Python 3.11+** - Programming language

### Database
- **MySQL** - Primary database (via `DATABASE_URL`)
- **SQLAlchemy** - ORM for database operations
- **Alembic** - Database migrations

### Authentication & Security
- **PyJWT** - JWT token generation/validation
- **Passlib + Bcrypt** - Password hashing
- **Python-jose** - JWT encoding/decoding

### Additional Libraries
- **Pydantic** - Data validation and settings
- **python-multipart** - File upload support
- **python-dotenv** - Environment variable management
- **CORS Middleware** - Cross-origin resource sharing for mobile apps

---

## 🗄 Database Schema

### Users Table
```sql
CREATE TABLE users (
    id VARCHAR(36) PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    display_name VARCHAR(100),
    avatar_url VARCHAR(500),
    role ENUM('admin', 'moderator', 'member') DEFAULT 'member',
    status ENUM('active', 'inactive', 'suspended') DEFAULT 'active',
    email_verified BOOLEAN DEFAULT FALSE,
    last_login_at DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_status (status)
);
```

### Members Table
```sql
CREATE TABLE members (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(20),
    date_of_birth DATE,
    gender ENUM('male', 'female', 'other', 'prefer_not_to_say'),
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    zip_code VARCHAR(20),
    country VARCHAR(100),
    member_status ENUM('active', 'inactive', 'pending', 'archived') DEFAULT 'active',
    membership_type VARCHAR(50),
    join_date DATE,
    photo_url VARCHAR(500),
    notes TEXT,
    tags JSON,
    custom_fields JSON,
    created_by VARCHAR(36),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_email (email),
    INDEX idx_status (member_status),
    INDEX idx_name (last_name, first_name)
);
```

### Member Groups Table
```sql
CREATE TABLE member_groups (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    group_type VARCHAR(50),
    color VARCHAR(20),
    icon VARCHAR(50),
    member_count INT DEFAULT 0,
    created_by VARCHAR(36),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_name (name)
);
```

### Member Group Assignments Table
```sql
CREATE TABLE member_group_assignments (
    id VARCHAR(36) PRIMARY KEY,
    member_id VARCHAR(36) NOT NULL,
    group_id VARCHAR(36) NOT NULL,
    assigned_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    assigned_by VARCHAR(36),
    FOREIGN KEY (member_id) REFERENCES members(id) ON DELETE CASCADE,
    FOREIGN KEY (group_id) REFERENCES member_groups(id) ON DELETE CASCADE,
    FOREIGN KEY (assigned_by) REFERENCES users(id) ON DELETE SET NULL,
    UNIQUE KEY unique_member_group (member_id, group_id),
    INDEX idx_member (member_id),
    INDEX idx_group (group_id)
);
```

### Messages Table
```sql
CREATE TABLE messages (
    id VARCHAR(36) PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    message_type ENUM('email', 'sms', 'push', 'in_app') DEFAULT 'email',
    status ENUM('draft', 'scheduled', 'sending', 'sent', 'failed') DEFAULT 'draft',
    scheduled_for DATETIME,
    sent_at DATETIME,
    recipient_count INT DEFAULT 0,
    opened_count INT DEFAULT 0,
    clicked_count INT DEFAULT 0,
    failed_count INT DEFAULT 0,
    template_id VARCHAR(36),
    created_by VARCHAR(36),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (template_id) REFERENCES templates(id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_status (status),
    INDEX idx_created_by (created_by),
    INDEX idx_scheduled (scheduled_for)
);
```

### Message Recipients Table
```sql
CREATE TABLE message_recipients (
    id VARCHAR(36) PRIMARY KEY,
    message_id VARCHAR(36) NOT NULL,
    member_id VARCHAR(36) NOT NULL,
    recipient_email VARCHAR(255),
    recipient_phone VARCHAR(20),
    status ENUM('pending', 'sent', 'delivered', 'opened', 'clicked', 'failed') DEFAULT 'pending',
    sent_at DATETIME,
    delivered_at DATETIME,
    opened_at DATETIME,
    clicked_at DATETIME,
    error_message TEXT,
    metadata JSON,
    FOREIGN KEY (message_id) REFERENCES messages(id) ON DELETE CASCADE,
    FOREIGN KEY (member_id) REFERENCES members(id) ON DELETE CASCADE,
    INDEX idx_message (message_id),
    INDEX idx_member (member_id),
    INDEX idx_status (status)
);
```

### Templates Table
```sql
CREATE TABLE templates (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    template_type ENUM('email', 'sms', 'push') DEFAULT 'email',
    category VARCHAR(100),
    subject VARCHAR(255),
    content TEXT NOT NULL,
    variables JSON,
    thumbnail_url VARCHAR(500),
    is_active BOOLEAN DEFAULT TRUE,
    usage_count INT DEFAULT 0,
    created_by VARCHAR(36),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_type (template_type),
    INDEX idx_active (is_active),
    INDEX idx_name (name)
);
```

### Automation Rules Table
```sql
CREATE TABLE automation_rules (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    trigger_type VARCHAR(50) NOT NULL,
    trigger_config JSON,
    action_type VARCHAR(50) NOT NULL,
    action_config JSON,
    conditions JSON,
    is_active BOOLEAN DEFAULT TRUE,
    last_run_at DATETIME,
    run_count INT DEFAULT 0,
    success_count INT DEFAULT 0,
    failure_count INT DEFAULT 0,
    created_by VARCHAR(36),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_active (is_active),
    INDEX idx_trigger (trigger_type)
);
```

### Automation Logs Table
```sql
CREATE TABLE automation_logs (
    id VARCHAR(36) PRIMARY KEY,
    rule_id VARCHAR(36) NOT NULL,
    status ENUM('success', 'failure', 'skipped') NOT NULL,
    trigger_data JSON,
    action_result JSON,
    error_message TEXT,
    execution_time_ms INT,
    executed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (rule_id) REFERENCES automation_rules(id) ON DELETE CASCADE,
    INDEX idx_rule (rule_id),
    INDEX idx_status (status),
    INDEX idx_executed (executed_at)
);
```

### Member Notes Table
```sql
CREATE TABLE member_notes (
    id VARCHAR(36) PRIMARY KEY,
    member_id VARCHAR(36) NOT NULL,
    note TEXT NOT NULL,
    note_type VARCHAR(50),
    is_private BOOLEAN DEFAULT FALSE,
    created_by VARCHAR(36),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (member_id) REFERENCES members(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_member (member_id),
    INDEX idx_created (created_at)
);
```

### Member Activities Table
```sql
CREATE TABLE member_activities (
    id VARCHAR(36) PRIMARY KEY,
    member_id VARCHAR(36) NOT NULL,
    activity_type VARCHAR(50) NOT NULL,
    description TEXT,
    metadata JSON,
    created_by VARCHAR(36),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (member_id) REFERENCES members(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_member (member_id),
    INDEX idx_type (activity_type),
    INDEX idx_created (created_at)
);
```

---

## 🔌 API Endpoints

### Base URL
```
Development: http://localhost:8000
Production: https://caresphere.ekddigital.com
Alternative: https://api.caresphere.ekddigital.com
```

### Standard Response Format
```json
{
  "success": true,
  "data": { /* response data */ },
  "error": null,
  "metadata": {
    "timestamp": "2025-11-13T10:30:00Z",
    "requestId": "uuid-v4",
    "version": "1.0.0",
    "pagination": { /* if applicable */ }
  }
}
```

---

## 🔐 Authentication Endpoints

### POST `/auth/register`
Create a new user account.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "SecurePass123!",
  "fullName": "John Doe",
  "displayName": "John"
}
```

**Response:** `201 Created`
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "fullName": "John Doe",
      "displayName": "John",
      "role": "member",
      "createdAt": "2025-11-13T10:30:00Z"
    },
    "accessToken": "eyJhbGciOiJIUzI1NiIs...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIs...",
    "expiresIn": 86400
  }
}
```

---

### POST `/auth/login`
Authenticate user and receive JWT tokens.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "SecurePass123!"
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "fullName": "John Doe",
      "role": "admin"
    },
    "accessToken": "eyJhbGciOiJIUzI1NiIs...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIs...",
    "expiresIn": 86400
  }
}
```

---

### POST `/auth/refresh`
Refresh access token using refresh token.

**Request Body:**
```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIs..."
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIs...",
    "expiresIn": 86400
  }
}
```

---

### GET `/auth/profile`
Get current user profile. **[Protected]**

**Headers:** `Authorization: Bearer {token}`

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "email": "user@example.com",
    "fullName": "John Doe",
    "displayName": "John",
    "avatarUrl": "https://...",
    "role": "admin",
    "status": "active",
    "lastLoginAt": "2025-11-13T10:00:00Z",
    "createdAt": "2025-01-01T00:00:00Z"
  }
}
```

---

### POST `/auth/logout`
Logout user (invalidate tokens). **[Protected]**

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "message": "Logged out successfully"
  }
}
```

---

## 👥 Member Endpoints

### GET `/members`
List all members with optional filtering. **[Protected]**

**Query Parameters:**
- `page` - Page number (default: 1)
- `limit` - Items per page (default: 20, max: 100)
- `status` - Filter by status: `active`, `inactive`, `pending`, `archived`
- `search` - Search by name, email, or phone
- `groupId` - Filter by group membership
- `sort` - Sort field (default: `lastName`)
- `order` - Sort order: `asc`, `desc` (default: `asc`)

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "members": [
      {
        "id": "uuid",
        "firstName": "John",
        "lastName": "Doe",
        "email": "john@example.com",
        "phone": "+1234567890",
        "memberStatus": "active",
        "membershipType": "Regular",
        "joinDate": "2024-01-15",
        "photoUrl": "https://...",
        "groups": ["Group A", "Group B"],
        "tags": ["tag1", "tag2"]
      }
    ]
  },
  "metadata": {
    "pagination": {
      "currentPage": 1,
      "totalPages": 5,
      "totalItems": 95,
      "itemsPerPage": 20,
      "hasNextPage": true,
      "hasPreviousPage": false
    }
  }
}
```

---

### POST `/members`
Create a new member. **[Protected]**

**Request Body:**
```json
{
  "firstName": "Jane",
  "lastName": "Smith",
  "email": "jane@example.com",
  "phone": "+1234567890",
  "dateOfBirth": "1990-05-15",
  "gender": "female",
  "address": "123 Main St",
  "city": "New York",
  "state": "NY",
  "zipCode": "10001",
  "country": "USA",
  "membershipType": "Regular",
  "joinDate": "2025-11-13",
  "tags": ["new", "volunteer"],
  "customFields": {
    "baptismDate": "2020-01-01"
  }
}
```

**Response:** `201 Created`
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "firstName": "Jane",
    "lastName": "Smith",
    "email": "jane@example.com",
    "memberStatus": "active",
    "createdAt": "2025-11-13T10:30:00Z"
  }
}
```

---

### GET `/members/{id}`
Get member details by ID. **[Protected]**

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "firstName": "Jane",
    "lastName": "Smith",
    "email": "jane@example.com",
    "phone": "+1234567890",
    "dateOfBirth": "1990-05-15",
    "gender": "female",
    "address": "123 Main St",
    "city": "New York",
    "state": "NY",
    "zipCode": "10001",
    "country": "USA",
    "memberStatus": "active",
    "membershipType": "Regular",
    "joinDate": "2025-11-13",
    "photoUrl": "https://...",
    "notes": "Active volunteer",
    "tags": ["volunteer", "youth"],
    "groups": [
      {
        "id": "uuid",
        "name": "Youth Group",
        "type": "ministry"
      }
    ],
    "customFields": {
      "baptismDate": "2020-01-01"
    },
    "createdAt": "2025-11-13T10:30:00Z",
    "updatedAt": "2025-11-13T10:30:00Z"
  }
}
```

---

### PUT `/members/{id}`
Update member information. **[Protected]**

**Request Body:** (all fields optional)
```json
{
  "firstName": "Jane",
  "lastName": "Smith",
  "email": "newemail@example.com",
  "phone": "+0987654321",
  "memberStatus": "active",
  "tags": ["volunteer", "youth", "leader"]
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "firstName": "Jane",
    "lastName": "Smith",
    "updatedAt": "2025-11-13T11:00:00Z"
  }
}
```

---

### DELETE `/members/{id}`
Delete a member. **[Protected - Admin only]**

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "message": "Member deleted successfully"
  }
}
```

---

### POST `/members/search`
Advanced member search. **[Protected]**

**Request Body:**
```json
{
  "query": "john",
  "filters": {
    "status": ["active", "pending"],
    "groups": ["uuid1", "uuid2"],
    "tags": ["volunteer"],
    "ageMin": 18,
    "ageMax": 65,
    "city": "New York"
  },
  "page": 1,
  "limit": 20
}
```

**Response:** Same as GET `/members`

---

### GET `/members/{id}/notes`
Get notes for a specific member. **[Protected]**

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "notes": [
      {
        "id": "uuid",
        "note": "Called to follow up",
        "noteType": "followup",
        "isPrivate": false,
        "createdBy": {
          "id": "uuid",
          "name": "Admin User"
        },
        "createdAt": "2025-11-13T10:30:00Z"
      }
    ]
  }
}
```

---

### POST `/members/{id}/notes`
Add a note to a member. **[Protected]**

**Request Body:**
```json
{
  "note": "Attended Sunday service",
  "noteType": "attendance",
  "isPrivate": false
}
```

**Response:** `201 Created`

---

### GET `/members/{id}/activities`
Get activity history for a member. **[Protected]**

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "activities": [
      {
        "id": "uuid",
        "activityType": "message_sent",
        "description": "Received welcome email",
        "metadata": {
          "messageId": "uuid",
          "messageTitle": "Welcome!"
        },
        "createdAt": "2025-11-13T09:00:00Z"
      }
    ]
  }
}
```

---

## 💬 Message Endpoints

### GET `/messages`
List all messages. **[Protected]**

**Query Parameters:**
- `page`, `limit` - Pagination
- `status` - Filter by status
- `type` - Filter by message type

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "messages": [
      {
        "id": "uuid",
        "title": "Weekly Newsletter",
        "messageType": "email",
        "status": "sent",
        "recipientCount": 150,
        "openedCount": 75,
        "clickedCount": 30,
        "scheduledFor": null,
        "sentAt": "2025-11-13T08:00:00Z",
        "createdAt": "2025-11-12T10:00:00Z"
      }
    ]
  }
}
```

---

### POST `/messages`
Create a new message. **[Protected]**

**Request Body:**
```json
{
  "title": "Weekly Update",
  "content": "Hello everyone, here's this week's update...",
  "messageType": "email",
  "status": "draft",
  "recipientGroupIds": ["uuid1", "uuid2"],
  "recipientMemberIds": ["uuid3", "uuid4"],
  "templateId": "uuid",
  "scheduledFor": "2025-11-15T10:00:00Z"
}
```

**Response:** `201 Created`

---

### GET `/messages/{id}`
Get message details. **[Protected]**

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "title": "Weekly Newsletter",
    "content": "Full message content...",
    "messageType": "email",
    "status": "sent",
    "recipientCount": 150,
    "openedCount": 75,
    "clickedCount": 30,
    "failedCount": 2,
    "scheduledFor": null,
    "sentAt": "2025-11-13T08:00:00Z",
    "recipients": [
      {
        "id": "uuid",
        "memberName": "John Doe",
        "recipientEmail": "john@example.com",
        "status": "opened",
        "sentAt": "2025-11-13T08:00:00Z",
        "openedAt": "2025-11-13T09:15:00Z"
      }
    ]
  }
}
```

---

### POST `/messages/{id}/send`
Send a message immediately. **[Protected]**

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "message": "Message queued for sending",
    "recipientCount": 150
  }
}
```

---

### GET `/messages/{id}/analytics`
Get detailed analytics for a message. **[Protected]**

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "totalSent": 150,
    "totalDelivered": 148,
    "totalOpened": 75,
    "totalClicked": 30,
    "totalFailed": 2,
    "openRate": 50.0,
    "clickRate": 20.0,
    "deliveryRate": 98.7,
    "opensByHour": [/* time series data */],
    "clicksByHour": [/* time series data */],
    "topLinks": [
      {
        "url": "https://example.com",
        "clicks": 15
      }
    ]
  }
}
```

---

## 📝 Template Endpoints

### GET `/templates`
List all templates. **[Protected]**

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "templates": [
      {
        "id": "uuid",
        "name": "Welcome Email",
        "description": "Welcome new members",
        "templateType": "email",
        "category": "onboarding",
        "thumbnailUrl": "https://...",
        "isActive": true,
        "usageCount": 45,
        "createdAt": "2025-01-01T00:00:00Z"
      }
    ]
  }
}
```

---

### POST `/templates`
Create a new template. **[Protected]**

**Request Body:**
```json
{
  "name": "Birthday Greeting",
  "description": "Send birthday wishes",
  "templateType": "email",
  "category": "celebrations",
  "subject": "Happy Birthday {{firstName}}!",
  "content": "Dear {{firstName}}, wishing you a wonderful birthday!",
  "variables": ["firstName", "lastName", "age"]
}
```

**Response:** `201 Created`

---

### GET `/templates/{id}`
Get template details. **[Protected]**

---

### PUT `/templates/{id}`
Update template. **[Protected]**

---

### DELETE `/templates/{id}`
Delete template. **[Protected - Admin only]**

---

## ⚙️ Automation Endpoints

### GET `/automation/rules`
List all automation rules. **[Protected]**

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "rules": [
      {
        "id": "uuid",
        "name": "Birthday Reminder",
        "description": "Send birthday message automatically",
        "triggerType": "birthday",
        "actionType": "send_message",
        "isActive": true,
        "runCount": 125,
        "successCount": 120,
        "lastRunAt": "2025-11-13T00:00:00Z"
      }
    ]
  }
}
```

---

### POST `/automation/rules`
Create automation rule. **[Protected]**

**Request Body:**
```json
{
  "name": "Welcome New Members",
  "description": "Send welcome email to new members",
  "triggerType": "member_created",
  "triggerConfig": {
    "delay": 0
  },
  "actionType": "send_message",
  "actionConfig": {
    "templateId": "uuid",
    "messageType": "email"
  },
  "conditions": {
    "memberStatus": "active"
  },
  "isActive": true
}
```

**Response:** `201 Created`

---

### GET `/automation/rules/{id}`
Get rule details. **[Protected]**

---

### PUT `/automation/rules/{id}`
Update rule. **[Protected]**

---

### DELETE `/automation/rules/{id}`
Delete rule. **[Protected - Admin only]**

---

### POST `/automation/rules/{id}/execute`
Manually execute a rule. **[Protected]**

---

### GET `/automation/logs`
Get automation execution logs. **[Protected]**

**Query Parameters:**
- `ruleId` - Filter by rule
- `status` - Filter by status
- `page`, `limit` - Pagination

---

## 📊 Analytics Endpoints

### GET `/analytics/dashboard`
Get dashboard overview. **[Protected]**

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "totalMembers": 1250,
    "activeMembers": 980,
    "newMembersThisMonth": 45,
    "messagesSentThisMonth": 120,
    "averageOpenRate": 58.5,
    "averageClickRate": 22.3,
    "automationRulesActive": 8,
    "recentActivities": [/* activity list */]
  }
}
```

---

### GET `/analytics/members`
Get member analytics. **[Protected]**

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "growthTrend": [/* time series */],
    "statusDistribution": {
      "active": 980,
      "inactive": 200,
      "pending": 50,
      "archived": 20
    },
    "demographicBreakdown": {
      "ageGroups": {/* age distribution */},
      "genderDistribution": {/* gender stats */},
      "cityDistribution": {/* city stats */}
    }
  }
}
```

---

### GET `/analytics/messages`
Get messaging analytics. **[Protected]**

---

### GET `/analytics/engagement`
Get engagement metrics. **[Protected]**

---

## 🔒 Authentication Flow

### Token-Based Authentication (JWT)

1. **Registration/Login:**
   - User provides credentials
   - Server validates and generates JWT tokens
   - Returns `accessToken` (24h expiry) and `refreshToken` (7d expiry)

2. **Making Authenticated Requests:**
   ```http
   Authorization: Bearer {accessToken}
   ```

3. **Token Refresh:**
   - When `accessToken` expires (401 error)
   - Client sends `refreshToken` to `/auth/refresh`
   - Server validates and returns new `accessToken`

4. **Token Structure:**
   ```json
   {
     "sub": "user-id",
     "email": "user@example.com",
     "role": "admin",
     "iat": 1234567890,
     "exp": 1234654290
   }
   ```

---

## 🚨 Error Handling

### Error Response Format
```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input data",
    "details": {
      "email": "Invalid email format",
      "password": "Password must be at least 8 characters"
    }
  },
  "metadata": {
    "timestamp": "2025-11-13T10:30:00Z",
    "requestId": "uuid",
    "version": "1.0.0"
  }
}
```

### Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `VALIDATION_ERROR` | 400 | Invalid input data |
| `AUTHENTICATION_ERROR` | 401 | Invalid credentials |
| `UNAUTHORIZED` | 401 | Missing or invalid token |
| `FORBIDDEN` | 403 | Insufficient permissions |
| `NOT_FOUND` | 404 | Resource not found |
| `CONFLICT` | 409 | Resource already exists |
| `RATE_LIMIT_EXCEEDED` | 429 | Too many requests |
| `INTERNAL_ERROR` | 500 | Server error |
| `DATABASE_ERROR` | 500 | Database connection error |

---

## 🔐 Security

### Authentication
- **JWT tokens** with short expiry (24h)
- **Refresh tokens** for extended sessions
- **Bcrypt hashing** for passwords (12 rounds)
- **Email verification** for new accounts

### Authorization
- **Role-based access control (RBAC)**
  - `admin` - Full access
  - `moderator` - Member and message management
  - `member` - Read-only access

### API Security
- **CORS** - Restricted to mobile app origins
- **Rate limiting** - 100 requests/minute per IP
- **Input validation** - Pydantic models
- **SQL injection protection** - SQLAlchemy ORM
- **HTTPS only** in production

### Data Protection
- **Password requirements:**
  - Minimum 8 characters
  - Must include uppercase, lowercase, number
- **Sensitive data encryption** in database
- **API key rotation** for third-party services

---

## 🚀 Deployment

### Environment Variables (`.env`)
```env
# Database
DATABASE_URL=mysql://user:pass@host:port/dbname

# Security
JWT_SECRET=your-secret-key-here
JWT_EXPIRES_IN=24h
JWT_REFRESH_EXPIRES_IN=7d
BCRYPT_SALT_ROUNDS=12

# Server
API_HOST=0.0.0.0
API_PORT=8000
DEBUG=false
ALLOWED_ORIGINS=https://caresphere.ekddigital.com,https://app.caresphere.ekddigital.com

# Features
ENABLE_DEMO_DATA=false
ENABLE_ANALYTICS=true
```

### Deployment Platforms
- **Railway** - Easy Python deployment
- **Heroku** - Free tier available
- **DigitalOcean App Platform** - $5/month
- **AWS Elastic Beanstalk** - Scalable production
- **Google Cloud Run** - Serverless option

### Production Checklist
- [ ] Set `DEBUG=false`
- [ ] Use strong `JWT_SECRET`
- [ ] Enable HTTPS
- [ ] Set up database backups
- [ ] Configure logging (Sentry, CloudWatch)
- [ ] Set up monitoring (UptimeRobot)
- [ ] Configure CORS properly
- [ ] Enable rate limiting
- [ ] Set up CI/CD pipeline

---

## 📦 Project Structure (Python/FastAPI)

```
caresphere-api/
├── app/
│   ├── __init__.py
│   ├── main.py                 # FastAPI app entry point
│   ├── config.py               # Configuration settings
│   ├── database.py             # Database connection
│   │
│   ├── models/                 # SQLAlchemy models
│   │   ├── __init__.py
│   │   ├── user.py
│   │   ├── member.py
│   │   ├── message.py
│   │   ├── template.py
│   │   └── automation.py
│   │
│   ├── schemas/                # Pydantic schemas
│   │   ├── __init__.py
│   │   ├── auth.py
│   │   ├── member.py
│   │   ├── message.py
│   │   └── common.py
│   │
│   ├── api/                    # API routes
│   │   ├── __init__.py
│   │   ├── auth.py
│   │   ├── members.py
│   │   ├── messages.py
│   │   ├── templates.py
│   │   ├── automation.py
│   │   └── analytics.py
│   │
│   ├── services/               # Business logic
│   │   ├── __init__.py
│   │   ├── auth_service.py
│   │   ├── member_service.py
│   │   ├── message_service.py
│   │   └── automation_service.py
│   │
│   ├── utils/                  # Utilities
│   │   ├── __init__.py
│   │   ├── security.py         # JWT, password hashing
│   │   ├── email.py            # Email sending
│   │   ├── validators.py       # Input validation
│   │   └── pagination.py       # Pagination helpers
│   │
│   └── middleware/             # Custom middleware
│       ├── __init__.py
│       ├── auth.py
│       └── error_handler.py
│
├── alembic/                    # Database migrations
│   ├── versions/
│   └── env.py
│
├── tests/                      # Unit tests
│   ├── test_auth.py
│   ├── test_members.py
│   └── test_messages.py
│
├── .env                        # Environment variables
├── .env.example                # Example env file
├── .gitignore
├── requirements.txt            # Python dependencies
├── alembic.ini                 # Migration config
├── README.md
└── Dockerfile                  # Docker configuration
```

---

## 📚 Dependencies (requirements.txt)

```txt
# Core Framework
fastapi==0.104.1
uvicorn[standard]==0.24.0
python-multipart==0.0.6

# Database
sqlalchemy==2.0.23
pymysql==1.1.0
alembic==1.12.1

# Authentication & Security
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
python-dotenv==1.0.0

# Data Validation
pydantic==2.5.0
pydantic-settings==2.1.0
email-validator==2.1.0

# Utilities
python-dateutil==2.8.2
pytz==2023.3
```

---

## 🎯 Next Steps

1. **Create GitHub repository:** https://github.com/Hetawk/caresphere-api.git
2. **Set up project structure** with all files from this design
3. **Implement authentication** endpoints first
4. **Create database models** and migrations
5. **Build member management** features
6. **Add messaging system**
7. **Implement templates and automation**
8. **Add analytics endpoints**
9. **Write tests**
10. **Deploy to production**

---

**End of API Design Document**  
**Version:** 1.0.0  
**Last Updated:** November 13, 2025  
**Repository:** https://github.com/Hetawk/caresphere-api.git
