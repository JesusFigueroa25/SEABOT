import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seabot/core/app_colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:seabot/models/reports_models.dart';
import 'package:seabot/services/reports_service.dart';

// ===========================
// VIEW TOGGLE – TABLA / GRAFICA
// ===========================
enum ReportViewType { chart, table }

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final ReportsService _service = ReportsService();

  late Future<List<WeeklyActivity>> actividadSemanal;
  late Future<List<EmotionCount>> emociones;
  late Future<PhqPromedio> phqPromedio;
  late Future<UsabilidadResultados> usabilidad;

  ReportViewType currentView = ReportViewType.chart;

  @override
  void initState() {
    super.initState();
    actividadSemanal = _service.getWeeklyActivity();
    emociones = _service.getEmotions();
    phqPromedio = _service.getPhqPromedio();
    usabilidad = _service.getUsabilidad();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData.light().copyWith(
      scaffoldBackgroundColor: const Color(0xFFF6F8FB),
      textTheme: GoogleFonts.manropeTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.manrope(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(title: const Text("Reportes Generales")),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ========= TOGGLE DE VISTAS =========
              _buildViewButtons(),
              const SizedBox(height: 20),

              // ---- CA1 ----
              FutureBuilder<List<WeeklyActivity>>(
                future: actividadSemanal,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _loadingCard("Actividad Semanal");
                  }

                  if (snapshot.hasError) {
                    return _connectionErrorCard("Actividad Semanal", () {
                      setState(() {
                        actividadSemanal = _service.getWeeklyActivity();
                      });
                    });
                  }
                  return _cardTemplate(
                    title: "Actividad semanal del usuario",
                    content: currentView == ReportViewType.chart
                        ? actividadSemanalChart(snapshot.data!)
                        : actividadSemanalTable(snapshot.data!),
                  );
                },
              ),

              const SizedBox(height: 20),

              // ---- CA2 ----
              FutureBuilder<List<EmotionCount>>(
                future: emociones,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _loadingCard("Emociones");
                  }

                  if (snapshot.hasError) {
                    return _connectionErrorCard("Emociones", () {
                      setState(() {
                        emociones = _service.getEmotions();
                      });
                    });
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _cardTemplate(
                      title: "Distribución de emociones detectadas",
                      content: Text(
                        "No hay datos disponibles.",
                        style: GoogleFonts.manrope(),
                      ),
                    );
                  }

                  return _cardTemplate(
                    title: "Distribución de emociones detectadas",
                    content: currentView == ReportViewType.chart
                        ? emocionesChart(snapshot.data!)
                        : emocionesTable(snapshot.data!),
                  );
                },
              ),

              const SizedBox(height: 20),

              // ---- CA3 ----
              FutureBuilder<PhqPromedio>(
                future: phqPromedio,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _loadingCard("PHQ-9");
                  }

                  if (snapshot.hasError) {
                    return _connectionErrorCard("PHQ-9", () {
                      setState(() {
                        phqPromedio = _service.getPhqPromedio();
                      });
                    });
                  }

                  if (!snapshot.hasData) {
                    return _cardTemplate(
                      title: "PHQ-9 Pretest vs Postest",
                      content: Text(
                        "No hay datos disponibles.",
                        style: GoogleFonts.manrope(),
                      ),
                    );
                  }

                  return _cardTemplate(
                    title: "PHQ-9 Pretest vs Postest",
                    content: currentView == ReportViewType.chart
                        ? phqChart(snapshot.data!)
                        : phqTable(snapshot.data!),
                  );
                },
              ),

              const SizedBox(height: 20),

              // ---- CA4 ----
              FutureBuilder<UsabilidadResultados>(
                future: usabilidad,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _loadingCard("Usabilidad y Satisfacción");
                  }

                  if (snapshot.hasError) {
                    return _connectionErrorCard(
                      "Usabilidad y Satisfacción",
                      () {
                        setState(() {
                          usabilidad = _service.getUsabilidad();
                        });
                      },
                    );
                  }

                  if (!snapshot.hasData) {
                    return _cardTemplate(
                      title: "Indicadores de Usabilidad",
                      content: Text(
                        "No hay datos disponibles.",
                        style: GoogleFonts.manrope(),
                      ),
                    );
                  }

                  return _cardTemplate(
                    title: "Indicadores de Usabilidad",
                    content: currentView == ReportViewType.chart
                        ? usabilidadChart(snapshot.data!)
                        : usabilidadTable(snapshot.data!),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================
  //               TOGGLE DE VISTAS (TABLA / GRAFICO)
  // ===========================================================
  Widget _buildViewButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _viewButton(Icons.bar_chart, ReportViewType.chart),
        _viewButton(Icons.table_chart, ReportViewType.table),
      ],
    );
  }

  Widget _viewButton(IconData icon, ReportViewType view) {
    bool selected = currentView == view;

    return GestureDetector(
      onTap: () => setState(() => currentView = view),
      child: CircleAvatar(
        radius: selected ? 26 : 23,
        backgroundColor: selected ? AppColors.primary : Colors.grey.shade300,
        child: Icon(
          icon,
          size: 26,
          color: selected ? Colors.white : Colors.black54,
        ),
      ),
    );
  }

  // ===========================================================
  //                     CA1 – Actividad Semanal
  // ===========================================================
  Widget actividadSemanalChart(List<WeeklyActivity> data) {
    if (data.isEmpty) {
      return Text("No hay datos disponibles.", style: GoogleFonts.manrope());
    }

    final sesiones = <FlSpot>[];
    final duracion = <FlSpot>[];
    final mensajes = <FlSpot>[];

    for (int i = 0; i < data.length; i++) {
      sesiones.add(FlSpot(i.toDouble(), data[i].sesionesTotales.toDouble()));
      duracion.add(FlSpot(i.toDouble(), data[i].duracionPromedio));
      mensajes.add(FlSpot(i.toDouble(), data[i].mensajesPromedio));
    }

    final valoresY = [
      ...sesiones.map((e) => e.y),
      ...duracion.map((e) => e.y),
      ...mensajes.map((e) => e.y),
    ];

    final maxDataValue = valoresY.reduce((a, b) => a > b ? a : b);
    final roundedMaxY =
        (((maxDataValue <= 0 ? 10 : maxDataValue) / 5).ceil() * 5).toDouble();
    final maxY = roundedMaxY < 10 ? 10.0 : roundedMaxY;

    return Column(
      children: [
        SizedBox(
          height: 300,
          child: Padding(
            padding: const EdgeInsets.only(right: 8, top: 8),
            child: LineChart(
              LineChartData(
                minX: -0.2,
                maxX: data.length == 1
                    ? 1.2
                    : (data.length - 1).toDouble() + 0.1,
                minY: 0,
                maxY: maxY,
                clipData: const FlClipData.none(),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) =>
                        AppColors.primary.withValues(alpha: 0.95),
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    getTooltipItems: (spots) {
                      return spots.map((spot) {
                        String label;

                        if (spot.barIndex == 0) {
                          label = "Sesiones";
                        } else if (spot.barIndex == 1) {
                          label = "Duración";
                        } else {
                          label = "Mensajes";
                        }

                        return LineTooltipItem(
                          "$label: ${spot.y.toStringAsFixed(1)}",
                          GoogleFonts.manrope(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),

                lineBarsData: [
                  LineChartBarData(
                    spots: sesiones,
                    isCurved: false,
                    barWidth: 3,
                    color: Colors.blueGrey.shade600,
                    dotData: const FlDotData(show: true),
                  ),
                  LineChartBarData(
                    spots: duracion,
                    isCurved: false,
                    barWidth: 3,
                    color: AppColors.secondaryDarkText,
                    dotData: const FlDotData(show: true),
                  ),
                  LineChartBarData(
                    spots: mensajes,
                    isCurved: false,
                    barWidth: 3,
                    color: AppColors.rojo,
                    dotData: const FlDotData(show: true),
                  ),
                ],

                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 5,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.grey.withValues(alpha: 0.18),
                    strokeWidth: 1,
                  ),
                ),

                // Ejes visibles: izquierda y abajo
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.45),
                      width: 1,
                    ),
                    bottom: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.45),
                      width: 1,
                    ),
                  ),
                ),

                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),

                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 30,
                      getTitlesWidget: (v, meta) {
                        final index = v.round();

                        // Evita que valores decimales como -0.2, 0.8, 1.8
                        // se conviertan en S1, S2, etc.
                        if ((v - index).abs() > 0.001) {
                          return const SizedBox.shrink();
                        }

                        if (index < 0 || index >= data.length) {
                          return const SizedBox.shrink();
                        }

                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 6,
                          child: Text(
                            "S${index + 1}",
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 5,
                      reservedSize: 32,
                      getTitlesWidget: (v, meta) {
                        if (v < 0 || v > maxY || (v % 5).abs() > 0.001) {
                          return const SizedBox.shrink();
                        }

                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 6,
                          child: Text(
                            v.toInt().toString(),
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _legendItem("Sesiones", Colors.blueGrey.shade600),
            _legendItem("Duración (min)", AppColors.secondaryDarkText),
            _legendItem("Mensajes", AppColors.rojo),
          ],
        ),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.subtitleLight,
          ),
        ),
      ],
    );
  }

  Widget actividadSemanalTable(List<WeeklyActivity> data) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 28,
        headingRowHeight: 42,
        dataRowHeight: 42,
        columns: const [
          DataColumn(label: Text("Semana")),
          DataColumn(label: Text("Sesiones")),
          DataColumn(label: Text("Duración (min)")),
          DataColumn(label: Text("Mensajes")),
        ],
        rows: List.generate(data.length, (i) {
          return DataRow(
            cells: [
              DataCell(Text("Semana ${i + 1}")),
              DataCell(Text(data[i].sesionesTotales.toString())),
              DataCell(Text(data[i].duracionPromedio.toStringAsFixed(1))),
              DataCell(Text(data[i].mensajesPromedio.toStringAsFixed(1))),
            ],
          );
        }),
      ),
    );
  }

  // ===========================================================
  //                CA2 – Emociones Detectadas
  // ===========================================================
  Widget emocionesChart(List<EmotionCount> data) {
    final total = data.fold(0, (a, b) => a + b.total);

    return Column(
      children: List.generate(data.length, (i) {
        final porcentaje = (data[i].total / total);
        final porcentajeTexto = (porcentaje * 100).toStringAsFixed(1);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              SizedBox(
                width: 140,
                child: Text(
                  data[i].category,
                  style: GoogleFonts.manrope(fontSize: 14),
                ),
              ),
              Expanded(
                child: Container(
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: porcentaje,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 50,
                child: Text(
                  "$porcentajeTexto%",
                  style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget emocionesTable(List<EmotionCount> data) {
    final total = data.fold(0, (a, b) => a + b.total);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text("Categoría")),
          DataColumn(label: Text("Total")),
          DataColumn(label: Text("%")),
        ],
        rows: List.generate(data.length, (i) {
          final p = (data[i].total / total) * 100;
          return DataRow(
            cells: [
              DataCell(Text(data[i].category)),
              DataCell(Text(data[i].total.toString())),
              DataCell(Text("${p.toStringAsFixed(1)}%")),
            ],
          );
        }),
      ),
    );
  }

  Widget _connectionErrorCard(String title, VoidCallback onRetry) {
    return _cardTemplate(
      title: title,
      content: Column(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.redAccent, size: 40),
          const SizedBox(height: 12),
          Text(
            "Sin conexión a internet",
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // ===========================================================
  //                      CA3 – PHQ PROMEDIO
  // ===========================================================
  Widget phqChart(PhqPromedio d) {
    final maxScore = d.promedioBefore > d.promedioAfter
        ? d.promedioBefore
        : d.promedioAfter;
    final roundedMaxY = (((maxScore <= 0 ? 20 : maxScore) / 5).ceil() * 5)
        .toDouble();
    final maxY = roundedMaxY < 20 ? 20.0 : roundedMaxY;
    final valores = [
      ("Antes", d.promedioBefore, AppColors.azulClaro),
      ("Después", d.promedioAfter, AppColors.gris),
    ];

    return SizedBox(
      height: 240,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          minY: 0,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.primary.withValues(alpha: 0.95),
              tooltipRoundedRadius: 8,
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                if (group.x < 0 || group.x >= valores.length) {
                  return null;
                }

                return BarTooltipItem(
                  "${valores[group.x].$1}: ${rod.toY.toStringAsFixed(1)}",
                  GoogleFonts.manrope(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
          barGroups: List.generate(valores.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: valores[i].$2,
                  width: 38,
                  color: valores[i].$3,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 34,
                getTitlesWidget: (v, meta) {
                  final index = v.toInt();
                  if (index < 0 || index >= valores.length) {
                    return const SizedBox.shrink();
                  }

                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 8,
                    child: Text(
                      valores[index].$1,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 5,
                reservedSize: 32,
                getTitlesWidget: (v, meta) {
                  if (v < 0 || v > maxY || (v % 5).abs() > 0.001) {
                    return const SizedBox.shrink();
                  }

                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 8,
                    child: Text(
                      v.toInt().toString(),
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 5,
            getDrawingHorizontalLine: (_) => FlLine(
              color: Colors.grey.withValues(alpha: 0.18),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget phqTable(PhqPromedio d) {
    return DataTable(
      columns: const [
        DataColumn(label: Text("Tipo")),
        DataColumn(label: Text("Promedio")),
      ],
      rows: [
        DataRow(
          cells: [
            const DataCell(Text("Antes")),
            DataCell(Text(d.promedioBefore.toStringAsFixed(1))),
          ],
        ),
        DataRow(
          cells: [
            const DataCell(Text("Después")),
            DataCell(Text(d.promedioAfter.toStringAsFixed(1))),
          ],
        ),
      ],
    );
  }

  // ===========================================================
  //              CA4 – USABILIDAD Y SATISFACCION
  // ===========================================================
  Widget usabilidadChart(UsabilidadResultados d) {
    final valores = [
      ("Empatía", d.empatia * 100),
      ("Coherencia", d.coherencia * 100),
      ("Retención", d.retencion * 100),
      ("SUS", d.sus * 100),
    ];

    return SizedBox(
      height: 260,
      child: BarChart(
        BarChartData(
          maxY: 100,
          minY: 0,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.primary.withValues(alpha: 0.95),
              tooltipRoundedRadius: 8,
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                if (group.x < 0 || group.x >= valores.length) {
                  return null;
                }

                return BarTooltipItem(
                  "${valores[group.x].$1}\n${rod.toY.toStringAsFixed(1)}%",
                  GoogleFonts.manrope(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
          barGroups: List.generate(valores.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: valores[i].$2,
                  width: 40,
                  color: AppColors.primary.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            );
          }),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 34,
                getTitlesWidget: (v, meta) {
                  final index = v.toInt();
                  if (index < 0 || index >= valores.length) {
                    return const SizedBox.shrink();
                  }

                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 8,
                    child: Text(
                      valores[index].$1,
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 20,
                reservedSize: 42,
                getTitlesWidget: (v, meta) {
                  if (v < 0 || v > 100 || v % 20 != 0) {
                    return const SizedBox.shrink();
                  }

                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 8,
                    child: Text(
                      "${v.toInt()}%",
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 20,
            getDrawingHorizontalLine: (_) => FlLine(
              color: Colors.grey.withValues(alpha: 0.18),
              strokeWidth: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget usabilidadTable(UsabilidadResultados d) {
    return DataTable(
      columns: const [
        DataColumn(label: Text("Indicador")),
        DataColumn(label: Text("Puntaje %")),
      ],
      rows: [
        DataRow(
          cells: [
            const DataCell(Text("Empatía")),
            DataCell(Text("${(d.empatia * 100).toStringAsFixed(1)}%")),
          ],
        ),
        DataRow(
          cells: [
            const DataCell(Text("Coherencia")),
            DataCell(Text("${(d.coherencia * 100).toStringAsFixed(1)}%")),
          ],
        ),
        DataRow(
          cells: [
            const DataCell(Text("Retención")),
            DataCell(Text("${(d.retencion * 100).toStringAsFixed(1)}%")),
          ],
        ),
        DataRow(
          cells: [
            const DataCell(Text("Escala SUS")),
            DataCell(Text("${(d.sus * 100).toStringAsFixed(1)}%")),
          ],
        ),
      ],
    );
  }

  // ===========================================================
  //                      HELPERS GENERALES
  // ===========================================================
  Widget _loadingCard(String title) {
    return _cardTemplate(
      title: title,
      content: const Padding(
        padding: EdgeInsets.all(12),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _cardTemplate({required String title, required Widget content}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            content,
          ],
        ),
      ),
    );
  }
}
