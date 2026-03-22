import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

/// App shell with bottom navigation for protected routes.
/// Used by GoRouter ShellRoute.
class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/agenda')) return 0;
    if (location.startsWith('/clients')) return 1;
    if (location.startsWith('/financial')) return 2;
    if (location.startsWith('/more')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.neutral200, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex(context),
          onTap: (i) {
            switch (i) {
              case 0:
                context.go('/agenda');
              case 1:
                context.go('/clients');
              case 2:
                context.go('/financial');
              case 3:
                context.go('/more');
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today_rounded),
              label: 'Agenda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline_rounded),
              activeIcon: Icon(Icons.people_rounded),
              label: 'Clientes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.attach_money_rounded),
              activeIcon: Icon(Icons.attach_money_rounded),
              label: 'Financeiro',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.more_horiz_rounded),
              activeIcon: Icon(Icons.more_horiz_rounded),
              label: 'Mais',
            ),
          ],
        ),
      ),
    );
  }
}
