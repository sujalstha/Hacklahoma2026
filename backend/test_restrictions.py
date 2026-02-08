
import asyncio
import os
from dotenv import load_dotenv
from app.services.recipe_service import recipe_service

# Mock the environment
load_dotenv()

async def test_restrictions():
    print("Testing Gemini with strict restrictions...")
    
    # Ingredients that normally go with eggs/milk (baking stuff)
    ingredients = ["Flour", "Sugar", "Butter", "Chocolate Chips", "Chicken", "Bread"]
    
    # Strict allergies
    allergens = ["eggs", "milk", "peanuts"]
    
    print(f"Ingredients: {ingredients}")
    print(f"Restrictions: {allergens}")
    
    recipes = await recipe_service._generate_recipes_with_gemini(
        ingredients=ingredients,
        dietary_restrictions=allergens,
        count=3
    )
    
    for r in recipes:
        print(f"\nRecipe: {r['name']}")
        print(f"Ingredients: {[i['name'] for i in r['ingredients']]}")
        # Simple check
        ing_text = " ".join([i['name'].lower() for i in r['ingredients']])
        if any(bad in ing_text for bad in ["egg", "milk", "peanut", "cream", "cheese", "yogurt"]):
            print("❌ WARNING: Possible allergen detection!")
        else:
            print("✅ Seems safe")

if __name__ == "__main__":
    asyncio.run(test_restrictions())
