import 'package:auratime/screens/dashboard_screen.dart';
import 'package:auratime/screens/history_screen.dart';
import 'package:flutter/material.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final ValueNotifier<int> _historyRefreshTrigger = ValueNotifier<int>(0);

  @override
  void dispose() {
    _historyRefreshTrigger.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          DashboardScreen(
            onHistoryRefreshRequested: _requestHistoryRefresh,
          ),
          HistoryScreen(
            refreshListenable: _historyRefreshTrigger,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: theme.colorScheme.surface,
        indicatorColor: theme.colorScheme.primary.withValues(alpha: 0.22),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today_rounded),
            label: 'Hoje',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Histórico',
          ),
        ],
      ),
    );
  }

  void _requestHistoryRefresh() {
    _historyRefreshTrigger.value++;
  }
}
