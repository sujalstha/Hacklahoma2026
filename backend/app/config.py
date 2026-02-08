from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    DATABASE_URL: str = "sqlite:///./whatsfordinner.db"
    SECRET_KEY: str = "groupb"

    # API Keys for recipe system
    SPOONACULAR_API_KEY: str = "19f3af0561424a42884bb060ec999982"
    GEMINI_API_KEY= "AIzaSyCRo1vALKJrsSsTYGSQW-nS9kmK5RehXek"

    class Config:
        env_file = ".env"
        extra = "ignore"  # Ignore extra fields in .env


settings = Settings()