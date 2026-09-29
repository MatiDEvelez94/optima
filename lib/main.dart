import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/login_screen.dart';
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
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.cream,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.navy),
      ),
      home: const LoginScreen(),
    );
  }
}