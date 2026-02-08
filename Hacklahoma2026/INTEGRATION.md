# What's For Dinner — Full-Stack Integration

This repo is wired as a **backend (Python FastAPI) + Swift (Xcode)** app. The recipe engine returns **exactly 4 recipes** per request, each with an optional **AI-generated image** from the API model layer.

## Architecture

- **Backend:** `backend/app` — FastAPI app (pantry + recipe routes).
- **Recipe engine:** `backend/app/services/recipe_service.py` — 4 recipes per request, AI image via `recipe_image_service.py`.
- **API model:** `API model/recipe_image.py` — logic to generate a unique AI image per recipe (OpenAI DALL-E 3).
- **Swift app:** `backend/whatsForDinner/` — iOS UI with Models, Networking, and Views.

## Backend (Python)

### 1. Environment

From `backend/`:

```bash
cd backend
python -m venv venv
source venv/bin/activate   # or venv\Scripts\activate on Windows
pip install -r requirements.txt
```

### 2. Environment variables

Create `backend/.env` (or export):

- `SPOONACULAR_API_KEY` — required for recipe search.
- `GEMINI_API_KEY` — required for step simplification.
- `OPENAI_API_KEY` — optional; when set, each recipe gets a unique DALL-E 3 image.

### 3. Run API

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

- Health: http://127.0.0.1:8000/health  
- 4 recipes: http://127.0.0.1:8000/api/recipe/suggestions?count=4  
  (Uses mock user from `deps.get_current_user` until you add real auth.)

## Swift / Xcode

### 1. Open project

Open the Swift app in Xcode (the folder that contains `whatsForDinnerApp.swift` and the new `Models/`, `Networking/`, `Views/`).

### 2. Add files to the app target

If you added new files outside Xcode, add them to the target:

- `Models/RecipeModels.swift`
- `Networking/RecipeService.swift`
- `Views/RecipeDetailView.swift`
- `AppConfig.swift`
- Ensure `Info.plist` is set as the target’s Info.plist (or add “App Transport Security” and allow localhost in the target’s Info).

### 3. Allow HTTP for localhost

`Info.plist` in `backend/whatsForDinner/` already allows insecure loads for `localhost` and `127.0.0.1`. If your project uses the target’s built-in Info, add:

- **App Transport Security** → **Exception Domains** → `127.0.0.1` and `localhost` with **Allow Insecure HTTP Loads** = YES.

### 4. Run

- Run the app in the **Simulator** (API base URL is `http://127.0.0.1:8000` in `AppConfig.swift`).
- For a **physical device**, set `AppConfig.apiBaseURL` to your Mac’s IP (e.g. `http://192.168.1.x:8000`) and ensure the device is on the same network.

## API model (AI images)

- **Logic:** `API model/recipe_image.py` — `generate_recipe_image_url(recipe_name)` and optional file save.
- **Backend use:** `backend/app/services/recipe_image_service.py` calls the same logic (OpenAI) so the backend stays self-contained.
- **Standalone test:**  
  `OPENAI_API_KEY=sk-... python "API model/recipe_image.py" "Chicken Jambalaya"`  
  writes a PNG under `API model/generated/`.

## Recipe engine (4 recipes)

- **Endpoint:** `GET /api/recipe/suggestions?count=4`  
- **Default:** 4 recipes per request (configurable 1–10).
- **Per recipe:** name, servings, time, macros, ingredients, steps, and `image_url` (Spoonacular or DALL-E 3 when `OPENAI_API_KEY` is set).

## Swift structure

- **Models:** `Recipe`, `RecipeIngredient` in `Models/RecipeModels.swift` (matches API).
- **Networking:** `RecipeService` in `Networking/RecipeService.swift` — `fetchSuggestions(count: 4)`, optional `fetchDailySuggestion()`.
- **Config:** `AppConfig.apiBaseURL` in `AppConfig.swift`.
- **UI:** `RecipesHomeView` (grid, pull-to-refresh, loading/error), `RecipeCard`, `RecipeDetailView` (ingredients + steps).

Everything is modular and ready to run: start the backend, then run the Swift app in Xcode against the same host.
