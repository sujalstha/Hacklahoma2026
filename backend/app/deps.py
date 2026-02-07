from sqlalchemy.orm import Session
from .db import get_db

# Placeholder for auth - implement proper JWT auth for production
def get_current_user():
    # For now, return a mock user
    # TODO: Implement proper JWT token validation
    return {"id": 1, "email": "test@example.com"}

# Export get_db for routes to use
__all__ = ["get_db", "get_current_user"]
