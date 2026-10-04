from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, Table
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base

aula_estudiante = Table(
    'aula_estudiante',
    Base.metadata,
    Column('aula_id', Integer, ForeignKey('aulas.id'), primary_key=True),
    Column('estudiante_id', Integer, ForeignKey('usuarios.id'), primary_key=True)
)

class Usuario(Base):
    __tablename__ = "usuarios"
    
    id = Column(Integer, primary_key=True, index=True)
    nombres = Column(String, nullable=False)
    apellidos = Column(String, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    dni = Column(String(8), unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    rol = Column(String, nullable=False)
    fecha_creacion = Column(DateTime(timezone=True), server_default=func.now())

    aulas_creadas = relationship("Aula", back_populates="docente", cascade="all, delete-orphan")
    aulas_inscritas = relationship("Aula", secondary=aula_estudiante, back_populates="estudiantes")
    intereses = relationship("Interes", back_populates="usuario", cascade="all, delete-orphan")

class Aula(Base):
    __tablename__ = "aulas"
    
    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String, nullable=False)
    descripcion = Column(String, nullable=True)
    codigo_acceso = Column(String(6), unique=True, index=True, nullable=False)
    
    # LA CORRECCIÓN ESTÁ AQUÍ
    docente_id = Column(Integer, ForeignKey("usuarios.id"), nullable=False)
    
    docente = relationship("Usuario", back_populates="aulas_creadas")
    estudiantes = relationship("Usuario", secondary=aula_estudiante, back_populates="aulas_inscritas")

class Interes(Base):
    __tablename__ = "intereses"
    
    id = Column(Integer, primary_key=True, index=True)
    usuario_id = Column(Integer, ForeignKey("usuarios.id"))
    palabra_clave = Column(String, nullable=False)

    usuario = relationship("Usuario", back_populates="intereses")
    
class Configuracion(Base):
    __tablename__ = "configuraciones"
    
    id = Column(Integer, primary_key=True, index=True)
    usuario_id = Column(Integer, ForeignKey("usuarios.id"), unique=True)
    densidad_visual = Column(Integer, default=8) # Rango de 2 a 12 pictogramas
    
    usuario = relationship("Usuario")
    
class RegistroUso(Base):
    __tablename__ = "registros_uso"
    
    id = Column(Integer, primary_key=True, index=True)
    usuario_id = Column(Integer, ForeignKey("usuarios.id"))
    palabra = Column(String, nullable=False)
    # Guarda la fecha y hora exacta del clic
    fecha_hora = Column(DateTime(timezone=True), server_default=func.now())
    
    usuario = relationship("Usuario")

class Rutina(Base):
    __tablename__ = "rutinas"
    
    id = Column(Integer, primary_key=True, index=True)
    estudiante_id = Column(Integer, ForeignKey("usuarios.id"))
    titulo = Column(String, nullable=False)
    
    aula_id = Column(Integer, ForeignKey("aulas.id"), nullable=True)
    
    usuario = relationship("Usuario")
    # Relación uno a muchos con sus pasos
    pasos = relationship("PasoRutina", back_populates="rutina", cascade="all, delete-orphan")

class PasoRutina(Base):
    __tablename__ = "pasos_rutina"
    
    id = Column(Integer, primary_key=True, index=True)
    rutina_id = Column(Integer, ForeignKey("rutinas.id"))
    orden = Column(Integer, nullable=False)
    palabra = Column(String, nullable=False)
    
    rutina = relationship("Rutina", back_populates="pasos")