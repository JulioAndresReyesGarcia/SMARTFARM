import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smartfarm_ai/services/session_provider.dart';
import 'package:smartfarm_ai/services/animals_provider.dart';
import 'package:smartfarm_ai/services/dashboard_provider.dart';
import 'package:smartfarm_ai/screens/login_screen.dart';
import 'package:smartfarm_ai/screens/home_shell.dart';
import 'package:smartfarm_ai/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SmartFarmAIApp());
}

class SmartFarmAIApp extends StatelessWidget {
  const SmartFarmAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SessionProvider()),
        ChangeNotifierProvider(create: (_) => AnimalsProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SmartFarm AI',
        theme: AppTheme.light(),
        home: Consumer<SessionProvider>(
          builder: (context, session, _) {
            return session.isLoggedIn ? const HomeShell() : const LoginScreen();
          },
        ),
      ),
    );
  }
}
