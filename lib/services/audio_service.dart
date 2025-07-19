import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AudioService {
  final Record _recorder = Record();

  Future<String?> startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return null;

    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/recording.wav';

    await _recorder.start(
      path: filePath,
      encoder: AudioEncoder.wav, // supported in v5.2.1
      bitRate: 128000,
      samplingRate: 44100,
    );

    return filePath;
  }

  Future<String?> stopAndTranscribe(String selectedLanguage) async {
    final path = await _recorder.stop();
    if (path == null) return null;

    final file = File(path);
    if (!file.existsSync()) return null;

    final dio = Dio();
    final apiKey = dotenv.env['OPENAI_API_KEY'];

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: 'recording.wav',
      ),
      'model': 'whisper-1',
      'response_format': 'text',
      'language': selectedLanguage,
    });

    final response = await dio.post(
      'https://api.openai.com/v1/audio/transcriptions',
      data: formData,
      options: Options(
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'multipart/form-data',
        },
      ),
    );

    return response.data.toString();
  }
}
