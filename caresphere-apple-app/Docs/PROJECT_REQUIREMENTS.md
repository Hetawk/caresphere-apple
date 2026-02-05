# CareSphere Platform Requirements and Architecture Overview

> Prepared for rebuilding the platform in a new framework while preserving current functionality and vision. Based on repository `church_connect` (branch `main`, November 2025 code snapshot).

---

## 1. Mission & Value Proposition

- **Purpose**: Equip mission-driven teams across faith-based, workplace, and broader community contexts with a digital hub for holistic member care (spiritual, physical, emotional, moral) and consistent outreach.
- **Primary Outcomes**: Centralized relationship records, multi-channel communication, automated care workflows, and actionable analytics for organizational leaders in any sector.
- **Core Audiences**: Church welfare teams, workplace care and wellness groups, non-profit care organizations, chaplaincy units, and community outreach programs needing scalable, multi-tenant tooling.

## 2. User Roles & Permissions

Defined within the shared user model under `lib/shared/models` and enforced by the authentication provider inside `lib/features/authentication/providers`:

- `super_admin`: Platform governance, subscription controls, full access across tenants.
- `admin`: Organization-level management of users, members, messaging, automation, analytics.
- `ministry_leader`: Leads specific ministries; manages members, templates, automation (limited scope).
- `volunteer`: Performs delegated care tasks (view/send messages, manage templates).
- `member`: Self-service access to personal profile (future module) and engagement history.

Each role exposes explicit permission flags (e.g., `manage_members`, `send_messages`, `view_analytics`) to support fine-grained authorization checks during the rebuild.

## 3. Core Functional Pillars

Derived from the root-level README, Flutter feature scaffolding, and backend route organization.

### 3.1 Member Care & Engagement

- Rich member profiles with demographics, spiritual journey data, tags, and care notes (see the SQL schema in the `database` directory for `members`, `member_notes`, `member_activities`).
- Care workflows: prayer requests, visitations, welfare follow-ups, and life event tracking (birthdays, anniversaries, baptisms).
- Household & relationship mapping for pastoral context.

### 3.2 Multi-Channel Messaging

- Channels: SMS, email, WhatsApp, push notifications, in-app messaging, voice (abstracted in the messaging route module under `api/routes`).
- Template management with dynamic variables (shared message template model within `lib/shared/models` and corresponding route module in `api/routes`).
- Delivery tracking (success, failures, engagement) via `messages` and `message_recipients` tables.

### 3.3 Automation & Workflows

- Trigger-based rules (birthdays, new members, attendance changes) and scheduled campaigns (automation route module plus the `automation_rules` schema).
- Automated reminders, follow-ups, welcome sequences, and prayer chains.
- Escalation paths for urgent requests.

### 3.4 Analytics & Reporting

- Dashboards within `lib/features/dashboard/screens` with placeholders for metrics: member growth, care requests, messaging volume, engagement trends.
- Future predictive analytics for disengagement risk and ministry effectiveness (outlined in README).

### 3.5 Organization Management

- Multi-tenant isolation with customizable branding, feature toggles, custom fields, and integration preferences (`organizations` table, `OrganizationModel` in Flutter).
- Subscription and plan awareness for scaling to SaaS delivery.

## 4. Frontend Architecture (Flutter Implementation)

Located under `lib/`.

### 4.1 Framework & Tooling

- **Flutter** with Riverpod for reactive state management and GoRouter for declarative navigation.
- Modular feature-based architecture with clear separation of concerns across authentication, dashboard, analytics, member management, messaging, automation, templates, and organization modules.

### 4.2 Application Shell

- Main application wrapper implementing MaterialApp.router pattern with global theming system.
- Router configuration defining authentication-gated routes and hierarchical navigation structure.
- Bottom navigation shell orchestrating high-level module access (Dashboard, Members, Messages, Analytics, Settings).

### 4.3 State & Services

- **Authentication System**: Handles complete user lifecycle (login/signup/logout), secure token persistence, OAuth integration, and permission-based access control.
- **HTTP Client Architecture**: Centralized API service with automatic authentication injection, comprehensive error handling, and configurable logging for debugging.
- **Service Layer Pattern**: Specialized services for each domain (auth, members, messages, etc.) providing clean abstraction over API endpoints.
- **Shared Data Models**: Standardized model definitions ensuring type safety and consistent data contracts across all feature modules.

### 4.4 UI Architecture & Design Patterns

- **Dashboard-Centered Design**: Primary interface providing statistical overview, quick actions, activity feeds, and contextual navigation to specialized modules.
- **Responsive Layout System**: Adaptive UI components that scale across mobile, tablet, and desktop form factors with consistent visual hierarchy.
- **Design System Foundation**: Unified theme architecture covering typography, color schemes, spacing standards, and reusable component library for brand consistency.

### 4.5 Frontend Implementation Strategy

