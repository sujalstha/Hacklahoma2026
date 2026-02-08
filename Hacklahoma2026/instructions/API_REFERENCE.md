# API Quick Reference - What's For Dinner

**Base URL:** `http://127.0.0.1:8000`

## 📋 All Endpoints

### User Preferences

| Method | Endpoint | Description | Body |
|--------|----------|-------------|------|
| POST | `/api/pantry/preferences` | Create preferences | `{"dietary_restrictions": [...], "target_calories": 2000, ...}` |
| GET | `/api/pantry/preferences` | Get preferences | - |
| PATCH | `/api/pantry/preferences` | Update preferences | `{"dietary_restrictions": [...]}` |
| GET | `/api/pantry/preferences/allergens` | Get allergen list | - |

### Pantry Items

| Method | Endpoint | Description | Body |
|--------|----------|-------------|------|
| POST | `/api/pantry/items` | Create pantry item | `{"name": "Chicken", "category": "protein", ...}` |
| GET | `/api/pantry/items/{id}` | Get item by ID | - |
| GET | `/api/pantry/items?query=milk` | Search items | - |
| POST | `/api/pantry/scan` | Scan barcode | `{"barcode": "041190468843"}` |

### Inventory

| Method | Endpoint | Description | Body |
|--------|----------|-------------|------|
| GET | `/api/pantry/inventory` | Get all inventory | - |
| POST | `/api/pantry/inventory` | Add to inventory | `{"item_id": 1, "quantity": 2, "unit": "lb", ...}` |
| PATCH | `/api/pantry/inventory/{id}` | Update inventory | `{"quantity": 1.5}` |
| POST | `/api/pantry/inventory/{id}/adjust?quantity_delta=-0.5` | Adjust quantity | - |
| DELETE | `/api/pantry/inventory/{id}` | Remove from inventory | - |
| GET | `/api/pantry/stats` | Get inventory stats | - |

### Recipes

| Method | Endpoint | Description | Body |
|--------|----------|-------------|------|
| GET | `/api/recipe/suggestions?count=4` | Get exactly 4 recipe suggestions (recipeEngine), each with optional AI image | - |
| GET | `/api/recipe/daily-suggestion` | Get today's recipe | - |
| POST | `/api/recipe/accept` | Accept recipe | `{"recipe_id": "123", "name": "...", ...}` |
| POST | `/api/recipe/swap` | Get different recipe | - |
| GET | `/api/recipe/too-tired` | Get emergency easy meal | - |

### Dinner History & Macros

| Method | Endpoint | Description | Body |
|--------|----------|-------------|------|
| GET | `/api/pantry/dinners?days=30` | Get dinner history | - |
| POST | `/api/pantry/dinners` | Log a dinner | `{"meal_name": "...", "calories_per_serving": 420, ...}` |
| PATCH | `/api/pantry/dinners/{id}` | Rate/update dinner | `{"rating": 5, "notes": "Great!"}` |
| GET | `/api/pantry/dinners/macros/summary?days=7` | Get macro summary | - |
| GET | `/api/recipe/macros/progress?days=7` | Get progress vs goals | - |

## 🔍 Example Requests

### 1. Create User Preferences
```bash
curl -X POST http://127.0.0.1:8000/api/pantry/preferences \
  -H "Content-Type: application/json" \
  -d '{
    "dietary_restrictions": ["gluten_free", "dairy_free"],
    "target_calories": 2000,
    "target_protein": 150,
    "target_carbs": 200,
    "target_fat": 65,
    "household_size": 2,
    "preferred_cuisines": ["italian", "mexican"]
  }'
```

### 2. Scan Barcode
```bash
curl -X POST http://127.0.0.1:8000/api/pantry/scan \
  -H "Content-Type: application/json" \
  -d '{"barcode": "041190468843"}'
```

Response:
```json
{
  "found": true,
  "item": {
    "id": 1,
    "name": "Whole Milk",
    "barcode": "041190468843",
    "category": "dairy",
    "calories_per_serving": 150
  }
}
```

### 3. Add to Inventory
```bash
curl -X POST http://127.0.0.1:8000/api/pantry/inventory \
  -H "Content-Type: application/json" \
  -d '{
    "item_id": 1,
    "quantity": 1,
    "unit": "gallon",
    "location": "fridge"
  }'
```

### 4. Get Daily Recipe
```bash
curl http://127.0.0.1:8000/api/recipe/daily-suggestion
```

