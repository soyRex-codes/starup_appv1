# FounderVers Mobile Design System

## 🎨 Material Design 3 Implementation

**Design System Version**: Material Design 3 (Material You)  
**Flutter Version**: 3.24.0+  
**Theme System**: Dynamic color schemes with brand consistency

## 🌈 Color Palette & Theming

### **Material Design 3 Color System**

The app implements Material Design 3's semantic color system with custom brand colors:

```dart
// lib/core/theme/app_theme.dart
class AppTheme {
  static final ColorScheme lightColorScheme = ColorScheme.fromSeed(
    seedColor: Color(0xFFFF6B35),           // Primary brand orange
    brightness: Brightness.light,
  );
  
  static final ColorScheme darkColorScheme = ColorScheme.fromSeed(
    seedColor: Color(0xFFFF6B35),           // Primary brand orange
    brightness: Brightness.dark,
  );
}
```

### **Semantic Color Roles**

| Role | Light | Dark | Usage |
|------|-------|------|-------|
| **Primary** | `#FF6B35` | `#FFB4A0` | Main brand actions, CTAs |
| **Primary Container** | `#FFEDE9` | `#4A2C23` | Subtle brand emphasis |
| **Secondary** | `#77574A` | `#E7BDB0` | Supporting actions |
| **Tertiary** | `#6B5D2F` | `#D2C5A0` | Accent elements |
| **Surface** | `#FFFBFF` | `#1C1B1F` | Card backgrounds |
| **Surface Variant** | `#F5DDD8` | `#52443E` | Subtle differentiation |
| **Outline** | `#85736E` | `#9C8A84` | Borders, dividers |

### **Custom Brand Extensions**

```dart
// Additional brand colors for specific contexts
extension AppColors on ColorScheme {
  // Investment & Financial Actions
  Color get investment => Color(0xFFFF6B35);           // Primary orange
  Color get investmentContainer => Color(0xFFFFEDE9);  // Light orange
  
  // Collaboration & Networking
  Color get collaboration => Color(0xFFFFA726);        // Golden yellow
  Color get collaborationContainer => Color(0xFFFFF4E6); // Light yellow
  
  // Success & Growth
  Color get success => Color(0xFF4CAF50);             // Material green
  Color get successContainer => Color(0xFFE8F5E8);    // Light green
  
  // Warning & Caution
  Color get warning => Color(0xFFFF9800);             // Material amber
  Color get warningContainer => Color(0xFFFFF3E0);    // Light amber
}
```

## 🎨 Typography System

### **Material Design 3 Type Scale**

```dart
// Implementing Material Design 3 typography
class AppTextTheme {
  static TextTheme get textTheme => TextTheme(
    // Headlines
    displayLarge: GoogleFonts.inter(
      fontSize: 57, fontWeight: FontWeight.w400, letterSpacing: -0.25,
    ),
    displayMedium: GoogleFonts.inter(
      fontSize: 45, fontWeight: FontWeight.w400,
    ),
    displaySmall: GoogleFonts.inter(
      fontSize: 36, fontWeight: FontWeight.w400,
    ),
    
    // Headlines
    headlineLarge: GoogleFonts.inter(
      fontSize: 32, fontWeight: FontWeight.w400,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: 28, fontWeight: FontWeight.w400,
    ),
    headlineSmall: GoogleFonts.inter(
      fontSize: 24, fontWeight: FontWeight.w400,
    ),
    
    // Titles
    titleLarge: GoogleFonts.inter(
      fontSize: 22, fontWeight: FontWeight.w500,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.15,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1,
    ),
    
    // Body text
    bodyLarge: GoogleFonts.inter(
      fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.5,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4,
    ),
    
    // Labels
    labelLarge: GoogleFonts.inter(
      fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5,
    ),
  );
}
```

## 🧩 Component Design System

### **Button System**

#### **Primary Actions (Investment, Key CTAs)**
```dart
FilledButton(
  onPressed: () => investInStartup(),
  style: FilledButton.styleFrom(
    backgroundColor: Theme.of(context).colorScheme.primary,
    foregroundColor: Theme.of(context).colorScheme.onPrimary,
  ),
  child: Text('Invest Now'),
)
```

#### **Secondary Actions (Collaboration)**
```dart
FilledButton.tonal(
  onPressed: () => startCollaboration(),
  child: Text('Collaborate'),
)
```

#### **Tertiary Actions (Less Important)**
```dart
OutlinedButton(
  onPressed: () => suggestImprovement(),
  child: Text('Suggest'),
)
```

### **Card System**

#### **Standard Content Cards**
```dart
Card(
  elevation: 1,
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Post Title', style: Theme.of(context).textTheme.titleMedium),
        SizedBox(height: 8),
        Text('Post description...', style: Theme.of(context).textTheme.bodyMedium),
      ],
    ),
  ),
)
```

#### **Elevated Cards (Important Content)**
```dart
Card(
  elevation: 3,
  child: Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Theme.of(context).colorScheme.primaryContainer,
          Theme.of(context).colorScheme.surface,
        ],
      ),
    ),
    child: content,
  ),
)
```

## 📐 Layout & Spacing System

### **Material Design 3 Spacing Scale**

```dart
class AppSpacing {
  static const double xs = 4.0;    // Extra small spacing
  static const double sm = 8.0;    // Small spacing
  static const double md = 16.0;   // Medium spacing (base unit)
  static const double lg = 24.0;   // Large spacing
  static const double xl = 32.0;   // Extra large spacing
  static const double xxl = 48.0;  // Extra extra large spacing
}
```

### **Responsive Layout Guidelines**

