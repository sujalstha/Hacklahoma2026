from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    DATABASE_URL: str = "sqlite:///./whatsfordinner.db"
    SECRET_KEY: str = "your-secret-key-change-this"
    
    class Config:
        env_file = ".env"

settings = Settings()
