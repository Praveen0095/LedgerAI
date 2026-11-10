import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_dashboard_screen.dart';
import 'services/ledger_state.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => LedgerState(),
      child: const LedgerApp(),
    ),
  );
}

class LedgerApp extends StatelessWidget {
  const LedgerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LedgerState>();

    return MaterialApp(
      title: 'LedgerAI • Dynamic Daily Quota & Personal Menu',
      debugShowCheckedModeBanner: false,
      themeMode: state.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const HomeDashboardScreen(),
    );
  }
}
