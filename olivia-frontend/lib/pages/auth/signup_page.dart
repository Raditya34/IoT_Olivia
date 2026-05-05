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

  bool isValidName(String name) {
    return name.length >= 3;
  }

  Future<void> _signup() async {
    final name = nameCtrl.text.trim();
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text.trim();

    // Validasi input kosong
    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      _showErrorSnackBar("Semua field wajib diisi");
      return;
    }

    // Validasi nama minimal 3 karakter
    if (!isValidName(name)) {
      _showErrorSnackBar("Nama minimal 3 karakter");
      return;
    }

    // Validasi format email
    if (!isValidEmail(email)) {
      _showErrorSnackBar("Format email tidak valid");
      return;
    }

    // Validasi panjang password
    if (pass.length < 6) {
      _showErrorSnackBar("Password minimal 6 karakter");
      return;
    }

    setState(() => isLoading = true);

    try {
      final authService = AuthService();
      await authService.register(name, email, pass).timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Connection timeout'),
          );

      if (!mounted) return;
      _showSuccessSnackBar("Registrasi berhasil, silakan login");

      // Delay sebelum navigasi
      await Future.delayed(const Duration(milliseconds: 500));

      // Navigasi ke login dengan GetX
      Get.offAllNamed(AppRoutes.login);
    } on Exception catch (e) {
      if (!mounted) return;
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      _showErrorSnackBar(errorMsg);
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 2),
      ),
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
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                // Logo
                Image.asset(
                  'assets/logo.png',
                  width: 84,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 14),

                // Heading
                Text('Create Account', style: AppText.h1(context)),
                const SizedBox(height: 6),
                Text(
                  'Daftar untuk mulai menggunakan OLIVIA.',
                  style: AppText.muted(context),
                ),
                const SizedBox(height: 18),

                // Form Card
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Nama Lengkap Field
                        Text(
                          'Nama Lengkap',
                          style: AppText.body(context),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: nameCtrl,
                          enabled: !isLoading,
                          decoration: InputDecoration(
                            hintText: 'Nama kamu',
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Email Field
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
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Password Field
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
                              onPressed: !isLoading
                                  ? () => setState(() => obscure = !obscure)
                                  : null,
                              icon: Icon(
                                obscure
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Sign Up Button
                        PrimaryButton(
                          text: isLoading ? 'Memproses...' : 'Daftar',
                          onTap: isLoading ? null : _signup,
                        ),
                        const SizedBox(height: 10),

                        // Login Link
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () => Get.offAllNamed(AppRoutes.login),
                          child: const Text('Sudah punya akun? Login'),
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
