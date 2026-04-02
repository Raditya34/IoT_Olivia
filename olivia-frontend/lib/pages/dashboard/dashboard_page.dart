import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'dart:convert';

import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/sensor_card.dart';
import '../../widgets/industrial_popup.dart';
import '../../widgets/progress_timeline.dart';

late MqttServerClient client;

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool systemOn = false;

  // step timeline: 0 idle/off, 1 minyak, 2 arang, 3 bleaching, 4 selesai
  int progressStep = 0;

  // Dummy sensor state
  double arangTemp = 62.4;
  double arangVol = 8.6;
  double bleachTemp = 74.2;

  double valVol = 7.9;
  double turb = 38.0;
  double visc = 52.0;
  String warna = 'Jernih';

  final List<Timer> _timers = [];

  @override
  void initState() {
    super.initState();
    // _tick();
    connectMqtt();
  }

  Future<void> connectMqtt() async {
    // 1. Initialize the client with your broker address and a unique client ID
    client = MqttServerClient(
        'your_broker_address_here', 'flutter_client_${Random().nextInt(100)}');
    client.port = 1883; // Default MQTT port
    client.keepAlivePeriod = 20;
    client.logging(on: false);

    final connMessage = MqttConnectMessage()
        .withClientIdentifier('flutter_client')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    client.connectionMessage = connMessage;

    try {
      print('MQTT: Connecting...');
      await client.connect();
    } catch (e) {
      print('MQTT: Exception - $e');
      client.disconnect();
      return;
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print('MQTT: Connected');

      // 2. Subscribe to your topic
      client.subscribe("sensor/data", MqttQos.atMostOnce);

      // 3. Listen for incoming data
      client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
        final pt =
            MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

        // 4. Update your state with real data from the hardware
        setState(() {
          final data = jsonDecode(pt);
          // Example: arangTemp = data['temp'];
        });
      });
    } else {
      print('MQTT: Connection failed - status is ${client.connectionStatus}');
      client.disconnect();
    }
  }

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }

  void _navigate(BuildContext context, String route) {
    Navigator.pushReplacementNamed(context, route);
  }

  void _cancelTimers() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
  }

  void _popup({
    required String title,
    required String message,
    IndustrialNoticeKind kind = IndustrialNoticeKind.info,
  }) {
    IndustrialPopup.show(
      context,
      title: title,
      message: message,
      kind: kind,
    );
  }

  void _scheduleDummyNotifs() {
    _cancelTimers();
    setState(() => progressStep = 1);

    _popup(
      title: 'Instruksi Operator',
      message: 'User memasukkan minyak',
      kind: IndustrialNoticeKind.info,
    );

    _timers.add(Timer(const Duration(minutes: 1), () {
      if (!mounted || !systemOn) return;
      setState(() => progressStep = 2);
      _popup(
        title: 'Instruksi Operator',
        message: 'User memasukkan arang',
        kind: IndustrialNoticeKind.warning,
      );
    }));

    _timers.add(Timer(const Duration(minutes: 2), () {
      if (!mounted || !systemOn) return;
      setState(() => progressStep = 3);
      _popup(
        title: 'Instruksi Operator',
        message: 'User memasukkan bleaching',
        kind: IndustrialNoticeKind.warning,
      );
    }));

    _timers.add(Timer(const Duration(minutes: 3), () {
      if (!mounted || !systemOn) return;
      setState(() => progressStep = 4);
      _popup(
        title: 'Siklus Selesai',
        message: 'Filtrasi minyak telah selesai, mohon di cek hasilnya',
        kind: IndustrialNoticeKind.success,
      );
    }));
  }

  void _toggleSystem() {
    setState(() => systemOn = !systemOn);

    if (systemOn) {
      _scheduleDummyNotifs();
    } else {
      _cancelTimers();
      setState(() => progressStep = 0);
      _popup(
        title: 'Sistem',
        message: 'Sistem dimatikan',
        kind: IndustrialNoticeKind.info,
      );
    }
  }

  void _tick() async {
    final rnd = Random();
    while (mounted) {
      await Future.delayed(const Duration(seconds: 2));
      if (!systemOn) continue;

      setState(() {
        // Arang
        arangTemp = (arangTemp + rnd.nextDouble() * 1.2 - 0.6).clamp(40, 95);
        arangVol = (arangVol + rnd.nextDouble() * 0.3 - 0.1).clamp(0, 15);

        // Bleaching
        bleachTemp = (bleachTemp + rnd.nextDouble() * 1.0 - 0.5).clamp(40, 95);

        // Validasi
        valVol = (valVol + rnd.nextDouble() * 0.2 - 0.1).clamp(0, 15);
        turb = (turb + rnd.nextDouble() * 4 - 2).clamp(0, 200);
        visc = (visc + rnd.nextDouble() * 3 - 1.5).clamp(10, 120);

        if (turb < 40) {
          warna = 'Jernih';
        } else if (turb < 90) {
          warna = 'Kurang Jernih';
        } else {
          warna = 'Kotor';
        }
      });
    }
  }

  String _recommendation() {
    if (!systemOn) return 'Aktifkan sistem untuk mulai monitoring.';
    if (warna == 'Jernih' && turb < 50 && visc < 70)
      return 'Layak digunakan / disimpan.';
    if (warna != 'Kotor' && turb < 90)
      return 'Perlu pemurnian tambahan (cek arang/bleaching).';
    return 'Tidak layak — disarankan ulangi filtrasi.';
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Dashboard',
      currentRoute: AppRoutes.dashboard,
      onNavigate: (r) => _navigate(context, r),
      child: ListView(
        children: [
          _hero(context),
          const SizedBox(height: 12),

          _systemControl(context),
          const SizedBox(height: 12),

          // ✅ Timeline
          ProgressTimeline(step: progressStep, active: systemOn),
          const SizedBox(height: 16),

          _sectionTitle(context, 'Navigasi Proses',
              'Pilih proses untuk melihat data sensor & monitoring.'),
          const SizedBox(height: 10),
          _processGrid(context),

          const SizedBox(height: 16),
          _sectionTitle(
            context,
            'Live Snapshot',
            systemOn ? 'Data sensor.' : 'Sistem OFF — data berhenti.',
          ),
          const SizedBox(height: 10),
          _snapshotGrid(context),

          const SizedBox(height: 16),
          _sectionTitle(context, 'Hasil Akhir', 'Berdasarkan hasil validasi.'),
          const SizedBox(height: 10),
          _recommendationCard(context),

          const SizedBox(height: 26),
        ],
      ),
    );
  }

  Widget _hero(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Transform.translate(
          offset: Offset(0, 14 * (1 - t)),
          child: Opacity(opacity: t, child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
          gradient: LinearGradient(
            colors: [
              AppColors.teal.withOpacity(0.14),
              AppColors.orange.withOpacity(0.10),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 20,
                    color: AppColors.teal.withOpacity(0.18),
                  )
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Image.asset('assets/logo.png', fit: BoxFit.contain),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('OLIVIA', style: AppText.h1(context)),
                  const SizedBox(height: 4),
                  Text('Oil Filtration Automation',
                      style: AppText.muted(context)),
                  const SizedBox(height: 8),
                  Text(
                    'Monitoring proses Arang • Bleaching • Validasi dengan data sensor real-time.',
                    style: AppText.body(context)
                        .copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _systemControl(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: _toggleSystem,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: systemOn
              ? LinearGradient(colors: [AppColors.teal, AppColors.tealDark])
              : LinearGradient(
                  colors: [Colors.grey.shade300, Colors.grey.shade400]),
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: systemOn
                  ? AppColors.teal.withOpacity(0.35)
                  : Colors.black.withOpacity(0.08),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.power_settings_new_rounded,
              size: 38,
              color: systemOn ? Colors.white : Colors.black54,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    systemOn ? 'SISTEM AKTIF' : 'SISTEM NONAKTIF',
                    style: AppText.h3(context).copyWith(
                      color: systemOn ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    systemOn
                        ? 'Monitoring berjalan'
                        : 'Tekan untuk mengaktifkan sistem',
                    style: AppText.muted(context).copyWith(
                      color: systemOn ? Colors.white70 : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: systemOn
                    ? Colors.white.withOpacity(0.20)
                    : Colors.black.withOpacity(0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                systemOn ? 'ON' : 'OFF',
                style: AppText.chip(context).copyWith(
                  color: systemOn ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.h2(context)),
          const SizedBox(height: 4),
          Text(subtitle, style: AppText.muted(context)),
        ],
      ),
    );
  }

  Widget _processGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final cols = w < 520 ? 1 : (w < 860 ? 2 : 3);

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _processCard(context, cols, w,
                title: 'Arang',
                subtitle: 'Suhu • Volume',
                icon: Icons.local_fire_department_rounded,
                route: AppRoutes.arang),
            _processCard(context, cols, w,
                title: 'Bleaching',
                subtitle: 'Suhu',
                icon: Icons.science_rounded,
                route: AppRoutes.bleaching),
            _processCard(context, cols, w,
                title: 'Validasi',
                subtitle: 'Kualitas akhir',
                icon: Icons.verified_rounded,
                route: AppRoutes.filtrasi),
          ],
        );
      },
    );
  }

  Widget _processCard(
    BuildContext context,
    int cols,
    double w, {
    required String title,
    required String subtitle,
    required IconData icon,
    required String route,
  }) {
    final cardW = (w - (12 * (cols - 1))) / cols;

    return SizedBox(
      width: cardW,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.pushNamed(context, route),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                blurRadius: 18,
                offset: const Offset(0, 10),
                color: Colors.black.withOpacity(0.05),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 14),
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
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _snapshotGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final cols = w < 520 ? 1 : (w < 980 ? 2 : 4);
        final cardW = (w - (12 * (cols - 1))) / cols;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: cardW,
              child: SensorCard(
                label: 'Arang • Suhu',
                value: arangTemp.toStringAsFixed(1),
                unit: '°C',
                icon: Icons.thermostat_rounded,
              ),
            ),
            SizedBox(
              width: cardW,
              child: SensorCard(
                label: 'Arang • Volume Minyak',
                value: arangVol.toStringAsFixed(1),
                unit: 'L',
                icon: Icons.water_drop_rounded,
              ),
            ),
            SizedBox(
              width: cardW,
              child: SensorCard(
                label: 'Bleaching • Suhu',
                value: bleachTemp.toStringAsFixed(1),
                unit: '°C',
                icon: Icons.thermostat_auto_rounded,
              ),
            ),
            SizedBox(
              width: cardW,
              child: SensorCard(
                label: 'Validasi • Turbidity',
                value: turb.toStringAsFixed(0),
                unit: 'NTU',
                icon: Icons.blur_on_rounded,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _recommendationCard(BuildContext context) {
    final bool isReady = systemOn && warna == 'Jernih' && turb < 50;
    final bool isWarning = systemOn && (turb >= 50 && turb < 90);
    final bool isCritical = systemOn && turb >= 90;

    Color themeColor = !systemOn
        ? Colors.grey
        : (isReady
            ? AppColors.teal
            : (isWarning ? AppColors.orange : AppColors.danger));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: themeColor.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            blurRadius: 30,
            offset: const Offset(0, 15),
            color: themeColor.withOpacity(0.08),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: themeColor.withOpacity(0.1),
                  child: Icon(Icons.analytics_rounded, color: themeColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Analisis Kualitas Akhir',
                          style: AppText.h3(context)),
                      Text(
                          systemOn
                              ? 'Data diproses secara real-time'
                              : 'Sistem Standby',
                          style: AppText.muted(context)),
                    ],
                  ),
                ),
                if (systemOn) _buildStatusBadge(isReady, isWarning, isCritical),
              ],
            ),
          ),

          const Divider(height: 1, indent: 20, endIndent: 20),

          // Detail Parameter
          Padding(
            padding: const EdgeInsets.all(20),
            child: systemOn
                ? Column(
                    children: [
                      _buildDataRow(
                          context,
                          'Turbidity',
                          '${turb.toStringAsFixed(0)} NTU',
                          turb / 200,
                          themeColor),
                      const SizedBox(height: 16),
                      _buildDataRow(
                          context,
                          'Viskositas',
                          '${visc.toStringAsFixed(0)} cP',
                          visc / 120,
                          themeColor),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildMiniInfo(
                              context, 'Warna', warna, Icons.palette_outlined),
                          const SizedBox(width: 12),
                          _buildMiniInfo(
                              context,
                              'Volume',
                              '${valVol.toStringAsFixed(1)} L',
                              Icons.straighten),
                        ],
                      ),
                    ],
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text('Nyalakan sistem untuk memulai analisis',
                          style: AppText.muted(context)),
                    ),
                  ),
          ),

          // Action/Recommendation Footer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: themeColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _recommendation(),
                    style: AppText.body(context).copyWith(
                      color: themeColor.withAlpha(200),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: systemOn
                      ? () => Navigator.pushNamed(context, AppRoutes.filtrasi)
                      : null,
                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                  color: themeColor,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool ready, bool warning, bool critical) {
    String text = ready ? 'LAYAK' : (warning ? 'PERLU CEK' : 'TIDAK LAYAK');
    Color color = ready
        ? AppColors.teal
        : (warning ? AppColors.orange : AppColors.danger);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildDataRow(BuildContext context, String label, String value,
      double percent, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppText.body(context)),
            Text(value, style: AppText.h3(context).copyWith(color: color)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: percent.clamp(0, 1),
          backgroundColor: color.withOpacity(0.1),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 6,
          borderRadius: BorderRadius.circular(10),
        ),
      ],
    );
  }

  Widget _buildMiniInfo(
      BuildContext context, String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppText.chip(context)),
                  Text(
                    value,
                    style: AppText.h3(context).copyWith(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
