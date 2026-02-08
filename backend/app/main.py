from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .routes import pantry, recipe
from dotenv import load_dotenv
# from .routes import dinner  # Your teammate's routes


app = FastAPI(title="What's For Dinner API")

# CORS for iOS app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Change to your iOS app URL in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(pantry.router)
app.include_router(recipe.router)  # Your teammate's routes

@app.get("/")
def root():
    return {"message": "What's For Dinner API"}

@app.get("/health")
def health_check():
    return {"status": "healthy"}
