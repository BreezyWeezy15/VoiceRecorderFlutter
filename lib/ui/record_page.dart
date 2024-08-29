import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/get_instance.dart';
import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:voice_rec/Note.dart';
import 'package:voice_rec/controller/records_controller.dart';
import 'package:voice_rec/main.dart';
import 'package:fluttertoast/fluttertoast.dart';

class RecordPage extends StatefulWidget {
  const RecordPage({super.key});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  late RecordsController _recordsController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;
  String playPauseBtn = "assets/images/play.png";
  late Future<List<Note>?> _list;
  var recordImg = 'assets/images/micro.png';
  final _record = Record();

  bool isPermissionGranted = false;
  late Timer _timer;
  bool _isRecording = false;
  int _time = 0;
  String audioPath = "";

  @override
  void initState() {
    super.initState();
    _recordsController = Get.find<RecordsController>();
    _list = dbHelper.getAllNotes();
    requestStoragePermission();
    _audioPlayer.playerStateStream.listen((playerState){
      if(playerState.processingState == ProcessingState.completed){
        setState(() {
          playPauseBtn = "assets/images/play.png";
        });
      }
    });
  }


  @override
  void dispose() {
    _timer.cancel();
    _record.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () async {

            if(!kIsWeb) {
              bool permissionStatus = await Permission.microphone.isGranted;
              if (!permissionStatus) {
                await Permission.microphone.request();
              }
              else {
                setState(() {
                  recordImg = 'assets/images/record.png';
                });

                if (_isRecording) {
                  _stopRecording();
                  _stopTimer();
                } else {
                  _startRecording();
                  _startTimer();
                }
              }
            }
          },
          child: Image.asset(recordImg,width: 25,height: 25,),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Voice Recorder',style: TextStyle(fontSize: 25),),
                  const Spacer(),
                  IconButton(onPressed: (){
                    showDialog(
                        context: context,
                        builder: (context){
                          return AlertDialog(
                            title: const Text('Delete all recordings'),
                            content: const Text("Are you sure you want to delete all records?"),
                            actions: [
                              ElevatedButton(onPressed: ()  {
                                _recordsController.deleteRecords();
                                Navigator.pop(context);
                              }, child: const Text("Yes")),
                              ElevatedButton(onPressed: (){
                                Navigator.pop(context);
                              }, child: const Text('No'))
                            ],
                          );
                        });
                  }, icon: const Icon(Icons.delete))
                ],
              ),
              const SizedBox(height: 20,),
              const Divider(),
              Expanded(
                child: Obx((){
                  if(_recordsController.records.value == null ||
                   _recordsController.records.value!.isEmpty){
                    return const Center(child: Text('No Recordings',style: TextStyle(fontSize: 25),),);
                  } else {
                    var data = _recordsController.records.value;
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: data?.length,
                      itemBuilder: (context,index){
                        return Dismissible(
                            key: UniqueKey(),
                            direction: DismissDirection.startToEnd,
                            onDismissed: (direction){
                              _recordsController.deleteRecord(data[index]);
                              Fluttertoast.showToast(msg: 'Successfully deleted');
                            },
                            child: Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Row(
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("File Name :${data![index].title}",
                                          style: const TextStyle(fontWeight: FontWeight.w300,fontSize: 18),),
                                        const SizedBox(height: 5,),
                                        Text("Length : ${data![index].length}"),
                                      ],
                                    ),
                                    const Spacer(),
                                    InkWell(
                                      onTap: () async {
                                        if(isPlaying){
                                          setState(() {
                                            playPauseBtn = "assets/images/play.png";
                                            isPlaying = false;
                                          });
                                          _audioPlayer.stop();
                                        } else {
                                          setState(() {
                                            playPauseBtn = "assets/images/pause.png";
                                            isPlaying = true;
                                          });
                                          await _audioPlayer.setFilePath(data![index].path);
                                          await _audioPlayer.play();
                                        }
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 10),
                                        child: Image.asset(playPauseBtn,width: 20,height: 20,),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ));
                      },
                    );
                  }
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Future<void> requestStoragePermission() async {
    if (Platform.isAndroid) {
      print('Print Block 1');
      if (await isAndroid11orHigher()) {
        print('Print Block 2');
        if (await Permission.manageExternalStorage.request().isGranted) {
          // Permission granted, proceed with file access
        } else {
          // Request the permission
          await Permission.manageExternalStorage.request();
        }
      }
      else {
        print('Print Block 3');
        if (await Permission.storage.request().isGranted) {
          // Permission granted, proceed with file access
        } else {
          // Request the permission
          await Permission.storage.request();
        }
      }
    }
  }
  Future<bool> isAndroid11orHigher() async {
    return Platform.isAndroid && (!await Permission.manageExternalStorage.isGranted || await Permission.manageExternalStorage.isPermanentlyDenied);
  }
  void _startTimer() async {
    const duration = Duration(seconds: 1);
    _timer = Timer.periodic(duration,(timer){
      setState(() {
        _time++;
        Fluttertoast.showToast(msg: "Recording : ${_formatDuration(Duration(seconds: _time))}");
      });
    });
  }
  void _stopTimer() async {
    _timer.cancel();
  }
  Future<void> _startRecording() async {
    var fileName = DateTime.now().microsecondsSinceEpoch.toString();
    try {
      if (await _record.hasPermission()) {
        Directory? dir;

        if (Platform.isIOS) {
          dir = await getApplicationDocumentsDirectory();
        } else {
          dir = Directory('/storage/emulated/0/Download');
          // Check if the directory exists and fallback to app directory if it doesn't
          if (!await dir.exists()) {
            dir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
          }
        }

        String filePath = "${dir.path}${Platform.pathSeparator}$fileName.m4a";
        await _record.start(path: filePath,);
        setState(() {
          _isRecording = true;
        });

      }
      else {
        print('Permission not granted');
      }
    } catch (e) {
      print('Error: $e');
    }
  }
  Future<void> _stopRecording() async {
    var path = await _record.stop();
    audioPath = path!;
    if(audioPath != ""){

      var title = "File ${DateTime.now().microsecondsSinceEpoch}";
      var length = await getFileDuration(audioPath);

      var note = Note(title: title, path: audioPath, length: length);
      var result = await dbHelper.create(note);
      if(result! >= 1){
        _timer.cancel();
        _record.dispose();
        setState(() {
          _time = 0;
          audioPath = "";
          _isRecording = false;
          recordImg = 'assets/images/micro.png';
        });
        Fluttertoast.showToast(msg: 'Added');
        _recordsController.getRecords();
      }
      else {
        Fluttertoast.showToast(msg: 'Failed to add');
      }
    }
  }
  Future<String> getFileDuration(String path) async {
    await _audioPlayer.setFilePath(path);
    Duration? duration = _audioPlayer.duration;
    return _formatDuration(duration);

  }
  String _formatDuration(Duration? duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration!.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }


}
