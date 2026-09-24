---
name: Technical Maritime M3
colors:
  surface: '#f8f9ff'
  surface-dim: '#cbdbf5'
  surface-bright: '#f8f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eff4ff'
  surface-container: '#e5eeff'
  surface-container-high: '#dce9ff'
  surface-container-highest: '#d3e4fe'
  on-surface: '#0b1c30'
  on-surface-variant: '#44474c'
  inverse-surface: '#213145'
  inverse-on-surface: '#eaf1ff'
  outline: '#74777d'
  outline-variant: '#c4c6cc'
  surface-tint: '#526071'
  primary: '#03111f'
  on-primary: '#ffffff'
  primary-container: '#182635'
  on-primary-container: '#7f8da0'
  inverse-primary: '#b9c8dc'
  secondary: '#006a61'
  on-secondary: '#ffffff'
  secondary-container: '#9df2e5'
  on-secondary-container: '#077167'
  tertiary: '#1d0b00'
  on-tertiary: '#ffffff'
  tertiary-container: '#3c1d00'
  on-tertiary-container: '#cc7720'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d5e4f8'
  primary-fixed-dim: '#b9c8dc'
  on-primary-fixed: '#0e1d2b'
  on-primary-fixed-variant: '#3a4858'
  secondary-fixed: '#9df2e5'
  secondary-fixed-dim: '#81d5c9'
  on-secondary-fixed: '#00201d'
  on-secondary-fixed-variant: '#005049'
  tertiary-fixed: '#ffdcc2'
  tertiary-fixed-dim: '#ffb77a'
  on-tertiary-fixed: '#2e1500'
  on-tertiary-fixed-variant: '#6d3a00'
  background: '#f8f9ff'
  on-background: '#0b1c30'
  surface-variant: '#d3e4fe'
typography:
  headline-lg:
    fontFamily: IBM Plex Sans
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
  headline-lg-mobile:
    fontFamily: IBM Plex Sans
    fontSize: 26px
    fontWeight: '600'
    lineHeight: 34px
  headline-md:
    fontFamily: IBM Plex Sans
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
  headline-sm:
    fontFamily: IBM Plex Sans
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: IBM Plex Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: IBM Plex Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: IBM Plex Sans
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  label-lg:
    fontFamily: IBM Plex Sans
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
  label-md:
    fontFamily: JetBrains Mono
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
  label-sm:
    fontFamily: JetBrains Mono
    fontSize: 10px
    fontWeight: '500'
    lineHeight: 14px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  margin: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

This design system expresses a refined, instrument-grade technical aesthetic inspired by functionalist industrial design (Dieter Rams) paired with the crisp precision of contemporary developer tools. Designed for Android using Material Design 3 foundations, it introduces a subtle maritime engineering character: rigorous, purposeful, and structural, entirely free of nautical cliches such as rope motifs, anchors, compass roses, or decorative waves.

The tone is calculated, durable, and understated. It treats interface space as navigational telemetry—clean data hierarchies, high legibility under direct sunlight, and hairline structural delineations reminiscent of technical blueprints and vessel schematics. Interactions evoke tactile instrumentation: firm state transitions, fine 1px structural framing, monospace metadata tags, and intentional whitespace. The quiet brand attribution `powered by HullQ` appears in upper-case micro-typography across system footers and secondary sheet headers to reinforce professional maritime provenance.

## Colors

The palette relies on high-contrast technical clarity optimized for light mode utility:

- **Primary Blueprint Navy (`#182635`):** Serves as the bedrock tone for key structural elements, active tab states, primary action surfaces, and primary typography. A lighter navy tint (`#1E2D3D`) functions as high-contrast structural text and pressed states.
- **Teal Accent (`#1B7A70` / `#238578`):** The functional confirmation signal used for completed checklist items, verified vessel waypoints, settled ledgers, and positive states. Never used decoratively.
- **Warm Amber Sand (`#D9822B` / `#E5A952`):** Reserved exclusively for warnings, maintenance alerts, advisory thresholds, and pending statuses. Aggressive danger reds are eliminated in favor of this maritime beacon amber.
- **Surface & Boundary Scale:**
  - Base canvas: `#F4F6F8` (a pale blueprint mist tinted with cool slate)
  - Surface Container / Card Base: `#FFFFFF`
  - Subtle Technical Grid / Frame Borders: `#E2E8F0` and `#CBD5E1`
  - Secondary Data & Inactive Elements: `#64748B` and `#94A3B8`

## Typography

The typographic hierarchy combines the humanist technical clarity of **IBM Plex Sans** for running interface copy and section headings with **JetBrains Mono** for telemetric data, counters, vessel coordinates, weights, and currency.

