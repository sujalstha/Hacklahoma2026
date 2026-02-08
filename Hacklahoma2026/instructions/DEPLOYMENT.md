# Deploy Backend to Production

Get your backend online so iOS app can access it from real devices (not just localhost).

## 🚀 Quick Deploy Options

### Option 1: Railway (Recommended - Easiest)
**Free tier:** 500 hours/month  
**Setup time:** 5 minutes

1. Go to https://railway.app
2. Sign up with GitHub
3. Click "New Project" → "Deploy from GitHub repo"
4. Select your backend repo
5. Railway auto-detects FastAPI!
6. Add environment variables:
   - `SPOONACULAR_API_KEY`
   - `GEMINI_API_KEY`
   - `DATABASE_URL` (Railway provides free PostgreSQL)
7. Deploy! You'll get URL like: `https://your-app.railway.app`

**Update iOS app:**
```swift
let baseURL = "https://your-app.railway.app"
```

---

### Option 2: Render (Also Easy)
**Free tier:** 750 hours/month  
**Setup time:** 10 minutes

1. Go to https://render.com
2. Sign up
3. New → Web Service
4. Connect GitHub repo
5. Settings:
   - **Build Command:** `pip install -r requirements.txt`
   - **Start Command:** `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
6. Add environment variables in dashboard
7. Deploy!

---

### Option 3: Fly.io (Good for demos)
**Free tier:** 3GB storage  
**Setup time:** 15 minutes

```bash
# Install flyctl
curl -L https://fly.io/install.sh | sh

# Login
flyctl auth login

# Initialize (in your backend folder)
flyctl launch

# Deploy
flyctl deploy
```

Create `fly.toml`:
```toml
app = "whatsfordinner"

[build]
  builder = "paketobuildpacks/builder:base"

[env]
  PORT = "8000"

[[services]]
  internal_port = 8000
  protocol = "tcp"

  [[services.ports]]
    port = 80
    handlers = ["http"]

  [[services.ports]]
    port = 443
    handlers = ["tls", "http"]
```

---

## 📝 Pre-Deployment Checklist

Before deploying, update these files:

### 1. Add `Procfile` (for Railway/Render)
Create `backend/Procfile`:
```
web: uvicorn app.main:app --host 0.0.0.0 --port $PORT
```

### 2. Update `requirements.txt`
Make sure it has everything:
```txt
fastapi==0.115.0
sqlalchemy==2.0.36
pydantic==2.10.3
pydantic-settings==2.7.0
httpx==0.28.1
python-multipart==0.0.18
uvicorn==0.34.0
google-generativeai==0.8.3
psycopg2-binary==2.9.9  # For PostgreSQL in production
```

### 3. Update CORS in `main.py`
```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Or specific iOS app domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

### 4. Environment Variables to Set
On your deployment platform, add:
```
DATABASE_URL=<provided by platform or use PostgreSQL>
SECRET_KEY=<generate a random secret>
SPOONACULAR_API_KEY=<your key>
GEMINI_API_KEY=<your key>
```

Generate secret key:
```python
import secrets
print(secrets.token_urlsafe(32))
```

---

## 🗄️ Database Options

