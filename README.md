# LeanLog 🥗

A native iOS nutrition tracking app built with SwiftUI and SwiftData. Track your meals, scan barcodes, create custom recipes, and monitor 30+ macro and micronutrients with a clean, modern interface.

**Tech Stack**: SwiftUI • SwiftData • AVFoundation • iOS 17+

## Features

### 🎯 Smart Goal Setting
- Personalized calorie and macro targets based on your profile
- Multiple goal types: weight loss, maintenance, muscle gain
- Activity level adjustments for accurate recommendations
- Support for various diet types (balanced, high protein, low carb, keto)
- Automatic BMR and TDEE calculations

### 📊 Comprehensive Nutrition Tracking
- Log individual foods or entire meals
- Track calories and macronutrients (protein, carbs, fat)
- Monitor 30+ micronutrients including:
  - Vitamins (A, B-complex, C, D, E, K)
  - Major minerals (calcium, iron, magnesium, potassium, etc.)
  - Trace minerals (selenium, zinc, copper, etc.)
  - Detailed carb breakdown (sugars, fiber)
  - Detailed fat breakdown (saturated, trans, mono/polyunsaturated)

### 🔍 Multiple Food Entry Methods
- **Barcode Scanner**: Scan product barcodes for instant nutrition data via OpenFoodFacts
- **USDA Search**: Search 800,000+ foods from the USDA FoodData Central database
- **Manual Entry**: Add custom foods with complete nutritional information
- **Recent Foods**: Quick access to recently logged items
- **Meal Templates**: Create and save recipes with multiple ingredients

### 📱 Beautiful, Modern Interface
- Clean, Apple-native design with dark mode support
- Smooth animations and haptic feedback
- Color-coded macronutrient tracking
- Interactive charts and progress visualizations
- Swipe gestures for quick actions

### 📈 Progress Tracking
- Daily nutrition overview with goal progress
- Weekly statistics and trends
- Day-by-day breakdown charts
- Intelligent insights and recommendations
- CSV export for external analysis

### 🍽️ Meal Management
- Create custom meal templates with multiple ingredients
- Calculate nutrition per 100g automatically
- Favorite frequently used meals
- Edit and update meal recipes
- Quick meal logging with portion control

## Technical Highlights

### Architecture & Design
- **SwiftUI + SwiftData**: iOS 17's modern persistence layer for type-safe local storage
- **MVVM Pattern**: Clean separation of concerns with SwiftData models as single source of truth
- **Reactive UI**: `@Query`, `@Environment`, and property wrappers for automatic UI updates
- **Modular Design**: Separated networking, models, UI components, and utilities

### Performance & Optimizations
- Debounced search (300ms) for USDA API calls
- Date-based filtering using normalized timestamps for fast queries
- Async/await concurrency for network operations
- Lazy loading for smooth scrolling with large datasets

### Implementation Details
- Service layer abstraction for USDA and OpenFoodFacts APIs
- Locale-aware number formatting for international support
- Comprehensive error handling with graceful fallbacks
- Secure API key management via excluded plist

## Technical Details

### Architecture
- **Framework**: SwiftUI + SwiftData
- **Minimum iOS Version**: iOS 17.0+
- **Design Pattern**: MVVM with SwiftData models
- **Persistence**: SwiftData for local storage

### Key Technologies
- **SwiftData**: Modern data persistence with automatic schema migration
- **AVFoundation**: Real-time barcode scanning
- **URLSession**: Async/await networking with structured concurrency
- **Swift Concurrency**: Task-based async operations

### Data Models

#### FoodEntry
Primary model for individual food logs with comprehensive nutritional data:
- Basic info (name, calories, serving size/unit)
- Timestamps for filtering and ordering
- Source tracking (USDA, OpenFoodFacts, Manual, Barcode)
- Complete macro and micronutrient profiles

#### Meal
Recipe templates with ingredient relationships:
- Name and total yield (in grams)
- Relationship with multiple ingredients
- Auto-calculated nutrition per 100g
- Favorite marking and usage tracking

#### UserProfile
User goals and preferences:
- Personal metrics (age, sex, height, weight)
- Goal type and activity level
- Diet preferences
- Calculated daily targets

### API Integrations

#### USDA FoodData Central
- Search 800,000+ foods
- Detailed nutritional information
- Standard serving sizes
- Brand and generic foods

#### OpenFoodFacts
- Barcode scanning support
- International product database
- Community-driven data
- Comprehensive micronutrient data

### Project Structure

```
LeanLog/
├── Models/
│   └── FoodEntry.swift          # Core data model
├── Services/
│   └── Networking/
│       ├── USDAService.swift    # USDA API client
│       └── OpenFoodFactsService.swift  # OFF API client
├── UI/
│   ├── Home/
│   │   └── HomeView.swift       # Main logging screen
│   ├── Food/
│   │   ├── AddFoodView.swift    # Food entry form
│   │   ├── EditFoodView.swift   # Edit existing entries
│   │   └── FoodSearchView.swift # USDA search
│   └── Scanner/
│       ├── BarcodeScannerViewController.swift
│       └── BarcodeScannerWrapper.swift
├── Theme/
│   └── AppTheme.swift           # Design system
├── Utilities/
│   └── LocalizedNumberIO.swift  # Locale-aware number formatting
├── GoalsView.swift              # Goal setting & onboarding
├── MealsView.swift              # Meal template management
├── CreateMealView.swift         # New meal creation
├── EditMealView.swift           # Meal editing
├── AddIngredientView.swift      # Ingredient entry
├── WeeklyView.swift             # Progress & analytics
├── SettingsView.swift           # App settings
├── MainTabView.swift            # Tab navigation
└── LeanLogApp.swift             # App entry point
```

