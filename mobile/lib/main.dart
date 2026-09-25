import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const DotaHeroesApp());
}

class DotaHeroesApp extends StatelessWidget {
  const DotaHeroesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dota Heroes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB33A3A),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
