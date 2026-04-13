from typing import Optional

from pydantic import BaseModel, field_validator


ALLOWED_SOCIAL_PROVIDERS = {"google", "kakao", "naver", "apple"}


class SocialLoginRequest(BaseModel):
    provider: str
    provider_user_id: str
    email: Optional[str] = None
    name: Optional[str] = None
    profile_image_url: Optional[str] = None
    access_token: Optional[str] = None
    id_token: Optional[str] = None

    @field_validator("provider")
    @classmethod
    def validate_provider(cls, value: str) -> str:
        normalized = value.strip().lower()
        if normalized not in ALLOWED_SOCIAL_PROVIDERS:
            raise ValueError("provider must be one of: google, kakao, naver, apple")
        return normalized

    @field_validator("provider_user_id")
    @classmethod
    def validate_provider_user_id(cls, value: str) -> str:
        normalized = value.strip()
        if not normalized:
            raise ValueError("provider_user_id is required")
        if len(normalized) > 100:
            raise ValueError("provider_user_id must be 100 characters or fewer")
        return normalized

    @field_validator("email")
    @classmethod
    def validate_email(cls, value: Optional[str]) -> Optional[str]:
        if value is None:
            return None
        normalized = value.strip()
        if not normalized:
            return None
        if len(normalized) > 255:
            raise ValueError("email must be 255 characters or fewer")
        return normalized

    @field_validator("name")
    @classmethod
    def validate_name(cls, value: Optional[str]) -> Optional[str]:
        if value is None:
            return None
        normalized = value.strip()
        if not normalized:
            return None
        if len(normalized) > 100:
            raise ValueError("name must be 100 characters or fewer")
        return normalized

    @field_validator("profile_image_url", "access_token", "id_token")
    @classmethod
    def validate_optional_fields(cls, value: Optional[str]) -> Optional[str]:
        if value is None:
            return None
        normalized = value.strip()
        return normalized or None


class SocialLoginResponse(BaseModel):
    user_id: int
    provider: str
    provider_user_id: str
    email: Optional[str] = None
    name: str
    is_new_user: bool
