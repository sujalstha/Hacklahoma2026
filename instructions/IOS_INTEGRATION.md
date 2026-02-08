# iOS Integration Guide - What's For Dinner

Complete guide for connecting your iOS app to the backend API.

## 🔗 API Base URL

**Local Testing:**
```swift
let baseURL = "http://127.0.0.1:8000"
```

**Production:** (Deploy backend to Railway, Render, etc.)
```swift
let baseURL = "https://your-backend-url.com"
```

## 📱 Required iOS Screens

Based on your backend, you'll need these screens:

1. **Onboarding** - Set preferences (allergens, macro goals)
2. **Home/Dashboard** - View today's recipe suggestion
3. **Inventory** - Scan barcodes, view pantry items
4. **Recipe Detail** - Show cooking steps, accept/swap recipe
5. **History** - View past dinners and macro progress
6. **Settings** - Update dietary restrictions

## 🏗️ Project Structure (Recommended)

```
WhatsFordinner/
├── Models/
│   ├── PantryModels.swift      # Inventory, preferences
│   ├── RecipeModels.swift      # Recipe data structures
│   └── UserModels.swift        # User/auth
├── Services/
│   ├── APIService.swift        # All API calls
│   ├── BarcodeScanner.swift    # Camera barcode scanning
│   └── NotificationService.swift
├── Views/
│   ├── OnboardingView.swift
│   ├── HomeView.swift
│   ├── InventoryView.swift
│   ├── RecipeDetailView.swift
│   ├── HistoryView.swift
│   └── SettingsView.swift
└── ViewModels/
    ├── InventoryViewModel.swift
    ├── RecipeViewModel.swift
    └── HistoryViewModel.swift
```

## 📦 Swift Data Models

Create these models to match your backend:

### Models/PantryModels.swift
```swift
import Foundation

// Enums matching backend
enum DietaryRestriction: String, Codable, CaseIterable {
    case glutenFree = "gluten_free"
    case dairyFree = "dairy_free"
    case nutFree = "nut_free"
    case eggFree = "egg_free"
    case soyFree = "soy_free"
    case shellfishFree = "shellfish_free"
    case fishFree = "fish_free"
    case porkFree = "pork_free"
    case vegetarian = "vegetarian"
    case vegan = "vegan"
    case halal = "halal"
    case kosher = "kosher"
    case lowCarb = "low_carb"
    case keto = "keto"
    
    var displayName: String {
        switch self {
        case .glutenFree: return "Gluten Free"
        case .dairyFree: return "Dairy Free"
        case .nutFree: return "Nut Free"
        case .eggFree: return "Egg Free"
        case .soyFree: return "Soy Free"
        case .shellfishFree: return "Shellfish Free"
        case .fishFree: return "Fish Free"
        case .porkFree: return "Pork Free"
        case .vegetarian: return "Vegetarian"
        case .vegan: return "Vegan"
        case .halal: return "Halal"
        case .kosher: return "Kosher"
        case .lowCarb: return "Low Carb"
        case .keto: return "Keto"
        }
    }
}

enum Category: String, Codable {
    case protein, grain, vegetable, fruit, dairy
    case condiment, spice, canned, frozen
    case snack, beverage, other
}

enum UnitType: String, Codable {
    case piece, lb, oz, g, kg
    case cup, tbsp, tsp, ml, l, gallon
    case package, pinch
}

// User Preferences
struct UserPreferences: Codable {
    let id: Int?
    let userId: Int?
    var dietaryRestrictions: [DietaryRestriction]
    var targetCalories: Double?
    var targetProtein: Double?
    var targetCarbs: Double?
    var targetFat: Double?
    var householdSize: Int
    var preferredCuisines: [String]
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, userId = "user_id"
        case dietaryRestrictions = "dietary_restrictions"
        case targetCalories = "target_calories"
        case targetProtein = "target_protein"
        case targetCarbs = "target_carbs"
        case targetFat = "target_fat"
        case householdSize = "household_size"
        case preferredCuisines = "preferred_cuisines"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// Pantry Item
struct PantryItem: Codable, Identifiable {
    let id: Int
    let name: String
    let barcode: String?
    let category: Category
    let defaultUnit: UnitType
    let brand: String?
    let caloriesPerServing: Double?
    let proteinPerServing: Double?
    let carbsPerServing: Double?
    let fatPerServing: Double?
    
    enum CodingKeys: String, CodingKey {
        case id, name, barcode, category, brand
        case defaultUnit = "default_unit"
        case caloriesPerServing = "calories_per_serving"
        case proteinPerServing = "protein_per_serving"
        case carbsPerServing = "carbs_per_serving"
        case fatPerServing = "fat_per_serving"
    }
}

// Inventory Item
struct InventoryItem: Codable, Identifiable {
    let id: Int
    let itemId: Int
    let quantity: Double
    let unit: UnitType
    let location: String?
    let isLowStock: Bool
    let item: PantryItem
    
    enum CodingKeys: String, CodingKey {
        case id
        case itemId = "item_id"
        case quantity, unit, location
        case isLowStock = "is_low_stock"
        case item
    }
}

// Dinner History
struct DinnerHistory: Codable, Identifiable {
    let id: Int
    let mealName: String
    let recipeId: String?
    let servings: Int
    let caloriesPerServing: Double?
    let proteinPerServing: Double?
    let carbsPerServing: Double?
    let fatPerServing: Double?
    let rating: Int?
    let notes: String?
    let dateCooked: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case mealName = "meal_name"
        case recipeId = "recipe_id"
        case servings
        case caloriesPerServing = "calories_per_serving"
        case proteinPerServing = "protein_per_serving"
        case carbsPerServing = "carbs_per_serving"
        case fatPerServing = "fat_per_serving"
        case rating, notes
        case dateCooked = "date_cooked"
    }
}

// Macro Summary
struct MacroSummary: Codable {
    let totalMeals: Int
    let avgCalories: Double
    let avgProtein: Double
    let avgCarbs: Double
    let avgFat: Double
    let dateRange: String
    
    enum CodingKeys: String, CodingKey {
        case totalMeals = "total_meals"
        case avgCalories = "avg_calories"
        case avgProtein = "avg_protein"
        case avgCarbs = "avg_carbs"
        case avgFat = "avg_fat"
        case dateRange = "date_range"
    }
}
```

