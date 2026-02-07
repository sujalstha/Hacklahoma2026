HACKLAHOMA_2026

# iOS Nutrition & Meal Planning App - Backend Logic

## 📱 Overview
This is a complete backend implementation for a nutrition tracking and meal planning iOS app with three main sections:
1. **Recipes** - Browse, create, and manage recipes
2. **Inventory** - Barcode scanning and food storage management
3. **Macros** - Daily and weekly nutrition tracking

## 🗂️ Project Structure

```
/
├── LoginManager.swift              # Authentication & login logic
├── AppCoordinator.swift            # App flow coordination
├── AppModels.swift                 # All data models
├── RecipeManager.swift             # Recipe CRUD operations
├── InventoryManager.swift          # Inventory & barcode scanning
├── MacroTrackingManager.swift      # Nutrition tracking
├── BarcodeScannerViewController.swift  # Camera-based barcode scanner
└── ViewControllers.swift           # Main UI controllers
```

## 🔐 Authentication System

### LoginManager
Handles user authentication with secure token storage using iOS Keychain.

**Features:**
- Username/password login
- Secure token storage in Keychain
- Session management
- Auto-logout

**Usage:**
```swift
LoginManager.shared.login(username: "user", password: "pass") { result in
    switch result {
    case .success(let user):
        print("Logged in as \(user.username)")
        AppCoordinator.shared.showMainApp()
    case .failure(let error):
        print("Login failed: \(error.description)")
    }
}
```

## 📊 Data Models

### Recipe
```swift
struct Recipe {
    let id: String
    var name: String
    var ingredients: [RecipeIngredient]
    var instructions: [String]
    var servings: Int
    var macros: MacroNutrients
    var category: RecipeCategory  // Breakfast, Lunch, Dinner, Snack, Dessert
    var isFavorite: Bool
}
```

### InventoryItem
```swift
struct InventoryItem {
    let id: String
    var foodItem: FoodItem
    var quantity: Double
    var expirationDate: Date?
    var location: StorageLocation  // Pantry, Fridge, Freezer
    var isExpiringSoon: Bool  // Auto-calculated
    var isExpired: Bool       // Auto-calculated
}
```

### DailyMacroLog
```swift
struct DailyMacroLog {
    let id: String
    var date: Date
    var meals: [MealLog]
    var totalMacros: MacroNutrients
    var waterIntake: Double
}
```

## 🍽️ Section 1: Recipes

### RecipeManager
Manages all recipe operations with server sync.

**Features:**
- Fetch all recipes
- Create new recipes
- Update existing recipes
- Delete recipes
- Search and filter by category
- Mark favorites
- Calculate recipe macros

**Example Usage:**
```swift
// Fetch all recipes
RecipeManager.shared.fetchRecipes { result in
    switch result {
    case .success(let recipes):
        self.recipes = recipes
    case .failure(let error):
        print(error)
    }
}

// Create a new recipe
let recipe = Recipe(
    id: UUID().uuidString,
    name: "Protein Pancakes",
    ingredients: [...],
    instructions: [...],
    servings: 2,
    macros: MacroNutrients(calories: 350, protein: 25, carbohydrates: 40, fat: 8)
)

RecipeManager.shared.createRecipe(recipe) { result in
    // Handle result
}

// Search recipes
let results = RecipeManager.shared.searchRecipes(query: "chicken", category: .dinner)
```

## 📦 Section 2: Inventory & Barcode Scanning

### InventoryManager
Handles food inventory and barcode scanning via OpenFoodFacts API.

**Features:**
- Add/update/delete inventory items
- Barcode lookup (OpenFoodFacts API)
- Sort by expiration date
- Filter by storage location
- Track expiring items
- Auto-alert for expired items
- Reduce quantity when using items

**Barcode Scanning:**
```swift
// Scan barcode
let scannerVC = BarcodeScannerViewController()
scannerVC.delegate = self
present(scannerVC, animated: true)

// Handle scanned barcode
func didScanBarcode(_ barcode: String) {
    InventoryManager.shared.lookupBarcode(barcode) { result in
        switch result {
        case .success(let product):
            print("Found: \(product.productName)")
            // Add to inventory
        case .failure:
            print("Product not found")
        }
    }
}
```

**Inventory Operations:**
```swift
// Get expiring items
let expiringItems = InventoryManager.shared.getExpiringSoonItems()

// Filter by location
let fridgeItems = InventoryManager.shared.filterInventory(by: .fridge)

// Use an item (reduce quantity)
InventoryManager.shared.useItem(id: itemId, amount: 100) { result in
    // Item quantity reduced or deleted if depleted
}
```

### BarcodeScannerViewController
Full-featured camera-based barcode scanner using AVFoundation.

**Supported Barcode Types:**
- EAN-8, EAN-13
- UPC-E
- Code 39, 93, 128
- QR Codes
- PDF417
- Data Matrix

## 📈 Section 3: Macro Tracking

### MacroTrackingManager
Tracks daily nutrition and provides weekly summaries.

**Features:**
- Daily meal logging
- Water intake tracking
- Goal setting and progress tracking
- Weekly summaries
- Macro calculations
- Goal achievement alerts

