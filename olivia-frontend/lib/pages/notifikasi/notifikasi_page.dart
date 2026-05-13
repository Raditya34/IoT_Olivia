import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_scaffold.dart';
import '../../services/notification_service.dart';
import '../../routes/app_routes.dart';

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
      Get.snackbar('Sukses', 'Semua notifikasi ditandai sudah dibaca');
      _refresh();
    } catch (e) {
      Get.snackbar('Error', 'Gagal memperbarui notifikasi');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Notifikasi',
      currentRoute: AppRoutes.notifications,
      actions: [
        IconButton(
          icon: const Icon(Icons.done_all_rounded),
          onPressed: _markAllAsRead,
          tooltip: 'Tandai semua dibaca',
        ),
      ],
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _notificationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data!.isEmpty) {
              return const Center(child: Text('Tidak ada notifikasi'));
            }

            final notifications = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return _notificationItem(notif);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _notificationItem(Map<String, dynamic> notif) {
    final bool isRead = notif['is_read'] == true || notif['read_at'] != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isRead ? 0 : 2,
      color: isRead ? Colors.grey[50] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getTypeColor(notif['type']).withOpacity(0.1),
          child: Icon(_getTypeIcon(notif['type']),
              color: _getTypeColor(notif['type'])),
        ),
        title: Text(
          notif['title'] ?? 'Pemberitahuan',
          style: TextStyle(
              fontWeight: isRead ? FontWeight.normal : FontWeight.bold),
        ),
        subtitle: Text(notif['message'] ?? ''),
        onTap: () async {
          if (!isRead) {
            await notificationService.markAsRead(notif['id'].toString());
            _refresh();
          }
        },
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
}
