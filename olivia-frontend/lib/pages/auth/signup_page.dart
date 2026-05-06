import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../theme/app_text.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/primary_button.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  bool obscure = true;
  bool isLoading = false;

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  bool isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
  }

  Future<void> _signup() async {
    final name = nameCtrl.text.trim();
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text.trim();

    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      _showSnackBar("Semua field wajib diisi", isError: true);
      return;
    }

    if (!isValidEmail(email)) {
      _showSnackBar("Format email tidak valid", isError: true);
      return;
    }

    if (pass.length < 6) {
      _showSnackBar("Password minimal 6 karakter", isError: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      await AuthService().register(name, email, pass).timeout(
            const Duration(seconds: 20),
            onTimeout: () => throw Exception('Koneksi timeout, coba lagi.'),
          );

      _showSnackBar("Registrasi berhasil, silakan login", isError: false);

      await Future.delayed(const Duration(seconds: 1));
      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''),
          isError: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    Get.snackbar(
      isError ? "Gagal" : "Berhasil",
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor:
          isError ? Colors.red.withOpacity(0.8) : Colors.green.withOpacity(0.8),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: '',
      currentRoute: AppRoutes.signup,
      showAppBar: false,
      showDrawer: false,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Column(
              children: [
                Image.asset('assets/logo.png', width: 80),
                const SizedBox(height: 16),
                Text('Buat Akun', style: AppText.h1(context)),
                Text('Daftar untuk mulai menggunakan OLIVIA',
                    style: AppText.muted(context)),
                const SizedBox(height: 24),
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Nama Lengkap', style: AppText.body(context)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: nameCtrl,
                          enabled: !isLoading,
                          decoration: InputDecoration(
                            hintText: 'Masukkan nama lengkap',
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('Email', style: AppText.body(context)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: emailCtrl,
                          enabled: !isLoading,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'nama@email.com',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('Password', style: AppText.body(context)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: passCtrl,
                          enabled: !isLoading,
                          obscureText: obscure,
                          decoration: InputDecoration(
                            hintText: 'Minimal 6 karakter',
                            prefixIcon: const Icon(Icons.lock_outlined),
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => obscure = !obscure),
                              icon: Icon(obscure
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                            ),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 24),
                        PrimaryButton(
                          text: isLoading ? 'Mendaftar...' : 'Daftar Sekarang',
                          onTap: isLoading ? null : _signup,
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () => Get.offAllNamed(AppRoutes.login),
                          child: const Text('Sudah punya akun? Login di sini'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