- **State Management Pattern**: Leverage reactive state architecture (Riverpod or equivalent) with clear data flow and minimal boilerplate.
- **Service Integration**: Implement robust API communication layer with automatic retry logic, offline caching, and error recovery mechanisms.
- **Permission-Aware UI**: Design role-based interface components that dynamically show/hide features based on user permissions and organizational settings.
- **Core Screen Requirements**:
  - Member management with advanced filtering and bulk operations
  - Message composer with template integration and delivery tracking
  - Analytics dashboards with real-time metrics and trend visualization
  - Automation workflow builder with drag-and-drop rule configuration
  - Organization settings with tenant customization and feature toggles
- **Offline Capability**: Implement local data persistence for critical workflows, draft management, and seamless online/offline transitions.

## 5. Backend Architecture (Node/Vercel API)

Located under `api/` with serverless handlers compatible with Vercel.

### 5.1 Entry Points & Routing

- Each handler in `api` (auth, messages, members, templates, automation, analytics, users) proxies to `api/server`, which delegates based on path segment.
- `server` performs manual routing using URL inspection and dispatches to feature modules under `api/routes`.

### 5.2 Feature Handlers (`api/routes/*`)

- **Auth route module**: Email/password login with bcrypt, registration, Google auth fallback, JWT issuance, user profile retrieval. Requires `DATABASE_URL` and `JWT_SECRET` env vars.
- **Users route module**: List/update users with role and activation changes; supports pagination and filtering by role/org.
- **Members route module**: CRUD for member records, status updates, care notes (check module for sub-features).
- **Messages route module**: CRUD operations, message status transitions, priority handling, JSON-encoded recipient arrays.
- **Templates route module**: Manage templated content with categories, variables.
- **Automation route module**: Manage automation rules and logs.
- **Analytics route module**: Aggregated queries (placeholder or initial metrics).

> **Note**: Current `ApiResponse` imports expect helper functions (`success`, `error`, `notFound`, etc.) from `api/_lib/response`. The module exports functions but not the `ApiResponse` object used by routers; this mismatch must be resolved during the rebuild.

### 5.3 Shared Libraries (`api/_lib`)

- Database helper: MySQL connection pooling via `mysql2/promise`, exposing `getConnection`, `query`, and transaction helpers.
  - `createConnectionFromEnv` referenced across routes is missing in the exported object—rewriters must add a factory that reads environment variables and returns connections (likely intended to wrap `getConnection`).
- Auth helper: JWT generation/verification, password utilities, middleware scaffolding for protected routes and permission checks.
- Response helper: CORS, response formatting, error helpers, pagination utilities.

### 5.4 Environment & Secrets

- `.env` is not included; runtime expects (via README and code): `DATABASE_URL`, `JWT_SECRET`, optional `DB_CONNECTION_LIMIT`, CORS origin, provider credentials (SendGrid, Twilio, etc.).
- `AppConfig` uses compile-time `String.fromEnvironment` for Flutter to inject matching base API URLs.

### 5.5 Deployment Considerations

- Vercel serverless functions with Node 18 runtime (default). Each handler must remain stateless and rely on pooled MySQL connections.
- Known issue: local `/api/*` calls returning 404 suggests Vercel routing misconfiguration or missing default export functions. Validate rewriting proxies and ensure `module.exports = async (req, res)` shape per file.

## 6. Data Model & Persistence

Outlined in the SQL schema within the `database` directory and mirrored by Flutter models.

| Domain        | Key Tables/Models                                                        | Purpose                                                                       |
| ------------- | ------------------------------------------------------------------------ | ----------------------------------------------------------------------------- |
| Users & Auth  | `users`, `UserModel`                                                     | Authentication, role-based permissions, token issuance.                       |
| Organizations | `organizations`, `OrganizationModel`                                     | Tenant-specific branding, settings, feature toggles.                          |
| Members       | `members`, `member_notes`, `member_activities`                           | Member profiles, care history, ministry engagement logs.                      |
| Messaging     | `messages`, `message_recipients`, `message_templates`, `MessageTemplate` | Multi-channel communication management with delivery tracking and templating. |
| Automation    | `automation_rules`, `automation_logs`                                    | Trigger definitions, workflow actions, execution logs.                        |
| Analytics     | Derived tables/views (planned)                                           | Engagement metrics, ministry dashboards.                                      |

Additional JSON fields (tags, variables, settings) enable flexible customization per organization.

## 7. Integrations & Third-Party Services

Platform integration requirements and external service patterns:

- **Communication Providers**: Multi-provider architecture supporting email (SendGrid/Mailgun), SMS (Twilio/Vonage), WhatsApp Business API, and push notification services with automatic failover capabilities.
- **Cloud Storage & Productivity**: Integration layers for Google Workspace (Drive, Sheets, Contacts), Microsoft 365 (SharePoint, OneDrive), Dropbox, and device contact synchronization.
- **Content & Reference APIs**: Scripture integration through ESV API, Bible Gateway, or YouVersion for devotional content and reference materials.
- **Infrastructure Services**: Background processing through Redis or AWS SQS for message queues, caching layers for performance optimization.

Rebuild must implement provider abstraction patterns enabling organizations to configure preferred services without code changes.

## 8. Automation, Analytics, and Personalization Requirements

