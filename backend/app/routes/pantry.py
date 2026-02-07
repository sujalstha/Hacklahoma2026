from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from typing import List, Optional

from ..schemas.pantry import (
    PantryItemCreate, PantryItemUpdate, PantryItemResponse,
    InventoryCreate, InventoryUpdate, InventoryResponse,
    UserPreferencesCreate, UserPreferencesUpdate, UserPreferencesResponse,
    DinnerHistoryCreate, DinnerHistoryUpdate, DinnerHistoryResponse,
    BarcodeScanRequest, BarcodeScanResponse,
    InventoryBatchAdd, InventoryBatchResponse,
    MacroSummary, Category
)
from ..models.pantry import UnitType
from ..import crud
from ..deps import get_db, get_current_user
from ..crud import pantry as crud
# from deps import get_db, get_current_user  # You'll need to implement these

router = APIRouter(prefix="/api/pantry", tags=["pantry"])


# ===== PANTRY ITEMS ENDPOINTS =====

@router.post("/items", response_model=PantryItemResponse, status_code=status.HTTP_201_CREATED)
def create_item(
    item: PantryItemCreate,
    db: Session = Depends(get_db)
):
    """
    Create a new pantry item (food/ingredient type).
    This is typically done when scanning a barcode that doesn't exist yet.
    """
    return crud.create_pantry_item(db, item)


@router.get("/items/{item_id}", response_model=PantryItemResponse)
def get_item(
    item_id: int,
    db: Session = Depends(get_db)
):
    """Get pantry item by ID"""
    item = crud.get_pantry_item(db, item_id)
    if not item:
        raise HTTPException(status_code=404, detail="Pantry item not found")
    return item


@router.get("/items", response_model=List[PantryItemResponse])
def search_items(
    query: Optional[str] = Query(None, description="Search by name or brand"),
    category: Optional[Category] = Query(None, description="Filter by category"),
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=500),
    db: Session = Depends(get_db)
):
    """
    Search pantry items by name/brand or filter by category.
    Useful for manual entry when user types item name.
    """
    return crud.search_pantry_items(db, query, category, skip, limit)


@router.patch("/items/{item_id}", response_model=PantryItemResponse)
def update_item(
    item_id: int,
    item_update: PantryItemUpdate,
    db: Session = Depends(get_db)
):
    """Update pantry item details"""
    item = crud.update_pantry_item(db, item_id, item_update)
    if not item:
        raise HTTPException(status_code=404, detail="Pantry item not found")
    return item


@router.delete("/items/{item_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_item(
    item_id: int,
    db: Session = Depends(get_db)
):
    """Delete pantry item (will also remove from all user inventories)"""
    if not crud.delete_pantry_item(db, item_id):
        raise HTTPException(status_code=404, detail="Pantry item not found")


# ===== BARCODE SCANNING =====

@router.post("/scan", response_model=BarcodeScanResponse)
def scan_barcode(
    scan_request: BarcodeScanRequest,
    db: Session = Depends(get_db)
):
    """
    Scan a barcode and return the pantry item if found.
    If not found, frontend can prompt user to manually enter item details.
    """
    item = crud.get_pantry_item_by_barcode(db, scan_request.barcode)
    
    if item:
        return BarcodeScanResponse(
            found=True,
            item=PantryItemResponse.model_validate(item),
            message="Item found!"
        )
    else:
        return BarcodeScanResponse(
            found=False,
            message="Item not found. Would you like to add it manually?"
        )


# ===== INVENTORY ENDPOINTS =====

