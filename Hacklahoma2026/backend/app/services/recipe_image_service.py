"""
Backend recipe image service - generates a unique AI image per recipe via OpenAI DALL-E 3.
Integrates with the API model logic (see API model/recipe_image.py for standalone usage).
"""

import os
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
    Generate a unique AI image for a recipe. Returns the image URL or None if disabled/fails.
    Synchronous (OpenAI client is sync). Call via asyncio.to_thread() from async code.
    """
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key or not OpenAI:
        return None
    try:
        client = OpenAI(api_key=api_key)
        resp = client.images.generate(
            model="dall-e-3",
            prompt=build_image_prompt(recipe_name),
            n=1,
            size="1024x1024",
            quality="standard",
            style="natural",
        )
        return resp.data[0].url if resp.data else None
    except Exception:
        return None
