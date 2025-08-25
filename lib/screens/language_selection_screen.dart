import 'package:flutter/material.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  final List<String> _languages = const [
    'Spanish',
    'French',
    'German',
    'Chinese',
  ];
  String? _selected;

  String _ttsLocaleFor(String language) {
    switch (language) {
      case 'Spanish':
        return 'es-ES';
      case 'French':
        return 'fr-FR';
      case 'German':
        return 'de-DE';
      case 'Chinese':
        return 'zh-CN';
      default:
        return 'en-US';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text('Select Language'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selected,
              dropdownColor: const Color(0xFF1A1F29),
              items:
                  _languages
                      .map(
                        (l) => DropdownMenuItem(
                          value: l,
                          child: Text(
                            l,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                      .toList(),
              decoration: InputDecoration(
                labelText: 'Language',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF141923),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (v) => setState(() => _selected = v),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.mic_none_rounded),
                label: const Text('Continue'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed:
                    _selected == null
                        ? null
                        : () {
                          final tts = _ttsLocaleFor(_selected!);
                          Navigator.pushNamed(
                            context,
                            '/fluency',
                            arguments: {
                              'selectedLanguage': _selected!,
                              'ttsLocale': tts,
                            },
                          );
                        },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
