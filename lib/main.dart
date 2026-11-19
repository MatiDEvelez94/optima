import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/splash_screen.dart';
import 'theme/app_colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: AppColors.navy,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const OptimaApp());
}

class OptimaApp extends StatelessWidget {
  const OptimaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Óptima',
      debugShowCheckedModeBanner: false,
      // Idioma: español de Argentina (calendario y fechas en dia/mes/año)
      locale: const Locale('es', 'AR'),
      supportedLocales: const [Locale('es', 'AR'), Locale('es')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.cream,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.navy),
        datePickerTheme: _calendarioTema,
      ),
      home: const SplashScreen(),
    );
  }
}

// Colores del calendario: los de la app (azul y crema)
final DatePickerThemeData _calendarioTema = DatePickerThemeData(
  backgroundColor: AppColors.cream,
  surfaceTintColor: Colors.transparent,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  headerBackgroundColor: AppColors.navy,
  headerForegroundColor: AppColors.cream,
  // Dia elegido: circulo azul con el numero en crema
  dayBackgroundColor: WidgetStateProperty.resolveWith<Color?>((estados) {
    if (estados.contains(WidgetState.selected)) return AppColors.navy;
    return null;
  }),
  dayForegroundColor: WidgetStateProperty.resolveWith<Color?>((estados) {
    if (estados.contains(WidgetState.selected)) return AppColors.cream;
    if (estados.contains(WidgetState.disabled)) return const Color(0xFFB5B5B5);
    return AppColors.navy;
  }),
  // Hoy: circulo azul clarito con borde azul
  todayBackgroundColor: WidgetStateProperty.resolveWith<Color?>((estados) {
    if (estados.contains(WidgetState.selected)) return AppColors.navy;
    return const Color(0xFFDCE4F0);
  }),
  todayForegroundColor: WidgetStateProperty.resolveWith<Color?>((estados) {
    if (estados.contains(WidgetState.selected)) return AppColors.cream;
    return AppColors.navy;
  }),
  todayBorder: const BorderSide(color: AppColors.navy),
  cancelButtonStyle: TextButton.styleFrom(foregroundColor: AppColors.navy),
  confirmButtonStyle: TextButton.styleFrom(foregroundColor: AppColors.navy),
);