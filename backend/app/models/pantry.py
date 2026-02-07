from sqlalchemy import Column, Integer, String, Float, DateTime, Boolean, ForeignKey, Enum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from ..db import Base
import enum

class UnitType(str, enum.Enum):
    """Standard measurement units"""
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

class Category(str, enum.Enum):
    """Food categories for organization"""
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

class PantryItem(Base):
    """
    Core pantry item - represents a type of food/ingredient
    This is the 'master list' of items that can be in inventory
    """
    __tablename__ = "pantry_items"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False, index=True)
    barcode = Column(String, unique=True, nullable=True, index=True)  # UPC/EAN barcode
    category = Column(Enum(Category), default=Category.OTHER)
    default_unit = Column(Enum(UnitType), default=UnitType.PIECE)
    brand = Column(String, nullable=True)
    
    # Nutrition info (per serving) - optional but useful
    calories_per_serving = Column(Float, nullable=True)
    protein_per_serving = Column(Float, nullable=True)
    carbs_per_serving = Column(Float, nullable=True)
    fat_per_serving = Column(Float, nullable=True)
    serving_size = Column(Float, nullable=True)
    serving_unit = Column(Enum(UnitType), nullable=True)
    
    # Metadata
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    inventory_entries = relationship("Inventory", back_populates="item", cascade="all, delete-orphan")


class Inventory(Base):
    """
    User's actual inventory - tracks what they currently have
    Links users to pantry items with quantities
    """
    __tablename__ = "inventory"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, nullable=False, index=True)  # FK to users table (you'll create this)
    item_id = Column(Integer, ForeignKey("pantry_items.id"), nullable=False)
    
    quantity = Column(Float, nullable=False, default=0)
    unit = Column(Enum(UnitType), nullable=False)
    
    # Location/organization
    location = Column(String, nullable=True)  # e.g., "fridge", "pantry", "freezer"
    
    # Shopping list integration
    low_stock_threshold = Column(Float, nullable=True)  # Alert when below this
    is_low_stock = Column(Boolean, default=False)
    
    # Metadata
    added_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    last_used = Column(DateTime(timezone=True), nullable=True)  # Track when used in recipes
    
    # Relationships
    item = relationship("PantryItem", back_populates="inventory_entries")


class DietaryRestriction(str, enum.Enum):
    """Common dietary restrictions and allergens"""
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


class UserPreferences(Base):
    """
    User dietary preferences, allergens, and macro goals
    """
    __tablename__ = "user_preferences"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, unique=True, nullable=False, index=True)
    
    # Dietary restrictions (stored as comma-separated values)
    dietary_restrictions = Column(String, nullable=True)  # e.g., "gluten_free,dairy_free"
    
    # Macro goals (daily targets)
    target_calories = Column(Float, nullable=True)
    target_protein = Column(Float, nullable=True)  # grams
    target_carbs = Column(Float, nullable=True)     # grams
    target_fat = Column(Float, nullable=True)       # grams
    
    # Preferences
    household_size = Column(Integer, default=2)
    preferred_cuisines = Column(String, nullable=True)  # e.g., "italian,mexican,asian"
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())


class DinnerHistory(Base):
    """
    Track dinners cooked and their macros
    """
    __tablename__ = "dinner_history"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, nullable=False, index=True)
    
    # Recipe/meal info
    meal_name = Column(String, nullable=False)
    recipe_id = Column(String, nullable=True)  # If from your recipe system
    date_cooked = Column(DateTime(timezone=True), server_default=func.now())
    
    # Nutritional info for the meal
    servings = Column(Integer, default=1)
    calories_per_serving = Column(Float, nullable=True)
    protein_per_serving = Column(Float, nullable=True)
    carbs_per_serving = Column(Float, nullable=True)
    fat_per_serving = Column(Float, nullable=True)
    
    # User rating
    rating = Column(Integer, nullable=True)  # 1-5 stars
    notes = Column(String, nullable=True)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
