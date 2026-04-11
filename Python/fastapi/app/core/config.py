from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "Nanji Parking API"
    app_env: str = "local"
    app_host: str = "127.0.0.1"
    app_port: int = 8000
    cors_origins: str = "http://127.0.0.1:5173,http://localhost:5173"
    mysql_host: str = "hangang-db.cfsau2mo0bww.ap-northeast-2.rds.amazonaws.com"
    mysql_port: int = 3306
    mysql_user: str = "admin"
    mysql_password: str = "qwer1234"
    mysql_db: str = "hangang_parking"

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

    @property
    def cors_origin_list(self) -> list[str]:
        return [origin.strip() for origin in self.cors_origins.split(",") if origin.strip()]


settings = Settings()
