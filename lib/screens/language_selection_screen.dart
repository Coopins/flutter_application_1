import 'package:flutter/material.dart';
import '../routes.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  // Display name + flag for UI; we pass only the CODE to the next screen.
  static const List<Map<String, String>> _languages = [
    {"name": "Spanish", "code": "es", "ttsLocale": "es-ES", "flag": "🇪🇸"},
    {"name": "Russian", "code": "ru", "ttsLocale": "ru-RU", "flag": "🇷🇺"},
    {"name": "Portuguese", "code": "pt", "ttsLocale": "pt-BR", "flag": "🇧🇷"},
    {"name": "Japanese", "code": "ja", "ttsLocale": "ja-JP", "flag": "🇯🇵"},
    {"name": "Korean", "code": "ko", "ttsLocale": "ko-KR", "flag": "🇰🇷"},
    {"name": "Romanian", "code": "ro", "ttsLocale": "ro-RO", "flag": "🇷🇴"},
    {"name": "French", "code": "fr", "ttsLocale": "fr-FR", "flag": "🇫🇷"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose a language')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _languages.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final lang = _languages[index];
          final name = lang['name']!;
          final flag = lang['flag'] ?? '';
          return ListTile(
            tileColor: const Color(0xFF1C1C1C),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            leading: Text(flag, style: const TextStyle(fontSize: 22)),
            title: Text(name, style: const TextStyle(fontSize: 16)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushNamed(
                context,
                Routes.fluency,
                // Pass the CODE only: 'es','ru','pt','ja','ko','ro','fr'
                arguments: {'language': lang['code']},
              );
            },
          );
        },
      ),
    );
  }
}
