import 'package:flutter/material.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({Key? key}) : super(key: key);

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  final List<String> _languages = ['Spanish', 'French', 'German', 'Chinese'];
  String? _selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Select Language',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DropdownButtonFormField<String>(
              value: _selected,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                labelText: 'Choose a language',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items:
                  _languages.map((String language) {
                    return DropdownMenuItem<String>(
                      value: language,
                      child: Text(language),
                    );
                  }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selected = newValue;
                });
              },
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _selected != null ? Colors.deepPurple : Colors.grey,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              onPressed:
                  _selected != null
                      ? () {
                        Navigator.pushNamed(
                          context,
                          '/fluencyAssessment',
                          arguments: _selected!,
                        );
                      }
                      : null,
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
