from sqlalchemy.orm import Session
from sqlalchemy import or_
from typing import Optional, List
from datetime import datetime
from fastapi import HTTPException

from pantry_models import PantryItem, Inventory, UserPreferences, DinnerHistory, UnitType, Category, DietaryRestriction
from pantry_schemas import (
    PantryItemCreate, PantryItemUpdate,
    InventoryCreate, InventoryUpdate,
    UserPreferencesCreate, UserPreferencesUpdate,
    DinnerHistoryCreate, DinnerHistoryUpdate
)


# ===== PANTRY ITEM CRUD =====

def create_pantry_item(db: Session, item: PantryItemCreate) -> PantryItem:
    """Create a new pantry item"""
    # Check if barcode already exists
    if item.barcode:
        existing = db.query(PantryItem).filter(PantryItem.barcode == item.barcode).first()
        if existing:
            raise HTTPException(status_code=400, detail="Item with this barcode already exists")
    
    db_item = PantryItem(**item.model_dump())
    db.add(db_item)
    db.commit()
    db.refresh(db_item)
    return db_item


def get_pantry_item(db: Session, item_id: int) -> Optional[PantryItem]:
    """Get pantry item by ID"""
    return db.query(PantryItem).filter(PantryItem.id == item_id).first()


def get_pantry_item_by_barcode(db: Session, barcode: str) -> Optional[PantryItem]:
    """Get pantry item by barcode"""
    return db.query(PantryItem).filter(PantryItem.barcode == barcode).first()


def search_pantry_items(
    db: Session, 
    query: Optional[str] = None,
    category: Optional[Category] = None,
    skip: int = 0,
    limit: int = 100
) -> List[PantryItem]:
    """Search pantry items by name/brand or filter by category"""
    q = db.query(PantryItem)
    
    if query:
        search_term = f"%{query}%"
        q = q.filter(
            or_(
                PantryItem.name.ilike(search_term),
                PantryItem.brand.ilike(search_term)
            )
        )
    
    if category:
        q = q.filter(PantryItem.category == category)
    
    return q.offset(skip).limit(limit).all()


def update_pantry_item(
    db: Session, 
    item_id: int, 
    item_update: PantryItemUpdate
) -> Optional[PantryItem]:
    """Update pantry item"""
    db_item = get_pantry_item(db, item_id)
    if not db_item:
        return None
    
    update_data = item_update.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(db_item, field, value)
    
    db.commit()
    db.refresh(db_item)
    return db_item


def delete_pantry_item(db: Session, item_id: int) -> bool:
    """Delete pantry item (will cascade delete inventory entries)"""
    db_item = get_pantry_item(db, item_id)
    if not db_item:
        return False
    
    db.delete(db_item)
    db.commit()
    return True


# ===== INVENTORY CRUD =====

def get_user_inventory(
    db: Session,
    user_id: int,
    location: Optional[str] = None,
    low_stock_only: bool = False
) -> List[Inventory]:
    """Get all inventory items for a user"""
    q = db.query(Inventory).filter(Inventory.user_id == user_id)
    
    if location:
        q = q.filter(Inventory.location == location)
    
    if low_stock_only:
        q = q.filter(Inventory.is_low_stock == True)
    
    return q.all()


def get_inventory_item(db: Session, inventory_id: int, user_id: int) -> Optional[Inventory]:
    """Get specific inventory item"""
    return db.query(Inventory).filter(
        Inventory.id == inventory_id,
        Inventory.user_id == user_id
    ).first()


def create_inventory_item(
    db: Session,
    user_id: int,
    item: InventoryCreate
) -> Inventory:
    """Add item to user's inventory"""
    # Verify pantry item exists
    pantry_item = get_pantry_item(db, item.item_id)
    if not pantry_item:
        raise HTTPException(status_code=404, detail="Pantry item not found")
    
    # Check if user already has this item
    existing = db.query(Inventory).filter(
        Inventory.user_id == user_id,
        Inventory.item_id == item.item_id
    ).first()
    
    if existing:
        # Update quantity instead of creating duplicate
        existing.quantity += item.quantity
        existing.updated_at = datetime.now()
        _check_low_stock(existing)
        db.commit()
        db.refresh(existing)
        return existing
    
    # Create new inventory entry
    db_item = Inventory(
        user_id=user_id,
        **item.model_dump()
    )
    _check_low_stock(db_item)
    
    db.add(db_item)
    db.commit()
    db.refresh(db_item)
    return db_item


