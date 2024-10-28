import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/intl.dart' show DateFormat;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;

  const MyHomePage({super.key, required this.title});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late FlutterSoundRecorder _recordingSession;
  final AudioPlayer audioPlayer = AudioPlayer();
  String? _recordedFilePath;
  bool _playAudio = false;
  String _timerText = '00:00:00';
  StreamSubscription? _recorderSubscription;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    initializer();
  }

  @override
  void dispose() {
    _recorderSubscription?.cancel();
    _recordingSession.closeRecorder();
    audioPlayer.dispose();
    super.dispose();
  }

  void initializer() async {
    _recordingSession = FlutterSoundRecorder();
    await _recordingSession.openRecorder();
    await _recordingSession.setSubscriptionDuration(const Duration(milliseconds: 10));
    await initializeDateFormatting();
    await [Permission.microphone, Permission.storage].request();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(title: const Text('Audio Recording and Playing')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 40),
            Center(
              child: Text(
                _timerText,
                style: const TextStyle(fontSize: 70, color: Colors.red),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                createElevatedButton(
                  icon: _isRecording ? Icons.stop : Icons.mic,
                  iconColor: Colors.red,
                  onPressFunc: () {
                    if (_isRecording) {
                      stopRecording();
                    } else {
                      startRecording();
                    }
                  },
                ),
                const SizedBox(width: 30),
                createElevatedButton(
                  icon: Icons.stop,
                  iconColor: Colors.red,
                  onPressFunc: stopRecording,
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  elevation: 9.0, backgroundColor: Colors.red),
              onPressed: _recordedFilePath == null ? null : () {
                setState(() {
                  _playAudio = !_playAudio;
                });
                if (_playAudio) playFunc();
                if (!_playAudio) stopPlayFunc();
              },
              icon: _playAudio
                  ? const Icon(Icons.stop)
                  : const Icon(Icons.play_arrow),
              label: _playAudio
                  ? const Text(
                "Stop",
                style: TextStyle(fontSize: 28),
              )
                  : const Text(
                "Play",
                style: TextStyle(fontSize: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ElevatedButton createElevatedButton({
    required IconData icon,
    required Color iconColor,
    required VoidCallback? onPressFunc,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(6.0),
        side: const BorderSide(
          color: Colors.red,
          width: 4.0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Colors.white,
        elevation: 9.0,
      ),
      onPressed: onPressFunc,
      icon: Icon(
        icon,
        color: iconColor,
        size: 38.0,
      ),
      label: const Text(''),
    );
  }

  Future<void> startRecording() async {
    try {
      var appDir = await getApplicationDocumentsDirectory();
      var fileName = 'recording_${DateTime.now().millisecondsSinceEpoch}.aac';
      String path = '${appDir.path}/$fileName';

      await _recordingSession.startRecorder(
        toFile: path,
        codec: Codec.aacMP4,
      );

      setState(() {
        _isRecording = true;
      });

      _recorderSubscription?.cancel();
      _recorderSubscription = _recordingSession.onProgress?.listen((e) {
        var date = DateTime.fromMillisecondsSinceEpoch(e.duration.inMilliseconds,
            isUtc: true);
        var timeText = DateFormat('mm:ss:SS', 'en_GB').format(date);
        setState(() {
          _timerText = timeText.substring(0, 8);
        });
      });
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  Future<void> stopRecording() async {
    try {
      _recordedFilePath = await _recordingSession.stopRecorder();
      _recorderSubscription?.cancel();
      setState(() {
        _isRecording = false;
        _timerText = '00:00:00';
      });
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  Future<void> playFunc() async {
    if (_recordedFilePath != null) {
      try {
        await audioPlayer.play(DeviceFileSource(_recordedFilePath!));
      } catch (e) {
        print('Error playing audio: $e');
      }
    }
  }

  Future<void> stopPlayFunc() async {
    try {
      await audioPlayer.stop();
    } catch (e) {
      print('Error stopping playback: $e');
    }
  }
}