### SQLite (Development Only)
✅ Good for: Local testing  
❌ Bad for: Production (doesn't work on most platforms)

### PostgreSQL (Production)
Most platforms provide free PostgreSQL:
- **Railway:** Automatic free PostgreSQL
- **Render:** $0/month PostgreSQL
- **Supabase:** Free PostgreSQL (external)

**Update config.py to use environment variable:**
```python
DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite:///./whatsfordinner.db")
```

Railway/Render will automatically provide `DATABASE_URL`.

---

## 🧪 Test Deployment

After deploying:

1. **Test health endpoint:**
```bash
curl https://your-app.railway.app/health
```

2. **Test API docs:**
Visit: `https://your-app.railway.app/docs`

3. **Create test preferences:**
```bash
curl -X POST https://your-app.railway.app/api/pantry/preferences \
  -H "Content-Type: application/json" \
  -d '{"dietary_restrictions": ["gluten_free"], "target_calories": 2000, "household_size": 2, "preferred_cuisines": []}'
```

4. **Get recipe:**
```bash
curl https://your-app.railway.app/api/recipe/daily-suggestion
```

---

## 📱 Update iOS App

Once deployed, update your iOS app:

### Before (localhost):
```swift
let baseURL = "http://127.0.0.1:8000"
```

### After (production):
```swift
let baseURL = "https://your-app.railway.app"
```

---

## 🐛 Common Deployment Issues

### Issue: "Module not found"
**Fix:** Make sure `requirements.txt` has all dependencies
```bash
pip freeze > requirements.txt
```

### Issue: Database connection failed
**Fix:** Check `DATABASE_URL` environment variable is set

### Issue: API calls timeout
**Fix:** Check CORS is allowing your iOS app domain

### Issue: 500 Internal Server Error
**Fix:** Check platform logs:
- Railway: Dashboard → Deployments → Logs
- Render: Dashboard → Logs tab

---

## 💰 Cost Comparison

| Platform | Free Tier | Good For |
|----------|-----------|----------|
| **Railway** | 500 hrs/month | Hackathons, demos |
| **Render** | 750 hrs/month | Small projects |
| **Fly.io** | 3 shared CPUs | Production |
| **Heroku** | Deprecated | ❌ Don't use |

**Recommendation for hackathon:** Railway (easiest & fastest)

---

## ⚡ Quick Railway Deploy (Step by Step)

1. Push your code to GitHub:
```bash
git add .
git commit -m "Ready for deployment"
git push origin main
```

2. Go to https://railway.app → Login with GitHub

3. New Project → Deploy from GitHub repo

4. Select `Hacklahoma2026` repo

5. Railway detects Python → Auto-configures!

6. Add environment variables:
   - Click project → Variables tab
   - Add `SPOONACULAR_API_KEY`
   - Add `GEMINI_API_KEY`
   - Railway auto-provides `DATABASE_URL` for PostgreSQL

7. Click Deploy → Wait 2-3 minutes

8. Get your URL from Settings → Domains
   - Will be like: `whatsfordinner-production-abc123.up.railway.app`

9. Update iOS app baseURL

10. Test: `https://your-url.railway.app/docs`

**You're live!** 🎉

---

## 🔒 Security Notes

For hackathon, basic setup is fine. For production:

1. **Add authentication:**
   - JWT tokens
   - OAuth with Google/Apple

2. **Rate limiting:**
```python
from slowapi import Limiter
limiter = Limiter(key_func=get_remote_address)

@app.get("/api/recipe/daily-suggestion")
@limiter.limit("10/minute")
async def get_recipe():
    ...
```

3. **HTTPS only:**
Most platforms provide free SSL.

4. **Environment variables:**
Never commit `.env` to git!

Add to `.gitignore`:
```
.env
*.db
__pycache__/
```

---

## 📊 Monitor Your App

### Railway Dashboard:
- Metrics tab → CPU/Memory usage
- Deployments → Logs
- Set up alerts for errors

### Quick health check endpoint:
```python
@app.get("/health")
async def health():
    return {
        "status": "healthy",
        "database": "connected",  # Check DB connection
        "apis": {
            "spoonacular": bool(settings.SPOONACULAR_API_KEY),
            "gemini": bool(settings.GEMINI_API_KEY)
        }
    }
```

---

## 🎯 Hackathon Day Checklist

Morning of hackathon:
- [ ] Backend deployed and accessible
- [ ] All API endpoints tested
- [ ] iOS team has production URL
- [ ] Environment variables set
- [ ] Database has test data
- [ ] API docs working (`/docs` endpoint)

You're ready to build! 🚀