def update_inventory_item(
    db: Session,
    inventory_id: int,
    user_id: int,
    item_update: InventoryUpdate
) -> Optional[Inventory]:
    """Update inventory item"""
    db_item = get_inventory_item(db, inventory_id, user_id)
    if not db_item:
        return None
    
    update_data = item_update.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(db_item, field, value)
    
    _check_low_stock(db_item)
    
    db.commit()
    db.refresh(db_item)
    return db_item


def adjust_inventory_quantity(
    db: Session,
    inventory_id: int,
    user_id: int,
    quantity_delta: float
) -> Optional[Inventory]:
    """Adjust inventory quantity by delta (positive or negative)"""
    db_item = get_inventory_item(db, inventory_id, user_id)
    if not db_item:
        return None
    
    db_item.quantity += quantity_delta
    
    # Don't allow negative quantities
    if db_item.quantity < 0:
        db_item.quantity = 0
    
    db_item.last_used = datetime.now() if quantity_delta < 0 else db_item.last_used
    _check_low_stock(db_item)
    
    db.commit()
    db.refresh(db_item)
    return db_item


def delete_inventory_item(db: Session, inventory_id: int, user_id: int) -> bool:
    """Remove item from inventory"""
    db_item = get_inventory_item(db, inventory_id, user_id)
    if not db_item:
        return False
    
    db.delete(db_item)
    db.commit()
    return True


def _check_low_stock(inventory_item: Inventory):
    """Helper to check if item is low stock"""
    if inventory_item.low_stock_threshold:
        inventory_item.is_low_stock = inventory_item.quantity <= inventory_item.low_stock_threshold
    else:
        inventory_item.is_low_stock = False


# ===== USER PREFERENCES CRUD =====

def get_user_preferences(db: Session, user_id: int) -> Optional[UserPreferences]:
    """Get user's dietary preferences and macro goals"""
    return db.query(UserPreferences).filter(UserPreferences.user_id == user_id).first()


def create_user_preferences(
    db: Session,
    user_id: int,
    prefs: UserPreferencesCreate
) -> UserPreferences:
    """Create user preferences"""
    # Check if already exists
    existing = get_user_preferences(db, user_id)
    if existing:
        raise HTTPException(status_code=400, detail="User preferences already exist. Use update instead.")
    
    # Convert lists to comma-separated strings for storage
    dietary_restrictions_str = ",".join(prefs.dietary_restrictions) if prefs.dietary_restrictions else None
    preferred_cuisines_str = ",".join(prefs.preferred_cuisines) if prefs.preferred_cuisines else None
    
    db_prefs = UserPreferences(
        user_id=user_id,
        dietary_restrictions=dietary_restrictions_str,
        target_calories=prefs.target_calories,
        target_protein=prefs.target_protein,
        target_carbs=prefs.target_carbs,
        target_fat=prefs.target_fat,
        household_size=prefs.household_size,
        preferred_cuisines=preferred_cuisines_str
    )
    
    db.add(db_prefs)
    db.commit()
    db.refresh(db_prefs)
    return db_prefs


def update_user_preferences(
    db: Session,
    user_id: int,
    prefs_update: UserPreferencesUpdate
) -> Optional[UserPreferences]:
    """Update user preferences"""
    db_prefs = get_user_preferences(db, user_id)
    if not db_prefs:
        return None
    
    update_data = prefs_update.model_dump(exclude_unset=True)
    
    # Convert lists to strings
    if "dietary_restrictions" in update_data and update_data["dietary_restrictions"] is not None:
        update_data["dietary_restrictions"] = ",".join(update_data["dietary_restrictions"])
    
    if "preferred_cuisines" in update_data and update_data["preferred_cuisines"] is not None:
        update_data["preferred_cuisines"] = ",".join(update_data["preferred_cuisines"])
    
    for field, value in update_data.items():
        setattr(db_prefs, field, value)
    
    db.commit()
    db.refresh(db_prefs)
    return db_prefs


