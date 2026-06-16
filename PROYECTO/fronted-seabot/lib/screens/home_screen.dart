import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seabot/core/app_colors.dart';
import 'package:seabot/core/app_data.dart';
import 'package:seabot/core/responsive_helper.dart';
import 'package:seabot/models/habit.dart';
import 'package:seabot/repositories/habits_repository.dart';
import 'package:seabot/repositories/student_repository.dart';
//import 'package:seabot/screens/DiaryScreen.dart';
import 'package:seabot/screens/EmotionalQuickLogScreen.dart';
import 'package:seabot/screens/EvolutionScreen.dart';
import 'package:seabot/screens/ProfileScreen.dart';
import 'package:seabot/screens/SettingsScreen.dart';
import 'package:seabot/screens/TestPHQ9Screen.dart';
import 'package:seabot/screens/conversations_screen.dart';
import 'package:seabot/screens/resourceshealthy.dart';
import 'package:seabot/services/phq_result_service.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final int studentID = AppData.studentID;
  final StudentRepository repository = StudentRepository();
  final PhqResultService phqservice = PhqResultService();
  final HabitsRepository habitsRepository = HabitsRepository();

  late StreamSubscription<List<ConnectivityResult>> _subscription;

  bool isConnected = false;
  bool _showBigMotivationalCard = false;
  bool _loadingHabits = false;

  int _selectedIndex = 0;
  int? lastScore;
  String dailyPhrase = "";
  DateTime? lastShown;
  List<Habit> _dailyHabits = [];

  final List<String> motivationalPhrases = [
    "Cada día es una nueva oportunidad para crecer 🌱",
    "Eres más fuerte de lo que piensas 💪",
    "Un paso a la vez sigue siendo progreso 🧩",
    "Hoy mereces paz, claridad y amor propio ✨",
    "Respira, suelta y sigue avanzando. Estoy contigo 💙",
    "Lo estás haciendo mejor de lo que crees 💫",
    "Tu paz es prioridad 🕊️",
    "No necesitas resolver tu vida en un día 🌤️",
    "Sé paciente con tus tiempos, estás creciendo 🌱",
    "Eres suficiente, más que suficiente ✨",
  ];

  @override
  void initState() {
    super.initState();

    _initHome();

    _subscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) async {
      final online = await hasInternet();

      if (!mounted) return;

      setState(() {
        isConnected = online;

        if (!online) {
          dailyPhrase = "";
          _showBigMotivationalCard = false;
        }
      });

      if (online) {
        await _loadDailyPhrase();
      }
    });
  }

  Future<void> _initHome() async {
    final online = await hasInternet();

    if (!mounted) return;

    setState(() {
      isConnected = online;

      if (!online) {
        dailyPhrase = "";
        _showBigMotivationalCard = false;
      }
    });

    await _loadResult();
    await _loadLastPHQ();
    await _loadDailyHabits();

    if (online) {
      await _loadDailyPhrase();
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  Future<void> _loadResult() async {
    final online = await hasInternet();
    await repository.fetchAndSyncStudent(studentID, online);
  }

  Future<void> _loadLastPHQ() async {
    final online = await hasInternet();

    if (!online) {
      if (!mounted) return;
      setState(() {
        lastScore = null;
      });
      return;
    }

    try {
      final list = await phqservice.getLast8ByStudent(studentID);

      if (!mounted) return;
      setState(() {
        lastScore = list.isNotEmpty ? list.first.totalScore : null;
      });
    } catch (e) {
      debugPrint("Error cargando último PHQ: $e");

      if (!mounted) return;
      setState(() {
        lastScore = null;
      });
    }
  }

  Future<void> _loadDailyHabits() async {
    final online = await hasInternet();
    if (mounted) {
      setState(() => _loadingHabits = true);
    }

    try {
      final habits = await habitsRepository.fetchAndSyncDailyHabits(
        studentID,
        online,
      );

      if (mounted) {
        setState(() => _dailyHabits = habits);
      }
    } catch (e) {
      debugPrint("Error cargando hábitos: $e");
    } finally {
      if (mounted) {
        setState(() => _loadingHabits = false);
      }
    }
  }

  Future<void> _toggleHabit(Habit habit, bool value) async {
    final previous = habit.completed;

    setState(() {
      habit.completed = value;
    });

    final online = await hasInternet();

    try {
      if (online) {
        await habitsRepository.apiService.toggleHabit(studentID, habit);
      }

      await habitsRepository.toggleHabitLocal(
        studentId: studentID,
        habit: habit,
      );
    } catch (e) {
      setState(() {
        habit.completed = previous;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Text(
            "No se pudo actualizar la tarea",
            style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
          ),
        ),
      );
    }
  }

  Future<void> _loadDailyPhrase() async {
    final online = await hasInternet();

    if (!online) {
      if (!mounted) return;

      setState(() {
        dailyPhrase = "";
        _showBigMotivationalCard = false;
      });

      return;
    }

    if (lastShown != null) {
      final difference = DateTime.now().difference(lastShown!);
      if (difference.inMinutes < 3) return;
    }

    final randomIndex =
        DateTime.now().millisecondsSinceEpoch % motivationalPhrases.length;

    if (!mounted) return;

    setState(() {
      dailyPhrase = motivationalPhrases[randomIndex];
      _showBigMotivationalCard = true;
      lastShown = DateTime.now();
    });
  }

  Future<bool> hasInternet() async {
    final connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult.contains(ConnectivityResult.none)) {
      return false;
    }

    try {
      final result = await InternetAddress.lookup(
        'seabot-backend-993787742289.us-central1.run.app',
      ).timeout(const Duration(seconds: 3));

      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    }
  }

/*  Future<void> _checkConnection() async {
    final hasNet = await hasInternet();
    if (mounted) setState(() => isConnected = hasNet);

    if (!hasNet && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFB3261E),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Row(
            children: [
              const Icon(Icons.wifi_off_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "No tienes conexión a internet",
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
*/

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  Map<String, dynamic> getPhqInterpretation(int score) {
    if (score <= 4) {
      return {
        "label": "Depresión mínima",
        "color": Colors.green,
        "emoji": "🟢",
        "range": "1 a 4",
      };
    }
    if (score <= 9) {
      return {
        "label": "Depresión leve",
        "color": Colors.amber.shade700,
        "emoji": "🟡",
        "range": "5 a 9",
      };
    }
    if (score <= 14) {
      return {
        "label": "Depresión moderada",
        "color": Colors.orange,
        "emoji": "🟠",
        "range": "10 a 14",
      };
    }
    if (score <= 19) {
      return {
        "label": "Depresión moderadamente severa",
        "color": Colors.red.shade400,
        "emoji": "🔴",
        "range": "15 a 19",
      };
    }

    return {
      "label": "Depresión severa",
      "color": Colors.red,
      "emoji": "🔴",
      "range": "20 a 27",
    };
  }

  void _showInterpretationModal(BuildContext context, int score) {
    final data = getPhqInterpretation(score);

    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.cardLight,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.secundary],
                    ),
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Interpretación PHQ-9",
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDarkText,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Tu último resultado: $score",
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "${data['label']} ${data['emoji']}",
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: data['color'],
                  ),
                ),
                const SizedBox(height: 10),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.secundary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      "Cerrar",
                      style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showNoScoreModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.cardLight,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline_rounded, size: 38),
              const SizedBox(height: 14),
              Text(
                "Sin resultados",
                style: GoogleFonts.manrope(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Aún no has realizado un Test PHQ-9.\n\nPor favor realiza uno para ver tu interpretación.",
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(fontSize: 14, height: 1.45),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secundary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    "Cerrar",
                    style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigate(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    //.then((_) => _checkConnection())
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final screens = [
      _buildHomeBody(theme, isDark),
      const ChatsScreen(),
      const SettingsScreen(),
    ];

    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('¿Deseas salir de la aplicación?'),
            content: const Text('Tu sesión seguirá activa.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Salir'),
              ),
            ],
          ),
        );

        if (shouldExit == true) {
          await SystemChannels.platform.invokeMethod('SystemNavigator.pop');
          return true;
        }
        return false;
      },
      child: Theme(
        data: theme.copyWith(
          textTheme: GoogleFonts.manropeTextTheme(theme.textTheme),
          scaffoldBackgroundColor: isDark
              ? const Color(0xFF0E1116)
              : const Color(0xFFF6F8FB),
        ),
        child: Scaffold(
          body: Stack(
            children: [
              SafeArea(child: screens[_selectedIndex]),
              if (_showBigMotivationalCard &&
                  isConnected &&
                  dailyPhrase.trim().isNotEmpty)
                _buildBigMotivationalCard(),
            ],
          ),
          bottomNavigationBar: ResponsiveHelper.centeredConstraint(
            context: context,
            maxTabletWidth: 600,
            child: _buildCustomNavBar(isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeBody(ThemeData theme, bool isDark) {
    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              _buildPremiumHeader(isDark),
              Transform.translate(
                offset: const Offset(0, -22),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: ResponsiveHelper.centeredConstraint(
                    context: context,
                    maxTabletWidth: 800,
                    child: Column(
                      children: [
                        _buildQuickStatusCard(isDark),
                        const SizedBox(height: 18),
                        _buildToolsSection(theme, isDark),
                        const SizedBox(height: 22),
                        _buildHabitsSection(isDark),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumHeader(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 38),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.secundary,
            AppColors.primary.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(34)),
      ),
      child: ResponsiveHelper.centeredConstraint(
        context: context,
        maxTabletWidth: 800,
        child: Column(
          children: [
            Row(
            children: [
              Expanded(child: _buildConnectionPill()),
              const SizedBox(width: 120),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.24),
                    border: Border.all(color: Colors.white.withOpacity(0.35)),
                  ),
                  child: const CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person_rounded,
                      color: AppColors.secundary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withOpacity(0.22)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hola, ¿cómo te sientes hoy?",
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Estoy aquí para acompañarte con herramientas, seguimiento y apoyo emocional.",
                      style: GoogleFonts.manrope(
                        color: Colors.white.withOpacity(0.92),
                        fontSize: 14.5,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildConnectionPill() {
    final connected = isConnected;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: connected ? AppColors.secundary : AppColors.accent,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.white.withOpacity(0.50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            connected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              connected ? "Conectado" : "Sin conexión",
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatusCard(bool isDark) {
    final hasResult = lastScore != null;
    final interpretation = hasResult ? getPhqInterpretation(lastScore!) : null;

    return _premiumCard(
      isDark: isDark,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (hasResult) {
                _showInterpretationModal(context, lastScore!);
              } else {
                _showNoScoreModal(context);
              }
            },
            child: AnimatedScale(
              scale: 1,
              duration: const Duration(milliseconds: 220),
              child: Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secundary],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.28),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Tu estado reciente",
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  hasResult
                      ? "${interpretation!['label']} ${interpretation['emoji']}"
                      : "Aún no tienes un resultado PHQ-9",
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  hasResult
                      ? "Toca el corazón para ver tu interpretación."
                      : "Realiza un test para visualizar tu interpretación.",
                  style: GoogleFonts.manrope(
                    fontSize: 12.5,
                    height: 1.35,
                    color: isDark ? Colors.white60 : Colors.black45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolsSection(ThemeData theme, bool isDark) {
    final items = [
      {
        "icon": Icons.self_improvement_rounded,
        "title": "Recursos de Bienestar",
        "subtitle": "Ejercicios ",
        "screen": const ResourcesScreen(),
      },
      {
        "icon": Icons.article_rounded,
        "title": "Conoce tu nivel de bienestar",
        "subtitle": "Evalúa tu estado",
        "screen": const TestPHQ9Screen(),
      },
      {
        "icon": Icons.insights_rounded,
        "title": "Evolución Emocional",
        "subtitle": "Mira tu progreso",
        "screen": const EvolutionScreen(),
      },
      {
        "icon": Icons.mood_rounded,
        "title": "¿Cómo te sientes hoy?",
        "subtitle": "Emoción del día",
        "screen": const EmotionalQuickLogScreen(),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Herramientas de bienestar",
          style: GoogleFonts.manrope(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF151922),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Accesos rápidos para cuidarte mejor cada día",
          style: GoogleFonts.manrope(
            fontSize: 13.5,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          itemCount: items.length,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: ResponsiveHelper.isTablet(context) ? 4 : 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: ResponsiveHelper.isTablet(context) ? 1.1 : 0.98,
          ),
          itemBuilder: (_, index) {
            final item = items[index];
            return InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => _navigate(context, item["screen"] as Widget),
              child: _premiumCard(
                isDark: isDark,
                radius: 24,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 70,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.16),
                            AppColors.secundary.withOpacity(0.28),
                          ],
                        ),
                      ),
                      child: Icon(
                        item["icon"] as IconData,
                        color: AppColors.secundary,
                        size: 40,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      item["title"] as String,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        color: isDark ? Colors.white : const Color(0xFF151922),
                      ),
                    ),
                    const SizedBox(height: 6),
                    //Text(
                    //  item["subtitle"] as String,
                    //  style: GoogleFonts.manrope(
                    //    fontSize: 12.5,
                    //    color: isDark ? Colors.white60 : Colors.black54,
                    //  ),
                    //),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHabitsSection(bool isDark) {
    final completedCount = _dailyHabits.where((h) => h.completed).length;
    final progress = _dailyHabits.isEmpty
        ? 0.0
        : completedCount / _dailyHabits.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Hábitos de bienestar",
          style: GoogleFonts.manrope(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF151922),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _dailyHabits.isEmpty
              ? "No hay tareas para hoy"
              : "$completedCount de ${_dailyHabits.length} completados hoy",
          style: GoogleFonts.manrope(
            fontSize: 13.5,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
        const SizedBox(height: 14),
        _premiumCard(
          isDark: isDark,
          radius: 24,
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        backgroundColor: isDark
                            ? Colors.white12
                            : const Color(0xFFE9EEF5),
                        valueColor: AlwaysStoppedAnimation(AppColors.secundary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "${(progress * 100).round()}%",
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (_loadingHabits)
                const Padding(
                  padding: EdgeInsets.all(10),
                  child: CircularProgressIndicator(),
                )
              else if (_dailyHabits.isEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "No hay tareas de bienestar para hoy.",
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                )
              else
                ..._dailyHabits.map((habit) => _buildHabitTile(habit, isDark)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHabitTile(Habit habit, bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: habit.completed
            ? AppColors.secundary.withOpacity(isDark ? 0.12 : 0.10)
            : (isDark
                  ? Colors.white.withOpacity(0.03)
                  : const Color(0xFFF8FAFD)),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: habit.completed
              ? AppColors.secundary.withOpacity(0.30)
              : (isDark ? Colors.white10 : const Color(0xFFE8EDF5)),
        ),
      ),
      child: CheckboxListTile(
        value: habit.completed,
        onChanged: (value) {
          if (value != null) {
            _toggleHabit(habit, value);
          }
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        activeColor: AppColors.secundary,
        checkboxShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        controlAffinity: ListTileControlAffinity.leading,
        title: Text(
          habit.nameHabit,
          style: GoogleFonts.manrope(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF151922),
            decoration: habit.completed
                ? TextDecoration.lineThrough
                : TextDecoration.none,
          ),
        ),
        subtitle: habit.description != null && habit.description!.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  habit.description!,
                  style: GoogleFonts.manrope(
                    fontSize: 12.5,
                    height: 1.35,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _premiumCard({
    required bool isDark,
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    double radius = 22,
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171C24) : Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : const Color(0xFFE8EDF5),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.18)
                : const Color(0x0D10233F),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildBigMotivationalCard() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() => _showBigMotivationalCard = false);
      },
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black.withOpacity(0.45),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GestureDetector(
              onTap: () {}, // Evita que se cierre al tocar dentro del card
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 28,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 62,
                              height: 62,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.secundary,
                                  ],
                                ),
                              ),
                              child: const Icon(
                                Icons.auto_awesome_rounded,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              "Mensaje para ti",
                              style: GoogleFonts.manrope(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDarkText,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              dailyPhrase,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.manrope(
                                fontSize: 17,
                                height: 1.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryDarkText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: -10,
                    right: -6,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() => _showBigMotivationalCard = false);
                        },
                        borderRadius: BorderRadius.circular(100),
                        child: Ink(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.14),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.close_rounded, size: 20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomNavBar(bool isDark) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 8),
      child: Container(
        height: 86,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF171C24) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isDark ? Colors.white10 : const Color(0xFFE7ECF4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    icon: Icons.home_rounded,
                    label: "Inicio",
                    index: 0,
                    isSelected: _selectedIndex == 0,
                  ),
                  const SizedBox(width: 86),
                  _buildNavItem(
                    icon: Icons.settings_rounded,
                    label: "Ajustes",
                    index: 2,
                    isSelected: _selectedIndex == 2,
                  ),
                ],
              ),
            ),
            Positioned(
              top: -18,
              child: GestureDetector(
                onTap: () => _onItemTapped(1),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: _selectedIndex == 1
                              ? AppColors.secundary
                              : const Color(0xFFE6EBF3),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.14),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.5),
                        child: Image.asset(
                          "assets/images/SeaBot.png",
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Chat",
                      style: GoogleFonts.manrope(
                        fontSize: 12.8,
                        fontWeight: FontWeight.w800,
                        color: _selectedIndex == 1
                            ? AppColors.secundary
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    final color = isSelected ? AppColors.secundary : Colors.grey;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.secundary.withOpacity(0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
