# Ruta: backend/app/core/database.py
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# Cadena de conexión a PostgreSQL
# Formato: postgresql://usuario:contraseña@servidor:puerto/nombre_bd
# Cambia 'admin' si utilizaste otra contraseña en la instalación
SQLALCHEMY_DATABASE_URL = "postgresql://postgres:root@localhost:5432/saac_db"

engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()