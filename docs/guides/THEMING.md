# Theming Guide

ShamelaGPT uses a distinct color palette inspired by Islamic art and nature: **Emerald Green** and **Gold/Amber**.

## Color Palette

| Token | Hex | Usage |
|-------|-----|-------|
| **Primary (Emerald)** | `#10B981` | Brand identity, primary buttons, user bubbles. |
| **Secondary (Amber)** | `#F59E0B` | Accents, gold highlights, call-outs. |
| **Background** | `#F9FAFB` | App background in light mode. |
| **Surface** | `#FFFFFF` | Cards, input background. |
| **Text Primary** | `#111827` | Main headings and body text. |
| **Text Secondary** | `#6B7280` | Subtitles, timestamps, metadata. |

## Platform Implementation

### iOS (`Theme` folder)
- Colors are defined as static properties on `Color` in `Color+Extensions.swift`.
- Assets include `Light` and `Dark` variants.

### Android (`theme` package)
- Defined in `Color.kt` using Material 3 color tokens.
- `Theme.kt` applies these colors via `lightColorScheme` and `darkColorScheme`.

## Typography
We prioritize readability for both Arabic and Latin scripts.

- **Primary Font**: System Default (San Francisco on iOS, Roboto on Android).
- **Arabic Font**: Optimized for readability on mobile (Traditional Arabic style where available).

## UI Patterns

### Message Bubbles
- **User**: Emerald background, White text, Right-aligned.
- **AI**: Light Gray background, Black text, Left-aligned.
- **Radius**: 16dp/pt with "round corners" except for the tail.

### Input Bar
- Floating design with elevation.
- Clear action buttons for Camera, Mic, and Send.
