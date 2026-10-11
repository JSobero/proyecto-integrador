from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware # IMPORTACIÓN NUEVA
from app.core.database import engine
from app.models import user as user_model

# Importar los nuevos enrutadores modulares
from app.routers import usuarios, aulas, estudiantes, motor_ia

# Sincronización de tablas
user_model.Base.metadata.create_all(bind=engine)

app = FastAPI(title="SAAC UTP Backend - Arquitectura Modular")

# --- CONFIGURACIÓN DE SEGURIDAD CORS ---
# Esto permite que tu app de Flutter (y solo tu app) se comunique con FastAPI
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # En un entorno real se pone la IP de Flutter, "*" permite todo por ahora
    allow_credentials=True,
    allow_methods=["*"],  # Permite GET, POST, PUT, DELETE
    allow_headers=["*"],
)
# ----------------------------------------

# Conectar los módulos al orquestador principal
app.include_router(usuarios.router)
app.include_router(aulas.router)
app.include_router(estudiantes.router)
app.include_router(motor_ia.router)