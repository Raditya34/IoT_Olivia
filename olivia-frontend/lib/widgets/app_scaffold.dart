import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'gradient_background.dart';
import 'app_drawer.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final String currentRoute;
  final void Function(String route) onNavigate;
  final Widget child;
  final bool showAppBar;
  final bool showDrawer;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const AppScaffold({
    super.key,
    required this.title,
    required this.currentRoute,
    required this.onNavigate,
    required this.child,
    this.showAppBar = true,
    this.showDrawer = true,
    this.actions,
    this.floatingActionButton,
  });

  void _safeGo(BuildContext context, String route) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      onNavigate(route);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        drawer: showDrawer
            ? AppDrawer(
                currentRoute: currentRoute,
                onNavigate: (r) => _safeGo(context, r),
              )
            : null,
        appBar: showAppBar
            ? AppBar(
                title: Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                leading: showDrawer
                    ? Builder(
                        builder: (ctx) => IconButton(
                          icon: const Icon(Icons.menu_rounded),
                          onPressed: () => Scaffold.of(ctx).openDrawer(),
                          tooltip: "Menu",
                        ),
                      )
                    : null,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded),
                    onPressed: () => _safeGo(context, "/notifikasi"),
                    tooltip: "Notifikasi",
                  ),
                  IconButton(
                    icon: const Icon(Icons.person_outline_rounded),
                    onPressed: () => _safeGo(context, "/profile"),
                    tooltip: "Profile",
                  ),
                  const SizedBox(width: 6),
                  if (actions != null) ...actions!,
                  const SizedBox(width: 6),
                ],
              )
            : null,
        floatingActionButton: floatingActionButton,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.border.withOpacity(0.7)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
