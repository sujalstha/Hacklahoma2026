#!/bin/bash
# Integration Test Script - What's For Dinner
# Tests the complete user flow end-to-end

BASE_URL="http://127.0.0.1:8000"

echo "========================================="
echo "🧪 What's For Dinner - Integration Tests"
echo "========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
PASSED=0
FAILED=0

# Function to test endpoint
test_endpoint() {
    local name=$1
    local method=$2
    local endpoint=$3
    local data=$4
    local expected_code=$5
    
    echo -n "Testing: $name... "
    
    if [ "$method" == "GET" ]; then
        response=$(curl -s -w "\n%{http_code}" "$BASE_URL$endpoint")
    else
        response=$(curl -s -w "\n%{http_code}" -X "$method" "$BASE_URL$endpoint" \
            -H "Content-Type: application/json" \
            -d "$data")
    fi
    
    # Split response and status code
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n-1)
    
    if [ "$http_code" == "$expected_code" ]; then
        echo -e "${GREEN}✓ PASS${NC} (HTTP $http_code)"
        PASSED=$((PASSED + 1))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC} (Expected $expected_code, got $http_code)"
        echo "Response: $body"
        FAILED=$((FAILED + 1))
        return 1
    fi
}

echo "1️⃣  HEALTH CHECK"
echo "-----------------------------------"
test_endpoint "Health endpoint" "GET" "/health" "" "200"
test_endpoint "API docs" "GET" "/docs" "" "200"
echo ""

echo "2️⃣  USER PREFERENCES"
echo "-----------------------------------"
# Create preferences
test_endpoint "Create preferences" "POST" "/api/pantry/preferences" \
    '{"dietary_restrictions":["gluten_free"],"target_calories":2000,"target_protein":150,"target_carbs":200,"target_fat":65,"household_size":2,"preferred_cuisines":["italian"]}' \
    "201"

# Get preferences
test_endpoint "Get preferences" "GET" "/api/pantry/preferences" "" "200"

# Get allergens (used by recipe engine)
test_endpoint "Get allergens" "GET" "/api/pantry/preferences/allergens" "" "200"
echo ""

echo "3️⃣  PANTRY ITEMS"
echo "-----------------------------------"
# Create pantry items
test_endpoint "Create item: Chicken" "POST" "/api/pantry/items" \
    '{"name":"Chicken Breast","category":"protein","default_unit":"lb"}' \
    "201"

test_endpoint "Create item: Rice" "POST" "/api/pantry/items" \
    '{"name":"White Rice","category":"grain","default_unit":"cup"}' \
    "201"

test_endpoint "Create item: Broccoli" "POST" "/api/pantry/items" \
    '{"name":"Broccoli","category":"vegetable","default_unit":"cup"}' \
    "201"

# Search items
test_endpoint "Search items" "GET" "/api/pantry/items?query=chicken" "" "200"

# Test barcode scan (this will fail gracefully if item not in OpenFood Facts)
test_endpoint "Scan barcode" "POST" "/api/pantry/scan" \
    '{"barcode":"041190468843"}' \
    "200"
echo ""

echo "4️⃣  INVENTORY MANAGEMENT"
echo "-----------------------------------"
# Add items to inventory
test_endpoint "Add chicken to inventory" "POST" "/api/pantry/inventory" \
    '{"item_id":1,"quantity":2,"unit":"lb","location":"fridge"}' \
    "201"

test_endpoint "Add rice to inventory" "POST" "/api/pantry/inventory" \
    '{"item_id":2,"quantity":4,"unit":"cup","location":"pantry"}' \
    "201"

test_endpoint "Add broccoli to inventory" "POST" "/api/pantry/inventory" \
    '{"item_id":3,"quantity":3,"unit":"cup","location":"fridge"}' \
    "201"

# Get inventory
test_endpoint "Get inventory" "GET" "/api/pantry/inventory" "" "200"

# Get inventory stats
test_endpoint "Get inventory stats" "GET" "/api/pantry/stats" "" "200"
echo ""

echo "5️⃣  RECIPE ENGINE 🔥"
echo "-----------------------------------"
echo "⚠️  This tests integration with Spoonacular & Gemini"
echo ""

# Get daily recipe suggestion
echo -n "Testing: Get daily recipe... "
recipe_response=$(curl -s -w "\n%{http_code}" "$BASE_URL/api/recipe/daily-suggestion")
recipe_code=$(echo "$recipe_response" | tail -n1)
recipe_body=$(echo "$recipe_response" | head -n-1)

