import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/shared_casino/theme/casino_theme.dart';
import 'features/lobby/views/lobby_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: BestCasinoApp(),
    ),
  );
}

class BestCasinoApp extends StatelessWidget {
  const BestCasinoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Best Casino',
      debugShowCheckedModeBanner: false,
      theme: CasinoTheme.darkTheme,
      home: const LobbyScreen(),
    );
  }
}
