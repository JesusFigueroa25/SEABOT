import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seabot/core/app_colors.dart';
import 'package:seabot/models/user.dart';
import 'package:seabot/services/user_service.dart';

class AdminMetricsScreen extends StatefulWidget {
  const AdminMetricsScreen({super.key});

  @override
  State<AdminMetricsScreen> createState() => _AdminMetricsScreenState();
}

class _AdminMetricsScreenState extends State<AdminMetricsScreen> {
  final UserService serviceController = UserService();
  late Future<Metricas> resultados;

  @override
  void initState() {
    super.initState();
    resultados = serviceController.getMetricas();
  }

  @override
  Widget build(BuildContext context) {
    // 🌞 Forzar modo claro con tipografía global Manrope
    final lightTheme = ThemeData.light().copyWith(
      scaffoldBackgroundColor: const Color(0xFFF8FAFD),
      textTheme: GoogleFonts.manropeTextTheme(ThemeData.light().textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.manrope(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      cardColor: Colors.white,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secundary,
      ),
    );

    return Theme(
      data: lightTheme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Métricas del Sistema"),
          centerTitle: true,
        ),
        body: SafeArea(
          child: FutureBuilder<Metricas>(
            future: resultados,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              } else if (!snapshot.hasData) {
                return const Center(
                  child: Text(
                    "❌ No se pudieron cargar las métricas.",
                    style: TextStyle(fontSize: 18, color: Colors.red),
                  ),
                );
              }

              final data = snapshot.data!;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // 🔹 Indicadores rápidos
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatCard("Usuarios", data.usuarios, AppColors.primary),
                        _buildStatCard("Chats activos", data.conversaciones, AppColors.secundary),
                        _buildStatCard("Recursos", data.recursos, Colors.deepPurple),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // 🔹 Gráfico de barras
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Distribución General",
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 200,
                              child: _BarChart(
                                totalUsuarios: data.usuarios,
                                conversacionesActivas: data.conversaciones,
                                recursosUsados: data.recursos,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // 🔹 Gráfico circular
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Porcentaje de Uso",
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 200,
                              child: PieChart(
                                PieChartData(
                                  sections: [
                                    PieChartSectionData(
                                      value: data.usuarios.toDouble(),
                                      color: AppColors.primary,
                                      title: "Usuarios",
                                      titleStyle: GoogleFonts.manrope(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    PieChartSectionData(
                                      value: data.conversaciones.toDouble(),
                                      color: AppColors.secundary,
                                      title: "Chats",
                                      titleStyle: GoogleFonts.manrope(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    PieChartSectionData(
                                      value: data.recursos.toDouble(),
                                      color: Colors.deepPurple,
                                      title: "Recursos",
                                      titleStyle: GoogleFonts.manrope(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 40,
                                  borderData: FlBorderData(show: false),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, int value, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Container(
        padding: const EdgeInsets.all(12),
        width: 100,
        child: Column(
          children: [
            Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "$value",
              style: GoogleFonts.manrope(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🔹 Gráfico de barras con tipografía Manrope
class _BarChart extends StatelessWidget {
  final int totalUsuarios;
  final int conversacionesActivas;
  final int recursosUsados;

  const _BarChart({
    Key? key,
    required this.totalUsuarios,
    required this.conversacionesActivas,
    required this.recursosUsados,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        backgroundColor: Colors.white,
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(toY: totalUsuarios.toDouble(), color: AppColors.primary, width: 18),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(toY: conversacionesActivas.toDouble(), color: AppColors.secundary, width: 18),
            ],
          ),
          BarChartGroupData(
            x: 2,
            barRods: [
              BarChartRodData(toY: recursosUsados.toDouble(), color: Colors.deepPurple, width: 18),
            ],
          ),
        ],
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 28),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final labelStyle = GoogleFonts.manrope(
                  fontSize: 12,
                  color: Colors.black87,
                );
                switch (value.toInt()) {
                  case 0:
                    return Text("Usuarios", style: labelStyle);
                  case 1:
                    return Text("Chats", style: labelStyle);
                  case 2:
                    return Text("Recursos", style: labelStyle);
                  default:
                    return const Text("");
                }
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: Colors.grey.shade300, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}
