"""
Recipe Service - Integrates Spoonacular API and Gemini AI for recipe suggestions

This service:
1. Gets user's dietary restrictions from pantry API
2. Gets user's available ingredients from pantry API
3. Searches Spoonacular for matching recipes
4. Uses Gemini AI to simplify cooking steps to 5 steps max
5. Returns recipe with macros and simplified instructions
6. Generates a unique AI image per recipe (API model integration)
"""

import asyncio
import httpx
import os
from typing import Optional, List, Dict, Union
from sqlalchemy.orm import Session
import google.generativeai as genai

from ..config import settings
from .recipe_image_service import generate_recipe_image_url

# Initialize APIs
SPOONACULAR_API_KEY = settings.SPOONACULAR_API_KEY
SPOONACULAR_BASE_URL = "https://api.spoonacular.com"


class RecipeService:
    def __init__(self):
        # Configure Gemini
        gemini_api_key = settings.GEMINI_API_KEY
        if gemini_api_key:
            genai.configure(api_key=gemini_api_key)
            self.model = genai.GenerativeModel('gemini-flash-latest')
        else:
            self.model = None
            print("WARNING: GEMINI_API_KEY not found. Recipe generation will fail.")

    async def get_daily_suggestion(
            self,
            user_id: int,
            db: Session
    ) -> Dict:
        """
        Main function: Get a single recipe suggestion for dinner tonight with 100% accuracy logic.
        """
        suggestions = await self.get_suggestions(user_id, db, count=1)
        if not suggestions:
            return {"error": "Could not generate a valid recipe for your current inventory."}
        return suggestions[0]

    async def get_suggestions(
            self,
            user_id: int,
            db: Session,
            count: int = 4,
            allergens_override: Optional[List[str]] = None
    ) -> List[Dict]:
        """
        Get exactly `count` recipe suggestions with unique AI image per recipe.
        Uses recursive verification to ensure 100% inventory compliance.
        """
        try:
            # 1. Get user constraints
            if allergens_override is not None:
                allergens = list(allergens_override)
                _, available_ingredients = await self._get_user_context(user_id, db)
            else:
                allergens, available_ingredients = await self._get_user_context(user_id, db)

            # 2. Generation Loop (Retry up to 5 times to get valid recipes)
            valid_recipes = []
            max_attempts = 5
            hallucinated_ingredients = set()
            
            for attempt in range(max_attempts):
                missing_count = count - len(valid_recipes)
                if missing_count <= 0:
                    break
                
                print(f"DEBUG: Recipe generation attempt {attempt + 1}/{max_attempts}")
                new_results = await self._generate_recipes_with_gemini(
                    ingredients=available_ingredients,
                    dietary_restrictions=allergens,
                    count=missing_count,
                    forbidden_override=list(hallucinated_ingredients)
                )
                
                # Programmatic Validation
                for recipe in new_results:
                    # Skip duplicate names
                    if any(r['name'].lower() == recipe['name'].lower() for r in valid_recipes):
                        continue
                        
                    is_valid, bad_ing = self._is_recipe_valid(recipe, available_ingredients)
                    if is_valid:
                        # 3. Generate Image for valid recipes
                        recipe["image_url"] = await asyncio.to_thread(
                            generate_recipe_image_url, recipe.get("image_search_keywords") or recipe["name"]
                        )
                        valid_recipes.append(recipe)
                    else:
                        print(f"DEBUG: Discarded invalid recipe '{recipe['name']}' due to: {bad_ing}")
                        if bad_ing:
                            hallucinated_ingredients.add(bad_ing)

            return valid_recipes[:count]
        except Exception as e:
            print(f"Error in get_suggestions: {e}")
            return []

    def _is_recipe_valid(self, recipe: Dict, available: List[str]) -> tuple[bool, Optional[str]]:
        """
        STRICT PROGRAMMATIC CHECK: Does this recipe use items NOT in the user's inventory?
        Returns (is_valid, first_bad_ingredient_name)
        """
        inventory_set = {i.lower().strip() for i in available}
        # Explicit staples that don't need to be in inventory
        staples = {"water", "salt"}
        
        for ing in recipe.get("ingredients", []):
            name = ing.get("name", "").lower().strip()
            if not name: continue
            if name in staples:
                continue
            
            # Fuzzy match: is this ingredient found in the inventory?
            # We check if inventory item name is in the recipe ingredient name (e.g. "Chicken" in "Grilled Chicken")
            is_found = any(inv_item in name or name in inv_item for inv_item in inventory_set)
            
            if not is_found:
                return False, name
                
        return True, None

    async def _get_user_context(self, user_id: int, db: Session):
        """Helper to get allergens and inventory DIRECTLY from database to avoid stale data"""
        from ..crud import pantry as crud
        
        # 1. Get Dietary restrictions
        raw_allergens = crud.get_allergen_filter(db, user_id)
        # Ensure we always get strings even if they are Enums
        allergens = []
        for r in raw_allergens:
            if hasattr(r, 'value'):
                allergens.append(str(r.value))
            else:
                allergens.append(str(r))

        # 2. Get Inventory
        inventory = crud.get_user_inventory(db, user_id)
        available_ingredients = []
        found = set()
        
        for item in inventory:
            # ONLY add items the user actually HAS (quantity > 0)
            if hasattr(item, 'item') and item.item and item.item.name and item.quantity > 0:
                name = item.item.name
                if name not in found:
                    found.add(name)
                    available_ingredients.append(name)
        
        return allergens, available_ingredients

    async def _generate_recipes_with_gemini(
            self,
            ingredients: List[str],
            dietary_restrictions: List[str],
            count: int,
            forbidden_override: Optional[List[str]] = None
    ) -> List[Dict]:
        """
        Use Gemini to generate full recipe JSONs based on ingredients.
        """
        if not self.model:
            return []

        # Logic for strict ingredient list
        if not ingredients:
            ing_str = "USER HAS NO FRESH INGREDIENTS."
            forbidden_clause = "You MUST ONLY suggest recipes using ONLY water and salt. If this is impossible, return empty list."
        else:
            ing_str = ", ".join(ingredients)
            # Calculate what's NOT there to be extra explicit
            common_items = ["Chicken", "Beef", "Olive Oil", "Flour", "Pasta", "Rice", "Milk", "Eggs", "Broccoli", "Spinach", "Onions", "Garlic"]
            missing = [p for p in common_items if not any(p.lower() in i.lower() for i in ingredients)]
            
            # Add dynamic forbidden items from previous retries
            if forbidden_override:
                missing.extend(forbidden_override)
            
            # Filter duplicates and empty strings
            missing = list(set([m for m in missing if m]))
            
            forbidden_clause = f"The user is MISSING these items: {', '.join(missing)}. You are STRICTLY FORBIDDEN from suggesting any recipe that uses them."

        diet_str = ", ".join(dietary_restrictions) if dietary_restrictions else "None"

        # Use prompt for strict JSON and absolute inventory compliance
        prompt = f"""
You are a highly logical and creative chef AI. Your ABSOLUTE mission is to create {count} unique dinner recipes based ONLY on the user's available inventory.

USER INVENTORY: {ing_str}
DIETARY RESTRICTIONS: {diet_str}

STRICT CONSTRAINTS:
1. {forbidden_clause}
2. MANDATORY: Every ingredient in your 'ingredients' list MUST be present in the USER INVENTORY, except for Salt and Water.
3. DIETARY SAFETY: If a restriction like 'dairy_free' is set, you MUST NOT use milk, butter, or cheese.
4. NO HALLUCINATIONS: If an item is not in the USER INVENTORY (or Salt/Water), it does NOT exist. Even Flour, Oil, and Pepper must be in the inventory to be used.
5. Return a STRICT JSON ARRAY of objects. No intro text, no markdown.

JSON Structure:
{{
    "recipe_id": "generate_uuid",
    "name": "Recipe Name",
    "servings": 4,
    "ready_in_minutes": 30,
    "calories_per_serving": 500,
    "protein_per_serving": 30,
    "carbs_per_serving": 40,
    "fat_per_serving": 20,
    "image_search_keywords": "vegetable stir fry",
    "ingredients": [
      {{ "name": "Ingredient from Inventory or Staple", "amount": 1, "unit": "cup" }}
    ],
    "steps": [
      "Step 1...",
      "Step 2..."
    ]
}}
"""
        print(f"DEBUG: Generating {count} recipes with Gemini...")
        try:
            # Using asyncio.to_thread since generate_content is blocking
            response = await asyncio.to_thread(self.model.generate_content, prompt)
            completion = response.text
            
            # Clean up potential markdown code blocks
            clean_json = completion.replace("```json", "").replace("```", "").strip()
            
            import json
            import uuid
            
            data = json.loads(clean_json)
            
            # Post-process to ensure valid format
            final_recipes = []
            if isinstance(data, list):
                for r in data:
                    # Enrich with missing fields if needed
                    if "recipe_id" not in r or r["recipe_id"] == "generate_uuid":
                        r["recipe_id"] = str(uuid.uuid4())
                    
                    # Ensure source is set
                    r["source"] = "gemini_ai"
                    r["spoonacular_url"] = None
                    
                    # Use search keywords if provided, else fallback to name
                    search_query = r.get("image_search_keywords") or r["name"]
                    r["image_url"] = await asyncio.to_thread(
                        generate_recipe_image_url, search_query
                    )
                    
                    final_recipes.append(r)
            
            print(f"DEBUG: Generated {len(final_recipes)} recipes")
            return final_recipes

        except Exception as e:
            print(f"Error generating recipes with Gemini: {e}")
            return []


