// lib/pages/notifications/notifikasi_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/app_scaffold.dart';
import '../../services/notification_service.dart';

class NotifikasiPage extends StatefulWidget {
  const NotifikasiPage({super.key});

  @override
  State<NotifikasiPage> createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage> {
  final notificationService = NotificationService();
  late Future<List<Map<String, dynamic>>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = notificationService.getAllNotifications();
  }

  Future<void> _refresh() async {
    setState(() {
      _notificationsFuture = notificationService.getAllNotifications();
    });
  }

  Future<void> _markAllAsRead() async {
    try {
      await notificationService.markAllAsRead();
      Get.snackbar(
        'Sukses',
        'Semua notifikasi sudah dibaca',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
      _refresh();
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Notifikasi',
      currentRoute: AppRoutes.notifications,
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: Column(
          children: [
            // Header dengan tombol mark all as read
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Notifikasi Sistem', style: AppText.h2(context)),
                  TextButton.icon(
                    onPressed: _markAllAsRead,
                    icon: const Icon(Icons.done_all_rounded, size: 18),
                    label: const Text('Tandai Semua'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.teal,
                    ),
                  ),
                ],
              ),
            ),
            // List notifikasi
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _notificationsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('Error: ${snapshot.error}'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _refresh,
                            child: const Text('Coba Lagi'),
                          )
                        ],
                      ),
                    );
                  }

                  final notifications = snapshot.data ?? [];

                  if (notifications.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.notifications_off_rounded,
                              size: 48, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text('Tidak ada notifikasi',
                              style: AppText.h3(context)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notif = notifications[index];
                      return _buildNotifItem(context, notif);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotifItem(BuildContext context, Map<String, dynamic> notif) {
    final isRead = notif['is_read'] ?? false;
    final type = notif['type'];
    final title = notif['title'] ?? 'Notifikasi';
    final message = notif['message'] ?? '';
    final createdAt = notif['created_at'];

    final typeColor = _getTypeColor(type);
    final typeIcon = _getTypeIcon(type);

    return GestureDetector(
      onTap: () async {
        if (!isRead) {
          await notificationService.markAsRead(notif['id']);
          _refresh();
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: isRead ? AppColors.surface : typeColor.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isRead ? AppColors.border : typeColor.withOpacity(0.3),
          ),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: typeColor.withOpacity(0.1),
            child: Icon(typeIcon, color: typeColor),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              if (!isRead)
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: typeColor,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              const SizedBox(height: 4),
              Text(
                _formatTime(createdAt),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          isThreeLine: true,
        ),
      ),
    );
  }

  Color _getTypeColor(String? type) {
    switch (type) {
      case 'arang':
        return Colors.orange;
      case 'bleaching':
        return Colors.blue;
      case 'validasi':
        return Colors.purple;
      case 'selesai':
        return Colors.green;
      default:
        return AppColors.teal;
    }
  }

  IconData _getTypeIcon(String? type) {
    switch (type) {
      case 'arang':
        return Icons.local_fire_department_rounded;
      case 'bleaching':
        return Icons.science_rounded;
      case 'validasi':
        return Icons.verified_rounded;
      case 'selesai':
        return Icons.check_circle_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inSeconds < 60) return 'Baru saja';
      if (diff.inMinutes < 60) return '${diff.inMinutes} menit yang lalu';
      if (diff.inHours < 24) return '${diff.inHours} jam yang lalu';
      return '${diff.inDays} hari yang lalu';
    } catch (e) {
      return timestamp;
    }
  }
}
