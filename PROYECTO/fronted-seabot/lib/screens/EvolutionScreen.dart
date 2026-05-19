import 'dart:io';
import 'dart:ui';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:seabot/core/app_colors.dart';
import 'package:seabot/core/app_data.dart';
import 'package:seabot/models/phq_result.dart';
import 'package:seabot/repositories/phq_results_repository.dart';

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

  String? selectedMonth;
  int? selectedDay;
  PhqResult? selectedResult;

  @override
  void initState() {
    super.initState();
    resultados = Future.value([]);
    _loadResults();
  }

  Future<void> _loadResults() async {
    bool online = await _hasInternet();
    if (!mounted) return;
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

  Color getPhqColor(int score) {
    if (score <= 4) return AppColors.secundary.withOpacity(0.40);
    if (score <= 9) return AppColors.secundary;
    if (score <= 14) return AppColors.secundaryStart;
    if (score <= 19) return AppColors.primary;
    return AppColors.accent;
  }

  String getPhqLabel(int score) {
    if (score <= 4) return "Mínimo";
    if (score <= 9) return "Leve";
    if (score <= 14) return "Moderado";
    if (score <= 19) return "Moderadamente severo";
    return "Severo";
  }

  double _averageScore(List<PhqResult> results) {
    if (results.isEmpty) return 0;
    final sum = results.fold<int>(0, (acc, r) => acc + (r.totalScore ?? 0));
    return sum / results.length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Theme(
      data: theme.copyWith(
        textTheme: GoogleFonts.manropeTextTheme(theme.textTheme),
      ),
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF0F1115)
            : const Color(0xFFF6F8FB),
        body: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            const Color(0xFF0F1115),
                            const Color(0xFF151A22),
                            const Color(0xFF0F1115),
                          ]
                        : [
                            const Color(0xFFF6F8FB),
                            const Color(0xFFF9FBFD),
                            const Color(0xFFF3F6FA),
                          ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              top: -70,
              right: -30,
              child: _buildBlurOrb(
                size: 220,
                color: AppColors.primary.withOpacity(isDark ? 0.14 : 0.16),
              ),
            ),
            Positioned(
              top: 220,
              left: -70,
              child: _buildBlurOrb(
                size: 180,
                color: AppColors.secundary.withOpacity(isDark ? 0.10 : 0.12),
              ),
            ),
            SafeArea(
              child: FutureBuilder<List<PhqResult>>(
                future: resultados,
                builder: (context, snapshot) {
                  return Column(
                    children: [
                      _buildHeaderPremium(
                        title: "Evolución Emocional",
                        subtitle: "Visualiza tu progreso en el tiempo",
                      ),
                      Expanded(child: _buildBody(snapshot, isDark)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AsyncSnapshot<List<PhqResult>> snapshot, bool isDark) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF171C24)
                : Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const CircularProgressIndicator(),
        ),
      );
    }

    if (snapshot.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF171C24)
                  : Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.04)
                    : Colors.black.withOpacity(0.04),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.redAccent,
                  size: 42,
                ),
                const SizedBox(height: 12),
                Text(
                  "Ocurrió un error al cargar la evolución emocional.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF18202A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 13.5,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!snapshot.hasData || snapshot.data!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF171C24)
                  : Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.04)
                    : Colors.black.withOpacity(0.04),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.20 : 0.06),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.insights_rounded,
                    color: AppColors.primary,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "No hay datos aún",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF18202A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Realiza primero un test PHQ-9 para visualizar tu evolución emocional.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    height: 1.5,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final results = List<PhqResult>.from(snapshot.data!)
      ..sort((a, b) => a.fecha.compareTo(b.fecha));

    _initializeCalendarSelection(results);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
            child: Column(
              children: [
                _buildSummaryCards(results, isDark),
                const SizedBox(height: 18),
                _buildViewButtons(isDark),
                const SizedBox(height: 18),
                SizedBox(
                  height: 460,
                  child: _buildCurrentView(results, isDark),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _initializeCalendarSelection(List<PhqResult> results) {
    Map<String, List<PhqResult>> grouped = {};
    for (var r in results) {
      final key = "${r.fecha.year}-${r.fecha.month}";
      grouped.putIfAbsent(key, () => []).add(r);
    }

    final months = grouped.keys.toList();
    if (months.isNotEmpty && selectedMonth == null) {
      selectedMonth = months.last;
    }
  }

  Widget _buildCurrentView(List<PhqResult> results, bool isDark) {
    switch (currentView) {
      case EvolutionViewType.list:
        return _buildListView(results, isDark);
      case EvolutionViewType.calendar:
        return _buildCalendarView(results, isDark);
      case EvolutionViewType.chart:
        return _buildChartView(results, isDark);
    }
  }

  Widget _buildViewButtons(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF171C24)
            : Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.04)
              : Colors.black.withOpacity(0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.20 : 0.06),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _viewButton(
              icon: Icons.view_list_rounded,
              label: "Lista",
              view: EvolutionViewType.list,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _viewButton(
              icon: Icons.calendar_month_rounded,
              label: "Mes",
              view: EvolutionViewType.calendar,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _viewButton(
              icon: Icons.show_chart_rounded,
              label: "Gráfica",
              view: EvolutionViewType.chart,
            ),
          ),
        ],
      ),
    );
  }

  Widget _viewButton({
    required IconData icon,
    required String label,
    required EvolutionViewType view,
  }) {
    bool selected = currentView == view;

    return GestureDetector(
      onTap: () => setState(() => currentView = view),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.secundaryStart.withOpacity(0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.secundaryStart : Colors.transparent,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: selected ? AppColors.secundaryStart : Colors.grey.shade500,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: selected
                    ? AppColors.secundaryStart
                    : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(List<PhqResult> results, bool isDark) {
    final latest = results.last.totalScore ?? 0;
    final average = _averageScore(results).toStringAsFixed(1);
    final total = results.length;

    return Row(
      children: [
        Expanded(
          child: _buildMiniStatCard(
            isDark: isDark,
            title: "Último",
            value: latest.toString(),
            subtitle: getPhqLabel(latest),
            color: getPhqColor(latest),
            icon: Icons.favorite_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMiniStatCard(
            isDark: isDark,
            title: "Promedio",
            value: average,
            subtitle: "Puntaje medio",
            color: AppColors.primary,
            icon: Icons.analytics_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMiniStatCard(
            isDark: isDark,
            title: "Registros",
            value: total.toString(),
            subtitle: "Historial",
            color: AppColors.secundaryStart,
            icon: Icons.history_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStatCard({
    required bool isDark,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF171C24)
            : Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.04)
              : Colors.black.withOpacity(0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.20 : 0.06),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF18202A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              fontSize: 11.8,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white60 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List<PhqResult> results, bool isDark) {
    return ListView.builder(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: results.length,
      itemBuilder: (context, index) {
        final r = results.reversed.toList()[index];
        final score = r.totalScore ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF171C24)
                : Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.04)
                  : Colors.black.withOpacity(0.04),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.20 : 0.06),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: getPhqColor(score).withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text("🩹", style: TextStyle(fontSize: 26)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Puntaje: $score",
                      style: GoogleFonts.manrope(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      getPhqLabel(score),
                      style: GoogleFonts.manrope(
                        fontSize: 13.3,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: getPhqColor(score),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCalendarView(List<PhqResult> results, bool isDark) {
    Map<String, List<PhqResult>> grouped = {};
    for (var r in results) {
      final key = "${r.fecha.year}-${r.fecha.month}";
      grouped.putIfAbsent(key, () => []).add(r);
    }

    final months = grouped.keys.toList();
    final monthData = grouped[selectedMonth] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 52,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: months.length,
            itemBuilder: (_, index) {
              final m = months[index];
              bool active = m == selectedMonth;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedMonth = m;
                    selectedDay = null;
                    selectedResult = null;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.secundaryStart
                        : (isDark
                              ? Colors.white.withOpacity(0.06)
                              : Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      _formatMonth(m),
                      style: GoogleFonts.manrope(
                        color: active
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.black87),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // RESULTADO MÁS ARRIBA
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF171C24)
                : Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.04)
                  : Colors.black.withOpacity(0.04),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.16 : 0.05),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: selectedResult != null
              ? Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: getPhqColor(
                          selectedResult!.totalScore ?? 0,
                        ).withOpacity(0.16),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text("📅", style: TextStyle(fontSize: 20)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Resultado del día $selectedDay: ${selectedResult!.totalScore} ${getPhqLabel(selectedResult!.totalScore ?? 0)}",
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                          height: 1.35,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                )
              : Text(
                  "Selecciona un día del calendario para ver el resultado.",
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
        ),

        const SizedBox(height: 12),

        // CALENDARIO
        Expanded(
          child: GridView.count(
            shrinkWrap: true,
            crossAxisCount: 7,
            childAspectRatio: 1.0,
            physics: const ClampingScrollPhysics(),
            children: List.generate(31, (i) {
              final day = i + 1;
              final list = monthData.where((d) => d.fecha.day == day).toList();

              bool hasData = list.isNotEmpty;
              bool isSelected = selectedDay == day;

              return GestureDetector(
                onTap: () {
                  if (!hasData) return;
                  setState(() {
                    selectedDay = day;
                    selectedResult = list.first;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: hasData
                        ? getPhqColor(list.first.totalScore ?? 0)
                        : (isDark ? Colors.white12 : Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: getPhqColor(
                                list.first.totalScore ?? 0,
                              ).withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      "$day",
                      style: GoogleFonts.manrope(
                        color: hasData
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.black87),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
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

  Widget _buildChartView(List<PhqResult> results, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 18, 18, 18),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF171C24)
            : Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.04)
              : Colors.black.withOpacity(0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.20 : 0.06),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          minX: -0.3,
          maxX: (results.length - 1).toDouble() + 0.3,
          minY: 0,
          maxY: 27,
          gridData: FlGridData(
            show: true,
            horizontalInterval: 5,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Colors.grey.withOpacity(0.15), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 5,
                reservedSize: 34,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: GoogleFonts.manrope(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white60 : Colors.black45,
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              isCurved: false,
              color: AppColors.secundary,
              barWidth: 3,
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.secundary.withOpacity(0.10),
              ),
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
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              tooltipRoundedRadius: 14,
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              getTooltipItems: (spots) {
                return spots.map((e) {
                  final score = e.y.toInt();
                  return LineTooltipItem(
                    "$score • ${getPhqLabel(score)}",
                    GoogleFonts.manrope(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
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

  Widget _buildBlurOrb({required double size, required Color color}) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }

  Widget _buildHeaderPremium({
    required String title,
    String? subtitle,
    Future<bool> Function()? onWillPopCustom,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.secundary,
            AppColors.secundary.withOpacity(0.92),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 🔹 decoración
          Positioned(
            right: -18,
            top: -10,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -30,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),

          // 🔹 contenido
          Row(
            children: [
              // 🔥 BOTÓN BACK REUTILIZABLE
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    if (onWillPopCustom != null) {
                      final canLeave = await onWillPopCustom();
                      if (canLeave && mounted) Navigator.pop(context);
                    } else {
                      if (mounted) Navigator.pop(context);
                    }
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.24)),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        letterSpacing: -0.4,
                      ),
                    ),

                    if (subtitle != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        style: GoogleFonts.manrope(
                          color: Colors.white.withOpacity(0.92),
                          fontSize: 13.8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
