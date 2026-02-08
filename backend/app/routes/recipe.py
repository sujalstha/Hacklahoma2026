"""
Recipe Routes - Example routes for your teammate

This shows how to:
1. Get daily recipe suggestion
2. Accept/reject recipes
3. Get recipe alternatives
4. Integrate with your pantry system
"""

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import List, Optional
import httpx

# You'll need to add these imports
# from ..services.recipe_service import recipe_service
# from ..deps import get_current_user

router = APIRouter(prefix="/api/recipe", tags=["recipe"])


# ===== REQUEST/RESPONSE SCHEMAS =====

class RecipeResponse(BaseModel):
    recipe_id: str
    name: str
    servings: int
    ready_in_minutes: int
    image_url: Optional[str] = None
    
    # Macros
    calories_per_serving: float
    protein_per_serving: float
    carbs_per_serving: float
    fat_per_serving: float
    
    # Ingredients
    ingredients: List[dict]
    
    # Simplified steps (max 5)
    steps: List[str]
    
    # Metadata
    source: str
    spoonacular_url: Optional[str] = None


class AcceptRecipeRequest(BaseModel):
    recipe_id: str
    name: str
    servings: int
    calories_per_serving: float
    protein_per_serving: float
    carbs_per_serving: float
    fat_per_serving: float
    ingredients: List[dict]


# ===== ENDPOINTS =====

@router.get("/daily-suggestion", response_model=RecipeResponse)
async def get_daily_suggestion(
    current_user: dict = Depends(get_current_user)
):
    """
    Get tonight's dinner suggestion.
    
    This is called at 5 PM (use a scheduler like APScheduler or Celery).
    
    Flow:
    1. Get user's allergens from pantry API
    2. Get user's inventory from pantry API
    3. Search Spoonacular for recipes
    4. Use AI to simplify cooking steps
    5. Return single best recipe
    """
    # Uncomment when you have recipe_service set up:
    # recipe = await recipe_service.get_daily_suggestion(
    #     user_id=current_user["id"]
    # )
    # return recipe
    
    # Mock response for testing:
    return {
        "recipe_id": "12345",
        "name": "Quick Chicken Stir Fry",
        "servings": 2,
        "ready_in_minutes": 25,
        "image_url": "https://example.com/image.jpg",
        "calories_per_serving": 420,
        "protein_per_serving": 35,
        "carbs_per_serving": 40,
        "fat_per_serving": 15,
        "ingredients": [
            {"name": "chicken breast", "amount": 1, "unit": "lb"},
            {"name": "soy sauce", "amount": 2, "unit": "tbsp"},
            {"name": "broccoli", "amount": 2, "unit": "cup"}
        ],
        "steps": [
            "Cut chicken into bite-sized pieces and season with salt and pepper.",
            "Heat oil in a large pan over high heat and cook chicken until golden, about 5 minutes.",
            "Add broccoli and stir-fry for 3 minutes until tender-crisp.",
            "Pour in soy sauce and toss everything together for 1 minute.",
            "Serve immediately over rice or enjoy as is!"
        ],
        "source": "spoonacular",
        "spoonacular_url": "https://spoonacular.com/recipe"
    }


@router.post("/accept")
async def accept_recipe(
    request: AcceptRecipeRequest,
    current_user: dict = Depends(get_current_user)
):
    """
    User accepted the recipe suggestion.
    
    Actions:
    1. Log dinner in pantry system (for macro tracking)
    2. Deduct ingredients from inventory
    """
    pantry_api_url = "http://localhost:8000/api/pantry"
    
    async with httpx.AsyncClient() as client:
        # 1. Log the dinner
        dinner_response = await client.post(
            f"{pantry_api_url}/dinners",
            json={
                "meal_name": request.name,
                "recipe_id": request.recipe_id,
                "servings": request.servings,
                "calories_per_serving": request.calories_per_serving,
                "protein_per_serving": request.protein_per_serving,
                "carbs_per_serving": request.carbs_per_serving,
                "fat_per_serving": request.fat_per_serving
            },
            headers={"Authorization": f"Bearer {current_user['token']}"}  # Add proper auth
        )
        
        if dinner_response.status_code != 201:
            raise HTTPException(status_code=500, detail="Failed to log dinner")
        
        # 2. Get user's inventory to match ingredients
        inventory_response = await client.get(
            f"{pantry_api_url}/inventory",
            headers={"Authorization": f"Bearer {current_user['token']}"}
        )
        inventory = inventory_response.json()
        
        # 3. Deduct ingredients from inventory
        deducted_items = []
        for ingredient in request.ingredients:
            # Find matching inventory item (fuzzy name match)
            matched = False
            for inv_item in inventory:
                item_name = inv_item["item"]["name"].lower()
                ingredient_name = ingredient["name"].lower()
                
                # Simple fuzzy match (can improve this)
                if ingredient_name in item_name or item_name in ingredient_name:
                    # Deduct quantity
                    adjust_response = await client.post(
                        f"{pantry_api_url}/inventory/{inv_item['id']}/adjust",
                        params={"quantity_delta": -ingredient["amount"]},
                        headers={"Authorization": f"Bearer {current_user['token']}"}
                    )
                    
                    if adjust_response.status_code == 200:
                        deducted_items.append(ingredient["name"])
                        matched = True
                        break
            
            if not matched:
                # Ingredient not in inventory (user might need to buy it)
                pass
    
    return {
        "success": True,
        "message": "Recipe accepted and logged!",
        "deducted_items": deducted_items
    }


