


import 'package:get/get.dart';
import 'package:voice_rec/main.dart';

import '../Note.dart';

class RecordsController extends GetxController {

  final Rx<List<Note>?> _list =  Rx<List<Note>?>(null);
  Rx<List<Note>?> get records => _list;

  @override
  void onInit() {
    super.onInit();
    getRecords();
  }

  void getRecords(){
    dbHelper.getAllNotes().then((value){
      _list.value = value!;
    });
  }

  void deleteRecords() async {
    await dbHelper.deleteAllNotes();
    getRecords();
  }

  void deleteRecord(Note note) async {
    await dbHelper.deleteNote(note);
    getRecords();
  }

}
