import sys
import os

# Add the current directory to sys.path so we can import app modules
sys.path.append(os.getcwd())

from app.db import SessionLocal
from app.models.pantry import PantryItem, Inventory, UserPreferences

def inspect():
    db = SessionLocal()
    try:
        print("--- Database Inspection ---")
        
        # Check Pantry Items
        pantry_count = db.query(PantryItem).count()
        print(f"Pantry Items: {pantry_count}")
        
        # Check Inventory
        inventory_count = db.query(Inventory).count()
        print(f"Inventory Items: {inventory_count}")
        
        if inventory_count > 0:
            print("\nFirst 10 Inventory Items:")
            items = db.query(Inventory).limit(10).all()
            for i in items:
                print(f"- ID {i.id}: {i.item.name} | Qty: {i.quantity} {i.unit} | User: {i.user_id}")
        else:
            print("No inventory items found.")

        # Check User Preferences (to verify user exists/has prefs)
        prefs_count = db.query(UserPreferences).count()
        print(f"\nUser Preferences Count: {prefs_count}")
        
    except Exception as e:
        print(f"Error inspecting DB: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    inspect()
