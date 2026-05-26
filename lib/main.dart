import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smartfarm_ai/database/app_database.dart';
import 'package:smartfarm_ai/services/session_provider.dart';
import 'package:smartfarm_ai/services/animals_provider.dart';
import 'package:smartfarm_ai/services/dashboard_provider.dart';
import 'package:smartfarm_ai/screens/app_bootstrap.dart';
import 'package:smartfarm_ai/screens/login_screen.dart';
import 'package:smartfarm_ai/screens/home_shell.dart';
import 'package:smartfarm_ai/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppBootstrap());
}

class SmartFarmAIApp extends StatefulWidget {
  const SmartFarmAIApp({super.key});

  @override
  State<SmartFarmAIApp> createState() => _SmartFarmAIAppState();
}

class _SmartFarmAIAppState extends State<SmartFarmAIApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppDatabase.instance.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      AppDatabase.instance.close();
    }
  }

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
