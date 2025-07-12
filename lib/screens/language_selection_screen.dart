import 'package:flutter/material.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({Key? key}) : super(key: key);

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  final List<String> _languages = ['Spanish', 'French', 'German', 'Chinese'];
  String? _selectedLanguage;

  void _goToFluencyAssessment() {
    if (_selectedLanguage != null) {
      Navigator.pushNamed(
        context,
        '/fluencyAssessment',
        arguments: {'selectedLanguage': _selectedLanguage},
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
              onPressed:
                  _selectedLanguage != null ? _goToFluencyAssessment : null,
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
