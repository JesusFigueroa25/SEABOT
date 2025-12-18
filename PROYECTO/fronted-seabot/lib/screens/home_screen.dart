import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seabot/core/app_data.dart';
import 'package:seabot/repositories/student_repository.dart';
import 'package:seabot/screens/DiaryScreen.dart';
import 'package:seabot/screens/EmotionalQuickLogScreen.dart';
import 'package:seabot/screens/EvolutionScreen.dart';
import 'package:seabot/screens/ProfileScreen.dart';
import 'package:seabot/screens/SettingsScreen.dart';
import 'package:seabot/screens/TestPHQ9Screen.dart';
import 'package:seabot/screens/conversations_screen.dart';
import 'package:seabot/screens/resources_educational_screen.dart';
import 'package:seabot/screens/resourceshealthy.dart';
import 'package:seabot/core/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:seabot/services/phq_result_service.dart';
import 'package:seabot/services/student_service.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int studentID = AppData.studentID;
  StudentRepository repository = StudentRepository();
  bool isConnected = false;
  late StreamSubscription<List<ConnectivityResult>> _subscription;
  int _selectedIndex = 0;

  /// 👇 NUEVO: estado para mostrar/ocultar frases motivacionales
  bool _showMotivational = true;

  int? lastScore;
  PhqResultService phqservice = PhqResultService();

  bool _showBigMotivationalCard = true;
  String dailyPhrase = "";
  DateTime? lastShown;

  @override
  void initState() {
    super.initState();
    _checkConnection();
    _loadResult();
    _loadLastPHQ();
    _loadDailyPhrase();

    _subscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) async {
      final result = results.isNotEmpty
          ? results.first
          : ConnectivityResult.none;
      bool connected = result != ConnectivityResult.none;
      if (mounted) setState(() => isConnected = connected);
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
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
        "color": Colors.yellow.shade700,
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

  final List<String> motivationalPhrases = [
    "Cada día es una nueva oportunidad para crecer 🌱",
    "Eres más fuerte de lo que piensas 💪",
    "Un paso a la vez sigue siendo progreso 🧩",
    "Hoy mereces paz, claridad y amor propio ✨",
    "Respira, suelta y sigue avanzando. Estoy contigo 💙",

    // --- NUEVAS ---
    "Lo estás haciendo mejor de lo que crees 💫",
    "Sé amable contigo mismo, estás aprendiendo 💛",
    "Tu bienestar es importante, no lo olvides 🌼",
    "Permítete descansar. Es parte del progreso 💤✨",
    "Todo a su tiempo. No te compares con nadie 🌿",
    "Respira profundo… estás aquí, estás a salvo 🌬️💙",
    "No necesitas tener todo resuelto hoy 🌙",
    "Confía en tu proceso, va a dar frutos 🍃",
    "Eres valioso simplemente por existir ⭐",
    "Hoy intenta hablarte con cariño 💕",
    "Has sobrevivido a tus peores días. Eso dice mucho de ti 🌟",
    "Haz lo que puedas con lo que tienes hoy 🤍",
    "Date permiso de empezar de nuevo 🌺",
    "Hoy elige un pensamiento que te haga bien ✨",
    "Tu paz es prioridad 🕊️",
    "No te rindas, tu yo del futuro te agradecerá 🌄",
    "Por favor, sé paciente contigo 💛",
    "Todo pasa, incluso esto 🌤️",
    "La calma llega cuando dejas de presionarte tanto 🌾",
    "Tú mereces descanso y momentos bonitos 🌸",
    "Hoy es un buen día para intentarlo otra vez ☀️",
    "Pequeños pasos también construyen grandes destinos 🧭",
    "Eres más querido de lo que imaginas 💞",
    "No te castigues por sentirte así. Es humano 🤍",
    "El progreso no siempre es visible, pero existe 🌱",
    "Hoy concéntrate en lo que sí puedes controlar ✨",
    "No estás solo; siempre hay alguien que te aprecia 💙",
    "Hoy mira tu vida con un poco más de ternura 🧸",
    "Permítete sentir. Tus emociones también hablan 🌧️➡️🌈",
    "Abrázate fuerte: lo estás intentando mucho 🤗",
    "Celebra tus pequeñas victorias 🎉",
    "Haz de hoy un día más suave contigo 🌼",
    "Busca lo que te hace bien y ve hacia allí 🚶💚",
    "A veces descansar es lo más productivo 🌙",
    "Eres capaz de superar esto, aunque no lo sientas ahora 🤍",
    "Una mente tranquila es más poderosa que una ocupada 🌌",
    "Hoy respira y vuelve a intentarlo 🌬️✨",
    "Tu esfuerzo vale más que el resultado 💛",
    "No necesitas ser perfecto para ser increíble 🌟",
    "Hablar de lo que sientes también es valentía 🗣️🤍",
    "Haz espacio para lo que te hace feliz 🌻",
    "Nadie espera que lo hagas todo tú solo 🍃",
    "Rodéate de lo que te aporta luz ☀️",
    "Lo que sientes importa, y tú también 🤎",
    "Eres un ser humano en construcción, no un proyecto terminado 🧱",
    "Hoy elige paz, aunque sea poquito 🕊️",
    "Lo que hoy es difícil, mañana será aprendizaje 📘",
    "Tu historia no termina aquí, aún quedan capítulos hermosos 📖✨",
    "Descansar también es avanzar 💤➡️🌱",
    "Lo que haces con amor siempre tiene valor 💙",
    "Tu sensibilidad es una fortaleza, no una debilidad 🌷",
    "Confía en que poco a poco todo mejora 🌄",
    "No necesitas resolver tu vida en un día 🌤️",
    "Sé paciente con tus tiempos, estás creciendo 🌱",
    "No dejes que un mal momento te haga olvidar tu valor 💎",
    "Hoy mereces un momento de calma 🌙",
    "Eres suficiente, más que suficiente ✨",
    "Sonríe un poquito, aunque sea solo por ti 😊",
    "Suelta lo que no puedes controlar… y respira 🌬️",
    "Hoy agradece algo pequeñito 🌼",
    "No eres una carga; eres un ser humano con emociones 🤍",
    "Tienes derecho a pedir ayuda ✋💛",
    "Tu vida también tiene espacio para cosas bonitas 🙂‍↕️",
    "Hoy pon tu mano en el corazón… siente la vida latiendo 💓",
    "Vales muchísimo, aunque a veces no lo sientas ⭐",
    "Cada día que sigues aquí es un acto de amor propio 💙",
    "Mereces sentirte bien contigo ✨",
    "Eres resiliente, aunque no lo notes 🌿",
    "Todo florece cuando lo tratas con ternura 🌺",
    "Que hoy encuentres un motivo para sonreír 🙂",
    "Lo que hoy duele, mañana será más liviano 🌤️",
    "Agradece tu propio esfuerzo, eres tu mejor aliado 🤝",
    "Guarda energía para lo que te hace bien 🌙",
    "No exijas tanto de ti mismo, estás haciendo lo mejor que puedes 💛",
    "Respira. No todo tiene que resolverse ahora 🌬️",
    "A veces avanzar es simplemente no rendirse 🌱",
    "Tú mereces amor, descanso y comprensión 💙",
    "Hoy busca paz, aunque sea por cinco minutos 🕊️",
    "Eres más importante de lo que crees 💫",
    "Tu corazón también necesita tiempo para sanar 💛",
    "Escucha tu cuerpo, él te habla 🧘",
    "No es debilidad sentir: es humanidad 🤍",
    "Sé tu propio refugio cuando el mundo se sienta pesado 🏡",
    "Tu bienestar emocional también es un logro 🌷",
    "La vida no pide perfección, solo sinceridad 💙",
    "Lo estás intentando, y eso es valioso 🎖️",
    "Hoy date un abrazo mental 🤗",
    "Puedes empezar de nuevo las veces que lo necesites 🌄",
    "Suelta la culpa, abraza tu proceso 💫",
    "La versión de ti del futuro estará orgullosa 😌",
    "Eres un milagro en movimiento 🌌",
    "Tus emociones no te definen; solo te acompañan 💛",
    "Permítete sentirte orgulloso por seguir adelante 😎",
    "Hoy intenta hacer algo que te haga feliz 🎨",
    "Trátate con la misma dulzura que tratas a otros 🧁",
    "Mereces calma más que presión 🕊️",
    "Confía: lo que hoy parece caótico, mañana tendrá sentido 🌤️",
    "Tu sonrisa tiene poder, aunque no lo notes 😊",
    "Hoy elige cuidarte como mereces 💙",
    "La vida también es suave, no solo dura ✨",
    "Lo mejor aún está por venir 🌅",
    "Sigue adelante, pero sin lastimarte 🌿",
  ];

  Future<void> _loadDailyPhrase() async {
    // Si ya hubo frase antes, espera mínimo 3 minutos para cambiar
    if (lastShown != null) {
      final difference = DateTime.now().difference(lastShown!);
      if (difference.inMinutes < 3) {
        return; // No cambiar frase todavía
      }
    }

    final randomIndex =
        DateTime.now().millisecondsSinceEpoch % motivationalPhrases.length;

    setState(() {
      dailyPhrase = motivationalPhrases[randomIndex];
      _showBigMotivationalCard = true;
      lastShown = DateTime.now();
    });
  }

  void _showInterpretationModal(BuildContext context, int score) {
    final data = getPhqInterpretation(score);

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              Icon(Icons.favorite_rounded, color: AppColors.accent),
              Text(
                "Interpretación PHQ-9",
                style: GoogleFonts.manrope(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDarkText,
                ),
              ),
            ],
          ),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Tu último resultado: $score",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDarkText,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "${data['label']} ${data['emoji']}",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: data['color'],
                ),
              ),
              SizedBox(height: 12),
              Text("Rango: ${data['range']}", style: TextStyle(fontSize: 15)),
              SizedBox(height: 10),
              Text(
                "Si obtuviste un puntaje dentro de este rango, significa que tu nivel de depresión es: ${data['label']}.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cerrar"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadResult() async {
    bool online = await hasInternet();
    setState(() {
      repository.fetchAndSyncStudent(studentID, online);
    });
  }

  Future<void> _loadLastPHQ() async {
    final list = await phqservice.getLast8ByStudent(studentID);
    if (mounted) {
      setState(() {
        lastScore = list.isNotEmpty ? list.first.totalScore : null;
      });
    }
  }

  Future<bool> hasInternet() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) return false;
    try {
      final result = await InternetAddress.lookup('platform.openai.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<void> _checkConnection() async {
    final hasNet = await hasInternet();
    if (mounted) setState(() => isConnected = hasNet);

    if (!hasNet) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          content: Row(
            children: [
              const Icon(Icons.wifi_off, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "No tienes conexión a internet",
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<Widget> _screens = [
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
        ),
        child: Scaffold(
          body: Stack(
            children: [
              SafeArea(child: _screens[_selectedIndex]),

              // ⭐ Tarjeta Motivacional
              if (_showBigMotivationalCard) _buildBigMotivationalCard(),
            ],
          ),
          bottomNavigationBar: _buildCustomNavBar(isDark, theme),
        ),
      ),
    );
  }

  Widget _buildBigMotivationalCard() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black.withOpacity(0.45), // Fondo oscuro
      child: Center(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // TARJETA
            Container(
              width: 300,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.cardLight,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                dailyPhrase,
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDarkText,
                ),
              ),
            ),

            // ❌ BOTÓN DE CERRAR FUERA DE LA TARJETA
            Positioned(
              top: -12,
              right: -12,
              child: GestureDetector(
                onTap: () {
                  setState(() => _showBigMotivationalCard = false);
                },
                child: Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(Icons.close, size: 20, color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🌊 Nuevo Bottom Navigation Bar
  Widget _buildCustomNavBar(bool isDark, ThemeData theme) {
    // 🔹 Obtenemos el padding del sistema (para gestos o botones)
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 8), // 🔹 margen visual uniforme
      child: Container(
        height: 80, // 🔹 altura adaptable
        padding: EdgeInsets.only(bottom: 0), // 🔹 siempre deja un espacio extra
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E1E1E)
              : theme.scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, -2),
            ),
          ],
          border: Border(
            top: BorderSide(color: Colors.grey.withOpacity(0.2), width: 0.8),
          ),
        ),
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              top: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    icon: Icons.home_rounded,
                    label: "Inicio",
                    index: 0,
                    isSelected: _selectedIndex == 0,
                  ),
                  const SizedBox(width: 80),
                  _buildNavItem(
                    icon: Icons.settings_rounded,
                    label: "Ajustes",
                    index: 2,
                    isSelected: _selectedIndex == 2,
                  ),
                ],
              ),
            ),

            // 💬 Botón flotante "Chat"
            Positioned(
              top: -36,
              child: GestureDetector(
                onTap: () => _onItemTapped(1),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: _selectedIndex == 1
                              ? AppColors.secundaryStart
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.asset(
                          "assets/images/SeaBot.png",
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Chat",
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _selectedIndex == 1
                            ? AppColors.secundaryStart
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

  // 🔹 Item helper para Inicio y Ajustes
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.secundaryStart : Colors.grey,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: isSelected ? AppColors.secundaryStart : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridAroundHeart(ThemeData theme, bool isDark) {
    final items = [
      {
        "icon": Icons.self_improvement_rounded,
        "title": "Recursos de Ayuda",
        "screen": const ResourcesScreen(),
      },
      {
        "icon": Icons.article_rounded,
        "title": "Test PHQ-9",
        "screen": const TestPHQ9Screen(),
      },
      {
        "icon": Icons.insights_rounded,
        "title": "Evolución \n Emocional ",
        "screen": const EvolutionScreen(),
      },
      {
        "icon": Icons.fingerprint_rounded,
        "title": "Registro Rapido Diario",
        "screen": const EmotionalQuickLogScreen(),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 40,
        crossAxisSpacing: 40,
      ),
      itemCount: items.length,
      itemBuilder: (_, index) {
        final item = items[index];
        return InkWell(
          onTap: () => _navigate(context, item["screen"] as Widget),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  item["icon"] as IconData,
                  size: 40,
                  color: isDark
                      ? AppColors.secondaryDark
                      : AppColors.primaryDarkText,
                ),
                SizedBox(height: 10),
                Text(
                  item["title"] as String,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textDark : AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 🌿 Pantalla principal
  Widget _buildHomeBody(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isDark),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Herramientas de Bienestar ",
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // LOS 4 BOTONES DEL GRID
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: _buildGridAroundHeart(theme, isDark),
                    ),

                    // ❤️ BOTÓN CENTRAL
                    Positioned(child: _buildHeartButton()),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secundary],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 16,
            top: 16,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              child: CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white.withOpacity(0.95),
                child: const Icon(Icons.person, color: AppColors.secundary),
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "\n Hola, ¿cómo te sientes hoy?",
                  style: GoogleFonts.manrope(
                    color: Colors.black54,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Estoy aquí para ayudarte 🤗😎",
                  style: GoogleFonts.manrope(
                    color: Colors.black54,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeartButton() {
    return GestureDetector(
      onTap: () {
        if (lastScore == null) {
          _showNoScoreModal(context);
        } else {
          _showInterpretationModal(context, lastScore!);
        }
      },
      child: Container(
        width: 95,
        height: 95,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.secundary,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Icon(Icons.favorite_rounded, color: AppColors.white, size: 50),
        ),
      ),
    );
  }

  void _showNoScoreModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Sin resultados"),
        content: Text(
          "Aún no has realizado un Test PHQ-9.\n\nPor favor realiza uno para ver tu interpretación.",
          style: GoogleFonts.manrope(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cerrar"),
          ),
        ],
      ),
    );
  }

  Widget _buildWellnessGrid(ThemeData theme, bool isDark) {
    final items = [
      //{
      //  "icon": Icons.favorite_rounded,
      //  "title": "Indicaciones",
      //  "action": "heart",
      //},
      {
        "icon": Icons.self_improvement_rounded,
        "title": "Recursos de Ayuda",
        "screen": const ResourcesScreen(),
      },
      {
        "icon": Icons.article_rounded,
        "title": "Test PHQ-9",
        "screen": const TestPHQ9Screen(),
      },
      {
        "icon": Icons.insights_rounded,
        "title": "Evolución Emocional",
        "screen": const EvolutionScreen(),
      },
      {
        "icon": Icons.fingerprint_rounded,
        "title": "Registro Emocional Rápido",
        "screen": const EmotionalQuickLogScreen(),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.05,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return InkWell(
          borderRadius: BorderRadius.circular(20),

          onTap: () {
            if (item["action"] == "heart") {
              if (lastScore == null) {
                _showNoScoreModal(context); // ⚠ Modal especial
              } else {
                _showInterpretationModal(context, lastScore!);
              }
              return;
            }

            if (item["screen"] != null) {
              _navigate(context, item["screen"] as Widget);
            }
          },

          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  item["icon"] as IconData,
                  size: 40,
                  color: isDark
                      ? AppColors.secondaryDark
                      : AppColors.primaryDarkText,
                ),
                const SizedBox(height: 10),
                Text(
                  item["title"] as String,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textDark : AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFraseMini(String label, Color color) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            height: 1.3,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  void _navigate(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    ).then((_) => _checkConnection());
  }
}
