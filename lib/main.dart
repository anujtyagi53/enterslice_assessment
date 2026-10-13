import 'package:enterslice_assessment/controllers/home_controller.dart';
import 'package:enterslice_assessment/ui_screens/home_page.dart';
import 'package:enterslice_assessment/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Enterslice assessment',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.scaffoldBg,
      ),
      home: const HomePage(),
      initialBinding: BindingsBuilder(() {
        Get.put(HomeController());
      }),
    );
  }
}
