from pydantic import BaseModel

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


        