@router.post("/swap")
async def swap_recipe(
    current_recipe_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    User wants a different recipe (clicked 'Swap' button).
    
    Get another suggestion with similar constraints.
    """
    # Uncomment when recipe_service is set up:
    # new_recipe = await recipe_service.get_daily_suggestion(
    #     user_id=current_user["id"]
    # )
    # return new_recipe
    
    return {"message": "Swap feature - returns alternative recipe"}


@router.get("/too-tired")
async def get_ultra_easy_meal(
    current_user: dict = Depends(get_current_user)
):
    """
    Emergency 'Too Tired' option - ultra-simple meals.
    
    Returns super easy recipes:
    - Max 3 ingredients
    - Max 15 minutes
    - Minimal cooking required
    """
    # Search Spoonacular with stricter constraints
    # max_ingredients=3, max_ready_time=15
    
    return {
        "recipe_id": "emergency_123",
        "name": "3-Ingredient Scrambled Eggs",
        "servings": 1,
        "ready_in_minutes": 5,
        "ingredients": [
            {"name": "eggs", "amount": 2, "unit": "piece"},
            {"name": "butter", "amount": 1, "unit": "tbsp"},
            {"name": "salt", "amount": 1, "unit": "pinch"}
        ],
        "steps": [
            "Crack eggs into a bowl and whisk.",
            "Melt butter in a pan over medium heat, add eggs.",
            "Stir gently until just set, about 2 minutes. Season and serve!"
        ]
    }


@router.get("/history")
async def get_recipe_history(
    days: int = 30,
    current_user: dict = Depends(get_current_user)
):
    """
    Get recipes the user has cooked recently.
    
    This calls your pantry API's dinner history endpoint.
    """
    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"http://localhost:8000/api/pantry/dinners?days={days}",
            headers={"Authorization": f"Bearer {current_user['token']}"}
        )
        return response.json()


@router.get("/macros/progress")
async def get_macro_progress(
    days: int = 7,
    current_user: dict = Depends(get_current_user)
):
    """
    Show user's macro progress vs. their goals.
    
    Combines:
    - User's target macros (from preferences)
    - User's actual macros (from dinner history)
    """
    async with httpx.AsyncClient() as client:
        # Get target macros
        prefs_response = await client.get(
            "http://localhost:8000/api/pantry/preferences",
            headers={"Authorization": f"Bearer {current_user['token']}"}
        )
        preferences = prefs_response.json()
        
        # Get actual macros
        summary_response = await client.get(
            f"http://localhost:8000/api/pantry/dinners/macros/summary?days={days}",
            headers={"Authorization": f"Bearer {current_user['token']}"}
        )
        actual = summary_response.json()
        
        # Calculate progress
        return {
            "period": f"Last {days} days",
            "target": {
                "calories": preferences.get("target_calories"),
                "protein": preferences.get("target_protein"),
                "carbs": preferences.get("target_carbs"),
                "fat": preferences.get("target_fat")
            },
            "actual": {
                "calories": actual["avg_calories"],
                "protein": actual["avg_protein"],
                "carbs": actual["avg_carbs"],
                "fat": actual["avg_fat"]
            },
            "progress": {
                "calories_percent": (actual["avg_calories"] / preferences["target_calories"] * 100) if preferences.get("target_calories") else 0,
                "protein_percent": (actual["avg_protein"] / preferences["target_protein"] * 100) if preferences.get("target_protein") else 0,
                # ... calculate others
            }
        }


# ===== SCHEDULER (Optional - for 5 PM notifications) =====

"""
You can use APScheduler to automatically send recipe suggestions at 5 PM:

from apscheduler.schedulers.asyncio import AsyncIOScheduler
import asyncio

scheduler = AsyncIOScheduler()

async def send_daily_recipe_notifications():
    '''Send recipe suggestion to all users at 5 PM'''
    # Get all users
    users = get_all_users()  # You need to implement this
    
    for user in users:
        recipe = await recipe_service.get_daily_suggestion(user_id=user.id)
        
        # Send push notification to user's phone
        await send_push_notification(
            user_id=user.id,
            title="What's for dinner?",
            body=f"Try {recipe['name']} tonight! Ready in {recipe['ready_in_minutes']} min.",
            data={"recipe": recipe}
        )

# Schedule for 5 PM every day
scheduler.add_job(
    send_daily_recipe_notifications,
    'cron',
    hour=17,
    minute=0
)

scheduler.start()
"""
