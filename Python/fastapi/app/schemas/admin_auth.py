from pydantic import BaseModel, ConfigDict, field_validator


class AdminLoginRequest(BaseModel):
    admin_id: str
    password: str

    @field_validator("admin_id", mode="before")
    @classmethod
    def validate_admin_id(cls, value: str) -> str:
        normalized = (value or "").strip()
        if not normalized:
            raise ValueError("관리자 ID를 입력해 주세요.")
        if len(normalized) > 255:
            raise ValueError("관리자 ID가 너무 깁니다.")
        return normalized

    @field_validator("password", mode="before")
    @classmethod
    def validate_password(cls, value: str) -> str:
        normalized = (value or "").strip()
        if not normalized:
            raise ValueError("비밀번호를 입력해 주세요.")
        if len(normalized) > 255:
            raise ValueError("비밀번호가 너무 깁니다.")
        return normalized


class AdminLoginResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    admin_id: int
    admin_login_id: str
    admin_name: str
    admin_role: str