**Usage:**
```swift
// Get today's log
MacroTrackingManager.shared.getTodayLog { result in
    switch result {
    case .success(let log):
        print("Today's calories: \(log.totalMacros.calories)")
    case .failure(let error):
        print(error)
    }
}

// Log a meal
let meal = MealLog(
    id: UUID().uuidString,
    mealType: .breakfast,
    recipeId: recipeId,
    customFoodItems: [],
    timestamp: Date(),
    totalMacros: recipeMacros
)

MacroTrackingManager.shared.logMeal(meal) { result in
    // Updated daily log
}

// Get weekly summary
MacroTrackingManager.shared.getWeeklySummary(for: Date()) { result in
    switch result {
    case .success(let summary):
        print("Weekly average: \(summary.averageDailyMacros.calories) cal/day")
    case .failure(let error):
        print(error)
    }
}

// Set goals
let goals = MacroGoals(
    dailyCalories: 2000,
    dailyProtein: 150,
    dailyCarbs: 200,
    dailyFat: 65,
    dailyWaterIntake: 2000,
    userId: userId
)

MacroTrackingManager.shared.updateUserGoals(goals) { result in
    // Goals updated
}
```

## 🚀 Setup Instructions

### 1. Configure API Endpoints
Update the `baseURL` in each manager:
```swift
// In LoginManager.swift
private let baseURL = "https://your-api.com"

// In RecipeManager.swift
private let baseURL = "https://your-api.com"

// In InventoryManager.swift
private let baseURL = "https://your-api.com"

// In MacroTrackingManager.swift
private let baseURL = "https://your-api.com"
```

### 2. Add Required Permissions to Info.plist
```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to scan barcodes</string>
```

### 3. Initialize App Coordinator
In your AppDelegate or SceneDelegate:
```swift
func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    guard let windowScene = (scene as? UIWindowScene) else { return }
    
    let window = UIWindow(windowScene: windowScene)
    AppCoordinator.shared.start(with: window)
}
```

### 4. Required Dependencies
- **iOS 14.0+**
- **AVFoundation** (for barcode scanning)
- **Security** (for Keychain storage)

## 🔌 API Endpoints Expected

### Authentication
```
POST   /auth/login
Body: { username, password }
Response: { success, token, user }
```

### Recipes
```
GET    /recipes
POST   /recipes
PUT    /recipes/:id
DELETE /recipes/:id
```

### Inventory
```
GET    /inventory
POST   /inventory
PUT    /inventory/:id
DELETE /inventory/:id
```

### Macros
```
GET    /macros/daily?date=YYYY-MM-DD
POST   /macros/daily
PUT    /macros/daily/:id
GET    /macros/weekly?start=YYYY-MM-DD&end=YYYY-MM-DD
GET    /macros/goals
PUT    /macros/goals
```

## 📝 Key Features

### Security
✅ Keychain storage for auth tokens
✅ Bearer token authentication
✅ Auto-logout on token expiration
✅ Secure password handling (never stored locally)

### User Experience
✅ Real-time barcode scanning
✅ Expiration date tracking with visual alerts
✅ Search and filter capabilities
✅ Offline data caching
✅ Progress tracking with goals
✅ Weekly analytics

### Data Management
✅ Automatic macro calculations
✅ Ingredient-based macro rollup
✅ Smart inventory sorting
✅ Favorite recipes
✅ Meal history

## 🎨 UI Components

### Tab Bar Structure
1. **Recipes Tab** - Browse and manage recipes
2. **Inventory Tab** - Scan and track food items
3. **Macros Tab** - View nutrition data and progress

### Navigation Flow
```
Login Screen
    ↓
Main Tab Bar
    ├── Recipes
    │   ├── Recipe List
    │   └── Recipe Detail
    ├── Inventory
    │   ├── Inventory List
    │   └── Barcode Scanner
    └── Macros
        ├── Daily View
        └── Weekly Summary
```

## 🔧 Customization

### Adding New Barcode APIs
You can easily switch or add barcode lookup APIs in `InventoryManager.lookupBarcode()`:

```swift
// Current: OpenFoodFacts
// Alternative: USDA FoodData Central, Nutritionix, etc.
```

### Extending Data Models
All models are in `AppModels.swift` and use `Codable` for easy JSON serialization.

### Custom Macro Goals
Modify `MacroGoals` struct to add custom targets (e.g., micronutrients).

## 📊 Example Workflow

1. **User logs in** → LoginManager authenticates
2. **Scans chicken breast barcode** → InventoryManager looks up nutrition data
3. **Adds to inventory** → Item stored with expiration date
4. **Creates recipe** → RecipeManager with chicken as ingredient
5. **Logs meal** → MacroTrackingManager updates daily totals
6. **Views weekly progress** → Chart shows macro trends

## 🚨 Error Handling

All managers use Swift's Result type for error handling:
```swift
enum LoginError: Error {
    case invalidCredentials
    case networkError
    case serverError(String)
    case tokenStorageError
}
```

## 📱 Production Checklist

- [ ] Replace all API URLs with production endpoints
- [ ] Add SSL certificate pinning
- [ ] Implement proper error logging (e.g., Crashlytics)
- [ ] Add analytics tracking
- [ ] Implement data persistence/sync
- [ ] Add unit tests
- [ ] Add UI tests for barcode scanner
- [ ] Implement proper loading states
- [ ] Add network reachability checks
- [ ] Implement offline mode

## 🤝 Contributing

This is a complete backend structure. To extend:
1. Add new managers for additional features
2. Extend existing models with new properties
3. Add new API endpoints in corresponding managers
4. Update view controllers with new UI

## 📄 License
Private repository — All rights reserved.  
No permission is granted to use, copy, modify, or distribute this code without explicit written permission.
****