def get_allergen_filter(db: Session, user_id: int) -> list[DietaryRestriction]:
    """Get user's allergens/dietary restrictions as a list for recipe filtering"""
    prefs = get_user_preferences(db, user_id)
    if not prefs or not prefs.dietary_restrictions:
        return []
    
    return [DietaryRestriction(r.strip()) for r in prefs.dietary_restrictions.split(",")]


# ===== DINNER HISTORY CRUD =====

def create_dinner_history(
    db: Session,
    user_id: int,
    dinner: DinnerHistoryCreate
) -> DinnerHistory:
    """Log a dinner that was cooked"""
    db_dinner = DinnerHistory(
        user_id=user_id,
        **dinner.model_dump()
    )
    
    db.add(db_dinner)
    db.commit()
    db.refresh(db_dinner)
    return db_dinner


def get_dinner_history(
    db: Session,
    user_id: int,
    days: int = 30
) -> List[DinnerHistory]:
    """Get dinner history for the last N days"""
    from datetime import datetime, timedelta
    cutoff_date = datetime.now() - timedelta(days=days)
    
    return db.query(DinnerHistory).filter(
        DinnerHistory.user_id == user_id,
        DinnerHistory.date_cooked >= cutoff_date
    ).order_by(DinnerHistory.date_cooked.desc()).all()


def get_dinner_by_id(db: Session, dinner_id: int, user_id: int) -> Optional[DinnerHistory]:
    """Get specific dinner entry"""
    return db.query(DinnerHistory).filter(
        DinnerHistory.id == dinner_id,
        DinnerHistory.user_id == user_id
    ).first()


def update_dinner_history(
    db: Session,
    dinner_id: int,
    user_id: int,
    dinner_update: DinnerHistoryUpdate
) -> Optional[DinnerHistory]:
    """Update dinner history (e.g., add rating or notes)"""
    db_dinner = get_dinner_by_id(db, dinner_id, user_id)
    if not db_dinner:
        return None
    
    update_data = dinner_update.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(db_dinner, field, value)
    
    db.commit()
    db.refresh(db_dinner)
    return db_dinner


def get_macro_summary(db: Session, user_id: int, days: int = 7) -> dict:
    """Calculate macro averages for a time period"""
    dinners = get_dinner_history(db, user_id, days)
    
    if not dinners:
        return {
            "total_meals": 0,
            "avg_calories": 0,
            "avg_protein": 0,
            "avg_carbs": 0,
            "avg_fat": 0,
            "date_range": f"Last {days} days"
        }
    
    # Filter dinners with nutrition data
    with_nutrition = [d for d in dinners if d.calories_per_serving is not None]
    
    if not with_nutrition:
        return {
            "total_meals": len(dinners),
            "avg_calories": 0,
            "avg_protein": 0,
            "avg_carbs": 0,
            "avg_fat": 0,
            "date_range": f"Last {days} days"
        }
    
    return {
        "total_meals": len(dinners),
        "avg_calories": sum(d.calories_per_serving or 0 for d in with_nutrition) / len(with_nutrition),
        "avg_protein": sum(d.protein_per_serving or 0 for d in with_nutrition) / len(with_nutrition),
        "avg_carbs": sum(d.carbs_per_serving or 0 for d in with_nutrition) / len(with_nutrition),
        "avg_fat": sum(d.fat_per_serving or 0 for d in with_nutrition) / len(with_nutrition),
        "date_range": f"Last {days} days"
    }


def delete_dinner_history(db: Session, dinner_id: int, user_id: int) -> bool:
    """Delete a dinner history entry"""
    db_dinner = get_dinner_by_id(db, dinner_id, user_id)
    if not db_dinner:
        return False
    
    db.delete(db_dinner)
    db.commit()
    return True
