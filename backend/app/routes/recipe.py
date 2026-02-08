"""
Recipe Routes - Example routes for your teammate

This shows how to:
1. Get daily recipe suggestion
2. Accept/reject recipes
3. Get recipe alternatives
4. Integrate with your pantry system
"""

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel
from sqlalchemy.orm import Session
from typing import List, Optional
import httpx

from ..services.recipe_service import recipe_service
from ..deps import get_current_user, get_db
from ..crud import pantry as crud
from ..schemas.pantry import DinnerHistoryCreate

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

# Exactly 4 recipes per request (recipeEngine)
RECIPE_ENGINE_COUNT = 4


def _parse_allergens(allergens: Optional[str]) -> Optional[List[str]]:
    """Parse comma-separated allergens (egg,milk,peanut) to internal format for Spoonacular."""
    if not allergens or not allergens.strip():
        return None
    # Map client names to our dietary_restrictions / Spoonacular keys
    mapping = {"egg": "egg_free", "eggs": "egg_free", "milk": "dairy_free", "peanut": "peanut_free", "peanuts": "peanut_free"}
    out = []
    for raw in allergens.strip().lower().split(","):
        key = raw.strip()
        if key in mapping and mapping[key] not in out:
            out.append(mapping[key])
        elif key in ("egg_free", "dairy_free", "peanut_free") and key not in out:
            out.append(key)
    return out if out else None


@router.get("/suggestions", response_model=List[RecipeResponse])
async def get_suggestions(
        count: int = RECIPE_ENGINE_COUNT,
        allergens: Optional[str] = Query(None, description="Comma-separated: egg, milk, peanut"),
        current_user: dict = Depends(get_current_user),
        db: Session = Depends(get_db)
):
    """
    Get exactly 4 recipe suggestions (recipeEngine) with unique AI image per recipe.
    Optional allergy filter: egg, milk, peanut. Uses pantry preferences when not provided.
    """
    recipes = await recipe_service.get_suggestions(
        user_id=current_user["id"],
        db=db,
        count=min(max(1, count), 10),  # clamp 1–10, default 4
        allergens_override=_parse_allergens(allergens),
    )
    if isinstance(recipes, dict) and "error" in recipes:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=recipes["error"],
        )
    return recipes


@router.get("/daily-suggestion", response_model=RecipeResponse)
async def get_daily_suggestion(
        current_user: dict = Depends(get_current_user),
        db: Session = Depends(get_db)
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

    recipe = await recipe_service.get_daily_suggestion(
        user_id=current_user["id"],
        db=db
    )

    # Check if recipe service returned an error
    if isinstance(recipe, dict) and "error" in recipe:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=recipe["error"]
        )

    return recipe


@router.post("/accept")
async def accept_recipe(
        request: AcceptRecipeRequest,
        current_user: dict = Depends(get_current_user),
        db: Session = Depends(get_db)
):
    """
    User accepted the recipe ("I will eat this" / Grub). Logs dinner for today
    so it appears in Macros for the day.
    """
    dinner = DinnerHistoryCreate(
        meal_name=request.name,
        recipe_id=request.recipe_id,
        servings=request.servings,
        calories_per_serving=request.calories_per_serving,
        protein_per_serving=request.protein_per_serving,
        carbs_per_serving=request.carbs_per_serving,
        fat_per_serving=request.fat_per_serving,
    )
    crud.create_dinner_history(db, current_user["id"], dinner)
    return {
        "success": True,
        "message": "Logged for today! Check Macros.",
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
                "calories_percent": (actual["avg_calories"] / preferences["target_calories"] * 100) if preferences.get(
                    "target_calories") else 0,
                "protein_percent": (actual["avg_protein"] / preferences["target_protein"] * 100) if preferences.get(
                    "target_protein") else 0,
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