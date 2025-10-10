// lib/services/stt_service.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class SttService {
  final AudioRecorder _rec = AudioRecorder();
  String? _lastPlannedPath;

  /// Start recording to a temp file (AAC). Returns when recording has begun.
  Future<void> start() async {
    final hasMic = await _rec.hasPermission();
    if (!hasMic) {
      throw Exception('Microphone permission not granted');
    }

    final tmp = await getTemporaryDirectory();
    final path =
        '${tmp.path}/gabgo_${DateTime.now().millisecondsSinceEpoch}.m4a';
    _lastPlannedPath = path;

    await _rec.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
        numChannels: 1,
      ),
      path: path,
    );
  }

  /// Mirrors your usage: `await _stt.isRecording`
  Future<bool> get isRecording async => await _rec.isRecording();

  /// Stop and return the recorded file path (or null).
  Future<String?> stop() async {
    final actualPath = await _rec.stop(); // v5 returns String? path
    final path = actualPath ?? _lastPlannedPath;
    if (path == null) return null;
    return File(path).existsSync() ? path : null;
  }

  Future<void> dispose() async {
    if (await _rec.isRecording()) {
      await _rec.stop();
    }
  }
}
