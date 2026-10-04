from fastapi import FastAPI, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
import bcrypt
import random
import string
import httpx
from pydantic import BaseModel
from sqlalchemy import func
from pydantic import BaseModel
from passlib.context import CryptContext

# Importaciones de la arquitectura de la tesis
from app.core.database import engine, get_db
from app.models import user as user_model
from app.schemas import user as user_schema

# Caché en memoria para mitigar la latencia de 4 segundos del Motor JIT
cache_pictogramas = {}

# Sincronización de tablas
user_model.Base.metadata.create_all(bind=engine)

app = FastAPI(title="SAAC UTP Backend")

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# =====================================================================
# 1. GESTIÓN DE USUARIOS (Registro y Autenticación)
# =====================================================================

@app.post("/usuarios/", response_model=user_schema.UsuarioResponse)
def registrar_usuario(usuario: user_schema.UsuarioCreate, db: Session = Depends(get_db)):
    if db.query(user_model.Usuario).filter(user_model.Usuario.email == usuario.email).first():
        raise HTTPException(status_code=400, detail="El correo ya está registrado")
    if db.query(user_model.Usuario).filter(user_model.Usuario.dni == usuario.dni).first():
        raise HTTPException(status_code=400, detail="El DNI ya está registrado")
    
    salt = bcrypt.gensalt()
    hashed_pwd = bcrypt.hashpw(usuario.password.encode('utf-8'), salt).decode('utf-8')
    
    nuevo_usuario = user_model.Usuario(
        nombres=usuario.nombres,
        apellidos=usuario.apellidos,
        email=usuario.email,
        dni=usuario.dni,
        rol=usuario.rol,
        hashed_password=hashed_pwd
    )
    db.add(nuevo_usuario)
    db.commit()
    db.refresh(nuevo_usuario)
    return nuevo_usuario


@app.post("/login/")
def iniciar_sesion(req: user_schema.LoginRequest, db: Session = Depends(get_db)):
    usuario = db.query(user_model.Usuario).filter(user_model.Usuario.email == req.email).first()
    
    if not usuario or not bcrypt.checkpw(req.password.encode('utf-8'), usuario.hashed_password.encode('utf-8')):
        raise HTTPException(status_code=401, detail="Correo o contraseña incorrectos")
    
    return {
        "id": usuario.id,
        "nombres": usuario.nombres,
        "apellidos": usuario.apellidos,
        "rol": usuario.rol
    }

@app.delete("/usuarios/{usuario_id}")
def eliminar_usuario(usuario_id: int, db: Session = Depends(get_db)):
    usuario = db.query(user_model.Usuario).filter(user_model.Usuario.id == usuario_id).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    
    try:
        # 1. Limpiar dependencias asociadas para evitar el error ForeignKeyViolation
        if hasattr(user_model, 'Configuracion'):
            db.query(user_model.Configuracion).filter(user_model.Configuracion.usuario_id == usuario_id).delete()
        
        if hasattr(user_model, 'RegistroUso'):
            db.query(user_model.RegistroUso).filter(user_model.RegistroUso.usuario_id == usuario_id).delete()
            
        if hasattr(user_model, 'Rutina'):
            rutinas = db.query(user_model.Rutina).filter(user_model.Rutina.estudiante_id == usuario_id).all()
            for r in rutinas:
                db.query(user_model.PasoRutina).filter(user_model.PasoRutina.rutina_id == r.id).delete()
                db.delete(r)

        # 2. Eliminar al usuario
        db.delete(usuario)
        db.commit()
        return {"detail": "Usuario y sus registros eliminados con éxito"}
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail="Error interno al limpiar las dependencias del usuario")

@app.put("/usuarios/{usuario_id}/reset-password")
def resetear_password(usuario_id: int, db: Session = Depends(get_db)):
    usuario = db.query(user_model.Usuario).filter(user_model.Usuario.id == usuario_id).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
        
    try:
        # Extrae el DNI de la base de datos y lo convierte en la nueva contraseña
        nuevo_password = usuario.dni 
        usuario.hashed_password = pwd_context.hash(nuevo_password)
        db.commit()
        return {"detail": "Contraseña restablecida exitosamente al DNI del usuario."}
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail="Error al restablecer la contraseña")

