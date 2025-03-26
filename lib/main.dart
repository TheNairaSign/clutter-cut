import 'package:clutter_cut/pages/start_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        primarySwatch: Colors.indigo,
        brightness: Brightness.light,
        cardColor: Colors.white,
        colorScheme: ColorScheme.light(
          primary: const Color(0xFF3B82F6),
          primaryContainer: const Color(0xFFEFF6FF),
          secondary: Color.fromARGB(255, 95, 234, 118),
          secondaryContainer: const Color(0xFFE6FFFA),
          error: const Color(0xFFEF4444),
          surface: Colors.white,
          background: const Color(0xFFF5F7FA),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onError: Colors.white,
          onSurface: const Color(0xFF1F2A44),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFF1F2A44)),
          bodySmall: TextStyle(color: Color(0xFF6B7280)),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: ThemeData.dark().scaffoldBackgroundColor,
        brightness: Brightness.dark,
        cardColor: const Color(0xFF212121),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF64B5F6),
          primaryContainer: const Color(0xFF1976D2),
          secondary: const Color(0xFF4CAF50),
          secondaryContainer: Colors.white,
          error: Color(0xFFEF4444),
          surface: const Color(0xFF212121),
          background: const Color(0xFF000000),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onError: Colors.white,
          onSurface: const Color(0xFFE0E0E0),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFFE0E0E0)),
          bodySmall: TextStyle(color: Color(0xFFB0BEC5)),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}