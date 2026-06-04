# Design System

## CircleStream — Flutter UI Design System

---

## 1. Design Philosophy

CircleStream menggunakan gaya **soft neumorphic minimal** — terasa premium, personal, dan tidak crowded. Prioritas utama adalah foto, bukan UI chrome.

**Kata kunci:** Warm · Intimate · Clean · Fast · Friendly

---

## 2. Color Palette

```dart
class AppColors {
  // Background
  static const Color background = Color(0xFFF7FAFF);
  static const Color surface    = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFEEF3FB);

  // Primary
  static const Color primary      = Color(0xFF7292CF);
  static const Color primaryLight = Color(0xFF9BB3E0);
  static const Color primaryDark  = Color(0xFF5070AD);

  // Accent
  static const Color accent      = Color(0xFFFF8A71);
  static const Color accentLight = Color(0xFFFFAA96);

  // Text
  static const Color textPrimary   = Color(0xFF2D3250);
  static const Color textSecondary = Color(0xFF8892AA);
  static const Color textHint      = Color(0xFFBBC3D4);

  // Semantic
  static const Color success = Color(0xFF4CAF82);
  static const Color error   = Color(0xFFFF5A5F);
  static const Color warning = Color(0xFFFFB347);

  // Neumorphic shadows
  static const Color shadowLight = Color(0xFFFFFFFF);
  static const Color shadowDark  = Color(0xFFD0D8E8);
}
```

---

## 3. Typography

Font: **DM Sans** (primary) + **Poppins** (headings)

```dart
class AppTextStyles {
  static const String fontPrimary  = 'DMSans';
  static const String fontHeading  = 'Poppins';

  // Display
  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontHeading,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  // Heading
  static const TextStyle h1 = TextStyle(
    fontFamily: fontHeading,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: fontHeading,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: fontHeading,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Body
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontPrimary,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  // Label
  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontPrimary,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    letterSpacing: 0.3,
  );
}
```

---

## 4. Spacing System

```dart
class AppSpacing {
  static const double xs   = 4.0;
  static const double sm   = 8.0;
  static const double md   = 16.0;
  static const double lg   = 24.0;
  static const double xl   = 32.0;
  static const double xxl  = 48.0;
  static const double xxxl = 64.0;
}
```

---

## 5. Border Radius

```dart
class AppRadius {
  static const double sm   = 8.0;
  static const double md   = 16.0;
  static const double lg   = 24.0;
  static const double xl   = 32.0;
  static const double pill = 100.0;
  static const double full = 1000.0;
}
```

---

## 6. Shadows

```dart
class AppShadows {
  // Soft neumorphic shadow
  static List<BoxShadow> get soft => [
    BoxShadow(
      color: AppColors.shadowDark.withOpacity(0.6),
      offset: const Offset(4, 4),
      blurRadius: 12,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: AppColors.shadowLight.withOpacity(0.9),
      offset: const Offset(-4, -4),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];

  // Card shadow
  static List<BoxShadow> get card => [
    BoxShadow(
      color: AppColors.shadowDark.withOpacity(0.4),
      offset: const Offset(0, 4),
      blurRadius: 16,
      spreadRadius: 0,
    ),
  ];

  // Floating / elevated
  static List<BoxShadow> get elevated => [
    BoxShadow(
      color: AppColors.primary.withOpacity(0.25),
      offset: const Offset(0, 8),
      blurRadius: 24,
      spreadRadius: 0,
    ),
  ];
}
```

---

## 7. Core Components

### AppButton

```dart
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isPrimary;
  final bool isLoading;

  // Primary: filled, accent color
  // Secondary: outlined
  // Ghost: text only
}
```

Variants:
- **Primary** — filled `#7292CF`, text white, rounded pill
- **Secondary** — outlined `#7292CF`, transparent fill
- **Ghost** — text only, no border
- **Danger** — filled `#FF5A5F`

---

### AppCard

```dart
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double radius;
  final bool useNeumorphic;
}
```

---

### AppTextField

```dart
class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final bool obscureText;
  final Widget? prefixIcon;
  final String? errorText;
}
```

Style: border radius 16, subtle fill, no hard border

---

### EmojiReactionBar

```dart
class EmojiReactionBar extends StatelessWidget {
  final Map<String, int> counts;
  final Function(String emoji) onReact;

  // Presets: ❤️ 😂 😮 🔥 👏 😢 🤩 💀
  // Show count badge jika > 0
}
```

---

### FloatingEmojiAnimation

```dart
class FloatingEmojiAnimation extends StatefulWidget {
  final String emoji;
  // Animasi emoji naik dari bawah dan fade out
  // Trigger dari Ably reaction_added event
}
```

---

## 8. Bottom Navigation (Floating Pill)

```dart
class AppBottomNav extends StatelessWidget {
  // Berbentuk pill (border radius sangat besar)
  // Floating di atas konten (tidak attached ke bottom)
  // Soft shadow
  // 3 tab: Feed, Camera, Profile
  // Tab aktif: icon + label berwarna primary
  // Tab inaktif: icon saja, warna abu
}
```

---

## 9. Animation Specs

| Animasi | Duration | Curve |
|---|---|---|
| Page transition | 300ms | `Curves.easeInOutCubic` |
| Modal bottom sheet | 350ms | `Curves.easeOutCubic` |
| Emoji float up | 1200ms | `Curves.easeOut` |
| Emoji fade out | 800ms | `Curves.easeIn` |
| Button press | 100ms | `Curves.easeInOut` |
| Card appear | 250ms | `Curves.easeOut` |
| Feed item appear | 200ms | `Curves.easeOut` (staggered) |

---

## 10. pubspec.yaml Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # UI
  google_fonts: ^6.1.0
  
  # State management
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5
  
  # Network
  dio: ^5.4.0
  
  # Image
  flutter_image_compress: ^2.1.0
  cached_network_image: ^3.3.1
  
  # Camera
  camera: ^0.10.5+9
  
  # Real-time
  ably_flutter: ^1.2.23
  
  # Storage
  flutter_secure_storage: ^9.0.0
  
  # Utilities
  uuid: ^4.3.3
  intl: ^0.18.1
  go_router: ^13.0.0
```
