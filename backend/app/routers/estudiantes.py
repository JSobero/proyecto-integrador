from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func
from pydantic import BaseModel
from typing import List, Optional

from app.core.database import get_db
from app.models import user as user_model
from app.schemas import user as user_schema

router = APIRouter(tags=["Clínica y Estudiantes"])

# --- RUTAS DE AULAS DEL ESTUDIANTE ---
@router.get("/estudiantes/{estudiante_id}/aulas/")
def listar_aulas_estudiante(estudiante_id: int, db: Session = Depends(get_db)):
    estudiante = db.query(user_model.Usuario).filter(user_model.Usuario.id == estudiante_id).first()
    if not estudiante: raise HTTPException(status_code=404)
    return [{"id": a.id, "nombre": a.nombre, "descripcion": a.descripcion, "docente": f"{a.docente.nombres} {a.docente.apellidos}"} for a in estudiante.aulas_inscritas]

# --- RUTAS DE INTERESES ---
@router.post("/estudiantes/{estudiante_id}/intereses/", response_model=user_schema.InteresResponse)
def agregar_interes(estudiante_id: int, interes: user_schema.InteresCreate, db: Session = Depends(get_db)):
    estudiante = db.query(user_model.Usuario).filter(user_model.Usuario.id == estudiante_id).first()
    if len(estudiante.intereses) >= 10: raise HTTPException(status_code=400, detail="Límite alcanzado")
    nuevo = user_model.Interes(palabra_clave=interes.palabra_clave.lower().strip(), usuario_id=estudiante_id)
    db.add(nuevo)
    db.commit()
    db.refresh(nuevo)
    return nuevo

@router.get("/estudiantes/{estudiante_id}/intereses/")
def listar_intereses(estudiante_id: int, db: Session = Depends(get_db)):
    return db.query(user_model.Interes).filter(user_model.Interes.usuario_id == estudiante_id).all()

@router.delete("/intereses/{interes_id}")
def eliminar_interes(interes_id: int, db: Session = Depends(get_db)):
    interes = db.query(user_model.Interes).filter(user_model.Interes.id == interes_id).first()
    if interes:
        db.delete(interes)
        db.commit()
    return {"detail": "Interés eliminado"}

# --- CONFIGURACIÓN CLÍNICA ---
class ConfiguracionUpdate(BaseModel):
    densidad_visual: int

@router.get("/estudiantes/{estudiante_id}/configuracion/")
def obtener_configuracion(estudiante_id: int, db: Session = Depends(get_db)):
    config = db.query(user_model.Configuracion).filter(user_model.Configuracion.usuario_id == estudiante_id).first()
    if not config:
        config = user_model.Configuracion(usuario_id=estudiante_id, densidad_visual=8)
        db.add(config)
        db.commit()
    return {"densidad_visual": config.densidad_visual}

@router.put("/estudiantes/{estudiante_id}/configuracion/")
def actualizar_configuracion(estudiante_id: int, req: ConfiguracionUpdate, db: Session = Depends(get_db)):
    config = db.query(user_model.Configuracion).filter(user_model.Configuracion.usuario_id == estudiante_id).first()
    if not config:
        config = user_model.Configuracion(usuario_id=estudiante_id, densidad_visual=req.densidad_visual)
        db.add(config)
    else:
        config.densidad_visual = req.densidad_visual
    db.commit()
    return {"detail": "Actualizado", "densidad_visual": config.densidad_visual}

# --- TRACKING ---
class RegistroUsoCreate(BaseModel):
    palabra: str

@router.post("/estudiantes/{estudiante_id}/tracking/")
def registrar_uso(estudiante_id: int, req: RegistroUsoCreate, db: Session = Depends(get_db)):
    nuevo = user_model.RegistroUso(usuario_id=estudiante_id, palabra=req.palabra.upper().strip())
    db.add(nuevo)
    db.commit()
    return {"detail": "Registrado"}

