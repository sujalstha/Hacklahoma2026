import requests

SPOONACULAR_API_KEY = "19f3af0561424a42884bb060ec999982"
URL = "https://api.spoonacular.com/recipes/findByIngredients"

def find_recipes(pantry_items):
    params = {
        "ingredients": ",".join(pantry_items),
        "number": 5,
        "ranking": 1,
        "ignorePantry": True,
        "apiKey": SPOONACULAR_API_KEY
    }

    response = requests.get(URL, params=params)
    response.raise_for_status()
    return response.json()

pantry = ["chicken", "garlic", "rice", "olive oil"]
recipes = find_recipes(pantry)

for r in recipes:
    print(r["title"])
    print("Used:", [i["name"] for i in r["usedIngredients"]])
    print("Missing:", [i["name"] for i in r["missedIngredients"]])
    print("----")
