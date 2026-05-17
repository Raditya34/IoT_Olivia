import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_scaffold.dart';
import '../../services/notification_service.dart';
import '../../routes/app_routes.dart';

class AppNotificationController extends GetxController {
  final NotificationService _service = NotificationService();
  var allNotifications = <Map<String, dynamic>>[].obs;
  var isLoadingNotif = true.obs;
  var unreadCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAllNotifications();
  }

  Future<void> fetchAllNotifications() async {
    try {
      isLoadingNotif(true);
      final list = await _service.getAllNotifications();
      allNotifications.assignAll(list);
      await fetchUnreadCount();
    } catch (e) {
      debugPrint("Error fetching notifications: $e");
    } finally {
      isLoadingNotif(false);
    }
  }

  Future<void> fetchUnreadCount() async {
    final count = await _service.getUnreadCount();
    unreadCount.value = count;
  }

  Future<void> markAsRead(String id) async {
    final success = await _service.markAsRead(id);
    if (success) {
      await fetchAllNotifications();
    }
  }

  Future<void> markAllAsRead() async {
    final success = await _service.markAllAsRead();
    if (success) {
      Get.snackbar('Sukses', 'Semua notifikasi ditandai sudah dibaca',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.1),
          colorText: Colors.green);
      await fetchAllNotifications();
    } else {
      Get.snackbar('Error', 'Gagal memperbarui notifikasi',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.1),
          colorText: Colors.red);
    }
  }
}

class NotifikasiPage extends StatelessWidget {
  const NotifikasiPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppNotificationController controller =
        Get.put(AppNotificationController());

    return AppScaffold(
      title: 'Notifikasi',
      currentRoute: AppRoutes.notifications,
      actions: [
        IconButton(
          icon: const Icon(Icons.done_all_rounded, color: AppColors.teal),
          onPressed: () => controller.markAllAsRead(),
          tooltip: 'Tandai semua dibaca',
        ),
      ],
      child: RefreshIndicator(
        onRefresh: () => controller.fetchAllNotifications(),
        color: AppColors.teal,
        child: Obx(() {
          if (controller.isLoadingNotif.value &&
              controller.allNotifications.isEmpty) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.teal));
          }

          if (controller.allNotifications.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                const Center(
                  child: Column(
                    children: [
                      Icon(Icons.notifications_none_rounded,
                          size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'Tidak ada pemberitahuan',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            itemCount: controller.allNotifications.length,
            itemBuilder: (context, index) {
              final notif = controller.allNotifications[index];
              final isRead = notif['is_read'] == true || notif['is_read'] == 1;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                color: isRead ? Colors.grey[50] : Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: isRead ? 0 : 2,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        _getTypeColor(notif['type']).withOpacity(0.1),
                    child: Icon(_getTypeIcon(notif['type']),
                        color: _getTypeColor(notif['type'])),
                  ),
                  title: Text(
                    notif['title'] ?? 'Pemberitahuan',
                    style: TextStyle(
                        fontWeight:
                            isRead ? FontWeight.normal : FontWeight.bold,
                        color: isRead ? Colors.grey[700] : Colors.black87),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(notif['message'] ?? '',
                          style: TextStyle(
                              color: isRead ? Colors.grey : Colors.black54)),
                      const SizedBox(height: 6),
                      Text(
                        _formatTime(notif['created_at']),
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                  onTap: () {
                    if (!isRead) {
                      controller.markAsRead(notif['id'].toString());
                    }
                  },
                ),
              );
            },
          );
        }),
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
        return Icons.verified_user_rounded;
      case 'selesai':
        return Icons.task_alt_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  String _formatTime(String? rawIso) {
    if (rawIso == null) return '';
    try {
      DateTime dt = DateTime.parse(rawIso).toLocal();
      return "${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return rawIso;
    }
  }
}