# =====================================================================
# ENDPOINT PARA EL PANEL DE ADMINISTRADOR (Listar Usuarios)
# =====================================================================
@app.get("/usuarios/")
def obtener_todos_los_usuarios(db: Session = Depends(get_db)):
    usuarios = db.query(user_model.Usuario).all()
    resultado = []
    
    for u in usuarios:
        resultado.append({
            "id": u.id,
            "nombres": u.nombres,
            "apellidos": u.apellidos,
            "email": u.email,
            "rol": u.rol
        })
        
    return resultado

# =====================================================================
# 2. GESTIÓN DE AULAS (Flujo Docente y Estudiante)
# =====================================================================

def generar_codigo_aula(db: Session):
    while True:
        codigo = ''.join(random.choices(string.ascii_uppercase + string.digits, k=6))
        if not db.query(user_model.Aula).filter(user_model.Aula.codigo_acceso == codigo).first():
            return codigo

@app.post("/aulas/")
def crear_aula(aula: user_schema.AulaCreate, docente_id: int, db: Session = Depends(get_db)):
    nueva_aula = user_model.Aula(
        nombre=aula.nombre,
        descripcion=aula.descripcion,
        codigo_acceso=generar_codigo_aula(db),
        docente_id=docente_id
    )
    db.add(nueva_aula)
    db.commit()
    db.refresh(nueva_aula)
    return nueva_aula


@app.get("/docente/{docente_id}/aulas/")
def listar_aulas_docente(docente_id: int, db: Session = Depends(get_db)):
    aulas = db.query(user_model.Aula).filter(user_model.Aula.docente_id == docente_id).all()
    resultado = []
    for aula in aulas:
        resultado.append({
            "id": aula.id,
            "nombre": aula.nombre,
            "descripcion": aula.descripcion,
            "codigo_acceso": aula.codigo_acceso,
            "alumnos": [{"id": e.id, "nombre": f"{e.nombres} {e.apellidos}"} for e in aula.estudiantes]
        })
    return resultado

# --- NUEVO ENDPOINT CORREGIDO PARA UNIRSE ---
class UnirseAulaRequest(BaseModel):
    estudiante_id: int
    codigo: str

@app.post("/aulas/unirse/")
def unirse_a_clase(req: UnirseAulaRequest, db: Session = Depends(get_db)):
    # 1. Buscar el aula por el código
    aula = db.query(user_model.Aula).filter(user_model.Aula.codigo_acceso == req.codigo.upper()).first()
    
    if not aula:
        raise HTTPException(status_code=404, detail="Código incorrecto o aula no encontrada")
        
    # 2. Buscar al estudiante
    estudiante = db.query(user_model.Usuario).filter(user_model.Usuario.id == req.estudiante_id, user_model.Usuario.rol == 'estudiante').first()
    
    if not estudiante:
        raise HTTPException(status_code=404, detail="Estudiante no encontrado")
        
    # 3. Validar si ya está inscrito
    if estudiante in aula.estudiantes:
        raise HTTPException(status_code=400, detail="Ya estás inscrito en esta clase")
        
    try:
        # 4. Inscribir
        aula.estudiantes.append(estudiante)
        db.commit()
        return {"detail": "¡Te uniste a la clase con éxito!"}
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail="Error interno al unirse a la clase")


@app.get("/estudiantes/{estudiante_id}/aulas/")
def listar_aulas_estudiante(estudiante_id: int, db: Session = Depends(get_db)):
    estudiante = db.query(user_model.Usuario).filter(user_model.Usuario.id == estudiante_id).first()
    if not estudiante:
        raise HTTPException(status_code=404, detail="Estudiante no encontrado")
    
    resultado = []
    for aula in estudiante.aulas_inscritas:
        resultado.append({
            "id": aula.id,
            "nombre": aula.nombre,
            "descripcion": aula.descripcion,
            "docente": f"{aula.docente.nombres} {aula.docente.apellidos}"
        })
    return resultado

