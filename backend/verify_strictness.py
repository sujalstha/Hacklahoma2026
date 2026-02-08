
import asyncio
from app.services.recipe_service import RecipeService
from app.db import SessionLocal

async def verify():
    service = RecipeService()
    db = SessionLocal()
    
    print("\n--- Final Stress Test: 'No Rice, No Milk, No Beef' ---")
    
    # User's specified inventory minus the "banned" items
    test_available = [
        "Pasta", "Eggs", "Broccoli", "Spinach", "Peppers", 
        "Onions", "Garlic", "Tomato Sauce", "Olive Oil", 
        "Yogurt", "Potatoes", "Butter", "Flour"
    ]
    
    print(f"Inventory ({len(test_available)} items): {test_available}")
    
    valid_recipes = []
    hallucinated = set()
    
    for attempt in range(5):
        needed = 4 - len(valid_recipes)
        if needed <= 0: break
        
        print(f"DEBUG: Attempt {attempt+1} - Requesting {needed} recipes...")
        recipes = await service._generate_recipes_with_gemini(
            ingredients=test_available,
            dietary_restrictions=[],
            count=needed,
            forbidden_override=list(hallucinated)
        )
        
        for r in recipes:
            # Note: _is_recipe_valid now returns (bool, bad_ing)
            is_valid, bad_ing = service._is_recipe_valid(r, test_available)
            if is_valid:
                # Filter out duplicates
                if not any(v['name'] == r['name'] for v in valid_recipes):
                    valid_recipes.append(r)
                    print(f"  ✅ VALID: {r['name']}")
                else:
                    print(f"  ⚠️ DUPLICATE: {r['name']} (Discarded)")
            else:
                print(f"  ❌ REJECTED: {r['name']} (Used: {bad_ing})")
                hallucinated.add(bad_ing)

    print(f"\nFINAL RESULT: {len(valid_recipes)}/4 Recipes Generated.")
    
    if len(valid_recipes) == 4:
        print("\n🏆 SUCCESS: 4 recipes generated without Rice, Milk, or Beef!")
        for i, r in enumerate(valid_recipes):
            print(f"Recipe {i+1}: {r['name']}")
            print(f"   Ingredients: {[ing['name'] for ing in r['ingredients']]}")
    else:
        print(f"\n⚠️ FAILED to get 4 recipes. Found {len(valid_recipes)}.")
        
    db.close()

if __name__ == "__main__":
    asyncio.run(verify())