@router.get("/inventory", response_model=List[InventoryResponse])
def get_my_inventory(
    location: Optional[str] = Query(None, description="Filter by location (fridge, pantry, freezer)"),
    low_stock_only: bool = Query(False, description="Show only low stock items"),
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get current user's inventory"""
    return crud.get_user_inventory(db, current_user["id"], location, low_stock_only)


@router.post("/inventory", response_model=InventoryResponse, status_code=status.HTTP_201_CREATED)
def add_to_inventory(
    item: InventoryCreate,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Add item to inventory. If item already exists, increases quantity.
    Use this after scanning barcode or manual entry.
    """
    return crud.create_inventory_item(db, current_user["id"], item)


@router.post("/inventory/batch", response_model=InventoryBatchResponse)
def batch_add_to_inventory(
    batch: InventoryBatchAdd,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Add multiple items to inventory at once"""
    results = []
    errors = []
    
    for item in batch.items:
        try:
            result = crud.create_inventory_item(db, current_user["id"], item)
            results.append(result)
        except Exception as e:
            errors.append(f"Failed to add item {item.item_id}: {str(e)}")
    
    return InventoryBatchResponse(
        success_count=len(results),
        failed_count=len(errors),
        results=results,
        errors=errors
    )


@router.get("/inventory/{inventory_id}", response_model=InventoryResponse)
def get_inventory_item(
    inventory_id: int,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get specific inventory item"""
    item = crud.get_inventory_item(db, inventory_id, current_user["id"])
    if not item:
        raise HTTPException(status_code=404, detail="Inventory item not found")
    return item


@router.patch("/inventory/{inventory_id}", response_model=InventoryResponse)
def update_inventory(
    inventory_id: int,
    item_update: InventoryUpdate,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update inventory item (quantity, location, etc.)"""
    item = crud.update_inventory_item(db, inventory_id, current_user["id"], item_update)
    if not item:
        raise HTTPException(status_code=404, detail="Inventory item not found")
    return item


@router.post("/inventory/{inventory_id}/adjust", response_model=InventoryResponse)
def adjust_quantity(
    inventory_id: int,
    quantity_delta: float = Query(..., description="Amount to add (positive) or subtract (negative)"),
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Adjust inventory quantity by a delta.
    Use negative values when cooking (e.g., -2 to use 2 cups of flour).
    """
    item = crud.adjust_inventory_quantity(db, inventory_id, current_user["id"], quantity_delta)
    if not item:
        raise HTTPException(status_code=404, detail="Inventory item not found")
    return item


@router.delete("/inventory/{inventory_id}", status_code=status.HTTP_204_NO_CONTENT)
def remove_from_inventory(
    inventory_id: int,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Remove item from inventory"""
    if not crud.delete_inventory_item(db, inventory_id, current_user["id"]):
        raise HTTPException(status_code=404, detail="Inventory item not found")


# ===== USER PREFERENCES ENDPOINTS =====

@router.get("/preferences", response_model=UserPreferencesResponse)
def get_my_preferences(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get user's dietary preferences and macro goals"""
    prefs = crud.get_user_preferences(db, current_user["id"])
    if not prefs:
        raise HTTPException(status_code=404, detail="User preferences not found. Please create them first.")
    return prefs


@router.post("/preferences", response_model=UserPreferencesResponse, status_code=status.HTTP_201_CREATED)
def create_my_preferences(
    prefs: UserPreferencesCreate,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Set dietary preferences, allergens, and macro goals.
    This info will be used to filter recipe suggestions.
    """
    return crud.create_user_preferences(db, current_user["id"], prefs)


@router.patch("/preferences", response_model=UserPreferencesResponse)
def update_my_preferences(
    prefs_update: UserPreferencesUpdate,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update dietary preferences and macro goals"""
    prefs = crud.update_user_preferences(db, current_user["id"], prefs_update)
    if not prefs:
        raise HTTPException(status_code=404, detail="User preferences not found")
    return prefs


@router.get("/preferences/allergens")
def get_my_allergens(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get user's allergens/restrictions as a simple list.
    Your recipe API can use this to filter recipes.
    """
    allergens = crud.get_allergen_filter(db, current_user["id"])
    return {
        "user_id": current_user["id"],
        "dietary_restrictions": allergens
    }


# ===== DINNER HISTORY ENDPOINTS =====

@router.post("/dinners", response_model=DinnerHistoryResponse, status_code=status.HTTP_201_CREATED)
def log_dinner(
    dinner: DinnerHistoryCreate,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Log a dinner that was cooked.
    Include macro info to track nutrition over time.
    """
    return crud.create_dinner_history(db, current_user["id"], dinner)


@router.get("/dinners", response_model=List[DinnerHistoryResponse])
def get_dinner_history(
    days: int = Query(30, ge=1, le=365, description="Number of days of history to retrieve"),
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get dinner history for the last N days"""
    return crud.get_dinner_history(db, current_user["id"], days)


@router.get("/dinners/{dinner_id}", response_model=DinnerHistoryResponse)
def get_dinner(
    dinner_id: int,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get specific dinner entry"""
    dinner = crud.get_dinner_by_id(db, dinner_id, current_user["id"])
    if not dinner:
        raise HTTPException(status_code=404, detail="Dinner not found")
    return dinner


@router.patch("/dinners/{dinner_id}", response_model=DinnerHistoryResponse)
def update_dinner(
    dinner_id: int,
    dinner_update: DinnerHistoryUpdate,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update dinner (e.g., add rating or notes after eating)"""
    dinner = crud.update_dinner_history(db, dinner_id, current_user["id"], dinner_update)
    if not dinner:
        raise HTTPException(status_code=404, detail="Dinner not found")
    return dinner


@router.delete("/dinners/{dinner_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_dinner(
    dinner_id: int,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Delete a dinner history entry"""
    if not crud.delete_dinner_history(db, dinner_id, current_user["id"]):
        raise HTTPException(status_code=404, detail="Dinner not found")


@router.get("/dinners/macros/summary", response_model=MacroSummary)
def get_macro_summary(
    days: int = Query(7, ge=1, le=365, description="Number of days to calculate averages for"),
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get macro averages for a time period.
    Compare against user's target macros to track progress.
    """
    return crud.get_macro_summary(db, current_user["id"], days)


# ===== UTILITY ENDPOINTS =====

@router.get("/stats")
def get_inventory_stats(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get inventory statistics (total items, low stock count, etc.)"""
    inventory = crud.get_user_inventory(db, current_user["id"])
    low_stock = crud.get_user_inventory(db, current_user["id"], low_stock_only=True)
    
    return {
        "total_items": len(inventory),
        "low_stock_count": len(low_stock),
        "total_quantity": sum(item.quantity for item in inventory),
        "locations": list(set(item.location for item in inventory if item.location))
    }
