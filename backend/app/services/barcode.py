"""
Barcode lookup service for external product databases.
This service can integrate with APIs like:
- Open Food Facts (free, good for food products)
- UPCitemdb (free tier available)
- Nutritionix (requires API key)
"""

import httpx
from typing import Optional, Dict
from ..schemas.pantry import PantryItemCreate, Category, UnitType


class BarcodeService:
    """Service for looking up product info from barcodes"""
    
    def __init__(self):
        self.open_food_facts_url = "https://world.openfoodfacts.org/api/v0/product"
        self.timeout = 10.0
    
    async def lookup_barcode(self, barcode: str) -> Optional[Dict]:
        """
        Look up barcode in external databases.
        Returns product info if found, None otherwise.
        """
        # Try Open Food Facts first (it's free and has good coverage)
        result = await self._lookup_open_food_facts(barcode)
        
        if result:
            return result
        
        # Could add more providers here as fallback
        # result = await self._lookup_upcitemdb(barcode)
        
        return None
    
    async def _lookup_open_food_facts(self, barcode: str) -> Optional[Dict]:
        """Query Open Food Facts API"""
        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.get(
                    f"{self.open_food_facts_url}/{barcode}.json",
                    headers={"User-Agent": "WhatsForDinner/1.0"}
                )
                
                if response.status_code != 200:
                    return None
                
                data = response.json()
                
                # Check if product was found
                if data.get("status") != 1 or "product" not in data:
                    return None
                
                product = data["product"]
                
                # Parse the response into our format
                return self._parse_open_food_facts_response(product, barcode)
        
        except Exception as e:
            print(f"Error looking up barcode in Open Food Facts: {e}")
            return None
    
    def _parse_open_food_facts_response(self, product: Dict, barcode: str) -> Dict:
        """Convert Open Food Facts response to our PantryItem format"""
        
        # Extract basic info
        name = product.get("product_name", "Unknown Product")
        brand = product.get("brands", "").split(",")[0].strip() if product.get("brands") else None
        
        # Try to determine category
        category = self._guess_category(product)
        
        # Get nutrition info (per 100g typically)
        nutriments = product.get("nutriments", {})
        serving_size = product.get("serving_size")
        
        # Parse serving size to get numeric value
        serving_quantity = None
        serving_unit = None
        if serving_size:
            serving_quantity, serving_unit = self._parse_serving_size(serving_size)
        
        return {
            "name": name,
            "barcode": barcode,
            "brand": brand,
            "category": category,
            "default_unit": serving_unit or UnitType.PIECE,
            
            # Nutrition per 100g (Open Food Facts standard)
            "calories_per_serving": nutriments.get("energy-kcal_100g"),
            "protein_per_serving": nutriments.get("proteins_100g"),
            "carbs_per_serving": nutriments.get("carbohydrates_100g"),
            "fat_per_serving": nutriments.get("fat_100g"),
            "serving_size": 100.0,
            "serving_unit": UnitType.GRAM,
            
            # Store original data for reference
            "source": "Open Food Facts",
            "source_url": f"https://world.openfoodfacts.org/product/{barcode}"
        }
    
    def _guess_category(self, product: Dict) -> Category:
        """Try to determine food category from product data"""
        categories = product.get("categories", "").lower()
        
        # Simple keyword matching
        if any(word in categories for word in ["meat", "chicken", "beef", "pork", "fish", "seafood"]):
            return Category.PROTEIN
        elif any(word in categories for word in ["pasta", "rice", "bread", "cereal", "grain"]):
            return Category.GRAIN
        elif any(word in categories for word in ["vegetable", "veggie"]):
            return Category.VEGETABLE
        elif any(word in categories for word in ["fruit", "apple", "banana", "orange"]):
            return Category.FRUIT
        elif any(word in categories for word in ["milk", "cheese", "yogurt", "dairy"]):
            return Category.DAIRY
        elif any(word in categories for word in ["sauce", "condiment", "dressing", "ketchup"]):
            return Category.CONDIMENT
        elif any(word in categories for word in ["spice", "seasoning", "herb"]):
            return Category.SPICE
        elif any(word in categories for word in ["canned", "can"]):
            return Category.CANNED
        elif any(word in categories for word in ["frozen"]):
            return Category.FROZEN
        elif any(word in categories for word in ["snack", "chip", "cookie", "candy"]):
            return Category.SNACK
        elif any(word in categories for word in ["beverage", "drink", "juice", "soda"]):
            return Category.BEVERAGE
        
        return Category.OTHER
    
    def _parse_serving_size(self, serving_size: str) -> tuple[Optional[float], Optional[UnitType]]:
        """Parse serving size string to quantity and unit"""
        serving_size = serving_size.lower().strip()
        
        # Try to extract number
        import re
        numbers = re.findall(r'\d+\.?\d*', serving_size)
        quantity = float(numbers[0]) if numbers else None
        
        # Determine unit
        unit = None
        if 'g' in serving_size or 'gram' in serving_size:
            unit = UnitType.GRAM
        elif 'ml' in serving_size or 'milliliter' in serving_size:
            unit = UnitType.MILLILITER
        elif 'oz' in serving_size or 'ounce' in serving_size:
            unit = UnitType.OUNCE
        elif 'cup' in serving_size:
            unit = UnitType.CUP
        elif 'tbsp' in serving_size or 'tablespoon' in serving_size:
            unit = UnitType.TABLESPOON
        elif 'tsp' in serving_size or 'teaspoon' in serving_size:
            unit = UnitType.TEASPOON
        
        return quantity, unit
    
    def create_pantry_item_from_barcode(self, barcode_data: Dict) -> PantryItemCreate:
        """Convert barcode lookup result to PantryItemCreate schema"""
        # Remove source metadata before creating schema
        data = {k: v for k, v in barcode_data.items() if k not in ["source", "source_url"]}
        return PantryItemCreate(**data)


# Singleton instance
barcode_service = BarcodeService()


# Example usage in your scan endpoint:
# ```python
# @router.post("/scan-external")
# async def scan_barcode_with_lookup(
#     scan_request: BarcodeScanRequest,
#     db: Session = Depends(get_db)
# ):
#     # First check if we already have it
#     item = crud.get_pantry_item_by_barcode(db, scan_request.barcode)
#     
#     if item:
#         return {"found": True, "item": item, "source": "database"}
#     
#     # Not in DB, try external lookup
#     barcode_data = await barcode_service.lookup_barcode(scan_request.barcode)
#     
#     if barcode_data:
#         # Create item in our database
#         item_create = barcode_service.create_pantry_item_from_barcode(barcode_data)
#         new_item = crud.create_pantry_item(db, item_create)
#         return {"found": True, "item": new_item, "source": "external"}
#     
#     return {"found": False, "message": "Product not found"}
# ```
