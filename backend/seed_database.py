
import sys
import os
from sqlalchemy.exc import IntegrityError

# Add the current directory to sys.path so we can import app modules
sys.path.append(os.getcwd())

from app.db import SessionLocal, engine, Base
from app.models.pantry import PantryItem, Inventory, UserPreferences, UnitType, Category, DietaryRestriction

def seed():
    # Create tables
    Base.metadata.create_all(bind=engine)
    
    db = SessionLocal()
    try:
        print("--- Seeding Database ---")

        # 1. Create Default User Preferences (User ID 1)
        user_id = 1
        existing_prefs = db.query(UserPreferences).filter(UserPreferences.user_id == user_id).first()
        if not existing_prefs:
            print("Creating User Preferences for User ID 1...")
            prefs = UserPreferences(
                user_id=user_id,
                dietary_restrictions="gluten_free", # Example
                target_calories=2000,
                target_protein=150,
                target_carbs=200,
                target_fat=70,
                household_size=2
            )
            db.add(prefs)
        else:
            print("User Preferences already exist.")

        # 2. Add Pantry Items & Inventory
        
        # Valid units from enum:
        # PIECE, POUND, OUNCE, GRAM, KILOGRAM, CUP, TABLESPOON, TEASPOON, LITER, MILLILITER, GALLON, PACKAGE

        fixed_items = [
            {"name": "Chicken Breast", "category": Category.PROTEIN, "unit": UnitType.POUND, "qty": 5.0},
            {"name": "Jasmine Rice", "category": Category.GRAIN, "unit": UnitType.POUND, "qty": 2.0},
            {"name": "Spaghetti Pasta", "category": Category.GRAIN, "unit": UnitType.PACKAGE, "qty": 3.0},
            {"name": "Marinara Sauce", "category": Category.CANNED, "unit": UnitType.PACKAGE, "qty": 2.0},
            {"name": "Large Eggs", "category": Category.DAIRY, "unit": UnitType.PIECE, "qty": 12.0},
            {"name": "Whole Milk", "category": Category.DAIRY, "unit": UnitType.GALLON, "qty": 0.5},
            {"name": "Cheddar Cheese", "category": Category.DAIRY, "unit": UnitType.POUND, "qty": 1.0},
            {"name": "Broccoli Crowns", "category": Category.VEGETABLE, "unit": UnitType.POUND, "qty": 1.5},
            {"name": "Carrots", "category": Category.VEGETABLE, "unit": UnitType.POUND, "qty": 2.0},
            {"name": "Yellow Onions", "category": Category.VEGETABLE, "unit": UnitType.PIECE, "qty": 4.0},
            {"name": "Garlic Bulbs", "category": Category.VEGETABLE, "unit": UnitType.PIECE, "qty": 3.0},
            {"name": "Olive Oil", "category": Category.CONDIMENT, "unit": UnitType.LITER, "qty": 1.0},
        ]

        print("Seeding Items...")
        for data in fixed_items:
            # Check if pantry item exists
            item = db.query(PantryItem).filter(PantryItem.name == data["name"]).first()
            if not item:
                item = PantryItem(
                    name=data["name"],
                    category=data["category"],
                    default_unit=data["unit"]
                )
                db.add(item)
                db.flush() # get ID
            
            # Add to User Inventory
            inv = db.query(Inventory).filter(Inventory.user_id == user_id, Inventory.item_id == item.id).first()
            if not inv:
                inv = Inventory(
                    user_id=user_id,
                    item_id=item.id,
                    quantity=data["qty"],
                    unit=data["unit"],
                    location="pantry" # default
                )
                db.add(inv)
                print(f"Added {data['name']} to inventory.")
            else:
                print(f"{data['name']} already in inventory.")
        
        db.commit()
        print("--- Seeding Complete ---")

    except Exception as e:
        db.rollback()
        print(f"Error Seeding DB: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    seed()
