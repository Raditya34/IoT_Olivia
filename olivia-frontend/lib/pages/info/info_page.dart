import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/app_scaffold.dart';

class InfoPage extends StatefulWidget {
  const InfoPage({super.key});

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  final _nameC = TextEditingController();
  final _phoneC = TextEditingController();
  final _msgC = TextEditingController();

  int rating = 4;
  String category = 'Saran';

  @override
  void dispose() {
    _nameC.dispose();
    _phoneC.dispose();
    _msgC.dispose();
    super.dispose();
  }

  void _copy(String text) {
    // sengaja tanpa Clipboard plugin dulu (biar gak nambah dependency)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Salin manual: $text'),
        backgroundColor: AppColors.tealDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _send() {
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Feedback terkirim.'),
        backgroundColor: AppColors.tealDark,
        behavior: SnackBarBehavior.floating,
      ),
    );

    _msgC.clear();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Info & Support',
      currentRoute: AppRoutes.info,
      child: ListView(
        children: [
          _header(context),
          const SizedBox(height: 12),
          Text('Kontak', style: AppText.h2(context)),
          const SizedBox(height: 6),
          Text('Hubungi jika ada kendala operasional atau sistem.',
              style: AppText.muted(context)),
          const SizedBox(height: 12),
          _contactCard(
            context,
            title: 'Contact Person',
            subtitle: '+62 812-1159-9164',
            icon: Icons.support_agent_rounded,
          ),
          const SizedBox(height: 10),
          _contactCard(
            context,
            title: 'Email',
            subtitle: 'difa082402@Gmail.com',
            icon: Icons.engineering_rounded,
          ),
          const SizedBox(height: 18),
          Text('Feedback & Saran', style: AppText.h2(context)),
          const SizedBox(height: 6),
          Text('Berikan masukan untuk pengembangan OLIVIA.',
              style: AppText.muted(context)),
          const SizedBox(height: 12),
          _feedbackCard(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(0.05),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppColors.modernGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.info_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bantuan OLIVIA', style: AppText.h2(context)),
                const SizedBox(height: 4),
                Text('Kontak cepat & feedback sistem.',
                    style: AppText.muted(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.teal.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.tealDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.h3(context)),
                const SizedBox(height: 4),
                Text(subtitle, style: AppText.muted(context)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _copy(subtitle),
            icon: const Icon(Icons.copy_rounded),
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }

  Widget _feedbackCard(BuildContext context) {
    InputDecoration deco(String hint) => InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: AppColors.background,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.teal.withOpacity(0.75)),
          ),
        );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(0.05),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // rating
          Row(
            children: [
              Text('Rating', style: AppText.h3(context)),
              const Spacer(),
              Row(
                children: List.generate(5, (i) {
                  final idx = i + 1;
                  final on = idx <= rating;
                  return IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => setState(() => rating = idx),
                    icon: Icon(
                        on ? Icons.star_rounded : Icons.star_border_rounded),
                    color: on ? AppColors.orange : AppColors.textMuted,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // category
          Row(
            children: [
              Text('Kategori', style: AppText.h3(context)),
              const Spacer(),
              DropdownButton<String>(
                value: category,
                items: const [
                  DropdownMenuItem(value: 'Bug', child: Text('Bug')),
                  DropdownMenuItem(value: 'Saran', child: Text('Saran')),
                  DropdownMenuItem(
                      value: 'Pertanyaan', child: Text('Pertanyaan')),
                ],
                onChanged: (v) => setState(() => category = v ?? category),
              ),
            ],
          ),
          const SizedBox(height: 12),

          TextField(controller: _nameC, decoration: deco('Nama')),
          const SizedBox(height: 10),
          TextField(controller: _phoneC, decoration: deco('No. HP')),
          const SizedBox(height: 10),
          TextField(
            controller: _msgC,
            maxLines: 4,
            decoration: deco('Tulis komentar / saran...'),
          ),
          const SizedBox(height: 12),

          ElevatedButton(
            onPressed: _send,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Kirim Feedback'),
          ),
        ],
      ),
    );
  }
}