```dart
class AppLayout {
  static EdgeInsets get pageMargin => EdgeInsets.symmetric(
    horizontal: 16.0,  // Consistent page margins
    vertical: 8.0,
  );
  
  static EdgeInsets get cardPadding => EdgeInsets.all(16.0);
  
  static double get borderRadius => 12.0; // Material Design 3 standard
  
  static BorderRadius get cardBorderRadius => BorderRadius.circular(12.0);
}
```

## 🎯 Component Usage Guidelines

### **Investment-Related Actions**
- **Color**: Primary (orange)
- **Style**: FilledButton with high emphasis
- **Context**: Funding, investment decisions, financial commitments

### **Collaboration & Networking**
- **Color**: Secondary/Tertiary tones
- **Style**: FilledButton.tonal for medium emphasis
- **Context**: Partnership requests, team building, networking

### **Content Interaction**
- **Color**: Surface variants
- **Style**: OutlinedButton or TextButton for low emphasis
- **Context**: Likes, shares, suggestions, comments

### **Navigation & System Actions**
- **Color**: Outline or surface colors
- **Style**: IconButton or NavigationBar items
- **Context**: Tab navigation, menu items, back buttons

| State | Color | Usage |
|-------|--------|--------|
| **Active Navigation** | `AppColors.primarySoft` | Selected nav items |
| **Focused Input** | `AppColors.primary` | Form field borders |
| **Selected Filter** | `AppColors.primary` | Filter chips, options |
| **Unread Badge** | `AppColors.primary` | Message notifications |

### DO NOT Use Orange For

- ❌ **Error states** → Use `Colors.red` or `AppColors.danger`
- ❌ **Success confirmations** → Use `Colors.green`
- ❌ **Warning alerts** → Use `Colors.amber`
- ❌ **Neutral/disabled states** → Use `Colors.grey`

## 🧩 Component Specifications

### Action Buttons

```dart
// Standard Action Button
_ActionButton(
  label: 'Invest',
  icon: AppIcons.money(size: 14),
  color: AppColors.primary,
  onPressed: () => handleAction(),
)

// Specifications
- Padding: EdgeInsets.symmetric(vertical: 10, horizontal: 6)
- Border radius: 10px
- Icon size: 14px
- Font size: 12px
- Font weight: FontWeight.w600
- Text scaling: FittedBox for responsive text
```

### Navigation Bar

```dart
// Navigation styling
Container(
  decoration: BoxDecoration(
    color: AppColors.bg,
    border: Border(top: BorderSide(color: AppColors.border)),
  ),
  // Active state background: AppColors.primarySoft
  // Badge color: AppColors.primary
)
```

### Cards & Containers

```dart
// Post cards
Container(
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 18,
        offset: Offset(0, 8),
      ),
    ],
  ),
)
```

### Form Elements

```dart
// Input decoration
InputDecorationTheme(
  filled: true,
  fillColor: AppColors.card,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: AppColors.border, width: 1),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: AppColors.primary, width: 1.4),
  ),
)
```

## 📱 Responsive Design

### Action Button Optimization

```dart
// Mobile-optimized spacing
- Vertical padding: 10px (reduced from 12px)
- Horizontal padding: 6px (reduced from 10px)
- Icon spacing: 4px (reduced from 6px)
- Icon size: 14px (reduced from 16px)
- Font size: 12px (reduced from 13px)
```

### Text Scaling

```dart
// Responsive text handling
Flexible(
  child: FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      maxLines: 1,
    ),
  ),
)
```

## 🌟 Brand Alignment

### Logo Color Extraction

The color scheme is directly inspired by the FounderVers logo:

- **Primary Orange** (`#FF6B35`): Main wing/body color from logo
- **Golden Yellow** (`#FFA726`): Bird head/accent color from logo  
- **Deep Orange** (`#E65100`): Wing tip emphasis color from logo

### Psychological Impact

- **Orange**: Energy, innovation, enthusiasm, creativity
- **Yellow**: Optimism, collaboration, warmth, friendliness
- **Combined**: Perfect for startup/entrepreneur community platform

### Visual Hierarchy

1. **Primary Orange**: Most important actions (invest, main CTAs)
2. **Golden Yellow**: Secondary actions (collaborate, partner)
3. **Deep Orange**: Tertiary actions (suggest, feedback)
4. **Warm Backgrounds**: Supporting, non-distracting context

## 🔧 Implementation Examples

### Theme Integration

```dart
// App theme setup
ThemeData buildAppTheme() {
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    primaryColor: AppColors.primary,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      surface: AppColors.bg,
    ),
  );
}
```

### Gradient Usage

```dart
// Subtle orange gradients for premium feel
LinearGradient(
  colors: [AppColors.primarySoft, AppColors.subtleFill],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
)
```

### Animation Colors

```dart
// Orange-themed loading states
CircularProgressIndicator(
  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
)

// Orange refresh indicators
RefreshIndicator(
  color: AppColors.primary,
  backgroundColor: Colors.white,
)
```

## 📋 Quality Checklist

### Before Using Colors

- [ ] Is this an error state? → Use red, not orange
- [ ] Is this a success state? → Use green, not orange
- [ ] Is this neutral/disabled? → Use grey, not orange
- [ ] Does it match the action hierarchy? (Primary > Accent > AccentDark)
- [ ] Is contrast ratio accessible? (4.5:1 minimum)
- [ ] Does it feel warm and approachable?

### Testing

- [ ] Test on light backgrounds
- [ ] Test with colorblind simulation
- [ ] Verify brand consistency
- [ ] Check mobile readability
- [ ] Validate against design system

---

**Design System Version**: 1.0.0  
**Last Updated**: September 1, 2025  
**Maintained by**: FounderVers Design Team