@app.delete("/aulas/{aula_id}/estudiantes/{estudiante_id}")
def remover_estudiante_aula(aula_id: int, estudiante_id: int, db: Session = Depends(get_db)):
    aula = db.query(user_model.Aula).filter(user_model.Aula.id == aula_id).first()
    if not aula:
        raise HTTPException(status_code=404, detail="Aula no encontrada")
    
    estudiante = db.query(user_model.Usuario).filter(user_model.Usuario.id == estudiante_id).first()
    if estudiante in aula.estudiantes:
        aula.estudiantes.remove(estudiante)
        
        # SOLO borra las rutinas que este profesor creó en ESTA aula específica
        rutinas_clase = db.query(user_model.Rutina).filter(
            user_model.Rutina.estudiante_id == estudiante_id, 
            user_model.Rutina.aula_id == aula_id
        ).all()
        for r in rutinas_clase:
            db.query(user_model.PasoRutina).filter(user_model.PasoRutina.rutina_id == r.id).delete()
            db.delete(r)

        db.commit()
        return {"detail": "Estudiante removido y sus rutinas de esta clase fueron limpiadas"}
        
    raise HTTPException(status_code=400, detail="El estudiante no pertenece a esta clase")

@app.delete("/aulas/{aula_id}")
def eliminar_aula(aula_id: int, db: Session = Depends(get_db)):
    aula = db.query(user_model.Aula).filter(user_model.Aula.id == aula_id).first()
    if not aula:
        raise HTTPException(status_code=404, detail="Aula no encontrada")
    
    # SOLO borra las rutinas vinculadas a este ID de aula
    rutinas_clase = db.query(user_model.Rutina).filter(user_model.Rutina.aula_id == aula_id).all()
    for r in rutinas_clase:
        db.query(user_model.PasoRutina).filter(user_model.PasoRutina.rutina_id == r.id).delete()
        db.delete(r)
            
    db.delete(aula)
    db.commit()
    return {"detail": "Aula y sus rutinas específicas eliminadas con éxito"}

# =====================================================================
# 3. MOTOR IA (Just-In-Time) Y LENGUAJE NATURAL - ARASAAC
# =====================================================================

@app.get("/pictogramas/generar/{palabra}")
async def generar_pictograma_jit(palabra: str):
    palabra_busqueda = palabra.lower().strip()
    
    if palabra_busqueda in cache_pictogramas:
        return cache_pictogramas[palabra_busqueda]
        
    # MEJORA: Uso de 'bestsearch' para obtener la coincidencia más exacta
    url = f"https://api.arasaac.org/api/pictograms/es/bestsearch/{palabra_busqueda}"
    
    async with httpx.AsyncClient() as client:
        response = await client.get(url)
        
        if response.status_code == 200 and response.json():
            data = response.json()
            picto_id = data[0]['_id']
            image_url = f"https://static.arasaac.org/pictograms/{picto_id}/{picto_id}_300.png"
            
            resultado = {"palabra": palabra_busqueda.upper(), "url": image_url}
            cache_pictogramas[palabra_busqueda] = resultado
            return resultado
            
    raise HTTPException(status_code=404, detail="No se encontró un pictograma para esta palabra")

@app.get("/frases/conjugar/{frase}")
async def conjugar_frase(frase: str):
    # MEJORA: Procesamiento de Lenguaje Natural para la síntesis de voz
    url = f"https://api.arasaac.org/api/phrases/flex/es/{frase}"
    
    async with httpx.AsyncClient() as client:
        response = await client.get(url)
        if response.status_code == 200:
            # ARASAAC devuelve un JSON con la llave "msg" que contiene la frase corregida
            return response.json()
            
    # Fallback: Si el servidor de ARASAAC falla, devolvemos la frase original cruda
    return {"msg": frase}


# =====================================================================
# 4. GESTIÓN DE INTERESES CLÍNICOS (Fringe Words)
# =====================================================================

@app.post("/estudiantes/{estudiante_id}/intereses/", response_model=user_schema.InteresResponse)
def agregar_interes(estudiante_id: int, interes: user_schema.InteresCreate, db: Session = Depends(get_db)):
    estudiante = db.query(user_model.Usuario).filter(user_model.Usuario.id == estudiante_id).first()
    if not estudiante:
        raise HTTPException(status_code=404, detail="Estudiante no encontrado")
    
    if len(estudiante.intereses) >= 10:
        raise HTTPException(status_code=400, detail="Límite de 10 intereses alcanzado para no saturar el tablero")
        
    nuevo_interes = user_model.Interes(palabra_clave=interes.palabra_clave.lower().strip(), usuario_id=estudiante_id)
    db.add(nuevo_interes)
    db.commit()
    db.refresh(nuevo_interes)
    return nuevo_interes


