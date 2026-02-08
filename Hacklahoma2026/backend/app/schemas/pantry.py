from pydantic import BaseModel, Field, ConfigDict
from typing import Optional
from datetime import datetime
from enum import Enum


# Enums matching the models
class UnitType(str, Enum):
    PIECE = "piece"
    POUND = "lb"
    OUNCE = "oz"
    GRAM = "g"
    KILOGRAM = "kg"
    CUP = "cup"
    TABLESPOON = "tbsp"
    TEASPOON = "tsp"
    LITER = "l"
    MILLILITER = "ml"
    GALLON = "gal"
    PACKAGE = "package"


class DietaryRestriction(str, Enum):
    GLUTEN_FREE = "gluten_free"
    DAIRY_FREE = "dairy_free"
    NUT_FREE = "nut_free"
    EGG_FREE = "egg_free"
    SOY_FREE = "soy_free"
    SHELLFISH_FREE = "shellfish_free"
    FISH_FREE = "fish_free"
    PORK_FREE = "pork_free"
    VEGETARIAN = "vegetarian"
    VEGAN = "vegan"
    HALAL = "halal"
    KOSHER = "kosher"
    LOW_CARB = "low_carb"
    KETO = "keto"


class Category(str, Enum):
    PROTEIN = "protein"
    GRAIN = "grain"
    VEGETABLE = "vegetable"
    FRUIT = "fruit"
    DAIRY = "dairy"
    CONDIMENT = "condiment"
    SPICE = "spice"
    CANNED = "canned"
    FROZEN = "frozen"
    SNACK = "snack"
    BEVERAGE = "beverage"
    OTHER = "other"


# ===== PANTRY ITEM SCHEMAS =====

class PantryItemBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=200)
    barcode: Optional[str] = Field(None, max_length=50)
    category: Category = Category.OTHER
    default_unit: UnitType = UnitType.PIECE
    brand: Optional[str] = Field(None, max_length=100)

    # Nutrition (optional)
    calories_per_serving: Optional[float] = None
    protein_per_serving: Optional[float] = None
    carbs_per_serving: Optional[float] = None
    fat_per_serving: Optional[float] = None
    serving_size: Optional[float] = None
    serving_unit: Optional[UnitType] = None


class PantryItemCreate(PantryItemBase):
    """Schema for creating a new pantry item"""
    pass


class PantryItemUpdate(BaseModel):
    """Schema for updating pantry item - all fields optional"""
    name: Optional[str] = Field(None, min_length=1, max_length=200)
    barcode: Optional[str] = Field(None, max_length=50)
    category: Optional[Category] = None
    default_unit: Optional[UnitType] = None
    brand: Optional[str] = Field(None, max_length=100)
    calories_per_serving: Optional[float] = None
    protein_per_serving: Optional[float] = None
    carbs_per_serving: Optional[float] = None
    fat_per_serving: Optional[float] = None
    serving_size: Optional[float] = None
    serving_unit: Optional[UnitType] = None


class PantryItemResponse(PantryItemBase):
    """Schema for returning pantry item data"""
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)


# ===== INVENTORY SCHEMAS =====

class InventoryBase(BaseModel):
    item_id: int
    quantity: float = Field(..., ge=0)
    unit: UnitType
    location: Optional[str] = Field(None, max_length=50)
    low_stock_threshold: Optional[float] = Field(None, ge=0)


class InventoryCreate(InventoryBase):
    """Schema for adding item to inventory"""
    pass


class InventoryUpdate(BaseModel):
    """Schema for updating inventory - all fields optional"""
    quantity: Optional[float] = Field(None, ge=0)
    unit: Optional[UnitType] = None
    location: Optional[str] = Field(None, max_length=50)
    low_stock_threshold: Optional[float] = Field(None, ge=0)


class InventoryResponse(InventoryBase):
    """Schema for returning inventory data"""
    id: int
    user_id: int
    is_low_stock: bool
    added_at: datetime
    updated_at: Optional[datetime] = None
    last_used: Optional[datetime] = None

    # Include the pantry item info
    item: PantryItemResponse

    model_config = ConfigDict(from_attributes=True)


# ===== BARCODE SCAN SCHEMAS =====

class BarcodeScanRequest(BaseModel):
    """Request to scan/lookup a barcode"""
    barcode: str = Field(..., min_length=1, max_length=50)


class BarcodeScanResponse(BaseModel):
    """Response from barcode scan"""
    found: bool
    item: Optional[PantryItemResponse] = None
    message: Optional[str] = None


