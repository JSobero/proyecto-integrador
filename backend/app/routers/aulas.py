from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
import random
import string

from app.core.database import get_db
from app.models import user as user_model
from app.schemas import user as user_schema

router = APIRouter(tags=["Gestión de Aulas"])

def generar_codigo_aula(db: Session):
    while True:
        codigo = ''.join(random.choices(string.ascii_uppercase + string.digits, k=6))
        if not db.query(user_model.Aula).filter(user_model.Aula.codigo_acceso == codigo).first():
            return codigo

@router.post("/aulas/")
def crear_aula(aula: user_schema.AulaCreate, docente_id: int, db: Session = Depends(get_db)):
    nueva_aula = user_model.Aula(nombre=aula.nombre, descripcion=aula.descripcion, codigo_acceso=generar_codigo_aula(db), docente_id=docente_id)
    db.add(nueva_aula)
    db.commit()
    db.refresh(nueva_aula)
    return nueva_aula

@router.get("/docente/{docente_id}/aulas/")
def listar_aulas_docente(docente_id: int, db: Session = Depends(get_db)):
    aulas = db.query(user_model.Aula).filter(user_model.Aula.docente_id == docente_id).all()
    return [{
        "id": a.id, "nombre": a.nombre, "descripcion": a.descripcion, "codigo_acceso": a.codigo_acceso,
        "alumnos": [{"id": e.id, "nombre": f"{e.nombres} {e.apellidos}"} for e in a.estudiantes]
    } for a in aulas]

class UnirseAulaRequest(BaseModel):
    estudiante_id: int
    codigo: str

@router.post("/aulas/unirse/")
def unirse_a_clase(req: UnirseAulaRequest, db: Session = Depends(get_db)):
    aula = db.query(user_model.Aula).filter(user_model.Aula.codigo_acceso == req.codigo.upper()).first()
    if not aula:
        raise HTTPException(status_code=404, detail="Código incorrecto o aula no encontrada")
    estudiante = db.query(user_model.Usuario).filter(user_model.Usuario.id == req.estudiante_id, user_model.Usuario.rol == 'estudiante').first()
    if not estudiante:
        raise HTTPException(status_code=404, detail="Estudiante no encontrado")
    if estudiante in aula.estudiantes:
        raise HTTPException(status_code=400, detail="Ya estás inscrito")
    try:
        aula.estudiantes.append(estudiante)
        db.commit()
        return {"detail": "¡Te uniste a la clase con éxito!"}
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail="Error al unirse a la clase")

@router.delete("/aulas/{aula_id}/estudiantes/{estudiante_id}")
def remover_estudiante_aula(aula_id: int, estudiante_id: int, db: Session = Depends(get_db)):
    aula = db.query(user_model.Aula).filter(user_model.Aula.id == aula_id).first()
    estudiante = db.query(user_model.Usuario).filter(user_model.Usuario.id == estudiante_id).first()
    
    if aula and estudiante in aula.estudiantes:
        aula.estudiantes.remove(estudiante)
        rutinas_clase = db.query(user_model.Rutina).filter(user_model.Rutina.estudiante_id == estudiante_id, user_model.Rutina.aula_id == aula_id).all()
        for r in rutinas_clase:
            db.query(user_model.PasoRutina).filter(user_model.PasoRutina.rutina_id == r.id).delete()
            db.delete(r)
        db.commit()
        return {"detail": "Estudiante removido"}
    raise HTTPException(status_code=400, detail="No se pudo remover al estudiante")

@router.delete("/aulas/{aula_id}")
def eliminar_aula(aula_id: int, db: Session = Depends(get_db)):
    aula = db.query(user_model.Aula).filter(user_model.Aula.id == aula_id).first()
    if not aula:
        raise HTTPException(status_code=404, detail="Aula no encontrada")
    rutinas_clase = db.query(user_model.Rutina).filter(user_model.Rutina.aula_id == aula_id).all()
    for r in rutinas_clase:
        db.query(user_model.PasoRutina).filter(user_model.PasoRutina.rutina_id == r.id).delete()
        db.delete(r)
    db.delete(aula)
    db.commit()
    return {"detail": "Aula eliminada"}