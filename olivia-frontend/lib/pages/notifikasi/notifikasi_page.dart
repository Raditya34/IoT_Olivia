import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotifikasiPage extends StatelessWidget {
  const NotifikasiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi Sistem',
            style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildNotifItem(
            title: 'Suhu Melebihi Batas',
            subtitle: 'Proses Arang: Suhu mencapai 85°C. Segera cek heater.',
            time: '2 menit yang lalu',
            icon: Icons.warning_amber_rounded,
            color: Colors.orange,
          ),
          _buildNotifItem(
            title: 'Filtrasi Selesai',
            subtitle: 'Minyak pada tahap validasi telah selesai diproses.',
            time: '1 jam yang lalu',
            icon: Icons.check_circle_outline,
            color: Colors.teal,
          ),
        ],
      ),
    );
  }

  Widget _buildNotifItem({
    required String title,
    required String subtitle,
    required String time,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle),
            const SizedBox(height: 4),
            Text(time,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
