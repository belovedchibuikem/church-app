# Mobile Interaction Audit

Updated: 2026-08-26

## Result

The application-wide static audit now reports **zero explicit empty or null
callbacks** for `onPressed` and `onTap`. Forty-one empty callbacks discovered
in the initial audit were replaced with either a canonical route/action or the
shared `fhcApiUnavailable` integration sheet. That sheet explicitly states
that no success state was created when Laravel/OpenAPI support is absent.

This closes the mechanical dead-callback gate. It does not claim that every
static fixture is bound to Laravel; those contract gaps remain in
`MOBILE_API_BINDING_MATRIX.md` and `KNOWN_GAPS.md`.

## Remediation register

| Screen ID / domain | Element type | Expected behavior | Implemented behavior | Permission / API dependency | Status |
|---|---|---|---|---|---|
| AUTH_SIGN_IN | Tabs/buttons | Register, recover, social auth | Sign-in navigates to verification; unavailable auth operations open an explicit integration sheet | Mobile auth OpenAPI incomplete | Safe / API blocked |
| PROFILE | Button | Edit profile | Explicit repository-integration sheet | `profile.update` / user API | Safe / API blocked |
| CHURCH_DISCOVERY_DETAIL | Buttons | Open detail, call, directions, website, share | Canonical detail route; native/API-dependent actions expose integration state | Public church API exists; native intents absent | Wired |
| CHURCH_LEADER | Buttons/filters | Members, ministries, documents, applications, attendance | Canonical routes where present; unavailable create/download/scan actions expose integration state | Scoped Church APIs absent | Wired / API blocked |
| EVENTS | Cards/buttons | Detail, registration, share | Detail and registration routes wired; share exposes integration state | Public event API exists | Wired |
| GIVING_PAYMENTS | CTA/list rows | Initiate, transaction detail | Give opens Payment Processing; history opens transaction detail; success remains server-addressable only | Payment API absent | Safe / API blocked |
| PRAYER_BIBLE_SERMONS | Rows/cards | Detail, reader/player, filters | Existing destinations wired where present; missing content operations expose integration state | Content/prayer APIs absent | Wired / API blocked |
| MISSION | CTAs | Soul capture, report, share | Soul capture route wired; report/share expose integration state | Operational Mission API absent | Wired / API blocked |
| KCA | CTA/chat | Enrol, learn, call, attach, send | Enrolment/modules routes wired; communications expose integration state | KCA lifecycle/chat APIs absent | Wired / API blocked |
| PRESS | Cards/buttons | Open, read, download, filter | Publication and download routes wired; unsupported filters expose integration state | Public Press API exists; download API absent | Wired |
| OFFLINE_SYNC | Retry/pause/preferences | Retry safely, pause/resume, save local preferences | Controls are interactive; Sync Now remains pending without server confirmation; upload pause/resume works locally | Sync/upload API and durable store absent | Safe / API blocked |
| ROUTER | Deep links | Resolve aliases/resources; invalid fallback | Canonical aliases and resource-path normalization added; unknown paths show Content Not Available | Platform link association absent | App-wired |

## Automated audit command

```powershell
rg -n "onPressed:\s*\(\)\s*\{\s*\}|onTap:\s*\(\)\s*\{\s*\}|onPressed:\s*null|onTap:\s*null" lib
```

Expected result: no matches.

## Remaining interaction risks

- Some static segmented filters change local selection but cannot query real
  data until repositories are bound.
- External share/call/directions/file-picker behavior requires approved native
  packages and platform projects.
- Entity routes normalize IDs to canonical screens, but the current screens
  still show fixtures because record repositories are not connected.
- Logout cannot revoke a real token until the mobile auth client and secure
  token store are implemented.

These are explained blockers, not silent or fake-success interactions.
