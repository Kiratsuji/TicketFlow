import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/welcomeScreen.dart';
import 'screens/colors/appColors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase não configurado para esta plataforma: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TicketFlow',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.bgColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryColor,
          secondary: AppColors.secondaryColor,
          surface: AppColors.surfaceColor,
        ),
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: AppColors.primaryTextColor,
          displayColor: AppColors.primaryTextColor,
        ),
      ),
      home: const WelcomeScreen(),
    );
  }
}