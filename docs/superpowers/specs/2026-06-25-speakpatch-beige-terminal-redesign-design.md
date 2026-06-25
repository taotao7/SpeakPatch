# SpeakPatch Beige Terminal Minimal Flat Redesign

## Overview

Redesign SpeakPatch's UI using the **"Analog Dream: Beige Terminal"** variant of the *Cassette Futurism* theme palette. The goal is a smaller, cleaner, minimal-flat popup panel and a consistent visual treatment across the main rewrite panel, the PopClip-style selection toolbar, and the Settings window.

## Decisions Made

| Question | Decision |
|----------|----------|
| Theme variant | Light only — Beige Terminal |
| Panel size | Compact — 480 × 380 |
| Scope | Main panel + selection toolbar + Settings |
| Visual personality | Minimal Flat / retro workstation |
| Design direction | **C. Minimal Flat** from the brainstorm mockups |

## Color Palette

All colors come directly from the provided Beige Terminal theme.

| Token | Hex | Usage |
|-------|-----|-------|
| `background` | `#f5f0e8` | App/panel background |
| `elevated_surface.background` | `#faf8f4` | Cards, editors, buttons |
| `surface.background` | `#ede8e0` | Secondary surfaces, hover |
| `border` | `#c4b8a8` | Borders, dividers |
| `text` | `#2d2a27` | Primary text |
| `text.muted` | `#6b6560` | Secondary text, inactive tabs |
| `text.placeholder` | `#928374` | Placeholders |
| `text.accent` / `icon.accent` | `#d65d0e` | Active tab, primary action, section headers |
| `success` | `#458588` | Info/success states |
| `error` | `#9d0006` | Errors |
| `error.background` | `#9d00061a` | Error banner background |

## 1. Main Rewrite Panel

### Size
- **480 × 380** (down from 600 × 540).
- Update in `AppCoordinator.swift` (`FloatingPanel` content rect and `RewritePanelView` frame).

### Layout
- Vertical stack with reduced spacing (12–14 pt instead of 16 pt).
- Padding reduced to ~16 pt.

### Header
- Single horizontal row.
- Left: app title **"SpeakPatch"** in primary text, current preset name below or beside as muted caption.
- Right: small icon-only buttons for **Settings** (gear) and **Close** (xmark).
- Remove the large app-icon block from the current design.

### Action Bar
- Tab-style segmented row directly under the header.
- Actions shown as short text labels:
  - `Fix`
  - `Natural`
  - `Concise`
  - `Explain`
  - `Trans`
- **Active tab**: accent color `#d65d0e` + 2 pt accent underline.
- **Inactive tabs**: muted `#6b6560`, no background fill.
- No filled/prominent buttons.

### Input Editor
- Label: small muted text "Input".
- Background: `#faf8f4`.
- Border: 1 pt `#c4b8a8`, corner radius 6 pt.
- Min height reduced to ~72 pt.
- Placeholder in `#928374`.

### Result Editor
- Same visual treatment as input editor.
- Label: "Result" with inline loading indicator when rewriting.
- Placeholder: "Your rewritten text will appear here."
- Min height ~88 pt.

### Error Banner
- Text in `#9d0006`.
- Background: `#9d00061a` (10% opacity) or left-border accent style.
- Compact padding, rounded 6 pt corners.

### Footer
- Flat text buttons:
  - **Copy** — accent color when enabled, disabled when result empty.
  - **Replace** — muted color, disabled when result empty.
- Right: `⌘⇧E` shortcut hint in muted text.

## 2. Selection Toolbar

- Keep the existing PopClip-style compact bar.
- Background: `#f5f0e8`.
- Border: 1 pt `#c4b8a8`.
- Shadow: subtle dark shadow (`rgba(45,42,39,0.12)`).
- Buttons: icon + tiny label, flat.
- Hover / pressed: `#e8e0d6` background.
- Divider before the "More" button.

## 3. Settings Window

- Keep the grouped form layout.
- Apply the beige palette:
  - Window/panel background: `#f5f0e8`.
  - Section headers: accent `#d65d0e` or muted `#6b6560`.
  - Text fields: beige background `#faf8f4`, 1 pt `#c4b8a8` border, 6 pt radius (replace `.roundedBorder` style).
  - System prompt editor: same beige card style as other editors.
  - Buttons (Reset to preset, Use Grammar Only): flat, muted background, accent text or icon.

## 4. Implementation Plan

1. Create `Sources/SpeakPatch/Theme.swift` with static color constants from the palette.
2. Update `RewritePanelView.swift`:
   - Reduce frame to 480 × 380.
   - Simplify header.
   - Replace action buttons with tab-style bar.
   - Recolor editors, footer, and error banner.
3. Update `SelectionToolbarView.swift`:
   - Apply beige background, border, shadow, and hover state.
4. Update `SettingsView.swift`:
   - Recolor form, fields, and buttons.
5. Update `AppCoordinator.swift`:
   - Adjust `FloatingPanel` content size to match new panel dimensions.
6. Build and visually verify the app.

## Out of Scope

- Dark mode or runtime theme switching.
- New animations or transitions.
- Changes to behavior, shortcuts, or LLM logic.
- Adding a theme picker in Settings.

## Acceptance Criteria

- [ ] Main panel renders at 480 × 380.
- [ ] All three surfaces (panel, toolbar, settings) use the Beige Terminal palette.
- [ ] Action bar uses tab-style active indicator (accent underline).
- [ ] Editors use beige card style with thin borders.
- [ ] Settings text fields and prompt editor match the new palette.
- [ ] App builds and runs without regressions in selection reading or rewriting.
