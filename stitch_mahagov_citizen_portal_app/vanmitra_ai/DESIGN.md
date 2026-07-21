---
name: VanMitra-AI
colors:
  surface: '#f8f9fa'
  surface-dim: '#d9dadb'
  surface-bright: '#f8f9fa'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f4f5'
  surface-container: '#edeeef'
  surface-container-high: '#e7e8e9'
  surface-container-highest: '#e1e3e4'
  on-surface: '#191c1d'
  on-surface-variant: '#3f4a3a'
  inverse-surface: '#2e3132'
  inverse-on-surface: '#f0f1f2'
  outline: '#6f7a68'
  outline-variant: '#becab5'
  surface-tint: '#056e00'
  primary: '#056c00'
  on-primary: '#ffffff'
  primary-container: '#138808'
  on-primary-container: '#fbfff3'
  inverse-primary: '#72de5c'
  secondary: '#8f4e00'
  on-secondary: '#ffffff'
  secondary-container: '#fe9832'
  on-secondary-container: '#683700'
  tertiary: '#4951ba'
  on-tertiary: '#ffffff'
  tertiary-container: '#636ad5'
  on-tertiary-container: '#fffdff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#8dfc75'
  primary-fixed-dim: '#72de5c'
  on-primary-fixed: '#012200'
  on-primary-fixed-variant: '#035300'
  secondary-fixed: '#ffdcc2'
  secondary-fixed-dim: '#ffb77a'
  on-secondary-fixed: '#2e1500'
  on-secondary-fixed-variant: '#6d3a00'
  tertiary-fixed: '#e0e0ff'
  tertiary-fixed-dim: '#bfc2ff'
  on-tertiary-fixed: '#00006e'
  on-tertiary-fixed-variant: '#3239a3'
  background: '#f8f9fa'
  on-background: '#191c1d'
  surface-variant: '#e1e3e4'
  status-success: '#138808'
  status-warning: '#FFB800'
  status-error: '#D32F2F'
  emblem-gold: '#B38B34'
  surface-white: '#FFFFFF'
typography:
  headline-lg:
    fontFamily: Noto Sans
    fontSize: 30px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-lg-mobile:
    fontFamily: Noto Sans
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
  headline-md:
    fontFamily: Noto Sans
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Noto Sans
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 26px
  body-md:
    fontFamily: Noto Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-xl:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 18px
  legal-print:
    fontFamily: Noto Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 22px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  touch-target-min: 48px
  gutter: 16px
  margin-mobile: 16px
  margin-desktop: 32px
  stack-sm: 8px
  stack-md: 16px
  stack-lg: 24px
---

## Brand & Style

The design system is engineered for the **Forest Rights Act (FRA) management** in Maharashtra. It embodies an **Official, Trustworthy, and Protective** personality, acting as a digital safeguard for tribal land rights. 

The aesthetic is **Corporate / Modern**, leaning heavily on **Material Design** principles to ensure familiarity for users accustomed to official government services. The visual narrative prioritizes transparency—specifically "explainable-by-design" AI—and extreme accessibility for rural populations. The interface uses high-contrast elements, large touch targets, and a clear information hierarchy to bridge the gap between complex legal data and end-user utility.

**Key Brand Pillars:**
- **Integrity:** Utilizing tamper-evident visual cues (like hash-chain badges) to prove record validity.
- **Accessibility:** Large-scale components and icon-assisted navigation for low-literacy users.
- **Authority:** Strict adherence to government branding standards, including proper placement of State Emblems and Digital India logos.

## Colors

The color palette is derived from the official tricolor of India and the Palghar district identity, ensuring instant institutional recognition. 

- **Primary (Deep Green):** Represents forest growth, stability, and "Success" states in claim monitoring.
- **Secondary (Saffron):** Used for primary action buttons and "Caution" states.
- **Tertiary (Navy Blue):** Reserved for institutional accents, typography in headers, and map-related UI elements.
- **Neutral (Off-White):** A soft, low-glare background designed for outdoor legibility.

