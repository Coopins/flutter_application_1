// lib/screens/auth/sign_in_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/routes.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtl = TextEditingController();
  final _passwordCtl = TextEditingController();

  bool _loading = false;
  String? _banner; // top error/info banner text

  @override
  void dispose() {
    _emailCtl.dispose();
    _passwordCtl.dispose();
    super.dispose();
  }

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.black54),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderSide: BorderSide.none,
      borderRadius: BorderRadius.circular(12),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  String _friendly(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found for that email.';
      case 'wrong-password':
        return 'Incorrect password. Try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment.';
      default:
        return e.message ?? 'Sign-in failed. Try again.';
    }
  }

  Future<void> _signIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _loading = true;
      _banner = null;
    });

    // Capture navigator/messenger before awaits to avoid context lint.
    final navigator = Navigator.of(context);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtl.text.trim(),
        password: _passwordCtl.text,
      );
      HapticFeedback.lightImpact();
      navigator.pushNamedAndRemoveUntil(Routes.home, (r) => false);
    } on FirebaseAuthException catch (e) {
      setState(() => _banner = _friendly(e));
    } catch (_) {
      setState(() => _banner = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtl.text.trim();
    if (email.isEmpty) {
      setState(() => _banner = 'Enter your email to reset your password.');
      return;
    }

    setState(() => _banner = null);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      messenger.showSnackBar(
        const SnackBar(content: Text('Password reset email sent.')),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _banner = _friendly(e));
    } catch (_) {
      setState(() => _banner = 'Could not send reset email. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF7C3AED);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Log In'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to main',
          onPressed: () {
            // Return to the marketing/landing screen
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(Routes.main, (r) => false);
          },
        ),
        actions: const [],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (_banner != null) ...[
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFB00020,
                          ).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(
                              0xFFB00020,
                            ).withValues(alpha: 0.9),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(
                                Icons.error_outline,
                                color: Colors.redAccent,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _banner!,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Email
                    TextFormField(
                      controller: _emailCtl,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(color: Colors.black87),
                      decoration: _dec('Email address'),
                      validator: (v) {
                        final t = (v ?? '').trim();
                        if (t.isEmpty) return 'Email is required';
                        final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(t);
                        return ok ? null : 'Enter a valid email';
                      },
                    ),
                    const SizedBox(height: 14),

                    // Password
                    TextFormField(
                      controller: _passwordCtl,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      style: const TextStyle(color: Colors.black87),
                      decoration: _dec('Password'),
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return 'Password is required';
                        if (v.length < 6) return 'Min 6 characters';
                        return null;
                      },
                      onFieldSubmitted: (_) => _signIn(),
                    ),

                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _loading ? null : _forgotPassword,
                        child: const Text(
                          'Forgot password?',
                          style: TextStyle(
                            color: purple,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _signIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child:
                            _loading
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text(
                                  'Log In',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
