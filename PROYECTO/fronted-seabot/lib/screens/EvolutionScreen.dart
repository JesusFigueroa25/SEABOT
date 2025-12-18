import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:seabot/core/app_colors.dart';
import 'package:seabot/core/app_data.dart';
import 'package:seabot/models/phq_result.dart';
import 'package:seabot/repositories/phq_results_repository.dart';

// ======== ENUM PARA VISTAS ========
enum EvolutionViewType { list, calendar, chart }

class EvolutionScreen extends StatefulWidget {
  const EvolutionScreen({super.key});

  @override
  State<EvolutionScreen> createState() => _EvolutionScreenState();
}

class _EvolutionScreenState extends State<EvolutionScreen> {
  int studentID = AppData.studentID;
  late Future<List<PhqResult>> resultados;
  final PHQResultsRepository repository = PHQResultsRepository();

  EvolutionViewType currentView = EvolutionViewType.list;

  @override
  void initState() {
    super.initState();
    resultados = Future.value([]);
    _loadResults();
  }

  Future<void> _loadResults() async {
    bool online = await _hasInternet();
    setState(() {
      resultados = repository.fetchAndSyncPHQResults(studentID, online);
    });
  }

  Future<bool> _hasInternet() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) return false;

    try {
      final result = await InternetAddress.lookup(
        'platform.openai.com',
      ).timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // =====================================================
  //           COLORES POR INTENSIDAD PHQ-9
  // =====================================================
  Color getPhqColor(int score) {
    if (score <= 4) return AppColors.secundary.withOpacity(0.40); // leve
    if (score <= 9) return AppColors.secundary; // leve-mod
    if (score <= 14) return AppColors.secundaryStart; // moderado
    if (score <= 19) return AppColors.primary; // moderado-severo
    return AppColors.accent; // severo
  }

  // =====================================================
  //                          UI
  // =====================================================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Theme(
      data: theme.copyWith(
        textTheme: GoogleFonts.manropeTextTheme(theme.textTheme),
      ),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text("Evolución Emocional"),
          backgroundColor: AppColors.primary,
          centerTitle: true,
        ),
        body: SafeArea(
          child: FutureBuilder<List<PhqResult>>(
            future: resultados,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(
                  child: Text(
                    "Error: ${snapshot.error}",
                    style: GoogleFonts.manrope(color: Colors.redAccent),
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text(
                    "No hay datos aún.\nRealiza primero un test PHQ-9.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                );
              }

              final results = snapshot.data!;

              return Column(
                children: [
                  Expanded(child: _buildCurrentView(results)),

                  const SizedBox(height: 10),

                  _buildViewButtons(),

                  const SizedBox(height: 16),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // =====================================================
  //      SWITCH DE INTERFACES (LISTA / MES / GRÁFICA)
  // =====================================================
  Widget _buildCurrentView(List<PhqResult> results) {
    switch (currentView) {
      case EvolutionViewType.list:
        return _buildListView(results);
      case EvolutionViewType.calendar:
        return _buildCalendarView(results);
      case EvolutionViewType.chart:
        return _buildChartView(results);
    }
  }

  // 🔘 Toggle inferior de vistas
  Widget _buildViewButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _viewButton(Icons.view_list, EvolutionViewType.list),
        _viewButton(Icons.calendar_month, EvolutionViewType.calendar),
        _viewButton(Icons.show_chart, EvolutionViewType.chart),
      ],
    );
  }

  Widget _viewButton(IconData icon, EvolutionViewType view) {
    bool selected = currentView == view;

    return GestureDetector(
      onTap: () => setState(() => currentView = view),
      child: CircleAvatar(
        radius: selected ? 26 : 23,
        backgroundColor: selected ? AppColors.secundary : Colors.grey.shade300,
        child: Icon(
          icon,
          size: 26,
          color: selected ? Colors.white : Colors.black54,
        ),
      ),
    );
  }

  // =====================================================
  //                 1️⃣ LISTA DE RESULTADOS
  // =====================================================
  Widget _buildListView(List<PhqResult> results) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final r = results[index];
        final score = r.totalScore ?? 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Text("🩹", style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),

                Expanded(
                  child: Container(
                    height: 22,
                    decoration: BoxDecoration(
                      color: getPhqColor(score),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Text(
                  score.toString(),
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =====================================================
  //                  2️⃣ CALENDARIO POR MES
  // =====================================================
  Widget _buildCalendarView(List<PhqResult> results) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Map<String, List<PhqResult>> grouped = {};
    for (var r in results) {
      final key = "${r.fecha.year}-${r.fecha.month}";
      grouped.putIfAbsent(key, () => []).add(r);
    }

    final months = grouped.keys.toList();
    String selectedMonth = months.first;
    int? selectedDay;
    PhqResult? selectedResult;

    return StatefulBuilder(
      builder: (context, setSB) {
        return Column(
          children: [
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: months.length,
                itemBuilder: (_, index) {
                  final m = months[index];
                  bool active = m == selectedMonth;

                  return GestureDetector(
                    onTap: () {
                      setSB(() {
                        selectedMonth = m;
                        selectedDay = null;
                        selectedResult = null;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.secundary
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          _formatMonth(m),
                          style: GoogleFonts.manrope(
                            color: active ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: GridView.count(
                crossAxisCount: 7,
                children: List.generate(31, (i) {
                  final day = i + 1;
                  final list = grouped[selectedMonth]!
                      .where((d) => d.fecha.day == day)
                      .toList();

                  bool hasData = list.isNotEmpty;

                  return GestureDetector(
                    onTap: () {
                      if (!hasData) return;
                      setSB(() {
                        selectedDay = day;
                        selectedResult = list.first;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: hasData
                            ? getPhqColor(list.first.totalScore!)
                            : (isDark ? Colors.white12 : Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          "$day",
                          style: GoogleFonts.manrope(
                            color: isDark ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            if (selectedResult != null)
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  "Resultado del día $selectedDay: ${selectedResult!.totalScore}",
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  String _formatMonth(String key) {
    final p = key.split("-");
    final month = int.parse(p[1]);
    const names = [
      "",
      "Enero",
      "Febrero",
      "Marzo",
      "Abril",
      "Mayo",
      "Junio",
      "Julio",
      "Agosto",
      "Septiembre",
      "Octubre",
      "Noviembre",
      "Diciembre",
    ];
    return names[month];
  }

  // =====================================================
  //                   3️⃣ GRÁFICA MEJORADA
  // =====================================================
  Widget _buildChartView(List<PhqResult> results) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          minX: -0.3, // 👈 Espacio extra a la izquierda
          maxX:
              (results.length - 1).toDouble() + 0.3, // 👈 Espacio extra derecha
          minY: 0,
          maxY: 27,

          gridData: FlGridData(
            show: true,
            horizontalInterval: 5,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Colors.grey.withOpacity(0.15), strokeWidth: 1),
          ),

          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  int i = value.toInt();
                  if (i < 0 || i >= results.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    //child: Text(
                    //  results[i].fecha.toIso8601String().substring(5, 10),
                    //  style: GoogleFonts.manrope(fontSize: 11),
                    //),
                  );
                },
              ),
            ),

            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 5,
                reservedSize: 34,
              ),
            ),
          ),

          lineBarsData: [
            LineChartBarData(
              isCurved: false, // ❗ LINEA RECTAAAAA
              color: AppColors.secundary,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  int score = results[index].totalScore ?? 0;
                  return FlDotCirclePainter(
                    radius: 6,
                    color: getPhqColor(score),
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),

              spots: [
                for (int i = 0; i < results.length; i++)
                  FlSpot(i.toDouble(), results[i].totalScore!.toDouble()),
              ],
            ),
          ],

          // 💬 Tooltip de puntaje
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) {
                return spots.map((e) {
                  final score = e.y.toInt();
                  return LineTooltipItem(
                    "$score",
                    GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: getPhqColor(score),
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}
