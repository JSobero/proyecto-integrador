from pydantic import BaseModel
from typing import Optional

# --- VALIDACIONES PARA USUARIOS ---
class LoginRequest(BaseModel):
    email: str
    password: str

class UsuarioBase(BaseModel):
    nombres: str
    apellidos: str
    email: str
    dni: str
    rol: str

class UsuarioCreate(UsuarioBase):
    password: str

class UsuarioResponse(UsuarioBase):
    id: int
    
    class Config:
        from_attributes = True

# --- VALIDACIONES PARA AULAS ---
class AulaCreate(BaseModel):
    nombre: str
    descripcion: str = ""

# --- VALIDACIONES PARA PACIENTES / ESTUDIANTES ---
class PacienteCreate(BaseModel):
    nombres: str
    apellidos: str
    nivel_soporte: int = 2

# --- VALIDACIONES PARA INTERESES CLINICOS ---
class InteresCreate(BaseModel):
    palabra_clave: str

class InteresResponse(InteresCreate):
    id: int
    
    class Config:
        from_attributes = True

class UsuarioUpdate(BaseModel):
    nombres: Optional[str] = None
    apellidos: Optional[str] = None
    email: Optional[str] = None
    dni: Optional[str] = None
    password_actual: Optional[str] = None
    nueva_password: Optional[str] = None
        
