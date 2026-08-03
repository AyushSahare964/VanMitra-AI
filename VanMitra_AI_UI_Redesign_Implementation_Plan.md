# VanMitra-AI — Unified UI Redesign & Implementation Plan

**Goal**: Keep the government-trust visual language you already have (Govt Blue header, Saffron accents, white high-contrast surfaces) but evolve it into **one consistent design system** — a shared set of components, spacing, and elevation rules — so every one of the 24 screens looks like it belongs to the same app instead of being styled screen-by-screen.

This is a refinement, not a rebuild: same palette family, same trust cues, tighter execution.

---

## 1. What Changes vs. What Stays

**Stays** (these are working — don't touch):
- Saffron (`#FF7A00`) as the single high-energy CTA accent
- All-white/light, high-contrast surface for sunlight legibility
- 4-language support pattern, TTS read-aloud affordance
- Green/Amber/Red semantic status system
- Bottom nav with 5 tabs (Dashboard, Claims, Sabha, Map, Profile)

**Changes**:
1. **Forest Green becomes the primary brand identity**, replacing Navy/Govt Blue as the dominant chrome color (header, nav, primary surfaces). This is a much more honest identity for "VanMitra" (forest companion) than a generic government navy — and paired with Saffron it still reads as an official Indian institutional palette (green + saffron), just literally about forests now instead of a MAHA-DBT copy. Govt Blue doesn't disappear — it's demoted to a secondary "institutional/legal" accent used specifically in the Legal Rights Hub and official document stamps, where the government-trust cue is actually load-bearing.
2. **One card system, not three.** Right now stat cards, action rows, and dashboard tiles each look slightly different (different radius, different shadow, different padding). Unify into a single `AppCard` primitive with 2–3 variants.
3. **A real spacing scale.** Replace ad-hoc padding (`16`, `12`, `20` mixed) with an 8pt grid (`4/8/12/16/24/32`).
4. **Elevation instead of flat blocks.** Current UI is mostly flat white-on-white with color blocks (see screenshot: 4 stat tiles all sit at the same visual depth as the header). Introduce a subtle 2-tier elevation system so hierarchy reads at a glance — header > primary CTA > cards > list rows.
5. **Header becomes a reusable component**, not a one-off per screen — currently each screen seems to rebuild its own top bar treatment.
6. **Icon + status color consistency** — stat icons (claims/meetings/resolutions/members) currently use 4 different pastel backgrounds with no shared logic; tie icon-tile color to the KPI's semantic meaning instead of arbitrary pastels.
7. **Typography scale** — define 6 sizes instead of per-screen font choices, so headers, labels, and body copy are predictable everywhere.
8. **Empty/loading states standardized** — the screenshot shows `"-"` for Total Claims and Meetings; every screen needs one shared empty-state pattern instead of ad-hoc dashes/blanks.

---

## 2. Design Tokens (Refined)

### 2.1 Color

Reorganized by *role*, with Forest Green now carrying the brand weight and a few additions for elevation/neutral hierarchy that were missing:

| Role | Token | Hex | Usage |
|---|---|---|---|
| **Brand primary** *(new)* | `forestCanopy` | `#1B4332` | Header, bottom nav base, primary surfaces — the app's dominant color |
| **Brand mid** *(new)* | `forestSage` | `#2D6A4F` | Gradients (hero cards), secondary buttons, pressed/active states |
| **Brand tint** *(new)* | `forestMist` | `#95D5B2` | Light background tints, subtle badge fills, onboarding accents |
| Brand accent | `saffron` | `#FF7A00` | CTAs, active tab indicator, ticker bar — unchanged, now paired against green instead of navy |
| Institutional accent *(demoted)* | `govtBlue` | `#0B3D91` | Legal Rights Hub, official document stamps/seals, GPS-verified badge context — used narrowly, not as chrome |
| Success | `successGreen` | `#2E7D32` | Approved, quorum met — kept visually distinct (warmer, brighter) from `forestCanopy` so status ≠ brand chrome |
| Warning | `warningAmber` | `#F2A900` | Pending, borderline quorum |
| Danger | `alertRed` | `#D32F2F` | Rejected, tamper detected |
| Women quorum | `womenPurple` | `#7B1FA2` | Rule 4 tracking |
| ST | `stCyan` | `#00838F` | ST representation |
| PVTG | `pvtgOrange` | `#E65100` | PVTG flags |
| Face verified | `faceDeepPurple` | `#512DA8` | Biometric stamp |
| GPS verified | `gpsBlue` | `#1976D2` | Geofence badge |
| **Surface base** *(new)* | `surfaceBase` | `#F4F7F5` | Screen background — faint green-gray instead of pure white or blue-gray (see 2.3) |
| **Surface card** | `surfaceCard` | `#FFFFFF` | Card / sheet surface |
| **Surface sunken** *(new)* | `surfaceSunken` | `#EAF2ED` | Stat tile backgrounds, input backgrounds — faint forest tint |
| Divider | `divider` | `#DCE7E1` | Borders, gridlines — warmed slightly toward green from the old slate |
| Text primary | `textPrimary` | `#0F172A` | Body copy |
| Text secondary | `textSecondary` | `#475569` | Metadata, timestamps |
| Text on brand | `textOnBrand` | `#FFFFFF` | Text over Forest Canopy / Saffron |

> **Why Forest Canopy over Navy**: `#1B4332` is dark enough to hold the same contrast role Govt Blue played (white text on top, strong header presence) but reads immediately as "forest" rather than "generic e-governance portal." It's deliberately deep/desaturated (not a bright green) so it still feels authoritative, not playful.
>
> **Why `surfaceBase` ≠ pure white**: in the screenshot, the header, ticker, and page background are all near-identical whites/blues with no separation — the stat cards visually merge into the page. A faint green-tinted neutral (`#F4F7F5`) behind white cards restores depth *and* reinforces the forest theme ambiently, without sacrificing contrast (still passes WCAG AA against `textPrimary`).
>
> **Why Success Green ≠ Forest Canopy**: tempting to unify them since "approved claim" and "forest" are thematically aligned, but keeping brand chrome and status color visually distinct (deep desaturated green vs. brighter warmer green) prevents a claim card from looking like "part of the navigation" at a glance.

### 2.2 Spacing (8pt grid)

| Token | Value | Use |
|---|---|---|
| `space.xs` | 4px | Icon-to-label gaps |
| `space.sm` | 8px | Inline element gaps |
| `space.md` | 16px | Card padding, section gaps |
| `space.lg` | 24px | Section-to-section spacing |
| `space.xl` | 32px | Screen top/bottom margins |

### 2.3 Elevation (2-tier system)

| Level | Shadow | Used for |
|---|---|---|
| `flat` | none, 1px `divider` border | List rows, dividers |
| `raised` | `0 2px 8px rgba(15,23,42,0.06)` | Cards, stat tiles, bottom sheets |
| `floating` | `0 4px 16px rgba(15,23,42,0.12)` | FAB, active modals, dropdown menus |

### 2.4 Typography Scale

| Token | Size / Weight | Use |
|---|---|---|
| `display` | 24px / 700 | "Hello, {Name}" greeting, screen hero titles |
| `title` | 18px / 600 | Section headers ("Admin Actions") |
| `subtitle` | 15px / 500 | Card titles ("Schedule Meeting") |
| `body` | 14px / 400 | Descriptions, form text |
| `caption` | 12px / 400 | Metadata, timestamps |
| `stat` | 28px / 700 | KPI numbers (the "500", "1", "-") |

### 2.5 Radius

| Token | Value | Use |
|---|---|---|
| `radius.sm` | 8px | Chips, badges |
| `radius.md` | 12px | List rows, buttons |
| `radius.lg` | 16px | Cards, stat tiles, sheets |

---

## 3. Shared Component Library (`lib/widgets/common/`)

This is the actual "one UI" — every screen composes from these instead of custom-building layout each time.

| Component | Replaces | Notes |
|---|---|---|
| `AppHeader` | Per-screen top bar | Forest Canopy background, logo, village name subtitle, language switcher, avatar. Slot for optional back button. Used on all 24 screens. |
| `NoticeTicker` | Dashboard-only banner | Reusable severity-colored ticker (info/warning/critical), dismissible, works on any screen that needs system messaging. |
| `GreetingHero` | Dashboard greeting card | Avatar + name + role/village line, on `forestCanopy`→`forestSage` gradient at `raised` elevation (currently flat solid navy). |
| `StatTile` | 4 dashboard KPI boxes | Fixed icon-tile + number (`stat` token) + label. Icon background color driven by KPI semantic (Claims → forestCanopy tint, Meetings → successGreen tint, Resolutions → saffron tint, Members → womenPurple tint) instead of arbitrary pastels. |
| `ActionListItem` | Admin Actions rows | Icon tile + title + subtitle + chevron, `raised` elevation, consistent 16px padding, used for every "tap to go deeper" list across all modules (Admin Actions, Legal Hub accordion entries, Alert History rows, etc.). |
| `StatusBadge` | Ad-hoc colored text/labels | Pill badge with semantic color (Approved/Pending/Rejected, Quorum Met/Not Met, Synced/Pending Sync). One component, all 24 screens. |
| `PrimaryButton` / `SecondaryButton` | Inconsistent CTA styling | Primary = Saffron fill; Secondary = Govt Blue outline. Full-width by default on mobile. |
| `EmptyState` | Blank `"-"` values | Icon + short message + optional CTA ("No claims yet — File your first claim"). Replaces silent dashes. |
| `SyncStatusChip` | Header sync indicator | Small chip: Synced (green dot) / Pending (amber dot, count) / Offline (grey dot) — same component in header and in Profile's Sync Audit card. |
| `BottomNavBar` | Existing nav | Same 5 tabs, but active tab now uses Saffron **fill** on the icon glyph + label instead of just label color change, for better sunlight visibility. |

### Example: unified card contract (Flutter)

```dart
class AppCard extends StatelessWidget {
  final Widget child;
  final AppElevation elevation; // flat | raised | floating
  final EdgeInsets padding;

  const AppCard({
    required this.child,
    this.elevation = AppElevation.raised,
    this.padding = const EdgeInsets.all(AppSpacing.md),
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      boxShadow: elevation.shadow,
    ),
    child: child,
  );
}
```

Every stat tile, action row, and dashboard card becomes `AppCard(child: ...)` with a variant — eliminating the current mix of `Container`, `Card`, and manually-decorated `Box` widgets that produce slightly different corner radii and shadows across screens.

---

## 4. Applying the System to the Dashboard (Your Screenshot)

| Current element | New treatment |
|---|---|
| Navy header bar | `AppHeader` on `forestCanopy` — same layout and role, new brand color, componentized |
| Blue ticker banner | `NoticeTicker(severity: info)` — keep `gpsBlue`/`govtBlue`-family tint for "info" severity so it still reads as an official notice against the new green chrome |
| "Hello, Sahare Ayush" navy card | `GreetingHero` — `forestCanopy`→`forestSage` gradient at `raised` elevation so it lifts off the `surfaceBase` background instead of sitting flush |
| 4 stat boxes (Claims/Meetings/Resolutions/Members) | `StatTile` × 4 in a `Wrap`/`GridView`, semantic icon-tile colors, `EmptyState`-aware (show "No claims yet" instead of "-" on tap, or a light skeleton while loading) |
| Admin Actions list | `ActionListItem` × N — already close to right, just standardize padding/elevation/icon-tile color to match `StatTile` logic |
| Bottom nav | `BottomNavBar` with filled active-icon treatment |

Net effect: same layout, same information, but the page gains visible depth (`surfaceBase` behind `raised` cards), the chrome now says "forest" instead of "generic government portal," and every number/icon follows one predictable color rule instead of designer's-choice pastels.

---

## 5. Screen-by-Screen Component Map (all 24 screens)

| Module | Screens | Primary shared components used |
|---|---|---|
| Onboarding | Splash, Language, Registration | `AppHeader` (minimal), `PrimaryButton`, form fields on `surfaceSunken` |
| Dashboards | Villager Home, Admin Home, Village Summary | `AppHeader`, `NoticeTicker`, `GreetingHero`, `StatTile`, `ActionListItem` |
| Claims (Module A) | My Claims, Claim Type, Evidence Checklist, AI Claim Form, Draft Preview, Rejection/Appeal | `AppHeader`, `StatusBadge` (claim status), `ActionListItem` (evidence rows), `PrimaryButton`, countdown variant of `StatusBadge` for appeal window |
| Atlas (Module B) | GIS Boundary Map, Alert Detail, Alert History | `AppHeader`, `StatusBadge` (tier: green/amber/red), `ActionListItem` (alert history rows) |
| Sabha (Module C) | FRC Hub, Member Enrolment, Upcoming/Meeting Detail, Check-in, Quorum Monitor, Resolution Recorder, Ledger/MoM Viewer | `AppHeader`, `ActionListItem`, `StatusBadge` (verified/quorum), `StatTile` (quorum gauges reuse the same tile shell), `SyncStatusChip` |
| Legal & Profile | Legal Hub, Profile/Settings | `AppHeader`, `ActionListItem` (accordion rows), `SyncStatusChip`, `EmptyState` (sync log empty) |

Every screen pulls from the same ~10 components in section 3 — nothing screen-specific gets custom-built except the map viewer canvas and the recorder waveform, which are inherently unique widgets.

---

## 6. Implementation Plan

### Phase 0 — Foundation (no visual change yet)
1. Create `lib/theme/app_colors.dart`, `app_spacing.dart`, `app_radius.dart`, `app_typography.dart`, `app_elevation.dart` — pure token files, no widgets.
2. Wire `AppColors`/`AppTypography` into a single `ThemeData` in `lib/theme/app_theme.dart` so `Theme.of(context)` reflects the new tokens app-wide.
3. No screen changes yet — this phase is invisible to users, just sets up the plumbing.

### Phase 1 — Shared Component Library
1. Build `lib/widgets/common/`: `AppHeader`, `AppCard`, `StatTile`, `ActionListItem`, `StatusBadge`, `PrimaryButton`, `SecondaryButton`, `EmptyState`, `SyncStatusChip`, `NoticeTicker`, `BottomNavBar`, `GreetingHero`.
2. Write each with a small Storybook-style demo screen (`/dev/components`) so design review happens once, centrally, instead of per-screen.

### Phase 2 — Migrate Dashboards First (highest-traffic screens)
1. Villager Home, Admin Home, Village Summary — rebuild using only Phase 1 components.
2. This is your fastest visible win and validates the component library against real data (loading/empty/error states) before rolling out further.

### Phase 3 — Migrate by Module
Order by usage frequency / offline-criticality:
1. **Module A (Claims)** — highest citizen-facing traffic
2. **Module C (Sabha)** — highest admin-facing complexity (quorum gauges, ledger)
3. **Module B (Atlas)** — map screens keep custom canvas, but wrap surrounding chrome (headers, alert cards) in shared components
4. **Legal & Profile** — lowest complexity, do last

### Phase 4 — Polish & Accessibility Pass
1. Verify all text/background pairs hit WCAG AA (especially `textSecondary` on `surfaceSunken`).
2. Confirm TTS read-aloud buttons exist on every screen using the new `AppHeader` slot for it, not ad-hoc placement.
3. Test on a low-end device in direct sunlight (or a brightness-simulated screenshot) to confirm the new `surfaceBase` gray doesn't reduce legibility versus the old pure-white.
4. Remove now-dead legacy styling code once every screen is migrated (avoid running two systems in parallel long-term).

### Suggested Folder Structure
```
lib/
  theme/
    app_colors.dart
    app_spacing.dart
    app_radius.dart
    app_typography.dart
    app_elevation.dart
    app_theme.dart
  widgets/
    common/
      app_header.dart
      app_card.dart
      stat_tile.dart
      action_list_item.dart
      status_badge.dart
      primary_button.dart
      secondary_button.dart
      empty_state.dart
      sync_status_chip.dart
      notice_ticker.dart
      bottom_nav_bar.dart
      greeting_hero.dart
  screens/
    onboarding/...
    dashboard/...
    claims/...
    atlas/...
    sabha/...
    legal/...
    profile/...
```

### Rollout Discipline
- **One PR per screen migration**, referencing this doc's component map (section 5) so reviewers can check "did this screen use shared components or invent new styling?"
- Freeze new ad-hoc `Container`/`BoxDecoration` styling in screen files once Phase 1 lands — any new screen work must consume `lib/widgets/common/`.
