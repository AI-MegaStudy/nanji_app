from sqlalchemy import create_engine
from sqlalchemy.engine import URL
from sqlalchemy.orm import sessionmaker

from app.core.config import settings


DATABASE_URL = URL.create(
    drivername="mysql+pymysql",
    username=settings.mysql_user,
    password=settings.mysql_password,
    host=settings.mysql_host,
    port=settings.mysql_port,
    database=settings.mysql_db,
)

engine = create_engine(DATABASE_URL, pool_pre_ping=True, pool_recycle=3600)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
