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
            pantry_api_url: str = "http://localhost:8000/api/pantry"
    ) -> Dict:
        """
        Main function: Get a single recipe suggestion for dinner tonight
        """
        # 1. Get user constraints
        allergens, available_ingredients = await self._get_user_context(user_id, pantry_api_url)

        # 2. Generate recipes using Gemini
        recipes = await self._generate_recipes_with_gemini(
            ingredients=available_ingredients,
            dietary_restrictions=allergens,
            count=1
        )

        if not recipes:
            return {"error": "Could not generate recipe. Please try again."}

        # 3. Get the first recipe
        best_recipe = recipes[0]
        
        # 4. Generate Image if possible
        best_recipe["image_url"] = await asyncio.to_thread(
            generate_recipe_image_url, best_recipe["name"]
        )

        return best_recipe

    async def get_suggestions(
            self,
            user_id: int,
            count: int = 4,
            allergens_override: Optional[List[str]] = None,
            pantry_api_url: str = "http://localhost:8000/api/pantry"
    ) -> List[Dict]:
        """
        Get exactly `count` recipe suggestions with unique AI image per recipe.
        """
        try:
            # 1. Get user constraints
            if allergens_override is not None:
                allergens = list(allergens_override)
                # Still need ingredients
                _, available_ingredients = await self._get_user_context(user_id, pantry_api_url)
            else:
                allergens, available_ingredients = await self._get_user_context(user_id, pantry_api_url)

            # 2. Generate recipes with Gemini
            # If no ingredients, assume staples
            if not available_ingredients:
                available_ingredients = ["common pantry staples"]

            results = await self._generate_recipes_with_gemini(
                ingredients=available_ingredients,
                dietary_restrictions=allergens,
                count=count
            )

            # 3. Generate Images for each
            for recipe in results:
                recipe["image_url"] = await asyncio.to_thread(
                    generate_recipe_image_url, recipe["name"]
                )

            return results
        except Exception as e:
            print(f"Error in get_suggestions: {e}")
            return []

    async def _get_user_context(self, user_id: int, pantry_api_url: str):
        """Helper to get allergens and inventory"""
        allergens = []
        available_ingredients = []
        
        async with httpx.AsyncClient() as client:
            try:
                # Dietary restrictions
                prefs_response = await client.get(
                    f"{pantry_api_url}/preferences/allergens",
                    headers={"user-id": str(user_id)},
                    timeout=5.0
                )
                if prefs_response.status_code == 200:
                    allergens = prefs_response.json().get("dietary_restrictions", []) or []
            except Exception:
                pass

            try:
                # Inventory
                inv_response = await client.get(
                    f"{pantry_api_url}/inventory",
                    headers={"user-id": str(user_id)},
                    timeout=5.0
                )
                if inv_response.status_code == 200:
                    inventory = inv_response.json()
                    found = set()
                    for item in inventory:
                        name = item.get("item", {}).get("name")
                        if name and name not in found:
                            found.add(name)
                            available_ingredients.append(name)
            except Exception:
                pass
        
        return allergens, available_ingredients

    async def _generate_recipes_with_gemini(
            self,
            ingredients: List[str],
            dietary_restrictions: List[str],
            count: int
    ) -> List[Dict]:
        """
        Use Gemini to generate full recipe JSONs based on ingredients.
        """
        if not self.model:
            return []

        ing_str = ", ".join(ingredients)
        diet_str = ", ".join(dietary_restrictions) if dietary_restrictions else "None"

        # Use prompt for strict JSON
        prompt = f"""
You are a creative chef AI. Create {count} unique, delicious dinner recipes using these ingredients: {ing_str}.
Dietary Restrictions: {diet_str}.
Target Audience: Busy working parents. 

Requirements:
1. Use provided ingredients where possible.
2. Return a STRICT JSON ARRAY of objects.
3. No markdown formatting (no ```json). Just the raw JSON string.

JSON Structure per recipe:
{{
    "recipe_id": "generate_uuid",
    "name": "Recipe Name",
    "servings": 4,
    "ready_in_minutes": 30,
    "calories_per_serving": 500,
    "protein_per_serving": 30,
    "carbs_per_serving": 40,
    "fat_per_serving": 20,
    "ingredients": [
      {{ "name": "Ingredient Name", "amount": 1, "unit": "cup" }}
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
                    r["image_url"] = None # Will be filled later
                    
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