import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smartfarm_ai/screens/dashboard_screen.dart';
import 'package:smartfarm_ai/screens/animals_screen.dart';
import 'package:smartfarm_ai/screens/recommendations_screen.dart';
import 'package:smartfarm_ai/services/animals_provider.dart';
import 'package:smartfarm_ai/services/dashboard_provider.dart';
import 'package:smartfarm_ai/services/session_provider.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnimalsProvider>().refresh();
      context.read<DashboardProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = const [
      DashboardScreen(),
      AnimalsScreen(),
      RecommendationsScreen(),
    ];

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.pets_outlined), selectedIcon: Icon(Icons.pets), label: 'Ganado'),
          NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome), label: 'IA'),
        ],
      ),
      floatingActionButton: _index == 0
          ? FloatingActionButton.extended(
              onPressed: () => context.read<SessionProvider>().logout(),
              icon: const Icon(Icons.logout),
              label: const Text('Salir'),
            )
          : null,
    );
  }
}