@router.get("/estudiantes/{estudiante_id}/estadisticas/")
def obtener_estadisticas(estudiante_id: int, db: Session = Depends(get_db)):
    total = db.query(func.count(user_model.RegistroUso.id)).filter(user_model.RegistroUso.usuario_id == estudiante_id).scalar() or 0
    tops = db.query(user_model.RegistroUso.palabra, func.count(user_model.RegistroUso.id)).filter(user_model.RegistroUso.usuario_id == estudiante_id).group_by(user_model.RegistroUso.palabra).order_by(func.count(user_model.RegistroUso.id).desc()).limit(5).all()
    return {"total_interacciones": total, "top_palabras": [{"palabra": r[0], "cantidad": r[1]} for r in tops]}

@router.get("/estudiantes/{estudiante_id}/historial/")
def obtener_historial(estudiante_id: int, db: Session = Depends(get_db)):
    registros = db.query(user_model.RegistroUso).filter(user_model.RegistroUso.usuario_id == estudiante_id).order_by(user_model.RegistroUso.fecha_hora.desc()).limit(20).all()
    return [{"palabra": r.palabra, "fecha_hora": r.fecha_hora.isoformat() if r.fecha_hora else None} for r in registros]

# --- VINCULACIÓN FAMILIAR ---
@router.get("/estudiantes/vincular/{dni}")
def vincular_estudiante_por_dni(dni: str, db: Session = Depends(get_db)):
    estudiante = db.query(user_model.Usuario).filter(user_model.Usuario.dni == dni, user_model.Usuario.rol == 'estudiante').first()
    if not estudiante: raise HTTPException(status_code=404)
    return {"id": estudiante.id, "nombre_completo": f"{estudiante.nombres} {estudiante.apellidos}"}

# --- RUTINAS ---
class PasoCreate(BaseModel):
    orden: int
    palabra: str

class RutinaCreate(BaseModel):
    titulo: str
    pasos: List[PasoCreate]
    aula_id: Optional[int] = None

@router.post("/estudiantes/{estudiante_id}/rutinas/")
def crear_rutina(estudiante_id: int, req: RutinaCreate, db: Session = Depends(get_db)):
    rutina = user_model.Rutina(estudiante_id=estudiante_id, titulo=req.titulo, aula_id=req.aula_id)
    db.add(rutina)
    db.commit()
    db.refresh(rutina)
    for paso in req.pasos:
        db.add(user_model.PasoRutina(rutina_id=rutina.id, orden=paso.orden, palabra=paso.palabra.lower().strip()))
    db.commit()
    return {"detail": "Creada"}

@router.get("/estudiantes/{estudiante_id}/rutinas/")
def listar_rutinas(estudiante_id: int, db: Session = Depends(get_db)):
    rutinas = db.query(user_model.Rutina).filter(user_model.Rutina.estudiante_id == estudiante_id).all()
    res = []
    for r in rutinas:
        pasos = db.query(user_model.PasoRutina).filter(user_model.PasoRutina.rutina_id == r.id).order_by(user_model.PasoRutina.orden).all()
        origen = "Personal"
        if r.aula_id:
            aula = db.query(user_model.Aula).filter(user_model.Aula.id == r.aula_id).first()
            origen = f"Clase: {aula.nombre}" if aula else "Clase archivada"
        res.append({"id": r.id, "titulo": r.titulo, "origen": origen, "pasos": [{"orden": p.orden, "palabra": p.palabra} for p in pasos]})
    return res

@router.delete("/rutinas/{rutina_id}")
def eliminar_rutina(rutina_id: int, db: Session = Depends(get_db)):
    rutina = db.query(user_model.Rutina).filter(user_model.Rutina.id == rutina_id).first()
    if rutina:
        db.delete(rutina)
        db.commit()
        return {"detail": "Eliminada"}
    raise HTTPException(status_code=404)