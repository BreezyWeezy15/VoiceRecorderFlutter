import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:voice_rec/bindings/app_binding.dart';
import 'package:voice_rec/db/db_helper.dart';
import 'package:voice_rec/ui/record_page.dart';

DbHelper dbHelper = DbHelper.instance;
void main() {
  runApp(GetMaterialApp(
    home: const MyApp(),
    debugShowCheckedModeBanner: false,
    initialBinding: AppBinding(),
    getPages: [
      GetPage(name: "/home", page: () => const RecordPage(),binding: AppBinding())
    ],
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const RecordPage();
  }
}


