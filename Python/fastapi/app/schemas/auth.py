from typing import Optional

from pydantic import BaseModel


class SocialLoginRequest(BaseModel):
    provider: str
    provider_user_id: str
    email: Optional[str] = None
    name: Optional[str] = None
    profile_image_url: Optional[str] = None
    access_token: Optional[str] = None
    id_token: Optional[str] = None


class SocialLoginResponse(BaseModel):
    user_id: int
    provider: str
    provider_user_id: str
    email: Optional[str] = None
    name: str
    is_new_user: bool