## Setup & Installation

### Prerequisites
- Xcode 15.0+
- iOS 17.0+ device or simulator
- USDA API Key (free from [FoodData Central](https://fdc.nal.usda.gov/api-key-signup.html))

### Installation Steps

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd LeanLog
   ```

2. **Configure API Keys**
   
   Copy the template and add your API key:
   ```bash
   cp LeanLog/Secrets.plist.template LeanLog/Secrets.plist
   ```
   
   Then edit `Secrets.plist` and replace `YOUR_USDA_API_KEY_HERE` with your actual API key.
   
   ⚠️ **Important**: `Secrets.plist` is excluded from version control. Never commit it to git.

3. **Open in Xcode**
   ```bash
   open LeanLog.xcodeproj
   ```

4. **Build and Run**
   - Select your target device or simulator
   - Press `Cmd + R` to build and run

### Getting a USDA API Key

1. Visit [USDA FoodData Central API](https://fdc.nal.usda.gov/api-key-signup.html)
2. Sign up for a free API key (requires valid email address)
3. Copy your API key from the confirmation email
4. Add the key to `Secrets.plist` (never commit this file!)

## Usage Guide

### First Time Setup
1. Launch the app and complete the onboarding
2. Enter your personal information (age, height, weight)
3. Select your goal type and activity level
4. Choose your preferred diet type
5. Review your calculated daily targets

### Logging Food
1. Navigate to the "Logs" tab
2. Tap the "+" button to add food
3. Choose your entry method:
   - **Scan**: Use barcode scanner
   - **Search**: Search USDA database
   - **Quick Add**: Manual entry
4. Adjust serving size if needed
5. Save to log

### Creating Meals
1. Go to the "Meals" tab
2. Tap "Create New Meal"
3. Add a meal name and total yield
4. Add ingredients using search, scan, or manual entry
5. Save your meal template
6. Log the meal with custom serving sizes

### Tracking Progress
1. Check daily progress on the "Logs" tab
2. View weekly trends in the "Progress" tab
3. Export data via CSV for external analysis

## Design System

LeanLog implements a centralized design system ([AppTheme.swift](LeanLog/Theme/AppTheme.swift)):

### Design Principles
- **Native Feel**: Follows Apple's Human Interface Guidelines
- **Dynamic Theming**: Automatic light/dark mode with semantic color system
- **Accessibility First**: System font scaling and high contrast support
- **Consistent Spacing**: Standardized layout constants (xs/sm/md/lg/xl)
- **Reusable Components**: Modular view modifiers for cards, buttons, and fields

### Color System
```swift
// Dynamic colors adapt to light/dark mode
static let background = dynamic(light: .systemGroupedBackground, dark: .black)
static let surface = dynamic(light: .secondarySystemGroupedBackground, dark: custom)
```

### Typography
Consistent font scaling using `AppTheme.Typography` with weights for title, headline, body, callout, and caption styles.

## Technical Challenges

### Challenge: Locale-Aware Number Input
**Problem**: SwiftUI's TextField doesn't respect decimal separators across locales (comma vs period)  
**Solution**: Built `LocalizedNumberIO` utility that sanitizes input based on user's locale settings

### Challenge: Efficient Date-Based Queries
**Problem**: SwiftData queries on exact timestamps are slow for date ranges  
**Solution**: Normalized all entries to `startOfDay` for fast indexed queries while preserving exact timestamps

### Challenge: Missing Nutrition Data
**Problem**: External APIs (USDA/OpenFoodFacts) have incomplete/missing nutritional fields  
**Solution**: Designed models with all optional nutrients, gracefully handle nil values in UI with fallbacks

### Challenge: Barcode Scanner UX
**Problem**: Scanning barcodes requires async API call before showing edit form  
**Solution**: Implemented intermediate loading state with error handling, allowing manual entry fallback

## Known Limitations

- **Camera Permissions**: Barcode scanning requires camera access (iOS standard permission flow)
- **API Rate Limits**: USDA free tier limited to 1000 requests/hour (adequate for single-user app)
- **bout This Project

LeanLog is a portfolio project showcasing production-ready iOS development. It demonstrates:
- Modern SwiftUI architecture and best practices
- Integration with external REST APIs
- Barcode scanning requires camera access (standard iOS permission flow)
- USDA free tier limited to 1000 requests/hour
- Offline mode not supported - internet required for searches
- OpenFoodFacts coverage varies by region

## Data Privacy

- All data stored locally using SwiftData - no cloud sync or remote storage
- Zero analytics, crash reporting, or user behavior tracking
- API calls go directly to USDA/OpenFoodFacts - no intermediary servers
- API keys stored in excluded plist file (`.gitignore` prevents accidental commits)
- Template file provided for easy setup

## Future Enhancements

- Apple Health integration (HealthKit)
- Widget support (WidgetKit)
- Watch app companion
- Photo-based logging (Vision framework)
- iCloud sync (CloudKit)

## Acknowledgments

- **USDA FoodData Central** - Comprehensive nutrition database
- **OpenFoodFacts** - Open product database for barcode scanning
- **Apple** - SwiftUI, SwiftData, AVFoundation, and SF Symbols

---

Copyright © 2026 Lokesh Kaki. All rights reserved.