Response:
```json
{
  "recipe_id": "12345",
  "name": "Quick Chicken Stir Fry",
  "servings": 2,
  "ready_in_minutes": 25,
  "calories_per_serving": 420,
  "protein_per_serving": 35,
  "carbs_per_serving": 40,
  "fat_per_serving": 15,
  "ingredients": [
    {"name": "chicken breast", "amount": 1, "unit": "lb"},
    {"name": "broccoli", "amount": 2, "unit": "cup"}
  ],
  "steps": [
    "Cut chicken into bite-sized pieces and season.",
    "Heat oil in pan, cook chicken 5 minutes.",
    "Add broccoli, stir-fry 3 minutes.",
    "Add sauce, toss 1 minute.",
    "Serve over rice!"
  ]
}
```

### 5. Accept Recipe
```bash
curl -X POST http://127.0.0.1:8000/api/recipe/accept \
  -H "Content-Type: application/json" \
  -d '{
    "recipe_id": "12345",
    "name": "Quick Chicken Stir Fry",
    "servings": 2,
    "calories_per_serving": 420,
    "protein_per_serving": 35,
    "carbs_per_serving": 40,
    "fat_per_serving": 15,
    "ingredients": [
      {"name": "chicken breast", "amount": 1, "unit": "lb"}
    ]
  }'
```

### 6. Get Macro Summary
```bash
curl http://127.0.0.1:8000/api/pantry/dinners/macros/summary?days=7
```

Response:
```json
{
  "total_meals": 7,
  "avg_calories": 520,
  "avg_protein": 38,
  "avg_carbs": 45,
  "avg_fat": 22,
  "date_range": "Last 7 days"
}
```

## 🎯 Common Workflows

### Onboarding Flow
1. `POST /api/pantry/preferences` - Set dietary restrictions & goals
2. `POST /api/pantry/items` - Add initial pantry items
3. `POST /api/pantry/inventory` - Add to inventory

### Daily Dinner Flow
1. `GET /api/recipe/daily-suggestion` - Get recipe at 5 PM
2. User reviews recipe
3. `POST /api/recipe/accept` - User accepts
   - Backend logs dinner
   - Backend deducts ingredients from inventory
4. After cooking: `PATCH /api/pantry/dinners/{id}` - Rate the meal

### Add Item via Barcode
1. User scans barcode with camera
2. `POST /api/pantry/scan` with barcode
3. If found: `POST /api/pantry/inventory` with item_id
4. If not found: Manual entry → `POST /api/pantry/items` first

### Check Progress
1. `GET /api/pantry/preferences` - Get target macros
2. `GET /api/pantry/dinners/macros/summary?days=7` - Get actual macros
3. Display progress bars/charts in UI

## 🔴 Error Codes

| Code | Meaning | Common Causes |
|------|---------|---------------|
| 200 | Success | - |
| 201 | Created | Resource successfully created |
| 400 | Bad Request | Invalid JSON, missing required fields |
| 404 | Not Found | Item/recipe doesn't exist |
| 500 | Server Error | Backend crashed, check logs |

## 💡 Tips for iOS Team

1. **Test in Postman first** before implementing in iOS
2. **Handle errors gracefully** - show user-friendly messages
3. **Use async/await** for all API calls
4. **Cache recipes** - don't fetch every time
5. **Offline mode** - store inventory locally, sync when online
6. **Loading states** - show spinners while waiting for API
7. **Retry logic** - network can fail, retry 2-3 times

## 🧪 Quick Test Script

Save this as `test_api.sh`:

```bash
#!/bin/bash
BASE_URL="http://127.0.0.1:8000"

echo "1. Create preferences..."
curl -X POST $BASE_URL/api/pantry/preferences \
  -H "Content-Type: application/json" \
  -d '{"dietary_restrictions": ["gluten_free"], "target_calories": 2000, "household_size": 2, "preferred_cuisines": []}'

echo -e "\n\n2. Create pantry item..."
curl -X POST $BASE_URL/api/pantry/items \
  -H "Content-Type: application/json" \
  -d '{"name": "Chicken Breast", "category": "protein", "default_unit": "lb"}'

echo -e "\n\n3. Add to inventory..."
curl -X POST $BASE_URL/api/pantry/inventory \
  -H "Content-Type: application/json" \
  -d '{"item_id": 1, "quantity": 2, "unit": "lb", "location": "fridge"}'

echo -e "\n\n4. Get daily recipe..."
curl $BASE_URL/api/recipe/daily-suggestion

echo -e "\n\nDone!"
```

Run with: `bash test_api.sh`
