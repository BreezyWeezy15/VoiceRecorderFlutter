



import 'package:get/get.dart';
import 'package:voice_rec/controller/records_controller.dart';

class AppBinding extends Bindings {


  @override
  void dependencies() {
    Get.lazyPut<RecordsController>(() => RecordsController());
  }

}
