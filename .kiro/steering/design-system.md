---
inclusion: always
---

# BhashaLens Design System Rules

This document defines the design system rules for integrating Figma designs into the BhashaLens Flutter application using the Figma MCP.

## Project Overview

BhashaLens is a Flutter-based translation and accessibility app with support for Android, iOS, Web, Windows, macOS, and Linux platforms. The app uses Material Design 3 with a custom blue-slate color scheme.

## 1. Token Definitions

### Color Tokens
Colors are defined in `lib/theme/app_colors.dart` using a slate-blue palette:

**Primary Colors:**
- `AppColors.primary` - Blue 600 (#2563EB) - Main brand color
- `AppColors.primaryLight` - Blue 500 (#3B82F6)
- `AppColors.primaryDark` - Blue 700 (#1D4ED8)

**Secondary Colors:**
- `AppColors.secondary` - Slate 600 (#475569)
- `AppColors.secondaryLight` - Slate 400 (#94A3B8)
- `AppColors.secondaryDark` - Slate 800 (#1E293B)

**Background & Surface:**
- `AppColors.background` - Slate 50 (#F8FAFC) - Light mode background
- `AppColors.backgroundDark` - Slate 950 (#020617) - Dark mode background
- `AppColors.surface` - White (#FFFFFF) - Light mode surface
- `AppColors.surfaceDark` - Slate 900 (#0F172A) - Dark mode surface

**Text Colors:**
- `AppColors.text` - Slate 900 (#0F172A) - Primary text
- `AppColors.textLight` - Slate 500 (#64748B) - Secondary text
- `AppColors.textMuted` - Slate 500 (#64748B) - Muted text
- `AppColors.textOnPrimary` - White - Text on primary color
- `AppColors.textDark` - White - Dark mode text

**Semantic Colors:**
- `AppColors.success` - Green (#10B981)
- `AppColors.error` - Red (#EF4444)
- `AppColors.warning` - Orange (#F59E0B)
- `AppColors.info` - Blue (#3B82F6)
- `AppColors.sosRed` - Red (#EF4444) - Emergency feature

**Borders & Dividers:**
- `AppColors.border` - Slate 200 (#E2E8F0)
- `AppColors.borderDark` - Slate 800 (#1E293B)
- `AppColors.divider` - Slate 200 (#E2E8F0)

**Effects:**
- `AppColors.shadow` - 10% black (#1A000000)
- `AppColors.overlay` - 50% black (#80000000)

### Typography Tokens
Typography uses Google Fonts with two font families:

**Display & Headings:** Lexend (bold/semi-bold)
- `displayLarge`, `displayMedium`, `displaySmall` - Lexend Bold
- `headlineLarge`, `headlineMedium`, `headlineSmall` - Lexend Semi-Bold (600)

**Body Text:** Source Sans 3
- All body text styles use Source Sans 3

**Font Weights:**
- Bold: 700 (displays)
- Semi-Bold: 600 (headlines, buttons)
- Regular: 400 (body text)

### Spacing Tokens
Flutter's standard spacing is used throughout:
- 4, 8, 12, 16, 24, 32 pixels
- Card padding: 16px
- Button padding: horizontal 24px, vertical 14px
- Input padding: horizontal 16px, vertical 16px

### Border Radius Tokens
- Cards: 16px
- Buttons: 12px
- Input fields: 12px
- Icon containers: 12px
- Small elements: 8px

## 2. Component Library

### Component Location
All reusable widgets are in `lib/widgets/`:
- `home_widgets.dart` - Home screen components (ModeCard, etc.)
- `responsive_layout.dart` - Responsive layout utilities

### Component Architecture
- Stateless widgets for presentational components
- StatefulWidget for interactive components
- Provider pattern for state management
- Theme-aware components using `Theme.of(context)`

### Key Components

**ModeCard** (`lib/widgets/home_widgets.dart`):
```dart
ModeCard(
  icon: Icons.translate,
  title: "Translation Mode",
  description: "Translate text in real-time",
  buttonText: "Start",
  onTap: () {},
  color: AppColors.primary, // Optional
  imageBackground: "assets/image.jpg", // Optional
)
```

**Card Pattern:**
- Uses Material 3 Card widget
- 16px border radius
- 0 elevation with 1px border
- Border color: `AppColors.border` (light) / `AppColors.borderDark` (dark)

**Button Pattern:**
- ElevatedButton with primary color background
- 12px border radius
- 0 elevation (flat design)
- Lexend font, 16px, semi-bold (600)
- Padding: 24px horizontal, 14px vertical

**Input Pattern:**
- Filled input with `AppColors.slate50` background
- 12px border radius
- 1px border (slate 200)
- 2px border on focus (primary color)
- 16px padding

## 3. Frameworks & Libraries

### UI Framework
- **Flutter SDK:** >=3.2.0 <4.0.0
- **Material Design:** Material 3 (useMaterial3: true)

### Styling Libraries
- **google_fonts:** ^6.2.1 - Lexend and Source Sans 3 fonts
- **Theme System:** Custom ThemeData with light/dark modes

### State Management
- **provider:** ^6.1.2 - Primary state management solution

### Key Dependencies
- **Firebase:** Core, Auth, Firestore, Analytics
- **ML Kit:** Translation, Text Recognition, Language ID
- **Google Generative AI:** ^0.4.0 (Gemini integration)
- **Accessibility:** speech_to_text, flutter_tts
- **Storage:** sqflite, shared_preferences, flutter_secure_storage

### Build System
- Flutter's standard build system
- Multi-platform support (Android, iOS, Web, Windows, macOS, Linux)

## 4. Asset Management

### Asset Location
Assets are stored in `assets/` directory:
- `assets/logo.png` - Primary logo
- `assets/logo2.png` - Secondary logo (launcher icon)
- `assets/google_logo.png` - Google sign-in logo
- Video assets for intents

### Asset Configuration
Defined in `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/
    - .env
```

### Asset Usage Pattern
```dart
Image.asset('assets/logo.png')
AssetImage('assets/logo2.png')
```

### Launcher Icons
- Generated using `flutter_launcher_icons` package
- Source: `assets/logo2.png`
- Background: #FFF8F5
- Theme color: #FF6B35 (legacy orange, now using blue)

## 5. Icon System

### Icon Library
- **Material Icons:** Primary icon system (built-in Flutter)
- No custom icon font or SVG system currently

### Icon Usage Pattern
```dart
Icon(Icons.translate, size: 32, color: AppColors.primary)
```

### Common Icons
- `Icons.translate` - Translation features
- `Icons.camera_alt` - Camera translation
- `Icons.mic` - Voice input
- `Icons.history` - History/saved items
- `Icons.settings` - Settings
- `Icons.help` - Help & support

### Icon Sizing
- Small: 16-20px
- Medium: 24px (default)
- Large: 32px
- Extra Large: 48px

## 6. Styling Approach

### CSS Methodology
Flutter uses a widget-based styling approach:
- **Theme System:** Centralized theme in `lib/theme/app_theme.dart`
- **Color System:** Centralized colors in `lib/theme/app_colors.dart`
- **Component Themes:** Defined in ThemeData (AppBarTheme, CardTheme, etc.)

### Theme Application
```dart
MaterialApp(
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
  themeMode: ThemeMode.system, // or light/dark
)
```

### Accessing Theme
```dart
// Colors
Theme.of(context).colorScheme.primary
Theme.of(context).colorScheme.surface

// Text styles
Theme.of(context).textTheme.titleLarge
Theme.of(context).textTheme.bodyMedium
```

### Responsive Design
- Uses `MediaQuery.of(context).size` for screen dimensions
- Responsive layout utilities in `lib/widgets/responsive_layout.dart`
- Adaptive layouts for different screen sizes

### Accessibility
- Dynamic text scaling via `AccessibilityService`
- Text size factor applied to all text themes
- High contrast mode support
- Screen reader support (TalkBack/VoiceOver)

## 7. Project Structure

```
bhashalens_app/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── theme/
│   │   ├── app_colors.dart       # Color definitions
│   │   └── app_theme.dart        # Theme configuration
│   ├── widgets/
│   │   ├── home_widgets.dart     # Reusable widgets
│   │   └── responsive_layout.dart
│   ├── pages/                    # Screen/page widgets
│   │   ├── home_page.dart
│   │   ├── camera_translate_page.dart
│   │   ├── voice_translate_page.dart
│   │   ├── settings_page.dart
│   │   └── auth/                 # Auth-related pages
│   ├── services/                 # Business logic & services
│   │   ├── firebase_auth_service.dart
│   │   ├── gemini_service.dart
│   │   ├── accessibility_service.dart
│   │   └── voice_translation_service.dart
│   ├── models/                   # Data models
│   └── data/                     # Static data & templates
├── assets/                       # Images, videos, etc.
├── pubspec.yaml                  # Dependencies & config
└── [platform folders]            # android/, ios/, web/, etc.
```

### Feature Organization
- **Pages:** Full-screen views in `lib/pages/`
- **Widgets:** Reusable components in `lib/widgets/`
- **Services:** Business logic in `lib/services/`
- **Models:** Data structures in `lib/models/`

## 8. Figma Integration Guidelines

### Converting Figma Designs to Flutter

When using Figma MCP to generate code:

1. **Replace Tailwind with Flutter Widgets:**
   - Tailwind classes → Flutter Container/Padding/SizedBox
   - CSS flexbox → Column/Row/Flex widgets
   - CSS grid → GridView widget

2. **Use Existing Color Tokens:**
   - Replace hex colors with `AppColors.*` constants
   - Use `Theme.of(context).colorScheme.*` for theme-aware colors

3. **Use Existing Typography:**
   - Replace font styles with `Theme.of(context).textTheme.*`
   - Maintain Lexend for headings, Source Sans 3 for body

4. **Reuse Existing Components:**
   - Check `lib/widgets/` for existing components before creating new ones
   - Extend existing components rather than duplicating

5. **Follow Material Design 3:**
   - Use Material 3 widgets (Card, ElevatedButton, etc.)
   - Maintain 0 elevation with borders for flat design
   - Use consistent border radius (16px cards, 12px buttons)

6. **Maintain Accessibility:**
   - Ensure sufficient color contrast
   - Support dynamic text scaling
   - Add semantic labels for screen readers

7. **Responsive Design:**
   - Use MediaQuery for responsive layouts
   - Test on multiple screen sizes
   - Consider tablet and desktop layouts

### Code Generation Workflow

1. Extract design context from Figma using `get_design_context`
2. Review generated React/Tailwind code as reference
3. Translate to Flutter widgets using this design system
4. Replace inline styles with theme tokens
5. Reuse existing components from `lib/widgets/`
6. Test on multiple platforms and themes (light/dark)

### Visual Parity Checklist

- [ ] Colors match design system tokens
- [ ] Typography uses Lexend/Source Sans 3
- [ ] Spacing follows 4/8/12/16/24/32px scale
- [ ] Border radius matches component standards
- [ ] Dark mode support implemented
- [ ] Accessibility features maintained
- [ ] Responsive on all target platforms

## 9. Platform-Specific Considerations

### Android
- Material Design is native
- Use platform-specific features via `Platform.isAndroid`

### iOS
- Cupertino widgets available but not primary
- Follow Material Design for consistency

### Web
- Responsive design critical
- Consider mouse/keyboard interactions
- Test on different browsers

### Desktop (Windows/macOS/Linux)
- Larger screen layouts
- Window management considerations
- Native menu integration

## 10. Development Best Practices

### Code Style
- Follow Flutter/Dart style guide
- Use `const` constructors where possible
- Prefer composition over inheritance
- Keep widgets small and focused

### Performance
- Use `const` widgets for static content
- Avoid rebuilding entire widget trees
- Use `ListView.builder` for long lists
- Optimize images and assets

### Testing
- Unit tests in `test/` directory
- Widget tests for UI components
- Integration tests for user flows

### Version Control
- Git-based workflow
- Feature branches
- Code review before merge

---

## Quick Reference

**Primary Color:** `AppColors.primary` (#2563EB)
**Font Families:** Lexend (headings), Source Sans 3 (body)
**Border Radius:** 16px (cards), 12px (buttons/inputs)
**Spacing Scale:** 4, 8, 12, 16, 24, 32px
**Component Location:** `lib/widgets/`
**Theme Files:** `lib/theme/app_colors.dart`, `lib/theme/app_theme.dart`
