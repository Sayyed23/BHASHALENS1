# BhashaLens Footer Navigation Screens - Design Specification

## Overview
Comprehensive design specifications for the 5 main footer navigation screens in BhashaLens Flutter app.

## Navigation Structure
Bottom navigation bar with 5 tabs: Home | Translate | Explain | Records | Assistant

---

## 1. HOME SCREEN (HomeContent)

### Purpose
Main dashboard with feature cards and quick access buttons

### Layout
- Header: Greeting + subtitle
- Recent Activity Card
- 3 Feature Cards (Translation, Explain, Assistant)
- Quick Access: 4 buttons (SOS, Offline Pack, Saved, History)

### Design Tokens
- Background: AppColors.background (Slate 50)
- Card color: AppColors.surface (White)
- Primary accent: AppColors.blue600 (#2563EB)
- Spacing: 20px padding, 24px between sections

### Components

**FeatureCard** (from lib/pages/home/widgets/feature_card.dart):
- Border radius: 16px
- Padding: 16px
- Icon container: 12px radius, 12px padding
- Gradient background option for primary card
- Button: Rounded 10px, semi-transparent background

**QuickAccessButton** (from lib/pages/home/widgets/quick_access_button.dart):
- Circular or rounded square design
- Icon + label layout
- Color-coded by function

### Typography
- Greeting: displaySmall, Lexend Bold, letter-spacing -0.5
- Subtitle: bodyMedium, onSurfaceVariant color
- Feature titles: titleLarge, bold
- Feature descriptions: bodyMedium

---

## 2. TRANSLATION MODE SCREEN

### Purpose
Selection hub for 3 translation methods

### Layout
- AppBar with title "Translation Mode"
- ListView with 3 FeatureCards:
  1. Camera Translate (Blue, primary)
  2. Voice Translate (Purple)
  3. Text Translate (Green)

### Design Tokens
- Background: Surface color
- Card spacing: 20px padding
- Icon colors: Blue (#136DEC), Purple (#A855F7), Green (#22C55E)

### Card Structure
Each card includes:
- Icon (camera_alt, mic, translate)
- Title
- Description
- "Start" button
- Tap navigates to respective page

---

## 3. EXPLAIN MODE SCREEN

### Purpose
AI-powered context explanation with voice/text input

### Layout (Dark Theme)

```
┌─────────────────────────────────────┐
│ AppBar: Language Selector Pill      │
├─────────────────────────────────────┤
│ Mode Tabs: Text Input | Voice Chat  │
├─────────────────────────────────────┤
│ [TEXT MODE]                          │
│ - Input Card (if no result)         │
│ - Result Cards (if analyzed):       │
│   • Translation Card                │
│   • "What this means" Card          │
│   • When to use + Tone (Grid)       │
│   • Situational Context             │
│   • Cultural Insight                │
│   • Safety Note (conditional)       │
│   • Footer Actions                  │
│                                      │
│ [VOICE MODE]                         │
│ - Chat UI with bubbles              │
│ - Mic button (80x80 circle)         │
│ - Context sheet (bottom)            │
└─────────────────────────────────────┘
```

### Color Palette (Dark Mode)
- Background: #101822 (bgDark)
- Card: #1C2027 (cardDark)
- Primary: #136DEC (primaryBlue)
- Text: #9DA8B9 (textGrey)
- Warning: #FF9800
- Danger: #EF5350

### Key Components

**Language Selector (AppBar)**:
- Pill-shaped container (16px radius)
- FROM/TO sections with swap icon
- Dark card background (#1C2027)
- Dropdown arrows

**Mode Tabs**:
- 2 large buttons in container
- Selected: Blue background
- Icons: keyboard_outlined, mic_none_outlined

**Input Card** (Text Mode):
- 24px padding, 24px radius
- TextField: 6 lines, dark background
- "Scan Text" button with camera icon
- "Explain Context" button (56px height, 16px radius)

**Result Cards**:
- Translation: Original + translated sections
- Meaning: Light blue background, lightbulb icon
- Info cards: Grid layout, icon + title + content
- Cultural insight: Globe watermark, blue border
- Safety note: Red accent, warning icon

**Voice Chat**:
- Chat bubbles: 20px radius (asymmetric)
- User: Left-aligned, grey background (#333A44)
- AI: Right-aligned, blue background
- Mic button: 80x80 circle, blue, centered
- Context sheet: Bottom drawer with handle

---

## 4. HISTORY & SAVED SCREEN

### Purpose
View and manage translation history and saved items

### Layout
```
┌─────────────────────────────────────┐
│ AppBar: "History & Saved"           │
├─────────────────────────────────────┤
│ Custom Tab Bar (History | Saved)    │
├─────────────────────────────────────┤
│ Search Bar + Filter Button          │
├─────────────────────────────────────┤
│ Filter Chips (All, Medical, etc.)   │
├─────────────────────────────────────┤
│ Item Cards List                      │
└─────────────────────────────────────┘
```

### Color Palette (Dark Mode)
- Background: #0F172A
- Card: #1E293B
- Primary: #136DEC
- Search/Tab background: #1E293B

### Components

**Custom Tab Bar**:
- Container with rounded corners (12px)
- Bottom border indicator (2px blue)
- Dark background

**Search Bar**:
- Height: 44px
- Dark background (#1E293B)
- Search icon prefix
- Placeholder: "Search history or saved items"

**Filter Chips**:
- Horizontal scroll
- Rounded pills (20px radius)
- Selected: Blue background
- Icons: all_inclusive, local_hospital, flight, business_center

**Item Card**:
- 20px radius, 16px padding
- Language tag (EN → HI) - dark blue background
- Timestamp
- Category badge with icon (green)
- Original text (grey, italic, light background)
- Translation (white, bold, left blue border 3px)
- Action buttons: "Speak" (blue) + "Explain" (outlined)
- More menu (3 dots): Copy, Save/Unsave, Delete

### Typography
- Card title: 18px, bold
- Translation: 18px, semi-bold
- Original: 14px, italic
- Metadata: 12px, grey

---

## 5. ASSISTANT MODE SCREEN

### Purpose
Context-aware speaking assistant for daily situations

### Layout
```
┌─────────────────────────────────────┐
│ AppBar: "Assistant Mode"            │
├─────────────────────────────────────┤
│ Situation Cards (Horizontal scroll) │
│ + "Basic Guide" button              │
├─────────────────────────────────────┤
│ Goal Selection (Wrap chips)         │
├─────────────────────────────────────┤
│ Recommendation Card:                │
│  - Your language text               │
│  - Translation (large, bold)        │
│  - Confidence Tip                   │
│  - Save button                      │
├─────────────────────────────────────┤
│ Audio Controls (Play + Slow toggle) │
├─────────────────────────────────────┤
│ "Practice Speaking" Button          │
├─────────────────────────────────────┤
│ Live Coaching Chat UI               │
└─────────────────────────────────────┘
```

### Color Palette (Dark Mode)
- Background: #101822
- Card: #1C2027
- Primary: #136DEC
- Text: #9DA8B9

### Components

**Situation Cards**:
- Size: 100x120px
- Squircle shape (24px radius)
- Selected: Blue border (2px) + shadow
- Icons: local_hospital, apartment, shopping_cart, school
- Active indicator text

**Goal Chips**:
- Pill-shaped (30px radius)
- Padding: 20px horizontal, 12px vertical
- Selected: Blue background
- Unselected: Dark card background

**Recommendation Card**:
- 24px radius, 20px padding
- Sections: Your language → Translation
- Confidence tip: Nested card, blue accent, verified icon
- Save button: Text button with bookmark icon

**Audio Controls**:
- Container: 40px radius, dark background
- Play button: 48px circle, blue
- Slow toggle: Switch component
- Label: "Natural AI voice"

**Practice Button**:
- Full width, outlined
- 30px radius, 16px vertical padding
- Blue border, mic icon

**Live Coaching Chat**:
- Fixed height: 400px
- Dark background (#151A22)
- Chat bubbles with ME label
- Translate + Speaker icons for AI messages
- Input row: Mic + TextField + Send
- Divider above input

### Typography
- Section headers: 16px, bold, white
- Recommendation translation: 24px, bold
- Confidence tip: 13px, white70
- Chat text: 14-16px, white

---

## Common Design Patterns

### Dark Mode Colors
- Primary background: #0F172A / #101822
- Card background: #1E293B / #1C2027
- Primary blue: #136DEC
- Text grey: #9DA8B9
- Border: #3B4554 with alpha

### Border Radius Standards
- Cards: 16-24px
- Buttons: 12-16px (small), 30px (pills)
- Input fields: 12-16px
- Chips: 20-30px

### Spacing Scale
- Section padding: 16-20px
- Card spacing: 16-24px
- Element spacing: 8-12px
- Icon spacing: 4-8px

### Icon Sizes
- Small: 14-16px
- Medium: 20px
- Large: 32-40px
- Extra large: 48-80px

### Button Patterns
- Primary: Blue background, white text, 0 elevation
- Outlined: Blue border, transparent background
- Text: No background, blue text
- Icon: Circular, semi-transparent background

### Typography Hierarchy
- Page title: 18-20px, bold, Lexend
- Section header: 16px, bold
- Card title: 18px, semi-bold
- Body: 14-16px, regular
- Caption: 12px, grey
- Label: 10-12px, uppercase, letter-spacing 1.2

---

## Accessibility Features

### Text Scaling
- All text respects `AccessibilityService.textSizeFactor`
- Dynamic font sizing via theme

### Color Contrast
- High contrast between text and backgrounds
- Semantic colors for states (success, error, warning)

### Voice Support
- TTS integration for reading content
- STT for voice input
- Slow speech mode toggle

### Touch Targets
- Minimum 44x44px for interactive elements
- Adequate spacing between buttons

---

## State Management

### Provider Pattern
- `AccessibilityService` - Theme and text size
- `VoiceTranslationService` - Voice features
- `GeminiService` - AI explanations
- `LocalStorageService` - History/saved items
- `FirestoreService` - Cloud sync

### Loading States
- CircularProgressIndicator for async operations
- Skeleton screens where appropriate
- "Analyzing..." / "Loading..." text

### Error States
- SnackBar for temporary errors
- Error cards for persistent issues
- Offline mode fallbacks

---

## Navigation Patterns

### Bottom Navigation
- Fixed at bottom
- 5 tabs with icons + labels
- Selected: Blue color
- Unselected: Grey color
- Background: Dark (#0F172A)

### Page Navigation
- `Navigator.pushNamed()` for routes
- Back button in AppBar
- Reset to Home index after navigation

### Modal Sheets
- Bottom sheets for options/pickers
- Draggable handle (40x4px)
- Rounded top corners (20-24px)
- Dark background

---

## Animation & Transitions

### Page Transitions
- Default Material page transitions
- Smooth navigation between tabs

### Micro-interactions
- Button press feedback
- Card tap ripple effects
- Smooth scrolling

### Voice Indicators
- Pulsing mic button when listening
- Animated waveforms (potential)

---

## Responsive Considerations

### Mobile First
- Optimized for phone screens
- Vertical scrolling layouts
- Bottom navigation for thumb reach

### Tablet Support
- Wider cards
- Multi-column layouts where appropriate
- Larger touch targets

### Desktop Support
- Centered content with max width
- Mouse hover states
- Keyboard navigation

---

## Implementation Notes

### File Structure
- Pages: `lib/pages/`
- Widgets: `lib/widgets/` and `lib/pages/home/widgets/`
- Theme: `lib/theme/`
- Services: `lib/services/`

### Key Files
- `home_page.dart` - Navigation shell
- `home_content.dart` - Home screen
- `translation_mode_page.dart` - Translation hub
- `explain_mode_page.dart` - Explain feature
- `history_saved_page.dart` - History/saved
- `assistant_mode_page.dart` - Assistant feature

### Reusable Components
- `FeatureCard` - Feature presentation
- `QuickAccessButton` - Quick action buttons
- `RecentActivityCard` - Activity display
- Custom chat bubbles
- Language selector pills

---

## Design System Integration

All screens follow the BhashaLens design system defined in `.kiro/steering/design-system.md`:

- Color tokens from `AppColors`
- Typography from `AppTheme`
- Material Design 3 components
- Consistent spacing and radius
- Theme-aware (light/dark mode)
- Accessibility compliant

---

## Future Enhancements

### Potential Improvements
- Animations for card transitions
- Skeleton loading screens
- Pull-to-refresh on lists
- Swipe gestures for cards
- Voice waveform visualizations
- Haptic feedback
- Offline indicators
- Sync status badges

### A/B Testing Opportunities
- Card layouts
- Button placements
- Color schemes
- Typography sizes
- Navigation patterns

---

**Document Version**: 1.0  
**Last Updated**: February 2026  
**Maintained By**: BhashaLens Design Team
