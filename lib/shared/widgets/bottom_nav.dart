import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/services/obd_manager.dart';
import '../../core/services/chat_manager.dart';
import '../../features/home/home_screen.dart';
import '../../features/diagnosis/diagnosis_screen.dart';
import '../../features/history/history_screen.dart';
import '../../features/chat/chat_screen.dart';

class MainScaffold extends StatefulWidget {
  final ObdManager obdManager;
  final ChatManager chatManager;

  const MainScaffold({
    super.key,
    required this.obdManager,
    required this.chatManager,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  List<Widget> get _screens => [
    HomeScreen(obdManager: widget.obdManager, onTabChanged: _onTabTapped),
    DiagnosisScreen(
      obdManager: widget.obdManager,
      onBackToHome: () => _onTabTapped(0),
    ),
    ChatScreen(
      chatManager: widget.chatManager,
      obdManager: widget.obdManager,
    ),
    HistoryScreen(onBackToHome: () => _onTabTapped(0)),
  ];

  static const List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Inicio',
    ),
    _NavItem(
      icon: Icons.search_outlined,
      activeIcon: Icons.search_rounded,
      label: 'Diagnóstico',
    ),
    _NavItem(
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble_rounded,
      label: 'Asistente',
    ),
    _NavItem(
      icon: Icons.history_outlined,
      activeIcon: Icons.history_rounded,
      label: 'Historial',
    ),
  ];

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppTheme.surfaceLight, width: 0.5),
          ),
        ),
        child: BottomAppBar(
          color: AppTheme.surface,
          elevation: 0,
          padding: EdgeInsets.zero,
          child: Row(
            children: List.generate(_navItems.length, (index) {
              final item = _navItems[index];
              final isSelected = _currentIndex == index;
              return Expanded(
                child: InkWell(
                  onTap: () => _onTabTapped(index),
                  splashColor: AppTheme.primary.withValues(alpha: 0.2),
                  highlightColor: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected ? item.activeIcon : item.icon,
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.textHint,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w500
                                : FontWeight.w400,
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
