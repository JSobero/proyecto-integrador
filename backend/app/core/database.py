# Ruta: backend/app/core/database.py
import os
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# Carga variables locales de .env si existe (útil en entorno local)
load_dotenv()

# Lee la variable DATABASE_URL del entorno (inyectada por Render en producción)
SQLALCHEMY_DATABASE_URL = os.getenv("DATABASE_URL")

if not SQLALCHEMY_DATABASE_URL:
    raise ValueError("¡ALERTA!: La variable DATABASE_URL no está configurada en el entorno.")

# PARCHE PARA RENDER: Convierte 'postgres://' a 'postgresql://' exigido por SQLAlchemy
if SQLALCHEMY_DATABASE_URL.startswith("postgres://"):
    SQLALCHEMY_DATABASE_URL = SQLALCHEMY_DATABASE_URL.replace("postgres://", "postgresql://", 1)

engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()