# Mobile Interaction Matrix

Updated: 2026-08-26

This matrix covers the significant canonical journeys. The 208-screen detail
inventory is in `MOBILE_SCREEN_REGISTRY.md`.

| Screen / element | Type | Action / destination | Use case / API | Role / permission | Confirmation | Offline | Success | Error |
|---|---|---|---|---|---|---|---|---|
| Splash / continue | CONTINUE | Onboarding | RestoreSession | Visitor/member | No | Yes | Onboarding/session route | Local fallback |
| Sign In / Sign In | SUBMIT | `/verify-phone` | MobileLogin | Visitor | No | No | Verification | Integration unavailable |
| Verification / Continue | SUBMIT | MFA/setup | VerifyChallenge | Visitor | No | No | Next setup step | Validation/API error |
| Module Hub / cards | NAVIGATE | Church, Mission, KCA, Press | Capabilities | Authenticated roles | No | Partial | Module dashboard | Restricted state |
| Discover / church | NAVIGATE | Dynamic church detail alias | listChurches/getChurch | Public | No | Cached-safe | Detail | Not found/unavailable |
| Give / Give | PAY | `/payments/processing` | PaymentRepository.initiate | `giving.create` | Provider | No | Server-owned pending/success | Payment failure |
| Payment / receipt | NAVIGATE/DOWNLOAD | Receipt/history | getTransaction/getReceipt | Own payment | No | Receipt only | Receipt | Forbidden/not found |
| Events / register | NAVIGATE/SUBMIT | Detail → register → payment → ticket | EventRepository | Public/member | Payment | Partial | Registration/ticket | Validation/payment error |
| Mission / Add Soul | CREATE | `/mission/souls/add` | MissionRepository.createSoul | `mission.souls.create` | No | Draft | Server record | Conflict/retry |
| KCA / Enrol | WORKFLOW_TRANSITION | `/kca/enrollment/1..8` | KcaRepository | `kca.enrollment.create` | Final review | Draft | Server application | Validation/restricted |
| KCA / module | CONTINUE | Lesson/assignment/evidence | EvaluateModulePrerequisites | `kca.modules.view` | No | Downloaded content | Server unlock | Locked/needs attention |
| Press / publication | NAVIGATE/DOWNLOAD | Resource/player/downloads | PressRepository | Public/entitled | Download options | Yes | Open/downloaded | Not found/storage error |
| Notification row | NAVIGATE | Resource-specific route | resolveDestination | Notification owner | No | No | Authorized destination | Restricted/unavailable |
| Unknown deep link | NAVIGATE | `/content/unavailable` state | Route resolver | Any | No | Yes | Safe fallback | Safe fallback |
| Sync Pending / Sync Now | RETRY | Remain pending until server response | SyncRepository.requestSync | `sync.queue.view_own` | No | Queue | Server-confirmed sync | Conflict/offline |
| Upload Failed / Retry | RETRY | Upload progress only after accepted retry | SyncRepository.retry | `uploads.retry_own` | No | Queue | Progress/server result | Upload failure |
| Upload Progress / pause | UPLOAD | Pause/resume item | SyncRepository pause/resume | `uploads.view_own` | No | Queue | Continued progress | Retry/failure |
| Downloads / Clear Cache | DELETE | Clear temporary cache | Press/KCA local repository | `downloads.manage_own` | Local | Yes | Cache cleared | Storage failure |
| Low Bandwidth / Save | SAVE | Persist media preferences | PreferenceRepository | User | No | Yes | Saved locally/server later | Storage/API error |
| Protected route guard | AUTHORIZE | Render or restricted state | AuthorizationGateway | Exact route permission | No | Cached decision prohibited | Allowed screen | 401/403/restricted |

## Action contract rule

No unavailable backend operation transitions to a success screen. It opens the
shared integration-required state or remains in its pending/error state. The
Laravel adapter must replace repository/transport contracts without changing
the routes or visual shells.
