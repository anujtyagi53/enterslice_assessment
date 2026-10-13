import 'dart:async';

import 'package:enterslice_assessment/models_enums/location_item.dart';
import 'package:enterslice_assessment/models_enums/permission_states.dart';
import 'package:enterslice_assessment/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class HomeController extends GetxController {
  static const method = MethodChannel('enterslice_assessment/location_methods');
  static const event = EventChannel('enterslice_assessment/location_stream');

  final isTracking = false.obs;
  final last_Location = Rxn<LocationItem>();
  final history = <LocationItem>[].obs;
  final permission_status = PermissionStatus.checking.obs;
  final selected_interval = 30.obs;
  final is_gpsEnabled = true.obs;

  StreamSubscription? locationSub;

  @override
  void onInit() {
    super.onInit();
    checkPermissions();
  }

  @override
  void onClose() {
    locationSub?.cancel();
    super.onClose();
  }

  Future<void> checkPermissions() async {
    try {
      final result = await method.invokeMapMethod<String, bool>('checkPermissions');
      if (result == null) return;

      final fine = result['fineLocation'] ?? false;
      final background = result['backgroundLocation'] ?? false;
      final notifications = result['notifications'] ?? false;

      if (!fine) {
        permission_status.value = PermissionStatus.needsFine;
      } else if (!background) {
        permission_status.value = PermissionStatus.needsBackground;
      } else if (!notifications) {
        permission_status.value = PermissionStatus.needsNotifications;
      } else {
        permission_status.value = PermissionStatus.ready;
        load_initials();
        track_location();
      }
    } catch (e) {
      show_error_noti(e);
    }
  }

  Future<void> requestFineLocation() async {
    try {
      final result = await method.invokeMapMethod<String, dynamic>('requestFineLocation');
      final granted = result?['granted'] as bool? ?? false;
      final permanentDenied = result?['permanentlyDenied'] as bool? ?? false;
      if (permanentDenied) {
        permission_status.value = PermissionStatus.finePermanentDenied;
      } else if (granted) {
        checkPermissions();
      }
    } on PlatformException catch (e) {
      show_error_noti(e);
    }
  }

  Future<void> request_backgroundLocation() async {
    try {
      final result = await method.invokeMapMethod<String, dynamic>('requestBackgroundLocation');
      final granted = result?['granted'] as bool? ?? false;
      final permanentDenied = result?['permanentlyDenied'] as bool? ?? false;
      if (permanentDenied) {
        permission_status.value = PermissionStatus.bgPermanentDenied;
      } else if (granted) {
        checkPermissions();
      }
    } on PlatformException catch (e) {
      show_error_noti(e);
    }
  }

  Future<void> request_notifications() async {
    try {
      final result = await method.invokeMapMethod<String, dynamic>('requestNotifications');
      final granted = result?['granted'] as bool? ?? false;
      final permanentDenied = result?['permanentlyDenied'] as bool? ?? false;
      if (permanentDenied) {
        permission_status.value = PermissionStatus.notifPermanentDenied;
      } else if (granted) {
        checkPermissions();
      }
    } on PlatformException catch (e) {
      show_error_noti(e);
    }
  }

  void open_settings() {
    method.invokeMethod('openAppSettings');
  }

  void load_initials() async {
    await Future.wait([fetch_TrackStatus(), fetch_lastLocation(), fetch_history(), check_Gps_isEnabled()]);
  }

  Future<void> check_Gps_isEnabled() async {
    try {
      final result = await method.invokeMapMethod<String, dynamic>('checkGpsEnabled');
      is_gpsEnabled.value = result?['enabled'] as bool? ?? true;
    } catch (_) {}
  }

  void openLocationSettings() => method.invokeMethod('openLocationSettings');

  void track_location() {
    locationSub?.cancel();
    locationSub = event.receiveBroadcastStream().listen(
      (data) {
        if (data == null) return;
        final record = LocationItem.fromMap(data as Map);
        last_Location.value = record;
        history.insert(0, record);
        if (history.length > 50) history.removeLast();
      },
      onError: (e) {
        Get.snackbar('Tracking Error...', e.toString(), duration: const Duration(seconds: 3));
      },
    );
  }

  Future<void> fetch_TrackStatus() async {
    try {
      final result = await method.invokeMapMethod<String, dynamic>('isTracking');
      isTracking.value = result?['tracking'] as bool? ?? false;
    } catch (e) {
      show_error_noti(e);
    }
  }

  Future<void> fetch_lastLocation() async {
    try {
      final result = await method.invokeMapMethod<dynamic, dynamic>('getLastLocation');
      if (result != null) last_Location.value = LocationItem.fromMap(result);
    } catch (e) {
      show_error_noti(e);
    }
  }

  Future<void> fetch_history() async {
    try {
      final result = await method.invokeListMethod<dynamic>('getHistory');
      if (result != null) {
        history.value = result.map((e) => LocationItem.fromMap(e as Map)).toList();
      }
    } catch (e) {
      show_error_noti(e);
    }
  }

  Future<void> start_tracking() async {
    await check_Gps_isEnabled();
    if (!is_gpsEnabled.value) {
      Get.snackbar(
        'GPS Disabled',
        'Please enable location services start tracking.',
        duration: const Duration(seconds: 4),
        mainButton: TextButton(
          onPressed: openLocationSettings,
          child: const Text('Enable', style: TextStyle(color: Colors.white)),
        ),
      );
      return;
    }
    try {
      await method.invokeMethod('startTracking', {'interval': selected_interval.value});
      isTracking.value = true;
    } on PlatformException catch (e) {
      show_error_noti(e);
    }
  }

  Future<void> stop_tracking() async {
    try {
      await method.invokeMethod('stopTracking');
      isTracking.value = false;
    } on PlatformException catch (e) {
      show_error_noti(e);
    }
  }

  Future<void> clear_history() async {
    try {
      final result = await method.invokeMapMethod<String, dynamic>('clearHistory');
      final deleted = result?['deleted'] as int? ?? 0;
      history.clear();
      last_Location.value = null;
      Get.snackbar('Done', '$deleted records deleted', duration: const Duration(seconds: 2));
    } on PlatformException catch (e) {
      show_error_noti(e);
    }
  }

  Future<void> update_interval(int seconds) async {
    selected_interval.value = seconds;
    if (!isTracking.value) return;
    try {
      await method.invokeMethod('setInterval', {'interval': seconds});
    } on PlatformException catch (e) {
      show_error_noti(e);
    }
  }

  void show_error_noti(dynamic e) {
    final msg = e is PlatformException ? '${e.code}: ${e.message}' : e.toString();
    Get.snackbar('Error', msg, duration: const Duration(seconds: 4), snackPosition: SnackPosition.BOTTOM);
  }
}