### Models/RecipeModels.swift
```swift
import Foundation

struct Recipe: Codable, Identifiable {
    let id: String
    let name: String
    let servings: Int
    let readyInMinutes: Int
    let imageUrl: String?
    
    // Macros
    let caloriesPerServing: Double
    let proteinPerServing: Double
    let carbsPerServing: Double
    let fatPerServing: Double
    
    // Content
    let ingredients: [Ingredient]
    let steps: [String]
    
    // Metadata
    let source: String
    let spoonacularUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "recipe_id"
        case name, servings
        case readyInMinutes = "ready_in_minutes"
        case imageUrl = "image_url"
        case caloriesPerServing = "calories_per_serving"
        case proteinPerServing = "protein_per_serving"
        case carbsPerServing = "carbs_per_serving"
        case fatPerServing = "fat_per_serving"
        case ingredients, steps, source
        case spoonacularUrl = "spoonacular_url"
    }
}

struct Ingredient: Codable {
    let name: String
    let amount: Double
    let unit: String
}
```

## 🌐 API Service Layer

Create a single service to handle all API calls:

### Services/APIService.swift
```swift
import Foundation

class APIService {
    static let shared = APIService()
    
    private let baseURL = "http://127.0.0.1:8000"
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    
    private init() {}
    
    // MARK: - Generic Request
    
    private func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Encodable? = nil
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let body = body {
            request.httpBody = try encoder.encode(body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        return try decoder.decode(T.self, from: data)
    }
    
    // MARK: - User Preferences
    
    func getUserPreferences() async throws -> UserPreferences {
        try await request(endpoint: "/api/pantry/preferences")
    }
    
    func createPreferences(_ prefs: UserPreferences) async throws -> UserPreferences {
        try await request(
            endpoint: "/api/pantry/preferences",
            method: "POST",
            body: prefs
        )
    }
    
    func updatePreferences(_ prefs: UserPreferences) async throws -> UserPreferences {
        try await request(
            endpoint: "/api/pantry/preferences",
            method: "PATCH",
            body: prefs
        )
    }
    
    // MARK: - Inventory
    
    func getInventory() async throws -> [InventoryItem] {
        try await request(endpoint: "/api/pantry/inventory")
    }
    
    func addToInventory(itemId: Int, quantity: Double, unit: UnitType, location: String?) async throws -> InventoryItem {
        let body: [String: Any] = [
            "item_id": itemId,
            "quantity": quantity,
            "unit": unit.rawValue,
            "location": location as Any
        ]
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        
        guard let url = URL(string: "\(baseURL)/api/pantry/inventory") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try decoder.decode(InventoryItem.self, from: data)
    }
    
    // MARK: - Barcode Scanning
    
    func scanBarcode(_ barcode: String) async throws -> PantryItem? {
        struct ScanRequest: Codable {
            let barcode: String
        }
        
        struct ScanResponse: Codable {
            let found: Bool
            let item: PantryItem?
        }
        
        let response: ScanResponse = try await request(
            endpoint: "/api/pantry/scan",
            method: "POST",
            body: ScanRequest(barcode: barcode)
        )
        
        return response.item
    }
    
    // MARK: - Recipes
    
    func getDailyRecipe() async throws -> Recipe {
        try await request(endpoint: "/api/recipe/daily-suggestion")
    }
    
    func acceptRecipe(_ recipe: Recipe) async throws {
        struct AcceptRequest: Codable {
            let recipeId: String
            let name: String
            let servings: Int
            let caloriesPerServing: Double
            let proteinPerServing: Double
            let carbsPerServing: Double
            let fatPerServing: Double
            let ingredients: [Ingredient]
            
            enum CodingKeys: String, CodingKey {
                case recipeId = "recipe_id"
                case name, servings
                case caloriesPerServing = "calories_per_serving"
                case proteinPerServing = "protein_per_serving"
                case carbsPerServing = "carbs_per_serving"
                case fatPerServing = "fat_per_serving"
                case ingredients
            }
        }
        
        let request = AcceptRequest(
            recipeId: recipe.id,
            name: recipe.name,
            servings: recipe.servings,
            caloriesPerServing: recipe.caloriesPerServing,
            proteinPerServing: recipe.proteinPerServing,
            carbsPerServing: recipe.carbsPerServing,
            fatPerServing: recipe.fatPerServing,
            ingredients: recipe.ingredients
        )
        
        let _: [String: String] = try await self.request(
            endpoint: "/api/recipe/accept",
            method: "POST",
            body: request
        )
    }
    
    func swapRecipe() async throws -> Recipe {
        try await request(endpoint: "/api/recipe/swap", method: "POST")
    }
    
    func getEasyMeal() async throws -> Recipe {
        try await request(endpoint: "/api/recipe/too-tired")
    }
    
    // MARK: - Dinner History
    
    func getDinnerHistory(days: Int = 30) async throws -> [DinnerHistory] {
        try await request(endpoint: "/api/pantry/dinners?days=\(days)")
    }
    
    func getMacroSummary(days: Int = 7) async throws -> MacroSummary {
        try await request(endpoint: "/api/pantry/dinners/macros/summary?days=\(days)")
    }
    
    func rateDinner(dinnerId: Int, rating: Int, notes: String?) async throws {
        struct RatingRequest: Codable {
            let rating: Int
            let notes: String?
        }
        
        let _: [String: String] = try await request(
            endpoint: "/api/pantry/dinners/\(dinnerId)",
            method: "PATCH",
            body: RatingRequest(rating: rating, notes: notes)
        )
    }
}

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodingError
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid server response"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .decodingError:
            return "Failed to decode response"
        }
    }
}
```

