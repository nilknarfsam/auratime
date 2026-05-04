import 'package:auratime/screens/dashboard_screen.dart';
import 'package:auratime/screens/history_screen.dart';
import 'package:auratime/screens/settings_screen.dart';
import 'package:flutter/material.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final ValueNotifier<int> _historyRefreshTrigger = ValueNotifier<int>(0);
  late final List<Widget?> _cachedScreens;

  @override
  void initState() {
    super.initState();
    _cachedScreens = List<Widget?>.filled(3, null);
    _cachedScreens[0] = _buildScreen(0);
  }

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
          _cachedScreens[0] ?? const SizedBox.shrink(),
          _cachedScreens[1] ?? const SizedBox.shrink(),
          _cachedScreens[2] ?? const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        height: 70,
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        indicatorColor: theme.colorScheme.primary.withValues(alpha: 0.22),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return theme.textTheme.labelSmall?.copyWith(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurfaceVariant,
          );
        }),
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
            _cachedScreens[index] ??= _buildScreen(index);
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
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune_rounded),
            label: 'Configurações',
          ),
        ],
      ),
    );
  }

  void _requestHistoryRefresh() {
    _historyRefreshTrigger.value++;
  }

  void _onSettingsSaved() {
    _requestHistoryRefresh();
    setState(() {});
  }

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return DashboardScreen(
          onHistoryRefreshRequested: _requestHistoryRefresh,
        );
      case 1:
        return HistoryScreen(
          refreshListenable: _historyRefreshTrigger,
        );
      case 2:
        return SettingsScreen(
          onSettingsSaved: _onSettingsSaved,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