# ===== USER PREFERENCES SCHEMAS =====

class UserPreferencesBase(BaseModel):
    dietary_restrictions: Optional[list[DietaryRestriction]] = []
    target_calories: Optional[float] = Field(None, ge=0)
    target_protein: Optional[float] = Field(None, ge=0)
    target_carbs: Optional[float] = Field(None, ge=0)
    target_fat: Optional[float] = Field(None, ge=0)
    household_size: int = Field(2, ge=1, le=20)
    preferred_cuisines: Optional[list[str]] = []


class UserPreferencesCreate(UserPreferencesBase):
    """Schema for creating user preferences"""
    pass


class UserPreferencesUpdate(BaseModel):
    """Schema for updating preferences - all fields optional"""
    dietary_restrictions: Optional[list[DietaryRestriction]] = None
    target_calories: Optional[float] = Field(None, ge=0)
    target_protein: Optional[float] = Field(None, ge=0)
    target_carbs: Optional[float] = Field(None, ge=0)
    target_fat: Optional[float] = Field(None, ge=0)
    household_size: Optional[int] = Field(None, ge=1, le=20)
    preferred_cuisines: Optional[list[str]] = None


class UserPreferencesResponse(BaseModel):
    """Schema for returning user preferences"""
    id: int
    user_id: int
    dietary_restrictions: list[DietaryRestriction] = []
    target_calories: Optional[float] = None
    target_protein: Optional[float] = None
    target_carbs: Optional[float] = None
    target_fat: Optional[float] = None
    household_size: int = 2
    preferred_cuisines: list[str] = []
    created_at: datetime
    updated_at: Optional[datetime] = None

    @classmethod
    def from_db(cls, db_prefs):
        """Convert database model to response schema"""
        # Convert comma-separated strings back to lists
        dietary_restrictions = []
        if db_prefs.dietary_restrictions:
            dietary_restrictions = [
                DietaryRestriction(r.strip())
                for r in db_prefs.dietary_restrictions.split(",")
            ]

        preferred_cuisines = []
        if db_prefs.preferred_cuisines:
            preferred_cuisines = [c.strip() for c in db_prefs.preferred_cuisines.split(",")]

        return cls(
            id=db_prefs.id,
            user_id=db_prefs.user_id,
            dietary_restrictions=dietary_restrictions,
            target_calories=db_prefs.target_calories,
            target_protein=db_prefs.target_protein,
            target_carbs=db_prefs.target_carbs,
            target_fat=db_prefs.target_fat,
            household_size=db_prefs.household_size,
            preferred_cuisines=preferred_cuisines,
            created_at=db_prefs.created_at,
            updated_at=db_prefs.updated_at
        )

    model_config = ConfigDict(from_attributes=True)


# ===== DINNER HISTORY SCHEMAS =====

class DinnerHistoryBase(BaseModel):
    meal_name: str = Field(..., min_length=1, max_length=200)
    recipe_id: Optional[str] = None
    servings: int = Field(1, ge=1)
    calories_per_serving: Optional[float] = Field(None, ge=0)
    protein_per_serving: Optional[float] = Field(None, ge=0)
    carbs_per_serving: Optional[float] = Field(None, ge=0)
    fat_per_serving: Optional[float] = Field(None, ge=0)
    rating: Optional[int] = Field(None, ge=1, le=5)
    notes: Optional[str] = Field(None, max_length=500)


class DinnerHistoryCreate(DinnerHistoryBase):
    """Schema for logging a dinner"""
    pass


class DinnerHistoryUpdate(BaseModel):
    """Schema for updating dinner history"""
    rating: Optional[int] = Field(None, ge=1, le=5)
    notes: Optional[str] = Field(None, max_length=500)


class DinnerHistoryResponse(DinnerHistoryBase):
    """Schema for returning dinner history"""
    id: int
    user_id: int
    date_cooked: datetime
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class MacroSummary(BaseModel):
    """Summary of macros for a time period"""
    total_meals: int
    avg_calories: float
    avg_protein: float
    avg_carbs: float
    avg_fat: float
    date_range: str


# ===== BATCH OPERATIONS =====

class InventoryBatchAdd(BaseModel):
    """Add multiple items to inventory at once"""
    items: list[InventoryCreate]


class InventoryBatchResponse(BaseModel):
    """Response for batch operations"""
    success_count: int
    failed_count: int
    results: list[InventoryResponse]
    errors: list[str] = []