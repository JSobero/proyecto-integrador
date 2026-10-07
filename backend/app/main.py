from fastapi import FastAPI
from app.core.database import engine
from app.models import user as user_model

# Importar los nuevos enrutadores modulares
from app.routers import usuarios, aulas, estudiantes, motor_ia

# Sincronización de tablas
user_model.Base.metadata.create_all(bind=engine)

app = FastAPI(title="SAAC UTP Backend - Arquitectura Modular")

# Conectar los módulos al orquestador principal
app.include_router(usuarios.router)
app.include_router(aulas.router)
app.include_router(estudiantes.router)
app.include_router(motor_ia.router)