@app.get("/estudiantes/{estudiante_id}/intereses/")
def listar_intereses(estudiante_id: int, db: Session = Depends(get_db)):
    return db.query(user_model.Interes).filter(user_model.Interes.usuario_id == estudiante_id).all()


@app.delete("/intereses/{interes_id}")
def eliminar_interes(interes_id: int, db: Session = Depends(get_db)):
    interes = db.query(user_model.Interes).filter(user_model.Interes.id == interes_id).first()
    if interes:
        db.delete(interes)
        db.commit()
    return {"detail": "Interés eliminado"}

class ConfiguracionUpdate(BaseModel):
    densidad_visual: int

@app.get("/estudiantes/{estudiante_id}/configuracion/")
def obtener_configuracion(estudiante_id: int, db: Session = Depends(get_db)):
    config = db.query(user_model.Configuracion).filter(user_model.Configuracion.usuario_id == estudiante_id).first()
    # Si no tiene configuración previa, le creamos una por defecto
    if not config:
        config = user_model.Configuracion(usuario_id=estudiante_id, densidad_visual=8)
        db.add(config)
        db.commit()
        db.refresh(config)
    return {"densidad_visual": config.densidad_visual}

@app.put("/estudiantes/{estudiante_id}/configuracion/")
def actualizar_configuracion(estudiante_id: int, req: ConfiguracionUpdate, db: Session = Depends(get_db)):
    config = db.query(user_model.Configuracion).filter(user_model.Configuracion.usuario_id == estudiante_id).first()
    if not config:
        config = user_model.Configuracion(usuario_id=estudiante_id, densidad_visual=req.densidad_visual)
        db.add(config)
    else:
        config.densidad_visual = req.densidad_visual
        
    db.commit()
    return {"detail": "Configuración actualizada", "densidad_visual": config.densidad_visual}

# =====================================================================
# 5. TRACKING Y ANALÍTICAS (HU-09)
# =====================================================================

class RegistroUsoCreate(BaseModel):
    palabra: str

@app.post("/estudiantes/{estudiante_id}/tracking/")
def registrar_uso_pictograma(estudiante_id: int, req: RegistroUsoCreate, db: Session = Depends(get_db)):
    # Solo registramos si el estudiante existe
    estudiante = db.query(user_model.Usuario).filter(user_model.Usuario.id == estudiante_id).first()
    if not estudiante:
        raise HTTPException(status_code=404, detail="Estudiante no encontrado")
        
    nuevo_registro = user_model.RegistroUso(
        usuario_id=estudiante_id,
        palabra=req.palabra.upper().strip()
    )
    db.add(nuevo_registro)
    db.commit()
    return {"detail": "Interacción registrada correctamente"}

@app.get("/estudiantes/{estudiante_id}/estadisticas/")
def obtener_estadisticas(estudiante_id: int, db: Session = Depends(get_db)):
    # Total de interacciones del niño
    total_clicks = db.query(func.count(user_model.RegistroUso.id)).filter(user_model.RegistroUso.usuario_id == estudiante_id).scalar() or 0

    # Top 5 palabras más usadas (Agrupación SQL)
    resultados = db.query(
        user_model.RegistroUso.palabra,
        func.count(user_model.RegistroUso.id).label('cantidad')
    ).filter(
        user_model.RegistroUso.usuario_id == estudiante_id
    ).group_by(
        user_model.RegistroUso.palabra
    ).order_by(
        func.count(user_model.RegistroUso.id).desc()
    ).limit(5).all()

    return {
        "total_interacciones": total_clicks,
        "top_palabras": [{"palabra": r[0], "cantidad": r[1]} for r in resultados]
    }

# =====================================================================
# 6. RUTINAS VISUALES (HU-07)
# =====================================================================

class PasoCreate(BaseModel):
    orden: int
    palabra: str

