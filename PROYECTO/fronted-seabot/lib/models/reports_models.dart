// -------------------------
// CA1 – Actividad Semanal
// -------------------------
class WeeklyActivity {
  final DateTime semana;
  final int sesionesTotales;
  final double duracionPromedio;
  final double mensajesPromedio;

  WeeklyActivity({
    required this.semana,
    required this.sesionesTotales,
    required this.duracionPromedio,
    required this.mensajesPromedio,
  });

  factory WeeklyActivity.fromJson(Map<String, dynamic> json) {
    return WeeklyActivity(
      semana: DateTime.parse(json["semana"]),
      sesionesTotales: json["sesiones_totales"],
      duracionPromedio: (json["duracion_promedio_sesion"] as num).toDouble(),
      mensajesPromedio: (json["mensajes_promedio_por_sesion"] as num).toDouble(),
    );
  }
}

// -------------------------
// CA2 – Emociones Identificadas
// -------------------------
class EmotionCount {
  final String category;
  final int total;

  EmotionCount({
    required this.category,
    required this.total,
  });

  factory EmotionCount.fromJson(Map<String, dynamic> json) {
    return EmotionCount(
      category: json["category"],
      total: json["total"],
    );
  }
}

// -------------------------
// CA3 – PHQ-9 Promedio
// -------------------------
class PhqPromedio {
  final double promedioBefore;
  final double promedioAfter;

  PhqPromedio({
    required this.promedioBefore,
    required this.promedioAfter,
  });

  factory PhqPromedio.fromJson(Map<String, dynamic> json) {
    return PhqPromedio(
      promedioBefore: (json["promedio_before"] as num).toDouble(),
      promedioAfter: (json["promedio_after"] as num).toDouble(),
    );
  }
}

// -------------------------
// CA4 – Usabilidad y Satisfacción
// -------------------------
class UsabilidadResultados {
  final double empatia;
  final double coherencia;
  final double retencion;
  final double sus;

  UsabilidadResultados({
    required this.empatia,
    required this.coherencia,
    required this.retencion,
    required this.sus,
  });

  factory UsabilidadResultados.fromJson(Map<String, dynamic> json) {
    return UsabilidadResultados(
      empatia: (json["empatia"] as num).toDouble(),
      coherencia: (json["coherencia"] as num).toDouble(),
      retencion: (json["retencion"] as num).toDouble(),
      sus: (json["sus"] as num).toDouble(),
    );
  }
}
