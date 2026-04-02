import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/primary_button.dart';
import '../../theme/app_text.dart';
import '../../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  bool obscure = true;

  bool isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
  }

  Future<void> _login() async {
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email dan password wajib diisi")),
      );
      return;
    }
    if (!isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Format email tidak valid")),
      );
      return;
    }
    if (pass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password minimal 6 karakter")),
      );
      return;
    }

    try {
      await AuthService().login(email,
          pass); // ✅ login ke Laravel + simpan token (di AuthService/AuthStorage)

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: '',
      currentRoute: AppRoutes.login,
      onNavigate: (_) {},
      showAppBar: false,
      showDrawer: false,
      child: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                Image.asset('assets/logo.png', width: 84),
                const SizedBox(height: 14),
                Text('Akses Sistem OLIVIA', style: AppText.h1(context)),
                const SizedBox(height: 6),
                Text(
                    'Login untuk melanjutkan pemantauan proses secara real-time.',
                    style: AppText.muted(context)),
                const SizedBox(height: 18),
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Email', style: AppText.body(context)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(),
                        ),
                        const SizedBox(height: 14),
                        Text('Password', style: AppText.body(context)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: passCtrl,
                          obscureText: obscure,
                          decoration: InputDecoration(
                            hintText: 'Minimal 6 karakter',
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => obscure = !obscure),
                              icon: Icon(
                                obscure
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        PrimaryButton(text: 'Login', onTap: _login),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () => Navigator.pushReplacementNamed(
                            context,
                            AppRoutes.signup,
                          ),
                          child: const Text('Belum punya akun? Daftar'),
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
