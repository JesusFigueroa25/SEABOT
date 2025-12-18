import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:seabot/screens/inicio_app_screen.dart';
import 'package:seabot/services/notification_service.dart';
import 'package:seabot/theme/theme_notifier.dart';
import 'package:seabot/core/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //await NotificationService.init();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const MainApp(),
    ),
  );
  Future.delayed(Duration.zero, () async {
    await NotificationService.init();
  });
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    final baseTextStyle = GoogleFonts.manropeTextTheme();

    return MaterialApp(
      navigatorKey: navigatorKey, // ✅ agrega esto

      debugShowCheckedModeBanner: false,
      title: 'SeaBot',

      // 🌞 Tema claro
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.backgroundLight,
        textTheme: baseTextStyle.apply(bodyColor: AppColors.textLight),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.primary,
          iconTheme: const IconThemeData(color: AppColors.white),
          titleTextStyle: GoogleFonts.manrope(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),

        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w600),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secundaryStart,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w600),
          ),
        ),
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.secundary,
        ),
        cardColor: AppColors.cardLight,
      ),

      // 🌙 Tema oscuro
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.backgroundDark,
        textTheme: baseTextStyle.apply(bodyColor: AppColors.textDark),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.primaryDark,
          iconTheme: const IconThemeData(color: AppColors.white),
          titleTextStyle: GoogleFonts.manrope(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),

        // 🎨 Bloque de estilos globales (modo oscuro)
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),

        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryDark,
            textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w600),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secundaryStart,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w600),
          ),
        ),

        colorScheme: const ColorScheme.dark(
          primary: AppColors.primaryDark,
          secondary: AppColors.secondaryDark,
        ),
        cardColor: AppColors.cardDark,
      ),

      // 🔄 Tema dinámico
      themeMode: themeNotifier.isDarkMode ? ThemeMode.dark : ThemeMode.light,

      home: const InicioAppScreen(),
    );
  }
}