The **Semantic System** follows a strict traffic-light metaphor:
- **Green:** Evidence Score ≥ 0.8 / Stable boundary.
- **Yellow:** Evidence Score 0.6–0.8 / Seasonal variation.
- **Red:** Evidence Score < 0.6 / Unauthorized activity detected.

## Typography

The system utilizes **Noto Sans** for its exceptional multi-script support (Marathi, Hindi, and English), which is critical for legal documentation and rural outreach. **Inter** is used for UI labels and data-heavy tables to maintain clarity at small scales.

**Functional Rules:**
- **Legibility First:** All body text for legal claim drafts should be no smaller than 16px on mobile devices.
- **Bilingual Priority:** Marathi/Hindi scripts should be given primary visual weight in rural village-level views, with English as secondary.
- **Hierarchy:** High-contrast weights (Bold 700) are used for "Risk Tiers" and "Claim Status" to ensure they are the first thing a user notices.

## Layout & Spacing

This design system uses a **Fluid Grid** model optimized for offline-first mobile usage. The spacing logic is centered around **high-confidence touch targets**, ensuring that forest guards and villagers can interact with the device in rugged outdoor environments.

**Layout Rules:**
- **Mobile-First:** A 4-column grid for mobile with 16px margins.
- **Touch Targets:** No interactive element (button, checkbox, or chip) shall be smaller than 48x48px.
- **Vertical Rhythm:** A consistent 8px baseline grid is used to manage vertical stacks, ensuring data-heavy forms remain readable.
- **Reflow:** On tablets or dashboards, cards reflow into a 2-column or 12-column fixed grid for administrative oversight.

## Elevation & Depth

Visual hierarchy is established through **Tonal Layers** and **Ambient Shadows**, following Material Design standards. 

- **Surface Levels:** The base layer is the Map (Sentinel-2 imagery). Overlays use a white surface with a "Soft Shadow" (Blur: 8px, Y: 2px, Opacity: 10% Black) to distinguish interactive cards from the background.
- **High-Alert Elevation:** Critical alerts or "Red Tier" notifications utilize a slightly higher elevation (Blur: 16px) or a high-contrast Saffron border to break the standard z-index.
- **Integrity Badges:** Unique "Tamper-Proof" status badges use a subtle inset shadow to appear "embossed" into the card, signifying a permanent record on the ledger.

## Shapes

The design system uses **Rounded (0.5rem)** corners to balance a professional government look with a friendly, modern app feel.

- **Standard Cards:** 0.5rem (8px) corner radius.
- **Action Buttons:** 0.5rem (8px) for primary actions; secondary buttons may use 1rem (16px) for distinctiveness.
- **Status Pills:** Fully rounded (Pill-shaped) for lifecycle indicators like "Approved" or "Pending."
- **Map Overlays:** Softened corners for information panels to ensure they feel like distinct UI elements floating above the geospatial data.

## Components

**Buttons:**
- **Primary:** Saffron (#FF9933) background with Navy Blue text for high visibility. Used for "Start Recording," "Capture Map," and "Submit Claim."
- **Secondary:** Deep Green borders with white background for secondary navigation.
- **Offline Actions:** Prominent floating action buttons with icons for Voice (Microphone), Map (Pin), and Camera.

**Cards:**
- **Claim Status Card:** Contains the claimant's name, a 3-tier risk badge (Green/Yellow/Red), and the "Hash-Chain Integrity Badge."
- **Village Dashboard Card:** High-density summaries showing percentages of claims approved vs. rejected.

**Input Fields:**
- **Multimodal Inputs:** Large text fields with integrated voice-to-text triggers. 
- **Checklists:** Evidence checklists use large 24x24px checkboxes for "Binary Indicators" (Yes/No evidence present).

**Navigation:**
- **Status Tracking:** A vertical "Legal Lifecycle" stepper showing the claim's journey from "Gram Sabha" to "District Committee."
- **Icon Assistance:** Every major navigation label must be accompanied by a clear, recognizable icon to aid low-literacy users.

**Logos:**
- **Header:** State of Maharashtra Emblem on the left, "Digital India" logo on the right.