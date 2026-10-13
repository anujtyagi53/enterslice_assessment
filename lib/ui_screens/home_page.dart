import 'package:enterslice_assessment/controllers/home_controller.dart';
import 'package:enterslice_assessment/models_enums/location_item.dart';
import 'package:enterslice_assessment/models_enums/permission_states.dart';
import 'package:enterslice_assessment/utils/app_colors.dart';
import 'package:enterslice_assessment/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        title: const Text('Home', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          Obx(() {
            if (controller.permission_status.value != PermissionStatus.ready) return const SizedBox();
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.delete_outline), tooltip: 'Clear History', onPressed: () => showRemoveDialog(context, controller)),
              ],
            );
          }),
        ],
      ),
      body: Obx(() => permission_views(context)),
    );
  }

  Widget permission_views(BuildContext context) {
    if (controller.permission_status.value == PermissionStatus.checking) {
      return const Center(child: CircularProgressIndicator());
    }
    return switch (controller.permission_status.value) {
      PermissionStatus.checking => const Center(child: CircularProgressIndicator()),
      PermissionStatus.needsFine => permission_Card(
        context,
        icon: Icons.location_on,
        title: 'Location Permission',
        message: 'App need precise location access to track your position.',
        buttonLabel: 'Grant Permission',
        onTap: controller.requestFineLocation,
        iconColor: AppColors.primary,
      ),
      PermissionStatus.finePermanentDenied => permission_Card(
        context,
        icon: Icons.location_off,
        title: 'Permission Denied',
        message: 'Please enable location permission from app settings.',
        buttonLabel: 'Open Settings',
        onTap: controller.open_settings,
        iconColor: AppColors.danger,
      ),
      PermissionStatus.needsBackground => permission_Card(
        context,
        icon: Icons.location_searching,
        title: 'Background Location Required',
        message: 'Select "Allow all the time" in the next screen for background tracking.',
        buttonLabel: 'Allow Background Location',
        onTap: controller.request_backgroundLocation,
        iconColor: AppColors.primary,
      ),
      PermissionStatus.bgPermanentDenied => permission_Card(
        context,
        icon: Icons.location_off,
        title: 'Background Location Denied',
        message: 'Enable "Allow all the time" for location in app settings.',
        buttonLabel: 'Open Settings',
        onTap: controller.open_settings,

        iconColor: AppColors.danger,
      ),
      PermissionStatus.needsNotifications => permission_Card(
        context,
        icon: Icons.notifications_active,
        title: 'Notification Permission',
        message: 'Allow notifications so the tracker can show live location updates in the status bar.',
        buttonLabel: 'Allow Notifications',
        onTap: controller.request_notifications,

        iconColor: AppColors.primary,
      ),
      PermissionStatus.notifPermanentDenied => permission_Card(
        context,
        icon: Icons.notifications_off,
        title: 'Notifications Permanently Denied',
        message: 'Enable notification permission from app settings.',
        buttonLabel: 'Open Settings',
        onTap: controller.open_settings,
        iconColor: AppColors.danger,
      ),
      PermissionStatus.ready => main_view(),
    };
  }

  Widget permission_Card(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    required String buttonLabel,
    required VoidCallback onTap,
    required Color iconColor,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon(icon, size: 64, color: isPermanent ? AppColors.danger : AppColors.primary),
                Icon(icon, size: 64, color: iconColor),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.blackshade),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: AppColors.darkGray, height: 1.5),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(buttonLabel, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget main_view() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            children: [
              status_ui(),
              const SizedBox(height: 12),
              gps_card(),
              last_locationCardView(),
              const SizedBox(height: 12),
              control_boxview(),
              const SizedBox(height: 12),
              interval_selector_row(),
              const SizedBox(height: 12),
              history_header(),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: historyList()),
      ],
    );
  }

  Widget status_ui() {
    return Obx(() {
      final running = controller.isTracking.value;
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(color: running ? AppColors.success : AppColors.gray, borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(running ? Icons.radio_button_on : Icons.radio_button_off, color: AppColors.white, size: 14),
                const SizedBox(width: 6),
                Text(
                  running ? 'Running' : 'Stopped',
                  style: const TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget gps_card() {
    return Obx(() {
      if (controller.is_gpsEnabled.value) return const SizedBox();
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3CD),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFFCA2C)),
        ),
        child: Row(
          children: [
            const Icon(Icons.gps_off, color: Color(0xFF856404), size: 18),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('GPS / Location services are disabled.', style: TextStyle(fontSize: 13, color: Color(0xFF856404))),
            ),
            TextButton(
              onPressed: controller.openLocationSettings,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Enable', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ),
      );
    });
  }

  Widget last_locationCardView() {
    return Obx(() {
      final loc = controller.last_Location.value;
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.my_location, color: AppColors.primary, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Last Location',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkGray),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              loc == null ? const Text('No location found', style: TextStyle(color: AppColors.gray, fontSize: 14)) : locationDetail(loc),
            ],
          ),
        ),
      );
    });
  }

  Widget locationDetail(LocationItem locItem) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          locItem.latLong,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.blackshade),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            info_view(Icons.adjust, '±${locItem.accuracy.toStringAsFixed(1)}m'),
            const SizedBox(width: 10),
            info_view(Icons.access_time, timestampToTime(locItem.timestamp)),
          ],
        ),
      ],
    );
  }

  Widget info_view(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.gray),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.darkGray)),
      ],
    );
  }

  Widget control_boxview() {
    return Obx(() {
      final running = controller.isTracking.value;
      return Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: running ? null : controller.start_tracking,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Tracking', style: TextStyle(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: AppColors.white,
                  disabledBackgroundColor: AppColors.grayLight,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: running ? controller.stop_tracking : null,
                icon: const Icon(Icons.stop),
                label: const Text('Stop Tracking', style: TextStyle(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: AppColors.white,
                  disabledBackgroundColor: AppColors.grayLight,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget interval_selector_row() {
    return Obx(() {
      return Row(
        children: [
          const Text(
            'Interval:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.darkGray),
          ),
          const SizedBox(width: 12),
          ...kIntervalOptions.map((sec) {
            final selected = controller.selected_interval.value == sec;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(sec >= 60 ? '${sec ~/ 60}m' : '${sec}s'),
                selected: selected,
                onSelected: (_) => controller.update_interval(sec),
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(color: selected ? AppColors.white : AppColors.blackshade, fontWeight: FontWeight.w500, fontSize: 12),
              ),
            );
          }),
        ],
      );
    });
  }

  Widget history_header() {
    return Obx(() {
      return Row(
        children: [
          const Text(
            'History data',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.blackshade),
          ),
          const SizedBox(width: 8),
          Text('(${controller.history.length})', style: const TextStyle(fontSize: 13, color: AppColors.gray)),
        ],
      );
    });
  }

  Widget historyList() {
    return Obx(() {
      if (controller.history.isEmpty) {
        return const Center(
          child: Text('No records found', style: TextStyle(color: AppColors.gray, fontSize: 14)),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: controller.history.length,
        itemBuilder: (_, i) => history_list_item(controller.history[i], i),
      );
    });
  }

  Widget history_list_item(LocationItem locItem, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.grayLight),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Text(
              '${index + 1}',
              style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  locItem.latLong,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.blackshade),
                ),
                const SizedBox(height: 2),
                Text(
                  '${timestampeToDateTim(locItem.timestamp)}  ±${locItem.accuracy.toStringAsFixed(1)}m',
                  style: const TextStyle(fontSize: 11, color: AppColors.gray),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
