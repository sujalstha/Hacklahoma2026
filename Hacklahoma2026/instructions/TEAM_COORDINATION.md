# Team Coordination Guide - What's For Dinner 🍽️

Everything your team needs to coordinate backend ↔ frontend integration.

## 👥 Team Roles

### Backend Team (You + Teammate)
- ✅ **Pantry System** (You) - COMPLETE
- ✅ **Recipe Engine** (Teammate/You) - COMPLETE
- ⏳ **Deployment** - TODO

### iOS/UI Team
- ⏳ **SwiftUI Views** - In Progress
- ⏳ **API Integration** - Ready to start
- ⏳ **Barcode Scanner** - Ready to implement

---

## 📚 Documentation Quick Links

| Document | Purpose | Who Needs It |
|----------|---------|--------------|
| **API_REFERENCE.md** | All API endpoints & examples | iOS team, testing |
| **IOS_INTEGRATION.md** | Swift code, models, API service | iOS team |
| **DEPLOYMENT.md** | Get backend online | Backend team |
| **INTEGRATION_GUIDE.md** | How everything connects | Everyone |
| **SETUP_GUIDE.md** | Backend setup instructions | Backend team |

---

## 🎯 Current Status

### ✅ DONE - Backend
- Pantry inventory system (barcode scan, CRUD)
- User preferences (allergens, macros)
- Dinner history tracking
- Macro calculations
- Recipe engine (Spoonacular + Gemini AI)
- Recipe acceptance (logs dinner, deducts ingredients)
- All API endpoints working

### ⏳ TODO - Integration
1. **Backend deployment** (30 min)
   - Deploy to Railway/Render
   - Get production URL
   - Share with iOS team

2. **iOS API integration** (2-3 hours)
   - Copy Swift models
   - Implement APIService
   - Connect views to backend

3. **Testing together** (1 hour)
   - Test full user flows
   - Fix any bugs
   - Polish UI/UX

---

## 🚀 Next Steps (Priority Order)

### Step 1: Deploy Backend (Backend Team)
**Time:** 30 minutes  
**Goal:** Get backend online

```bash
# Push to GitHub
git add .
git commit -m "Backend ready for production"
git push

# Deploy to Railway (easiest)
# Follow DEPLOYMENT.md
```

**Output:** Production URL like `https://whatsfordinner.railway.app`

---

### Step 2: Share API with iOS Team
**Time:** 5 minutes  
**Goal:** iOS team can test API

Share with iOS team:
1. ✅ Production URL
2. ✅ API_REFERENCE.md (all endpoints)
3. ✅ IOS_INTEGRATION.md (Swift code)

iOS team can immediately test in Postman/curl while building UI.

---

### Step 3: iOS Team Implements API Layer
**Time:** 1-2 hours  
**Goal:** iOS app can talk to backend

Copy from IOS_INTEGRATION.md:
1. Models (PantryModels.swift, RecipeModels.swift)
2. APIService.swift (all API calls)
3. Update baseURL to production URL

Test each endpoint as you implement:
```swift
Task {
    let recipe = try await APIService.shared.getDailyRecipe()
    print(recipe)
}
```

---

### Step 4: Build Views
**Time:** 2-3 hours  
**Goal:** Complete UI connected to backend

Views to build (priority order):
1. **OnboardingView** - Set preferences
2. **HomeView** - Show daily recipe
3. **RecipeDetailView** - Cooking steps
4. **InventoryView** - View pantry + scan barcodes
5. **HistoryView** - Past dinners + macros

Use examples in IOS_INTEGRATION.md as templates.

---

### Step 5: Test End-to-End
**Time:** 1 hour  
**Goal:** Everything works together

Test these user flows:
1. ✅ New user onboarding (set allergens/goals)
2. ✅ Scan barcode → add to inventory
3. ✅ Get daily recipe suggestion
4. ✅ Accept recipe → ingredients deducted
5. ✅ View dinner history
6. ✅ Check macro progress

---

## 🧪 Testing Strategy

### Backend Testing (Backend Team)
Use the API docs: `http://127.0.0.1:8000/docs` or `/docs` on production

**Test sequence:**
```bash
# 1. Create preferences
POST /api/pantry/preferences

# 2. Add pantry items
POST /api/pantry/items (x3)

# 3. Add to inventory
POST /api/pantry/inventory (x3)

# 4. Get recipe
GET /api/recipe/daily-suggestion

# 5. Accept recipe
POST /api/recipe/accept

# 6. Check results
GET /api/pantry/inventory (should see reduced quantities)
GET /api/pantry/dinners (should see logged dinner)
```

### iOS Testing (iOS Team)
1. **API Service tests** - Can you fetch data?
2. **View tests** - Do views display correctly?
3. **Flow tests** - Can user complete actions?

### Integration Testing (Everyone)
1. Backend team watches logs
2. iOS team runs through flows
3. Fix any issues together

---

## 📱 Key Integration Points

### 1. User Onboarding
**iOS → Backend:**
```
POST /api/pantry/preferences
{
  "dietary_restrictions": ["gluten_free"],
  "target_calories": 2000,
  "household_size": 2
}
```

