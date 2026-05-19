// lib/state/dashboard_binding.dart
import 'package:get/get.dart';
import 'dashboard_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    // Memasukkan controller ke dalam memory GetX sebagai Singleton / Permanent instance
    Get.lazyPut<DashboardController>(() => DashboardController(), fenix: true);
  }
}