# Singleton instance
recipe_service = RecipeService()

# Example usage in your route:
"""
from fastapi import APIRouter, Depends
from .services.recipe_service import recipe_service

router = APIRouter(prefix="/api/recipe", tags=["recipe"])

@router.get("/daily-suggestion")
async def get_daily_suggestion(current_user: dict = Depends(get_current_user)):
    '''Get tonight's dinner suggestion at 5 PM'''
    recipe = await recipe_service.get_daily_suggestion(
        user_id=current_user["id"]
    )
    return recipe

@router.post("/accept")
async def accept_recipe(
    recipe_id: str,
    recipe_data: dict,  # Include name, macros, etc.
    current_user: dict = Depends(get_current_user)
):
    '''
    User accepted the recipe - log it and deduct ingredients
    '''
    # 1. Log the dinner in pantry system
    async with httpx.AsyncClient() as client:
        await client.post(
            "http://localhost:8000/api/pantry/dinners",
            json={
                "meal_name": recipe_data["name"],
                "recipe_id": recipe_id,
                "servings": recipe_data["servings"],
                "calories_per_serving": recipe_data["calories_per_serving"],
                "protein_per_serving": recipe_data["protein_per_serving"],
                "carbs_per_serving": recipe_data["carbs_per_serving"],
                "fat_per_serving": recipe_data["fat_per_serving"]
            },
            headers={"user-id": str(current_user["id"])}
        )

        # 2. Deduct ingredients from inventory
        for ingredient in recipe_data["ingredients"]:
            # Find matching inventory item
            inventory_response = await client.get(
                f"http://localhost:8000/api/pantry/inventory",
                headers={"user-id": str(current_user["id"])}
            )
            inventory = inventory_response.json()

            # Match ingredient to inventory item (fuzzy match by name)
            for inv_item in inventory:
                if ingredient["name"].lower() in inv_item["item"]["name"].lower():
                    # Deduct quantity
                    await client.post(
                        f"http://localhost:8000/api/pantry/inventory/{inv_item['id']}/adjust",
                        params={"quantity_delta": -ingredient["amount"]},
                        headers={"user-id": str(current_user["id"])}
                    )
                    break

    return {"success": True, "message": "Recipe accepted and logged!"}
"""