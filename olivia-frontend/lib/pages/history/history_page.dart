import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_scaffold.dart';
import '../../state/history_controller.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Memanggil atau menginisialisasi HistoryController
    final HistoryController controller = Get.put(HistoryController());

    return AppScaffold(
      title: 'Riwayat Proses',
      currentRoute: AppRoutes.history,
      child: RefreshIndicator(
        onRefresh: () => controller.fetchHistoryData(),
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.teal),
            );
          }

          if (controller.historyData.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 200),
                Center(
                  child: Text(
                    'Belum ada riwayat proses pembakaran.',
                    style: TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                ),
              ],
            );
          }

          final cycleNumbers = controller.historyData.keys.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: cycleNumbers.length,
            itemBuilder: (context, index) {
              final cycleNumber = cycleNumbers[index];
              final records = List.from(controller.historyData[cycleNumber]!);
              return _cycleCard(context, cycleNumber, records);
            },
          );
        }),
      ),
    );
  }

  Widget _cycleCard(BuildContext context, String cycleNumber, List records) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.teal.withOpacity(0.1),
          child: Text(
            cycleNumber,
            style: const TextStyle(
                color: AppColors.teal, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          'Cycle Pembakaran #$cycleNumber',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Terdapat ${records.length} tahapan data'),
        trailing: const Icon(Icons.chevron_right, color: AppColors.teal),
        onTap: () => Get.toNamed(
          AppRoutes.historyDetail,
          arguments: {
            'cycleNumber': cycleNumber,
            'records': records,
          },
        ),
      ),
    );
  }
}