## 📸 Barcode Scanner

### Services/BarcodeScanner.swift
```swift
import SwiftUI
import AVFoundation

struct BarcodeScannerView: UIViewControllerRepresentable {
    @Binding var scannedCode: String?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> ScannerViewController {
        ScannerViewController(scannedCode: $scannedCode)
    }
    
    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}
}

class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    @Binding var scannedCode: String?
    
    init(scannedCode: Binding<String?>) {
        self._scannedCode = scannedCode
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean8, .ean13, .upce, .code128]
        } else {
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            scannedCode = stringValue
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if captureSession?.isRunning == true {
            captureSession.stopRunning()
        }
    }
}
```

## 🎨 Example Views

### Views/OnboardingView.swift
```swift
import SwiftUI

struct OnboardingView: View {
    @State private var selectedRestrictions: Set<DietaryRestriction> = []
    @State private var targetCalories: String = "2000"
    @State private var householdSize: Int = 2
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Dietary Restrictions") {
                    ForEach(DietaryRestriction.allCases, id: \.self) { restriction in
                        Toggle(restriction.displayName, isOn: Binding(
                            get: { selectedRestrictions.contains(restriction) },
                            set: { isSelected in
                                if isSelected {
                                    selectedRestrictions.insert(restriction)
                                } else {
                                    selectedRestrictions.remove(restriction)
                                }
                            }
                        ))
                    }
                }
                
                Section("Daily Goals") {
                    HStack {
                        Text("Target Calories")
                        Spacer()
                        TextField("2000", text: $targetCalories)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section("Household") {
                    Stepper("Servings: \(householdSize)", value: $householdSize, in: 1...10)
                }
                
                Button("Get Started") {
                    savePreferences()
                }
                .disabled(isLoading)
            }
            .navigationTitle("Set Up Your Profile")
        }
    }
    
    func savePreferences() {
        isLoading = true
        
        let prefs = UserPreferences(
            id: nil,
            userId: nil,
            dietaryRestrictions: Array(selectedRestrictions),
            targetCalories: Double(targetCalories),
            targetProtein: 150,
            targetCarbs: 200,
            targetFat: 65,
            householdSize: householdSize,
            preferredCuisines: [],
            createdAt: nil,
            updatedAt: nil
        )
        
        Task {
            do {
                _ = try await APIService.shared.createPreferences(prefs)
                // Navigate to home screen
            } catch {
                print("Error saving preferences: \(error)")
            }
            isLoading = false
        }
    }
}
```

