import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../routes/app_routes.dart';
import '../../widgets/app_scaffold.dart';
import '../../theme/app_text.dart';
import '../../theme/app_colors.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _loading = false;

  Future<void> _onStart() async {
    if (_loading) return;
    setState(() => _loading = true);

    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool('logged_in') ?? false;

    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      loggedIn ? AppRoutes.dashboard : AppRoutes.login,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: '',
      currentRoute: AppRoutes.splash,
      onNavigate: (_) {},
      showAppBar: false,
      showDrawer: false,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.background,
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // === LOGO CIRCLE ===
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface,
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 40,
                          spreadRadius: 6,
                          color: AppColors.orange.withOpacity(0.25),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // === TITLE ===
                  Text(
                    'OLIVIA',
                    style: AppText.h1(context).copyWith(
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    '(OIL FILTRATION AUTOMATION SYSTEM)',
                    style: AppText.h2(context),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Turning Waste Oil into Value',
                    style: AppText.muted(context),
                    textAlign: TextAlign.center,
                  ),

                  const Spacer(flex: 3),

                  // === BUTTON MULAI ===
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: SizedBox(
                      height: 56,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _onStart,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.orangeDeep,
                          foregroundColor: AppColors.textDark,
                          elevation: 10,
                          shadowColor: AppColors.orangeDeep.withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          textStyle: AppText.body(context),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.6,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text('Mulai'),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    'Tekan tombol untuk melanjutkan',
                    style: AppText.body(context),
                  ),

                  const SizedBox(height: 22),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
