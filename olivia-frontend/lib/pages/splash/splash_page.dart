import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Tambahkan ini
import 'package:shared_preferences/shared_preferences.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_text.dart';
import '../../theme/app_colors.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _loading = false;

  // Fungsi navigasi menggunakan GetX
  Future<void> _onStart() async {
    if (_loading) return;
    setState(() => _loading = true);

    // Simulasi loading sebentar
    await Future.delayed(const Duration(milliseconds: 500));

    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool('logged_in') ?? false;

    // MENGGUNAKAN GETX: Membersihkan stack agar tidak bisa balik ke splash
    if (loggedIn) {
      Get.offAllNamed(AppRoutes.dashboard);
    } else {
      Get.offAllNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Kita tidak perlu AppScaffold di Splash Screen agar tampilan full screen bersih
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // === LOGO CIRCLE ===
                Hero(
                  tag:
                      'app_logo', // Tambahkan Hero animation agar transisi ke login mulus
                  child: Container(
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
                ),

                const SizedBox(height: 28),

                // === TITLE ===
                Text(
                  'OLIVIA',
                  style: AppText.h1(context).copyWith(
                    letterSpacing: 2,
                    color: AppColors.textDark,
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
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.6,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text('Mulai',
                              style: AppText.h3(context)
                                  .copyWith(color: Colors.white)),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  'Tekan tombol untuk melanjutkan',
                  style: AppText.body(context)
                      .copyWith(color: AppColors.textMuted),
                ),

                const SizedBox(height: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