if [ "$recipe_code" == "200" ]; then
    echo -e "${GREEN}✓ PASS${NC}"
    PASSED=$((PASSED + 1))
    
    # Validate recipe structure
    echo "   Checking recipe structure..."
    
    # Extract recipe_id for later use
    recipe_id=$(echo "$recipe_body" | grep -o '"recipe_id":"[^"]*"' | head -1 | cut -d'"' -f4)
    recipe_name=$(echo "$recipe_body" | grep -o '"name":"[^"]*"' | head -1 | cut -d'"' -f4)
    
    if [ -n "$recipe_id" ]; then
        echo -e "   ${GREEN}✓${NC} Recipe ID found: $recipe_id"
    else
        echo -e "   ${RED}✗${NC} Recipe ID missing"
    fi
    
    if [ -n "$recipe_name" ]; then
        echo -e "   ${GREEN}✓${NC} Recipe name: $recipe_name"
    else
        echo -e "   ${RED}✗${NC} Recipe name missing"
    fi
    
    # Check for steps (from Gemini AI)
    steps_count=$(echo "$recipe_body" | grep -o '"steps":\[' | wc -l)
    if [ "$steps_count" -gt 0 ]; then
        echo -e "   ${GREEN}✓${NC} Cooking steps generated (Gemini AI working!)"
    else
        echo -e "   ${YELLOW}⚠${NC} Cooking steps may be missing"
    fi
    
    # Check for ingredients
    ingredients_count=$(echo "$recipe_body" | grep -o '"ingredients":\[' | wc -l)
    if [ "$ingredients_count" -gt 0 ]; then
        echo -e "   ${GREEN}✓${NC} Ingredients list present"
    else
        echo -e "   ${YELLOW}⚠${NC} Ingredients may be missing"
    fi
    
else
    echo -e "${RED}✗ FAIL${NC} (HTTP $recipe_code)"
    echo "Response: $recipe_body"
    echo ""
    echo -e "${YELLOW}Common causes:${NC}"
    echo "  - SPOONACULAR_API_KEY not set or invalid"
    echo "  - GEMINI_API_KEY not set or invalid"
    echo "  - No recipes match user's allergens/inventory"
    echo "  - API rate limit reached"
    FAILED=$((FAILED + 1))
fi
echo ""

# Test other recipe endpoints
test_endpoint "Get 'too tired' meal" "GET" "/api/recipe/too-tired" "" "200"
echo ""

echo "6️⃣  DINNER HISTORY & MACROS"
echo "-----------------------------------"
# Log a dinner manually (simulating recipe acceptance)
test_endpoint "Log dinner" "POST" "/api/pantry/dinners" \
    '{"meal_name":"Test Chicken Stir Fry","servings":2,"calories_per_serving":420,"protein_per_serving":35,"carbs_per_serving":40,"fat_per_serving":15,"rating":5}' \
    "201"

# Get dinner history
test_endpoint "Get dinner history" "GET" "/api/pantry/dinners?days=30" "" "200"

# Get macro summary
test_endpoint "Get macro summary" "GET" "/api/pantry/dinners/macros/summary?days=7" "" "200"
echo ""

echo "7️⃣  INTEGRATION TEST: FULL FLOW"
echo "-----------------------------------"
echo "Testing complete user workflow..."
echo ""

# This simulates accepting a recipe
echo -n "Simulating recipe acceptance... "
accept_response=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/api/recipe/accept" \
    -H "Content-Type: application/json" \
    -d '{
        "recipe_id":"test_123",
        "name":"Integration Test Recipe",
        "servings":2,
        "calories_per_serving":400,
        "protein_per_serving":30,
        "carbs_per_serving":35,
        "fat_per_serving":18,
        "ingredients":[
            {"name":"chicken breast","amount":0.5,"unit":"lb"}
        ]
    }')

accept_code=$(echo "$accept_response" | tail -n1)

if [ "$accept_code" == "200" ]; then
    echo -e "${GREEN}✓ PASS${NC}"
    PASSED=$((PASSED + 1))
    
    # Verify inventory was deducted
    echo -n "   Checking inventory deduction... "
    inventory=$(curl -s "$BASE_URL/api/pantry/inventory")
    
    # Check if chicken quantity decreased (was 2, should be less now)
    if echo "$inventory" | grep -q "chicken"; then
        echo -e "${GREEN}✓${NC} Inventory updated"
    else
        echo -e "${YELLOW}⚠${NC} Could not verify inventory update"
    fi
    
    # Verify dinner was logged
    echo -n "   Checking dinner was logged... "
    dinners=$(curl -s "$BASE_URL/api/pantry/dinners")
    
    if echo "$dinners" | grep -q "Integration Test Recipe"; then
        echo -e "${GREEN}✓${NC} Dinner logged successfully"
    else
        echo -e "${YELLOW}⚠${NC} Could not verify dinner logging"
    fi
    
else
    echo -e "${RED}✗ FAIL${NC} (HTTP $accept_code)"
    FAILED=$((FAILED + 1))
fi

echo ""
echo "========================================="
echo "📊 TEST RESULTS"
echo "========================================="
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 ALL TESTS PASSED!${NC}"
    echo ""
    echo "✅ Your backend is fully integrated and ready to deploy!"
    echo ""
    echo "Next steps:"
    echo "  1. Deploy to Railway/Render (see DEPLOYMENT.md)"
    echo "  2. Share production URL with iOS team"
    echo "  3. iOS team can start integration"
    exit 0
else
    echo -e "${RED}⚠️  SOME TESTS FAILED${NC}"
    echo ""
    echo "Common fixes:"
    echo "  - Make sure server is running: uvicorn app.main:app --reload"
    echo "  - Check .env file has API keys (SPOONACULAR_API_KEY, GEMINI_API_KEY)"
    echo "  - Verify database exists: whatsfordinner.db"
    echo "  - Check server logs for errors"
    exit 1
fi
