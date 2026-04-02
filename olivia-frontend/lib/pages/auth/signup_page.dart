import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../routes/app_routes.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/primary_button.dart';
import '../../theme/app_text.dart';
import '../../services/auth_service.dart';

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

  bool isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
  }

  Future<void> _signup() async {
    final name = nameCtrl.text.trim();
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text.trim();

    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Semua field wajib diisi")),
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
      await AuthService().register(name, email, pass);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registrasi berhasil, silakan login")),
      );
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
    // ✅ SIMPAN (sementara)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setString('user_email', email);
    await prefs.setString('user_password', pass);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Registrasi berhasil, silakan login")),
    );
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: '',
      currentRoute: AppRoutes.signup,
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
                Text('Create Account', style: AppText.h1(context)),
                const SizedBox(height: 6),
                Text('Daftar untuk mulai menggunakan OLIVIA.',
                    style: AppText.muted(context)),
                const SizedBox(height: 18),
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Nama Lengkap', style: AppText.body(context)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Nama kamu',
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text('Email', style: AppText.body(context)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            hintText: 'nama@email.com',
                          ),
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
                        PrimaryButton(text: 'Daftar', onTap: _signup),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () => Navigator.pushReplacementNamed(
                            context,
                            AppRoutes.login,
                          ),
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
