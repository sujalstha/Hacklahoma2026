from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    DATABASE_URL: str = "sqlite:///./whatsfordinner.db"
    SECRET_KEY: str = "your-secret-key-change-this"

    # API Keys for recipe system
    SPOONACULAR_API_KEY: str = ""
    ANTHROPIC_API_KEY: str = ""

    class Config:
        env_file = ".env"
        extra = "ignore"  # Ignore extra fields in .env


settings = Settings()