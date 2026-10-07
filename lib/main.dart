import 'package:flutter/material.dart';

import 'pages/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SmontiamoLaVoceApp());
}

class SmontiamoLaVoceApp extends StatelessWidget {
  const SmontiamoLaVoceApp({super.key});

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF071521);
    const cyan = Color(0xFF58D5E8);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smontiamo la voce!',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: navy,
        colorScheme: ColorScheme.fromSeed(
          seedColor: cyan,
          brightness: Brightness.dark,
          surface: const Color(0xFF102432),
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: Color(0xFF102432),
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
