from sqlalchemy.orm import Session
from sqlalchemy import text

# ===========================
# CA1 – ACTIVIDAD SEMANAL
# ===========================
def get_actividad_semanal(db: Session):
    query = text("""
    WITH mensajes_ordenados AS (
        SELECT
            m.id,
            m.conversation_id,
            m.fecha_hora,
            LAG(m.fecha_hora) OVER (
                PARTITION BY m.conversation_id
                ORDER BY m.fecha_hora
            ) AS prev_time
        FROM messages m
        JOIN conversations c ON c.id = m.conversation_id
        WHERE m.conversation_id IN (SELECT conversation_id FROM selected_conversations_view)
    ),
    bloques AS (
        SELECT
            id,
            conversation_id,
            fecha_hora,
            CASE
                WHEN prev_time IS NULL THEN 1
                WHEN EXTRACT(EPOCH FROM (fecha_hora - prev_time)) > 1800 THEN 1
                ELSE 0
            END AS corte
        FROM mensajes_ordenados
    ),
    sesiones AS (
        SELECT
            id,
            conversation_id,
            fecha_hora,
            SUM(corte) OVER (
                PARTITION BY conversation_id
                ORDER BY fecha_hora
            ) AS session_id
        FROM bloques
    ),
    duraciones AS (
        SELECT
            conversation_id,
            session_id,
            MIN(fecha_hora) AS inicio_sesion,
            MAX(fecha_hora) AS fin_sesion,
            EXTRACT(EPOCH FROM (MAX(fecha_hora) - MIN(fecha_hora))) / 60 AS duracion_min
        FROM sesiones
        GROUP BY conversation_id, session_id
    ),
    mensajes_por_sesion AS (
        SELECT
            conversation_id,
            session_id,
            COUNT(*) AS total_mensajes
        FROM sesiones
        GROUP BY conversation_id, session_id
    )
    SELECT
        DATE_TRUNC('week', d.inicio_sesion) AS semana,
        COUNT(*) AS sesiones_totales,
        ROUND(AVG(d.duracion_min)::numeric, 1) AS duracion_promedio_sesion,
        ROUND(AVG(mps.total_mensajes)::numeric, 1) AS mensajes_promedio_por_sesion
    FROM duraciones d
    JOIN mensajes_por_sesion mps
        ON d.conversation_id = mps.conversation_id
       AND d.session_id = mps.session_id
    GROUP BY DATE_TRUNC('week', d.inicio_sesion)
    ORDER BY semana;
    """)
    
    result = db.execute(query).mappings().all()
    return result


# ===========================
# CA2 – EMOCIONES PORCENTUALES
# ===========================
def get_emociones(db: Session):
    query = text("""
    SELECT 
        category,
        COUNT(*) AS total
    FROM messages
    WHERE role = 'user'
      AND conversation_id IN (SELECT conversation_id FROM selected_conversations_view)
    GROUP BY category
    ORDER BY total DESC;
    """)
    return db.execute(query).mappings().all()


# ===========================
# CA3 – PROMEDIOS PHQ-9
# ===========================
def get_phq_promedio(db: Session):
    query = text("""
    WITH phq_before AS (
        SELECT DISTINCT ON (student_id)
            student_id,
            total_score
        FROM phq_results
        where student_id IN (select student_id from selected_students_view)
        ORDER BY student_id, fecha ASC
    ),
    phq_after AS (
        SELECT DISTINCT ON (student_id)
            student_id,
            total_score
        FROM phq_results
         where student_id IN (select student_id from selected_students_view)
        ORDER BY student_id, fecha DESC
    )
    SELECT
        ROUND(AVG(phq_before.total_score), 1) AS promedio_before,
        ROUND(AVG(phq_after.total_score), 1)  AS promedio_after
    FROM phq_before
    JOIN phq_after USING (student_id);
    """)
    return db.execute(query).mappings().first()
