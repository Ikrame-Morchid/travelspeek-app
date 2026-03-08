import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

enum RecordingState { idle, recording, stopped }

class AudioRecorderService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  RecordingState _state = RecordingState.idle;
  bool _isInitialized = false;

  bool get isRecording => _state == RecordingState.recording;
  RecordingState get state => _state;

  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> _initialize() async {
    if (!_isInitialized) {
      await _recorder.openRecorder();
      _isInitialized = true;
    }
  }

  Future<String?> startRecording() async {
    if (!await requestPermission()) {
      debugPrint(" Permission microphone refusée");
      return null;
    }

    await _initialize();

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.aac';

    await _recorder.startRecorder(
      toFile: path,
      codec: Codec.aacADTS,
      bitRate: 128000,
      sampleRate: 44100,
    );

    _state = RecordingState.recording;
    debugPrint(" Enregistrement démarré : $path");
    return path;
  }

  Future<String?> stopRecording() async {
    if (_state != RecordingState.recording) return null;

    final path = await _recorder.stopRecorder();
    _state = RecordingState.stopped;
    debugPrint("Enregistrement arrêté : $path");
    return path;
  }

  Future<double> getAmplitude() async {
    if (!isRecording) return 0.0;
    // flutter_sound ne fournit pas directement l'amplitude
    return 0.5;
  }

  Future<void> dispose() async {
    if (_isInitialized) {
      await _recorder.closeRecorder();
      _isInitialized = false;
    }
  }
}