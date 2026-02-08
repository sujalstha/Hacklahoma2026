"""
Recipe Service - Integrates Spoonacular API and Gemini AI for recipe suggestions

This service:
1. Gets user's dietary restrictions from pantry API
2. Gets user's available ingredients from pantry API
3. Searches Spoonacular for matching recipes
4. Uses Gemini AI to simplify cooking steps to 5 steps max
5. Returns recipe with macros and simplified instructions
"""

import httpx
from typing import Optional, List, Dict
import google.generativeai as genai
import logging

# Import settings from config instead of using os.getenv
from ..config import settings

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class RecipeService:
    def __init__(self):
        # Use settings from config.py instead of os.getenv
        self.spoonacular_key = settings.SPOONACULAR_API_KEY

        # Log API key status (first/last 4 chars only for security)
        if self.spoonacular_key:
            key_preview = f"{self.spoonacular_key[:4]}...{self.spoonacular_key[-4:]}"
            logger.info(f"Spoonacular API key loaded: {key_preview}")
        else:
            logger.warning("Spoonacular API key NOT configured!")

        # Configure Gemini - use settings from config.py
        gemini_api_key = settings.GEMINI_API_KEY
        if gemini_api_key:
            try:
                genai.configure(api_key=gemini_api_key)
                self.model = genai.GenerativeModel('gemini-3-flash-preview')
                logger.info("Gemini AI configured successfully")
            except Exception as e:
                logger.error(f"Failed to configure Gemini AI: {e}")
                self.model = None
        else:
            self.model = None
            logger.warning("Gemini API key not configured - will use fallback for step simplification")

    async def get_daily_suggestion(
            self,
            user_id: int,
            pantry_api_url: str = "http://localhost:8000/api/pantry"
    ) -> Dict:
        """
        Main function: Get a single recipe suggestion for dinner tonight
        """
        logger.info(f"Getting daily suggestion for user {user_id}")

        # 1. Get user constraints from your pantry API
        allergens = []
        available_ingredients = []

        try:
            async with httpx.AsyncClient() as client:
                # Get dietary restrictions
                try:
                    prefs_response = await client.get(
                        f"{pantry_api_url}/preferences/allergens",
                        headers={"user-id": str(user_id)},
                        timeout=5.0
                    )
                    if prefs_response.status_code == 200:
                        allergens = prefs_response.json().get("dietary_restrictions", [])
                        logger.info(f"User allergens: {allergens}")
                    else:
                        logger.warning(f"Could not get allergens: {prefs_response.status_code}")
                except Exception as e:
                    logger.warning(f"Error getting allergens (will continue without): {e}")

                # Get available ingredients
                try:
                    inventory_response = await client.get(
                        f"{pantry_api_url}/inventory",
                        headers={"user-id": str(user_id)},
                        timeout=5.0
                    )
                    if inventory_response.status_code == 200:
                        inventory = inventory_response.json()
                        available_ingredients = [item["item"]["name"] for item in inventory]
                        logger.info(f"User has {len(available_ingredients)} ingredients in inventory")
                    else:
                        logger.warning(f"Could not get inventory: {inventory_response.status_code}")
                except Exception as e:
                    logger.warning(f"Error getting inventory (will continue without): {e}")

        except Exception as e:
            logger.error(f"Error communicating with pantry API: {e}")
            # Continue anyway - we'll search without constraints

        # 2. Search Spoonacular for matching recipes
        recipes = await self._search_recipes(
            dietary_restrictions=allergens,
            ingredients=available_ingredients,
            number=10  # Get more options to increase chances
        )

        if not recipes:
            # If no recipes found with constraints, try a broader search
            logger.warning("No recipes found with constraints, trying broader search...")
            recipes = await self._search_recipes_fallback()

        if not recipes:
            return {"error": "No recipes found matching your constraints"}

        logger.info(f"Found {len(recipes)} recipes")

        # 3. Get the best recipe (first one)
        best_recipe = recipes[0]
        logger.info(f"Selected recipe: {best_recipe.get('title', best_recipe.get('id'))}")

        # 4. Get detailed recipe info from Spoonacular
        recipe_details = await self._get_recipe_details(best_recipe["id"])

        if not recipe_details:
            return {"error": "Failed to get recipe details from Spoonacular"}

        # 5. Simplify cooking steps using AI
        instructions = recipe_details.get("instructions", "")
        if not instructions:
            # Try to get from analyzedInstructions
            analyzed = recipe_details.get("analyzedInstructions", [])
            if analyzed:
                instructions = " ".join([
                    step["step"]
                    for instruction in analyzed
                    for step in instruction.get("steps", [])
                ])

        simplified_steps = await self._simplify_with_ai(
            recipe_name=recipe_details["title"],
            original_steps=instructions,
            max_steps=5
        )

        # 6. Build final recipe object
        # Safely extract nutrition data
        nutrition = recipe_details.get("nutrition", {})
        nutrients = nutrition.get("nutrients", [])

        # Get calories (usually first nutrient)
        calories = 0
        if nutrients:
            calories = nutrients[0].get("amount", 0)

        return {
            "recipe_id": str(best_recipe["id"]),
            "name": recipe_details["title"],
            "servings": recipe_details.get("servings", 4),
            "ready_in_minutes": recipe_details.get("readyInMinutes", 30),
            "image_url": recipe_details.get("image"),

            # Macros (per serving)
            "calories_per_serving": calories,
            "protein_per_serving": self._get_nutrient(nutrition, "Protein"),
            "carbs_per_serving": self._get_nutrient(nutrition, "Carbohydrates"),
            "fat_per_serving": self._get_nutrient(nutrition, "Fat"),

            # Ingredients
            "ingredients": [
                {
                    "name": ing.get("name", ing.get("nameClean", "Unknown")),
                    "amount": ing.get("amount", 0),
                    "unit": ing.get("unit", "")
                }
                for ing in recipe_details.get("extendedIngredients", [])
            ],

            # AI-simplified steps (max 5)
            "steps": simplified_steps,

            # Metadata
            "source": "spoonacular",
            "spoonacular_url": recipe_details.get("sourceUrl", recipe_details.get("spoonacularSourceUrl"))
        }

    async def _search_recipes(
            self,
            dietary_restrictions: List[str],
            ingredients: List[str],
            number: int = 10
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
            "maxReadyTime": 60,  # Increased from 45 to get more results
            "sort": "popularity"
        }

        # Add dietary constraints
        if intolerances:
            params["intolerances"] = ",".join(intolerances)
            logger.info(f"Searching with intolerances: {intolerances}")
        if diet:
            params["diet"] = diet
            logger.info(f"Searching with diet: {diet}")

        # Search by ingredients user has (but don't make it too restrictive)
        if ingredients and len(ingredients) > 0:
            # Use fewer ingredients to get broader results
            top_ingredients = ingredients[:3]  # Reduced from 5 to 3
            params["includeIngredients"] = ",".join(top_ingredients)
            params["ranking"] = 1  # Changed from 2 to 1 for broader search
            logger.info(f"Searching with ingredients: {top_ingredients}")

        logger.info(f"Calling Spoonacular complexSearch")

        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(
                    f"{settings.SPOONACULAR_BASE_URL}/recipes/complexSearch",
                    params=params,
                    timeout=15.0
                )

                logger.info(f"Spoonacular response status: {response.status_code}")

                if response.status_code != 200:
                    logger.error(f"Spoonacular API error: {response.text}")
                    return []

                data = response.json()
                results = data.get("results", [])
                logger.info(f"Spoonacular returned {len(results)} recipes")
                return results

        except Exception as e:
            logger.error(f"Error calling Spoonacular API: {e}")
            return []

    async def _search_recipes_fallback(self) -> List[Dict]:
        """Fallback search with minimal constraints - just get ANY popular recipes"""
        logger.info("Running fallback recipe search (no constraints)")

        params = {
            "apiKey": self.spoonacular_key,
            "number": 10,
            "addRecipeInformation": True,
            "fillIngredients": True,
            "includeNutrition": True,
            "instructionsRequired": True,
            "maxReadyTime": 60,
            "sort": "popularity",
            "type": "main course"  # At least limit to main courses
        }

        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(
                    f"{settings.SPOONACULAR_BASE_URL}/recipes/complexSearch",
                    params=params,
                    timeout=15.0
                )

                if response.status_code == 200:
                    data = response.json()
                    results = data.get("results", [])
                    logger.info(f"Fallback search returned {len(results)} recipes")
                    return results
                else:
                    logger.error(f"Fallback search failed: {response.status_code}")
                    return []
        except Exception as e:
            logger.error(f"Fallback search error: {e}")
            return []

    async def _get_recipe_details(self, recipe_id: int) -> Optional[Dict]:
        """Get full recipe details including nutrition and instructions"""
        params = {
            "apiKey": self.spoonacular_key,
            "includeNutrition": True
        }

        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(
                    f"{settings.SPOONACULAR_BASE_URL}/recipes/{recipe_id}/information",
                    params=params,
                    timeout=15.0
                )

                if response.status_code == 200:
                    return response.json()
                else:
                    logger.error(f"Failed to get recipe details: {response.status_code}")
                    return None
        except Exception as e:
            logger.error(f"Error getting recipe details: {e}")
            return None

    async def _simplify_with_ai(
            self,
            recipe_name: str,
            original_steps: str,
            max_steps: int = 5
    ) -> List[str]:
        """
        Use Gemini AI to simplify cooking instructions to max 5 steps
        Makes recipes less overwhelming for tired parents!
        """
        if not original_steps or original_steps.strip() == "":
            return [
                "Preheat and prepare your ingredients",
                "Follow the cooking method for your main ingredient",
                "Combine and season to taste",
                "Cook until done",
                "Serve and enjoy!"
            ]

        if not self.model:
            # Fallback if no API key - return generic steps
            logger.warning("Using fallback steps (no Gemini API)")
            return [
                "Preheat and prepare all ingredients as needed",
                "Follow the main cooking steps from the recipe",
                "Season and combine ingredients",
                "Cook until done according to recipe timing",
                "Serve hot and enjoy your meal!"
            ]

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

        try:
            response = self.model.generate_content(prompt)
            response_text = response.text

            # Parse response into list
            steps = []
            for line in response_text.split("\n"):
                line = line.strip()
                # Remove numbering (1., 2., etc.)
                if line and line[0].isdigit():
                    step_text = line.split(".", 1)[1].strip() if "." in line else line
                    steps.append(step_text)

            if len(steps) >= max_steps:
                return steps[:max_steps]
            else:
                # If we didn't get enough steps, pad with generic ones
                logger.warning(f"Only got {len(steps)} steps from AI, padding to {max_steps}")
                while len(steps) < max_steps:
                    steps.append("Continue following the recipe instructions")
                return steps

        except Exception as e:
            logger.error(f"Error calling Gemini API: {e}")
            # Fallback to simple steps
            return [
                "Prep all ingredients",
                "Cook the main components",
                "Combine everything",
                "Season to taste",
                "Serve and enjoy!"
            ]

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
            if nutrient.get("name") == nutrient_name:
                return nutrient.get("amount", 0.0)
        return 0.0


# Singleton instance
recipe_service = RecipeService()