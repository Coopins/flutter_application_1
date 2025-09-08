// lib/screens/auth/auth_gate.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/routes.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (snap.data == null) {
          // Not signed in -> send to Sign In
          Future.microtask(() {
            if (!context.mounted) return;
            Navigator.of(context)
                .pushNamedAndRemoveUntil(Routes.signIn, (r) => false);
          });
          return const SizedBox.shrink();
        }
        // Signed in -> go Home
        Future.microtask(() {
          if (!context.mounted) return;
          Navigator.of(context)
              .pushNamedAndRemoveUntil(Routes.home, (r) => false);
        });
        return const SizedBox.shrink();
      },
    );
  }
}
