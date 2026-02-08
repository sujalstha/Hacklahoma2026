import os
import httpx
import urllib.parse
from typing import Optional

try:
    from openai import OpenAI
except ImportError:
    OpenAI = None


def build_image_prompt(recipe_name: str) -> str:
    """Build a consistent, high-quality prompt for food photography."""
    return (
        f'Professional food photograph of "{recipe_name}", centered in frame. '
        "The dish is in the middle of the image on a simple plate or bowl. "
        "Top-down or slight angle view. Clean composition, the food fills the frame nicely. "
        "Home-cooked appearance, neutral or wooden table background, soft natural lighting, "
        "shallow depth of field. High-quality, appetizing. No text, logos, or watermarks."
    )


def generate_recipe_image_url(recipe_name: str) -> Optional[str]:
    """
    Generate or search for a recipe image.
    1. Try OpenAI DALL-E 3 if key is present.
    2. Fallback to Spoonacular search if key is present.
    3. Fallback to a reliable image placeholder service (Lorem Flickr).
    """
    # 1. Try OpenAI
    openai_key = os.getenv("OPENAI_API_KEY")
    if openai_key and OpenAI:
        try:
            client = OpenAI(api_key=openai_key)
            resp = client.images.generate(
                model="dall-e-3",
                prompt=build_image_prompt(recipe_name),
                n=1,
                size="1024x1024",
                quality="standard",
                style="natural",
            )
            if resp.data:
                return resp.data[0].url
        except Exception as e:
            print(f"OpenAI Image Error: {e}")

    # 2. Fallback to Spoonacular Search
    spoon_key = os.getenv("SPOONACULAR_API_KEY")
    if spoon_key:
        try:
            # Clean up key (sometimes it has quotes)
            spoon_key = spoon_key.replace('"', '').replace("'", "")
            
            # Use raw words for search
            words = recipe_name.lower().replace("recipe", "").replace("dinner", "").split()
            # Try full name first, then just the first few meaningful words
            queries = [recipe_name]
            if len(words) > 2:
                queries.append(" ".join(words[:3]))
            
            with httpx.Client() as client:
                for q in queries:
                    resp = client.get(
                        "https://api.spoonacular.com/recipes/complexSearch",
                        params={
                            "query": q,
                            "number": 1,
                            "apiKey": spoon_key,
                            "type": "main course"
                        },
                        timeout=5.0
                    )
                    if resp.status_code == 200:
                        results = resp.json().get("results", [])
                        if results:
                            img = results[0].get("image")
                            if img: return img
        except Exception as e:
            print(f"Spoonacular Image Error: {e}")

    # 3. Last Resort: Dynamic high-quality food fallback
    # We use a unique seed salt combined with the recipe name to force uniqueness
    import hashlib
    # Increase the seed range and add a random-ish salt that's stable for this recipe name
    seed = int(hashlib.md5(f"salt_v2_{recipe_name}".encode()).hexdigest(), 16) % 5000
    
    # Refine tags: 'gourmet', 'culinary', and 'plating' yield better results than generic 'food'
    clean_name = "".join(c for c in recipe_name if c.isalnum() or c.isspace()).strip()
    # Prioritize the recipe name but surround it with high-quality keywords
    safe_tags = urllib.parse.quote(f"culinary,plating,gourmet,dish,{clean_name.replace(' ', ',')}")
    
    # Use Lorem Flickr with a guaranteed unique lock and higher-quality keyword set
    return f"https://loremflickr.com/800/800/{safe_tags}?lock={seed}"
