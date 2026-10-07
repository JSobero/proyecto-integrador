from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
import bcrypt
from passlib.context import CryptContext

from app.core.database import get_db
from app.models import user as user_model
from app.schemas import user as user_schema

router = APIRouter(tags=["Usuarios y Autenticación"])
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

@router.post("/usuarios/", response_model=user_schema.UsuarioResponse)
def registrar_usuario(usuario: user_schema.UsuarioCreate, db: Session = Depends(get_db)):
    if db.query(user_model.Usuario).filter(user_model.Usuario.email == usuario.email).first():
        raise HTTPException(status_code=400, detail="El correo ya está registrado")
    if db.query(user_model.Usuario).filter(user_model.Usuario.dni == usuario.dni).first():
        raise HTTPException(status_code=400, detail="El DNI ya está registrado")
    
    salt = bcrypt.gensalt()
    hashed_pwd = bcrypt.hashpw(usuario.password.encode('utf-8'), salt).decode('utf-8')
    
    nuevo_usuario = user_model.Usuario(
        nombres=usuario.nombres, apellidos=usuario.apellidos,
        email=usuario.email, dni=usuario.dni,
        rol=usuario.rol, hashed_password=hashed_pwd
    )
    db.add(nuevo_usuario)
    db.commit()
    db.refresh(nuevo_usuario)
    return nuevo_usuario

@router.post("/login/")
def iniciar_sesion(req: user_schema.LoginRequest, db: Session = Depends(get_db)):
    usuario = db.query(user_model.Usuario).filter(user_model.Usuario.email == req.email).first()
    if not usuario or not bcrypt.checkpw(req.password.encode('utf-8'), usuario.hashed_password.encode('utf-8')):
        raise HTTPException(status_code=401, detail="Correo o contraseña incorrectos")
    return {"id": usuario.id, "nombres": usuario.nombres, "apellidos": usuario.apellidos, "rol": usuario.rol}

@router.delete("/usuarios/{usuario_id}")
def eliminar_usuario(usuario_id: int, db: Session = Depends(get_db)):
    usuario = db.query(user_model.Usuario).filter(user_model.Usuario.id == usuario_id).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    try:
        if hasattr(user_model, 'Configuracion'):
            db.query(user_model.Configuracion).filter(user_model.Configuracion.usuario_id == usuario_id).delete()
        if hasattr(user_model, 'RegistroUso'):
            db.query(user_model.RegistroUso).filter(user_model.RegistroUso.usuario_id == usuario_id).delete()
        if hasattr(user_model, 'Rutina'):
            rutinas = db.query(user_model.Rutina).filter(user_model.Rutina.estudiante_id == usuario_id).all()
            for r in rutinas:
                db.query(user_model.PasoRutina).filter(user_model.PasoRutina.rutina_id == r.id).delete()
                db.delete(r)
        db.delete(usuario)
        db.commit()
        return {"detail": "Usuario y sus registros eliminados con éxito"}
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail="Error interno al limpiar las dependencias")

@router.put("/usuarios/{usuario_id}/reset-password")
def resetear_password(usuario_id: int, db: Session = Depends(get_db)):
    usuario = db.query(user_model.Usuario).filter(user_model.Usuario.id == usuario_id).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    try:
        usuario.hashed_password = pwd_context.hash(usuario.dni)
        db.commit()
        return {"detail": "Contraseña restablecida exitosamente al DNI del usuario."}
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail="Error al restablecer la contraseña")

@router.get("/usuarios/")
def obtener_todos_los_usuarios(db: Session = Depends(get_db)):
    usuarios = db.query(user_model.Usuario).all()
    return [{"id": u.id, "nombres": u.nombres, "apellidos": u.apellidos, "email": u.email, "rol": u.rol} for u in usuarios]