class RutinaCreate(BaseModel):
    titulo: str
    pasos: List[PasoCreate]
    aula_id: Optional[int] = None # NUEVO: Puede ser Nulo si lo crea el niño

@app.post("/estudiantes/{estudiante_id}/rutinas/")
def crear_rutina(estudiante_id: int, req: RutinaCreate, db: Session = Depends(get_db)):
    estudiante = db.query(user_model.Usuario).filter(user_model.Usuario.id == estudiante_id).first()
    if not estudiante:
        raise HTTPException(status_code=404, detail="Estudiante no encontrado")
        
    # Guarda el aula_id. Si es nulo, se entiende que es una rutina "Personal"
    nueva_rutina = user_model.Rutina(estudiante_id=estudiante_id, titulo=req.titulo, aula_id=req.aula_id)
    db.add(nueva_rutina)
    db.commit()
    db.refresh(nueva_rutina)
    
    for paso in req.pasos:
        nuevo_paso = user_model.PasoRutina(rutina_id=nueva_rutina.id, orden=paso.orden, palabra=paso.palabra.lower().strip())
        db.add(nuevo_paso)
        
    db.commit()
    return {"detail": "Rutina creada con éxito"}

@app.get("/estudiantes/{estudiante_id}/rutinas/")
def listar_rutinas(estudiante_id: int, db: Session = Depends(get_db)):
    rutinas = db.query(user_model.Rutina).filter(user_model.Rutina.estudiante_id == estudiante_id).all()
    resultado = []
    
    for r in rutinas:
        pasos = db.query(user_model.PasoRutina).filter(user_model.PasoRutina.rutina_id == r.id).order_by(user_model.PasoRutina.orden).all()
        
        # CATEGORIZACIÓN: Descubrimos si es Personal o de una Clase
        origen = "Personal"
        if r.aula_id:
            aula = db.query(user_model.Aula).filter(user_model.Aula.id == r.aula_id).first()
            origen = f"Clase: {aula.nombre}" if aula else "Clase archivada"

        resultado.append({
            "id": r.id,
            "titulo": r.titulo,
            "origen": origen, # Enviamos la etiqueta a Flutter
            "pasos": [{"orden": p.orden, "palabra": p.palabra} for p in pasos]
        })
    return resultado

@app.delete("/rutinas/{rutina_id}")
def eliminar_rutina(rutina_id: int, db: Session = Depends(get_db)):
    rutina = db.query(user_model.Rutina).filter(user_model.Rutina.id == rutina_id).first()
    if rutina:
        db.delete(rutina)
        db.commit()
        return {"detail": "Rutina eliminada"}
    raise HTTPException(status_code=404, detail="Rutina no encontrada")

@app.get("/estudiantes/{estudiante_id}/historial/")
def obtener_historial_comunicacion(estudiante_id: int, db: Session = Depends(get_db)):
    # Obtenemos los últimos 20 pictogramas presionados
    registros = db.query(user_model.RegistroUso)\
        .filter(user_model.RegistroUso.usuario_id == estudiante_id)\
        .order_by(user_model.RegistroUso.fecha_hora.desc())\
        .limit(20).all()
        
    resultado = []
    for r in registros:
        # Formateamos la fecha para que Flutter la lea fácil
        resultado.append({
            "palabra": r.palabra,
            "fecha_hora": r.fecha_hora.isoformat() if r.fecha_hora else None
        })
        
    return resultado

# =====================================================================
# ENDPOINT SEGURO PARA VINCULACIÓN FAMILIAR
# =====================================================================
@app.get("/estudiantes/vincular/{dni}")
def vincular_estudiante_por_dni(dni: str, db: Session = Depends(get_db)):
    # Buscamos que exista un usuario con ese DNI y que estrictamente sea un "estudiante"
    estudiante = db.query(user_model.Usuario).filter(
        user_model.Usuario.dni == dni, 
        user_model.Usuario.rol == 'estudiante'
    ).first()
    
    if not estudiante:
        raise HTTPException(status_code=404, detail="No se encontró un paciente con este DNI")
        
    # Devolvemos el ID interno y el nombre para que el padre confirme a quién vinculó
    return {
        "id": estudiante.id, 
        "nombre_completo": f"{estudiante.nombres} {estudiante.apellidos}"
    }