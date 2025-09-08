import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Simple STT service backed by OpenAI Whisper.
/// Usage:
///   final stt = STTService(apiKey: `YOUR_OPENAI_API_KEY`);
///   final text = await stt.transcribe(File(path), languageCode: 'es'); // or null to auto-detect
class STTService {
  final String apiKey;
  final Uri _whisperUrl = Uri.parse(
    'https://api.openai.com/v1/audio/transcriptions',
  );

  STTService({required this.apiKey});

  /// Returns a trimmed final transcript. Throws on network/HTTP errors.
  /// [languageCode] should be a short code like `es`, `fr`, `en`.
  /// If null, Whisper will auto-detect.
  Future<String> transcribe(File audioFile, {String? languageCode}) async {
    if (!await audioFile.exists()) {
      throw Exception('Audio file does not exist: ${audioFile.path}');
    }

    final request =
        http.MultipartRequest('POST', _whisperUrl)
          ..headers['Authorization'] = 'Bearer $apiKey'
          ..fields['model'] = 'whisper-1'
          ..fields['response_format'] = 'json';

    // Optional language hint (recommended). Use short code only.
    if (languageCode != null && languageCode.trim().isNotEmpty) {
      final shortCode =
          languageCode.split(RegExp('[-_]')).first.toLowerCase().trim();
      request.fields['language'] = shortCode;
    }

    // NOTE: We omit `contentType` to avoid MediaType type mismatches.
    // The API will infer from the file extension.
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        audioFile.path,
        filename: audioFile.uri.pathSegments.last,
      ),
    );

    final streamed = await request.send();
    final resp = await http.Response.fromStream(streamed);

    if (resp.statusCode != 200) {
      throw Exception('Whisper error ${resp.statusCode}: ${resp.body}');
    }

    final data = json.decode(resp.body) as Map<String, dynamic>;
    final text = (data['text'] ?? '').toString().trim();
    return text;
  }
}
