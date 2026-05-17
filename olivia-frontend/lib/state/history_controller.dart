import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../../services/notification_service.dart';

class HistoryController extends GetxController {
  var isLoading = true.obs;
  var historyData = <String, List<dynamic>>{}.obs;

  final NotificationService _service = NotificationService();

  @override
  void onInit() {
    super.onInit();
    fetchHistoryData();
  }

  Future<void> fetchHistoryData() async {
    try {
      isLoading(true);
      final data = await _service.getProcessHistory();
      historyData.assignAll(data);
    } catch (e) {
      debugPrint("Error fetching history data in controller: $e");
    } finally {
      isLoading(false);
    }
  }
}