Key formatting rules:
- All numeric measurements (nautical miles, kg, currency values, ledger line items, and quantities) must utilize tabular figures (`font-variant-numeric: tabular-nums`) and align flush right in tables and row lists.
- Overline indicators, log timestamps, and metadata tags are set in `label-sm` or `label-md` with `text-transform: uppercase` and `letter-spacing: 0.05em`.
- Top-level mobile screen titles use `headline-lg-mobile` to maintain visual weight without awkward text wraps on narrow viewports.

## Layout & Spacing

Layout is structured around an 8-point baseline grid aligned to Android phone and tablet ergonomics:

- **Mobile Viewport (< 600dp):** Single fluid column with 16dp (`margin`) horizontal screen padding and 16dp (`gutter`) inter-element rhythm. Bottom navigation is anchored, accommodating Android system navigation bars and gesture insets.
- **Tablet Viewport (600dp - 840dp):** 8-column layout with 24dp screen margins. Primary navigation converts from the 4-item bottom bar into a streamlined left navigation rail.
- **Rhythm & Lineage:** Cards and surface blocks maintain strict vertical alignment. Hairline dividers (`1px solid #E2E8F0`) extend across list items with an optional 16dp inset matching the text start line, reinforcing structured blueprint division rather than freeform separation.

## Elevation & Depth

Visual hierarchy abandons fuzzy, atmospheric cast shadows in favor of precise Material Design 3 surface-container tonal tiers coupled with low-contrast structural boundaries:

- **Base Layer (Elevation 0):** Canvas background `#F4F6F8`.
- **Card and Surface Tier (Elevation 1):** Solid white `#FFFFFF` surface framed with a crisp hairline border (`1px solid #E2E8F0`). Elevation is communicated through tone and outline definition, not drop shadows.
- **Active / Focused Containers (Elevation 2):** Pure white background with border `#CBD5E1` and an imperceptible, diffuse contact shadow (`0px 1px 3px rgba(24, 38, 53, 0.06)`).
- **Overlays & Bottom Sheets (Elevation 3):** Solid white sheet container with an upper edge border (`1px solid #E2E8F0`) accompanied by a standard directional scrim (`rgba(24, 38, 53, 0.35)`). A subtle horizontal pill handle (32dp x 4dp, `#CBD5E1`) signals sheet drag affordance.

## Shapes

The design system employs balanced, functional corner treatments:
- Cards, containers, and elevated modules use `rounded-xl` (16dp / `1rem`) or `rounded-2xl` (24dp / `1.5rem`), softening the technical linework so screens feel approachable.
- Input fields, filter chips, and primary buttons conform to `rounded-lg` (8dp / `0.5rem`) for compact structural density.
- Badges, status tags, and bottom sheet drag handles use full pill radii.

## Components

- **Buttons:**
  - *Primary:* Solid deep navy (`#182635`) with white text, 8dp corner radius, 48dp height for touch targets. No drop shadow.
  - *Secondary / Outlined:* 1px solid border in `#CBD5E1`, text in `#182635`, hover/pressed state in `#F4F6F8`.
  - *Success / Confirmed Action:* Petrol teal (`#1B7A70`) fill with tabular confirmation check icon.
- **Bottom Navigation Bar:**
  - Fixed 4-tab bar at 64dp height (excluding system inset).
  - Tabs: **Liste**, **Törn**, **Bordkasse**, **Mehr**.
  - Inactive: 24dp outlined stroke icon with `#64748B` label (`label-sm`).
  - Active: Filled navy icon with an ambient pill indicator (`#E2E8F0`), label in `#182635` semi-bold.
- **Cards & Data Lists:**
  - White surface with 1px `#E2E8F0` border.
  - List items feature tabular figures aligned flush right (e.g., fuel level `420 L`, provision counts `12 Stk.`, ledger `€ 84,50`).
  - Section dividers use 1px horizontal blueprint linework.
- **Input Fields:**
  - Flat container with 1px border `#CBD5E1` on resting, shifting to `#182635` (2px) on active focus.
  - Numeric inputs automatically display currency or unit suffixes in `#64748B` JetBrains Mono.
- **Checkboxes & Status Indicators:**
  - Checkboxes use square rounded corners (4dp radius) with 1.5px `#64748B` border.
  - Completed state snaps to teal `#1B7A70` with crisp white checkmark.
  - Warning tags use sand amber `#D9822B` background at 12% opacity with solid `#D9822B` text.
- **Footer Attribution:**
  - Secondary utility views and sheets incorporate a subtle bottom-centered micro-label: `POWERED BY HULLQ` set in 10dp monospaced caps (`#94A3B8`).