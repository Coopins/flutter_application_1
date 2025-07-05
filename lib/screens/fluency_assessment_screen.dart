// lib/screens/fluency_assessment_screen.dart

import 'package:flutter/material.dart';

class FluencyAssessmentScreen extends StatelessWidget {
  const FluencyAssessmentScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: GestureDetector(
          onTap: () {
            // Navigate back to Home; user will then tap "My Lesson Plan"
            Navigator.pushNamed(context, '/home');
          },
          child: Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.smart_toy, size: 64, color: Colors.black),
            ),
          ),
        ),
      ),
    );
  }
}