### Views/HomeView.swift
```swift
import SwiftUI

struct HomeView: View {
    @State private var todaysRecipe: Recipe?
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            ScrollView {
                if isLoading {
                    ProgressView()
                } else if let recipe = todaysRecipe {
                    RecipeCard(recipe: recipe) {
                        acceptRecipe()
                    } onSwap: {
                        swapRecipe()
                    }
                }
            }
            .navigationTitle("What's For Dinner?")
            .task {
                await loadTodaysRecipe()
            }
        }
    }
    
    func loadTodaysRecipe() async {
        do {
            todaysRecipe = try await APIService.shared.getDailyRecipe()
        } catch {
            print("Error loading recipe: \(error)")
        }
        isLoading = false
    }
    
    func acceptRecipe() {
        guard let recipe = todaysRecipe else { return }
        
        Task {
            do {
                try await APIService.shared.acceptRecipe(recipe)
                // Navigate to cooking view
            } catch {
                print("Error accepting recipe: \(error)")
            }
        }
    }
    
    func swapRecipe() {
        isLoading = true
        Task {
            do {
                todaysRecipe = try await APIService.shared.swapRecipe()
            } catch {
                print("Error swapping recipe: \(error)")
            }
            isLoading = false
        }
    }
}

struct RecipeCard: View {
    let recipe: Recipe
    let onAccept: () -> Void
    let onSwap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Recipe image
            if let imageUrl = recipe.imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray
                }
                .frame(height: 200)
                .clipped()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(recipe.name)
                    .font(.title2)
                    .bold()
                
                HStack {
                    Label("\(recipe.readyInMinutes) min", systemImage: "clock")
                    Spacer()
                    Label("\(recipe.servings) servings", systemImage: "person.2")
                }
                .foregroundColor(.secondary)
                
                // Macros
                HStack(spacing: 20) {
                    MacroLabel(name: "Cal", value: Int(recipe.caloriesPerServing))
                    MacroLabel(name: "Protein", value: Int(recipe.proteinPerServing))
                    MacroLabel(name: "Carbs", value: Int(recipe.carbsPerServing))
                    MacroLabel(name: "Fat", value: Int(recipe.fatPerServing))
                }
                
                Divider()
                
                // Actions
                HStack {
                    Button(action: onSwap) {
                        Label("Swap", systemImage: "arrow.triangle.2.circlepath")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: onAccept) {
                        Label("Cook This!", systemImage: "checkmark")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 5)
        .padding()
    }
}

struct MacroLabel: View {
    let name: String
    let value: Int
    
    var body: some View {
        VStack {
            Text("\(value)g")
                .font(.headline)
            Text(name)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
```

## 🚀 Quick Start for iOS Team

1. **Copy all model files** into your Xcode project
2. **Add APIService.swift** - handles all backend calls
3. **Add BarcodeScannerView.swift** - camera barcode scanning
4. **Create views** using the examples above
5. **Update baseURL** to your backend URL

## 📝 Testing Checklist

- [ ] Can create user preferences (onboarding)
- [ ] Can scan barcode and add to inventory
- [ ] Can fetch daily recipe
- [ ] Recipe shows 5 simplified steps from Gemini
- [ ] Can accept recipe (logs dinner, deducts ingredients)
- [ ] Can swap recipe for a different one
- [ ] Can view dinner history
- [ ] Can see macro progress vs goals

## 🔔 Push Notifications (Optional)

For 5 PM recipe notifications, you'll need:
1. APNs setup in Apple Developer
2. Firebase Cloud Messaging (easier option)
3. Backend endpoint to register device tokens
4. Scheduler on backend to send notifications

Let me know if you need help with notifications!
