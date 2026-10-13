import 'dart:ui';

import 'package:enterslice_assessment/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

const kIntervalOptions = [10, 30, 60];

String timestampToTime(timestamp) {
  final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
  var formatter = DateFormat('HH:mm');
  String formattedDate = formatter.format(dt);
  return formattedDate;
}

String timestampeToDateTim(timestamp) {
  final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
  var formatter = DateFormat('dd/MM/yyyy hh:mm:ss');
  String formattedDate = formatter.format(dt);
  return formattedDate;
}

void showRemoveDialog(BuildContext context, controller) {
  showDialog(
    context: context,
    builder: (_) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: EdgeInsets.zero,
        title: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppColors.blackshade,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: const Text(
            'Clear History',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        content: const Text(
          'All location records will be permanently deleted.',
          style: TextStyle(fontSize: 14, color: AppColors.darkGray, height: 1.5),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(left: 8, bottom: 8),
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                      controller.clear_history();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('Clear'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 8, bottom: 8),
                  child: ElevatedButton(
                    onPressed: Get.back,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.grayLight,
                      foregroundColor: AppColors.blackshade,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