- **Automation Triggers**: Event-driven (birthdays, new members, attendance gaps), schedule-based (weekly devotionals), manual triggers from dashboard.
- **Actions**: Send message, create care note, assign follow-up, notify leaders, escalate urgent cases.
- **Analytics Dashboards**: KPIs for member growth, care response times, message performance, volunteer workload.
- **Personalization**: Dynamic placeholders in templates (`MessageTemplate.placeholders`), preference-based scheduling, segmentation via tags and engagement scores.

## 9. Non-Functional Requirements

- **Scalability**: Multi-tenant support with isolated data and configuration per organization.
- **Security**: JWT-based auth, hashed passwords (bcrypt), optional MFA, permission checks for sensitive actions.
- **Reliability**: Database transactions for critical flows, retry logic for communication providers, audit logging for care actions.
- **Extensibility**: Modular code organization (both Flutter and Node) to enable new feature packages.
- **Internationalization**: Support for multiple languages/time zones (see `OrganizationSettings.defaultLanguage`, `defaultTimeZone`).

## 10. Build, Tooling, and Infrastructure

Development and deployment requirements:

- **Frontend Toolchain**: Flutter development environment with Dart SDK, package management via pub, and HTTP client libraries for API integration.
- **Backend Infrastructure**: Node.js serverless runtime (Vercel-compatible), managed MySQL database service, comprehensive environment variable management for service credentials.
- **Development Automation**: Database initialization scripts, data seeding utilities, deployment automation for consistent environment provisioning.
- **CI/CD Pipeline**: Automated testing, code quality checks, multi-environment deployment with GitHub Actions integration (planned enhancement).

## 11. Known Gaps & Technical Debt (To Address During Rebuild)

1. **Vercel 404s**: Endpoint consolidation introduced routing issues—verify exports and rewrites.
2. **Missing Helpers**: `createConnectionFromEnv` and `ApiResponse.methodNotAllowed` referenced but not implemented; rebuild must supply equivalents.
3. **Generated JSON Artifacts**: Regenerate the JSON serialization output after manual model changes to prevent duplication and keep serialization consistent.
4. **Placeholder Screens**: Most functional modules still display placeholders. UI/UX work is required for production readiness.
5. **Error Handling Consistency**: API responses mix direct SQL errors and sanitized messages; define standardized error contracts.
6. **Tests**: No automated tests exist for either Flutter or Node layers—add unit/integration tests in the new implementation.
7. **Infrastructure**: README references microservices, queues, and caching not yet implemented; treat as future phases or align rebuild scope accordingly.

## 12. Recommended Rewrite Roadmap

1. **Discovery & Alignment**

   - Validate stakeholder priorities: initial MVP vs. full README scope.
   - Confirm required channels/providers for launch to avoid over-engineering.

2. **Domain Modeling**

   - Recreate shared DTOs/models based on `lib/shared/models` and the SQL schema in the `database` directory.
   - Define API contract (OpenAPI/GraphQL) before implementing new backend.

3. **Backend Implementation**

   - Choose framework (e.g., NestJS, FastAPI, AdonisJS) supporting modular architecture, JWT auth, and MySQL ORM.
   - Implement feature modules aligning with current routes (auth, users, members, messages, templates, automation, analytics).
   - Add integration layers for messaging providers and Google/Microsoft APIs (stub for now if out of scope).
   - Provide health checks, logging, metrics, and centralized error handling.

4. **Frontend Implementation**

   - Replicate navigation schema and state management using chosen framework (Flutter, React Native, etc.).
   - Build dashboard, member management, messaging composer, automation builder, analytics views, organization settings screens.
   - Implement auth flows with token storage, refresh handling, and role-based UI gating.
   - Establish design system (typography, color, spacing, components) consistent with `AppTheme` inspiration.

5. **Data & Migration**

   - Produce migration scripts for existing MySQL schema.
   - Define seeding strategy for default templates, organizations, admin users.
   - Plan data import/export capabilities (CSV, cloud storage connectors).

6. **Testing & QA**

   - Unit tests for services and widgets.
   - Integration tests for endpoints (auth, members, messaging).
   - End-to-end scenarios: onboarding a new organization, sending a care message, resolving prayer request.

7. **Deployment & Monitoring**
   - Containerize backend services or configure serverless equivalents.
   - Setup CI/CD pipelines, environment promotion strategy, observability (logs, metrics, alerts).

## 13. Documentation & Handover Expectations

- Maintain updated architectural diagrams, module descriptions, and environment setup instructions.
- Provide API reference (OpenAPI/Swagger), data dictionary, and integration guides.
- Document permission matrix mapping to UI elements and API endpoints.
- Include operational runbooks for incident response (e.g., provider outages, database failover).

---

### Summary

The CareSphere blueprint, informed by the existing ChurchConnect repository, captures a comprehensive vision for ministry-focused member care, messaging, and automation. While many modules are still stubs, the Flutter scaffolding, Node handlers, and SQL schema provide clear guidance for a full rebuild. The new implementation must honor multi-tenant requirements, robust role-based access, automation workflows, and deep integrations—all articulated in the current codebase and README. Use this document as the blueprint when standing up the next-generation system in your framework of choice.
