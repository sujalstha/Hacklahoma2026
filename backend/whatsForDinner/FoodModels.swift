import Foundation

// MARK: - Open Food Facts API Response

struct OpenFoodFactsResponse: Codable {
    let status: Int
    let statusVerbose: String?
    let code: String?
    let product: FoodProduct?
    
    enum CodingKeys: String, CodingKey {
        case status
        case statusVerbose = "status_verbose"
        case code
        case product
    }
}

struct FoodProduct: Codable, Identifiable {
    var id: String { code }
    
    let code: String
    let productName: String?
    let brands: String?
    let imageURL: String?
    let quantity: String?
    let categories: String?
    let nutriments: Nutriments?
    
    enum CodingKeys: String, CodingKey {
        case code
        case productName = "product_name"
        case brands
        case imageURL = "image_url"
        case quantity
        case categories
        case nutriments
    }
    
    var displayName: String {
        productName ?? "Unknown Product"
    }
    
    var displayBrand: String {
        brands ?? "Unknown Brand"
    }
}

struct Nutriments: Codable {
    let energyKcal: Double?
    let proteins: Double?
    let carbohydrates: Double?
    let fat: Double?
    let fiber: Double?
    let salt: Double?
    let sugars: Double?
    
    enum CodingKeys: String, CodingKey {
        case energyKcal = "energy-kcal_100g"
        case proteins = "proteins_100g"
        case carbohydrates = "carbohydrates_100g"
        case fat = "fat_100g"
        case fiber = "fiber_100g"
        case salt = "salt_100g"
        case sugars = "sugars_100g"
    }
}

// MARK: - Inventory Item Model

struct InventoryItem: Identifiable, Codable {
    let id: UUID
    let barcode: String
    let productName: String
    let brand: String
    let imageURL: String?
    let quantity: String?
    let dateAdded: Date
    
    // Nutritional info (per 100g)
    let calories: Double?
    let protein: Double?
    let carbs: Double?
    let fat: Double?
    
    init(
        id: UUID = UUID(),
        barcode: String,
        productName: String,
        brand: String,
        imageURL: String? = nil,
        quantity: String? = nil,
        dateAdded: Date = Date(),
        calories: Double? = nil,
        protein: Double? = nil,
        carbs: Double? = nil,
        fat: Double? = nil
    ) {
        self.id = id
        self.barcode = barcode
        self.productName = productName
        self.brand = brand
        self.imageURL = imageURL
        self.quantity = quantity
        self.dateAdded = dateAdded
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
    }
    
    init(from product: FoodProduct) {
        self.id = UUID()
        self.barcode = product.code
        self.productName = product.displayName
        self.brand = product.displayBrand
        self.imageURL = product.imageURL
        self.quantity = product.quantity
        self.dateAdded = Date()
        self.calories = product.nutriments?.energyKcal
        self.protein = product.nutriments?.proteins
        self.carbs = product.nutriments?.carbohydrates
        self.fat = product.nutriments?.fat
    }
}

// MARK: - Sample Data

extension InventoryItem {
    static let samples: [InventoryItem] = [
        InventoryItem(
            barcode: "737628064502",
            productName: "Organic Milk",
            brand: "Horizon",
            quantity: "1L",
            calories: 60,
            protein: 3.3,
            carbs: 4.7,
            fat: 3.3
        ),
        InventoryItem(
            barcode: "011110421388",
            productName: "Whole Wheat Bread",
            brand: "Dave's Killer Bread",
            quantity: "650g",
            calories: 260,
            protein: 5,
            carbs: 46,
            fat: 4.5
        )
    ]
}
