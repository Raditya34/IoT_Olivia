import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_scaffold.dart';
import '../../services/notification_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final notificationService = NotificationService();
  late Future<Map<String, dynamic>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = notificationService.getProcessHistory();
  }

  Future<void> _refresh() async {
    setState(() {
      _historyFuture = notificationService.getProcessHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Riwayat Proses',
      currentRoute: AppRoutes.history,
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<Map<String, dynamic>>(
          future: _historyFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: AppColors.teal));
            }
            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data!.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  const Center(
                    child: Column(
                      children: [
                        Icon(Icons.history_rounded,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('Belum ada riwayat proses',
                            style: TextStyle(color: Colors.grey, fontSize: 16)),
                      ],
                    ),
                  ),
                ],
              );
            }

            final groupedData = snapshot.data!;
            final cycleNumbers = groupedData.keys.toList()
              ..sort((a, b) => int.parse(b).compareTo(int.parse(a)));

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: cycleNumbers.length,
              itemBuilder: (context, index) {
                final cycleNumber = cycleNumbers[index];
                final records = List.from(groupedData[cycleNumber]);
                return _cycleCard(context, cycleNumber, records);
              },
            );
          },
        ),
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
