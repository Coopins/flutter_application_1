import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({Key? key}) : super(key: key);

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  final List<String> _languages = ['Spanish', 'French', 'German', 'Chinese'];
  String? _selectedLanguage;

  Future<void> _handleContinue() async {
    if (_selectedLanguage == null) return;

    final permission = await Permission.microphone.request();

    if (permission.isGranted) {
      Navigator.pushNamed(
        context,
        '/fluencyAssessment',
        arguments: {'selectedLanguage': _selectedLanguage},
      );
    } else {
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              backgroundColor: Colors.grey[900],
              title: const Text(
                "Microphone Permission",
                style: TextStyle(color: Colors.white),
              ),
              content: const Text(
                "Gabi needs microphone access to assess your fluency.",
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    "OK",
                    style: TextStyle(color: Colors.purpleAccent),
                  ),
                ),
              ],
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Select Language'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedLanguage,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.transparent,
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.purpleAccent),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: Colors.purpleAccent,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              dropdownColor: Colors.black,
              iconEnabledColor: Colors.white,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              hint: const Text(
                'Choose a language',
                style: TextStyle(color: Colors.white70),
              ),
              items:
                  _languages.map((language) {
                    return DropdownMenuItem<String>(
                      value: language,
                      child: Text(
                        language,
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value;
                });
              },
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _selectedLanguage != null ? _handleContinue : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
              ),
              child: const Text("Continue"),
            ),
          ],
        ),
      ),
    );
  }
}
