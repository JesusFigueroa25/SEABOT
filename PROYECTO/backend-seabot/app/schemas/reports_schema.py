from pydantic import BaseModel
from datetime import datetime
from typing import Optional, List

# CA1 – Actividad Semanal
class WeeklyActivity(BaseModel):
    semana: datetime
    sesiones_totales: int
    duracion_promedio_sesion: float
    mensajes_promedio_por_sesion: float

# CA2 – Emociones Identificadas
class EmotionPercent(BaseModel):
    category: str
    total: int

# CA3 – PHQ-9 Promedio
class PhqPromedio(BaseModel):
    promedio_before: float
    promedio_after: float

# CA4 – Usabilidad y Satisfacción (encuesta externa)
class UsabilidadResultados(BaseModel):
    empatia: float
    coherencia: float
    retencion: float
    sus: float
