"""
Recipe Service - Integrates Spoonacular API and AI for recipe suggestions

This service:
1. Gets user's dietary restrictions from pantry API
2. Gets user's available ingredients from pantry API
3. Searches Spoonacular for matching recipes
4. Uses AI to simplify cooking steps to 5 steps max
5. Returns recipe with macros and simplified instructions
"""

import httpx
import os
from typing import Optional, List, Dict
from anthropic import Anthropic

# Initialize APIs
SPOONACULAR_API_KEY = os.getenv("SPOONACULAR_API_KEY", "YOUR_KEY_HERE")
SPOONACULAR_BASE_URL = "https://api.spoonacular.com"


class RecipeService:
    def __init__(self):
        self.spoonacular_key = SPOONACULAR_API_KEY
        self.ai_client = Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))
    
    async def get_daily_suggestion(
        self, 
        user_id: int,
        pantry_api_url: str = "http://localhost:8000/api/pantry"
    ) -> Dict:
        """
        Main function: Get a single recipe suggestion for dinner tonight
        """
        # 1. Get user constraints from your pantry API
        async with httpx.AsyncClient() as client:
            # Get dietary restrictions
            prefs_response = await client.get(
                f"{pantry_api_url}/preferences/allergens",
                headers={"user-id": str(user_id)}  # You'll need proper auth
            )
            allergens = prefs_response.json().get("dietary_restrictions", [])
            
            # Get available ingredients
            inventory_response = await client.get(
                f"{pantry_api_url}/inventory",
                headers={"user-id": str(user_id)}
            )
            inventory = inventory_response.json()
            available_ingredients = [item["item"]["name"] for item in inventory]
        
        # 2. Search Spoonacular for matching recipes
        recipes = await self._search_recipes(
            dietary_restrictions=allergens,
            ingredients=available_ingredients,
            number=5  # Get 5 options, pick best one
        )
        
        if not recipes:
            return {"error": "No recipes found matching your constraints"}
        
        # 3. Get the best recipe (first one)
        best_recipe = recipes[0]
        
        # 4. Get detailed recipe info from Spoonacular
        recipe_details = await self._get_recipe_details(best_recipe["id"])
        
        # 5. Simplify cooking steps using AI
        simplified_steps = await self._simplify_with_ai(
            recipe_name=recipe_details["title"],
            original_steps=recipe_details["instructions"],
            max_steps=5
        )
        
        # 6. Build final recipe object
        return {
            "recipe_id": str(best_recipe["id"]),
            "name": recipe_details["title"],
            "servings": recipe_details["servings"],
            "ready_in_minutes": recipe_details["readyInMinutes"],
            "image_url": recipe_details["image"],
            
            # Macros (per serving)
            "calories_per_serving": recipe_details["nutrition"]["nutrients"][0]["amount"],
            "protein_per_serving": self._get_nutrient(recipe_details["nutrition"], "Protein"),
            "carbs_per_serving": self._get_nutrient(recipe_details["nutrition"], "Carbohydrates"),
            "fat_per_serving": self._get_nutrient(recipe_details["nutrition"], "Fat"),
            
            # Ingredients
            "ingredients": [
                {
                    "name": ing["name"],
                    "amount": ing["amount"],
                    "unit": ing["unit"]
                }
                for ing in recipe_details["extendedIngredients"]
            ],
            
            # AI-simplified steps (max 5)
            "steps": simplified_steps,
            
            # Metadata
            "source": "spoonacular",
            "spoonacular_url": recipe_details["sourceUrl"]
        }
    
    async def _search_recipes(
        self, 
        dietary_restrictions: List[str],
        ingredients: List[str],
        number: int = 5
    ) -> List[Dict]:
        """Search Spoonacular for recipes matching constraints"""
        
        # Convert dietary restrictions to Spoonacular format
        intolerances = self._convert_allergens_to_spoonacular(dietary_restrictions)
        diet = self._get_diet_type(dietary_restrictions)
        
        # Build query params
        params = {
            "apiKey": self.spoonacular_key,
            "number": number,
            "addRecipeInformation": True,
            "fillIngredients": True,
            "includeNutrition": True,
            "instructionsRequired": True,
            "maxReadyTime": 45,  # Max 45 minutes (busy parents!)
            "sort": "popularity"
        }
        
        # Add dietary constraints
        if intolerances:
            params["intolerances"] = ",".join(intolerances)
        if diet:
            params["diet"] = diet
        
        # Search by ingredients user has
        if ingredients:
            # Limit to top 5 ingredients to avoid too narrow search
            params["includeIngredients"] = ",".join(ingredients[:5])
            params["ranking"] = 2  # Maximize used ingredients
        
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{SPOONACULAR_BASE_URL}/recipes/complexSearch",
                params=params,
                timeout=10.0
            )
            
            if response.status_code != 200:
                return []
            
            data = response.json()
            return data.get("results", [])
    
    async def _get_recipe_details(self, recipe_id: int) -> Dict:
        """Get full recipe details including nutrition and instructions"""
        params = {
            "apiKey": self.spoonacular_key,
            "includeNutrition": True
        }
        
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{SPOONACULAR_BASE_URL}/recipes/{recipe_id}/information",
                params=params,
                timeout=10.0
            )
            return response.json()
    
    async def _simplify_with_ai(
        self, 
        recipe_name: str,
        original_steps: str,
        max_steps: int = 5
    ) -> List[str]:
        """
        Use Claude AI to simplify cooking instructions to max 5 steps
        Makes recipes less overwhelming for tired parents!
        """
        prompt = f"""You are a helpful cooking assistant for busy working parents.

Recipe: {recipe_name}

Original instructions:
{original_steps}

Task: Simplify these cooking instructions to EXACTLY {max_steps} clear, actionable steps.

Requirements:
- Maximum {max_steps} steps
- Each step should be 1-2 sentences
- Use simple language
- Focus on essential actions only
- Combine similar tasks when possible
- Be encouraging and friendly

Return ONLY a numbered list of {max_steps} steps, nothing else."""

        message = self.ai_client.messages.create(
            model="claude-sonnet-4-20250514",
            max_tokens=1000,
            messages=[
                {"role": "user", "content": prompt}
            ]
        )
        
        # Parse AI response into list
        response_text = message.content[0].text
        steps = []
        
        for line in response_text.split("\n"):
            line = line.strip()
            # Remove numbering (1., 2., etc.)
            if line and line[0].isdigit():
                step_text = line.split(".", 1)[1].strip() if "." in line else line
                steps.append(step_text)
        
        return steps[:max_steps]  # Ensure max steps
    
    def _convert_allergens_to_spoonacular(self, restrictions: List[str]) -> List[str]:
        """Convert our allergen format to Spoonacular intolerances"""
        mapping = {
            "dairy_free": "dairy",
            "egg_free": "egg",
            "gluten_free": "gluten",
            "peanut_free": "peanut",
            "nut_free": "tree nut",
            "soy_free": "soy",
            "shellfish_free": "shellfish",
            "fish_free": "seafood"
        }
        
        return [mapping[r] for r in restrictions if r in mapping]
    
    def _get_diet_type(self, restrictions: List[str]) -> Optional[str]:
        """Get diet type for Spoonacular from restrictions"""
        if "vegan" in restrictions:
            return "vegan"
        if "vegetarian" in restrictions:
            return "vegetarian"
        if "keto" in restrictions:
            return "ketogenic"
        return None
    
    def _get_nutrient(self, nutrition: Dict, nutrient_name: str) -> float:
        """Extract specific nutrient from Spoonacular nutrition data"""
        for nutrient in nutrition.get("nutrients", []):
            if nutrient["name"] == nutrient_name:
                return nutrient["amount"]
        return 0.0


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