### 2. Barcode Scanning
**iOS → Backend:**
```
// 1. Scan with camera
let barcode = "041190468843"

// 2. Check if exists
POST /api/pantry/scan {"barcode": barcode}

// 3a. If found: Add to inventory
POST /api/pantry/inventory {"item_id": 1, "quantity": 1, "unit": "gallon"}

// 3b. If not found: Manual entry
POST /api/pantry/items {"name": "Milk", ...}
then POST /api/pantry/inventory
```

### 3. Daily Recipe
**Backend → iOS:**
```
// Backend has this running at 5 PM (or iOS fetches on demand)
GET /api/recipe/daily-suggestion

Returns:
- Recipe name
- 5 simplified steps (from Gemini)
- Ingredients
- Macros
- Image
```

**iOS displays in HomeView**

### 4. Accept Recipe
**iOS → Backend:**
```
POST /api/recipe/accept
{
  "recipe_id": "123",
  "name": "Chicken Stir Fry",
  // ... recipe data
}
```

**Backend does:**
1. Logs dinner in history
2. Deducts ingredients from inventory

### 5. View Progress
**iOS → Backend:**
```
GET /api/pantry/dinners/macros/summary?days=7
```

**iOS displays:**
- Chart showing calories/protein/carbs/fat
- Progress vs goals
- Trend over time

---

## 💬 Communication Checklist

### Backend → iOS Team
- [ ] Production API URL shared
- [ ] API documentation shared (API_REFERENCE.md)
- [ ] Swift integration code shared (IOS_INTEGRATION.md)
- [ ] Test credentials shared (if needed)
- [ ] Backend health check working

### iOS → Backend Team
- [ ] Questions about data models?
- [ ] Need additional endpoints?
- [ ] Found any bugs?
- [ ] Performance issues?

---

## 🐛 Common Issues & Solutions

### Issue: iOS can't connect to API
**Check:**
1. Is backend deployed and running?
2. Is CORS enabled in main.py?
3. Is iOS using correct URL (not localhost)?
4. Are environment variables set?

**Fix:**
```python
# main.py - make sure this exists
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

### Issue: Recipe steps are weird/incomplete
**Cause:** Gemini AI issue or API key problem

**Fix:**
1. Check `GEMINI_API_KEY` in environment variables
2. Check Gemini API quota
3. Fallback: Use Spoonacular's original instructions

### Issue: Barcode scan not working
**Possibilities:**
1. Camera permissions not granted (iOS)
2. Barcode not in OpenFood Facts database
3. Network timeout

**Fix:**
- Add fallback for manual entry
- Increase timeout in APIService

### Issue: Inventory not updating after recipe acceptance
**Check:**
1. Backend logs - are ingredients being deducted?
2. Name matching - do inventory items match recipe ingredients?
3. Network error during acceptance?

**Debug:**
```swift
// Log the response
do {
    try await APIService.shared.acceptRecipe(recipe)
    print("✅ Recipe accepted")
} catch {
    print("❌ Error: \(error)")
}
```

---

## 📊 Demo Day Preparation

### Day Before:
- [ ] Backend deployed and stable
- [ ] iOS app builds and runs
- [ ] Test data in database (sample pantry items)
- [ ] All core features working

### Demo Day:
- [ ] Backend uptime 100%
- [ ] Quick demo script prepared
- [ ] Backup plans if API fails (cached data)
- [ ] Screenshots/video backup

### Demo Flow (2 minutes):
1. **Show problem** (decision fatigue)
2. **Onboarding** - Quick setup
3. **Scan item** - Barcode → inventory
4. **Get recipe** - AI-simplified steps
5. **Accept** - Log dinner, track macros
6. **Show progress** - Charts over time

---

## 🎓 Resources

### For iOS Team:
- **API Docs:** `https://your-url.railway.app/docs`
- **SwiftUI:** https://developer.apple.com/tutorials/swiftui
- **URLSession:** https://developer.apple.com/documentation/foundation/urlsession

### For Backend Team:
- **FastAPI:** https://fastapi.tiangolo.com
- **Railway:** https://docs.railway.app
- **Spoonacular API:** https://spoonacular.com/food-api/docs

---

## 🏆 Success Metrics

By end of hackathon, your app should:
- [ ] Complete user flow works end-to-end
- [ ] Recipe suggestions work with real data
- [ ] Barcode scanning adds to inventory
- [ ] Macro tracking shows real charts
- [ ] 5 PM notification (bonus)
- [ ] Polished UI that looks professional

**You've got all the pieces. Now put them together!** 🚀

---

## 📞 Quick Contact Protocol

During integration:

**Backend issue?** → Check server logs first  
**iOS issue?** → Check Xcode console first  
**Integration issue?** → Check API docs, test endpoint in Postman  

**Can't solve in 15 min?** → Get both teams together to debug

**Time zones matter!** Sync up times for integration work.

---

## 🎉 You're Ready!

**Backend:** ✅ All systems go  
**iOS:** 📚 Full documentation + code examples ready  
**Integration:** 🔗 Clear connection points defined  

**Next:** Deploy backend, then iOS team connects → Test together → Polish → Demo! 

Good luck at Hacklahoma! 🏆
