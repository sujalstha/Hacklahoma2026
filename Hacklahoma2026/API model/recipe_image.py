"""
Recipe AI Image Generation - What's for Dinner?

Generates a unique food image for each recipe using OpenAI DALL-E 3.
Used by the backend recipe engine and can be run standalone for testing.

Usage from backend:
  from recipe_image import generate_recipe_image_url

Usage standalone:
  python recipe_image.py "Chicken Jambalaya"

Requires: OPENAI_API_KEY environment variable
"""

import os
import re
import urllib.request
from typing import Optional

# Optional: use openai package if available (backend); else use urllib for standalone
try:
    from openai import OpenAI
    _HAS_OPENAI = True
except ImportError:
    _HAS_OPENAI = False


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
    Generate a unique AI image for a recipe and return the image URL.
    Returns None if OPENAI_API_KEY is missing or the API call fails.
    """
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        return None

    prompt = build_image_prompt(recipe_name)

    if _HAS_OPENAI:
        try:
            client = OpenAI(api_key=api_key)
            resp = client.images.generate(
                model="dall-e-3",
                prompt=prompt,
                n=1,
                size="1024x1024",
                quality="standard",
                style="natural",
            )
            return resp.data[0].url if resp.data else None
        except Exception:
            return None
    else:
        # Fallback: raw HTTP for standalone script without openai package
        import json
        import urllib.request
        req = urllib.request.Request(
            "https://api.openai.com/v1/images/generations",
            data=json.dumps({
                "model": "dall-e-3",
                "prompt": prompt,
                "n": 1,
                "size": "1024x1024",
                "quality": "standard",
                "style": "natural",
            }).encode(),
            headers={
                "Content-Type": "application/json",
                "Authorization": f"Bearer {api_key}",
            },
            method="POST",
        )
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                data = json.loads(r.read().decode())
                return data.get("data", [{}])[0].get("url")
        except Exception:
            return None


def save_recipe_image_to_file(recipe_name: str, output_dir: str) -> Optional[str]:
    """
    Generate image for recipe and save to output_dir. Returns path to saved file or None.
    """
    url = generate_recipe_image_url(recipe_name)
    if not url:
        return None
    os.makedirs(output_dir, exist_ok=True)
    safe_name = re.sub(r"[^a-zA-Z0-9\-_]", "_", recipe_name)[:50]
    path = os.path.join(output_dir, f"{safe_name}.png")
    urllib.request.urlretrieve(url, path)
    return path


if __name__ == "__main__":
    import sys
    if len(sys.argv) < 2:
        print("Usage: python recipe_image.py \"Recipe Name\"")
        sys.exit(1)
    name = " ".join(sys.argv[1:])
    out_dir = os.path.join(os.path.dirname(__file__), "generated")
    path = save_recipe_image_to_file(name, out_dir)
    if path:
        print(f"Saved: {path}")
    else:
        print("Failed (set OPENAI_API_KEY?)")
        sys.exit(1)
