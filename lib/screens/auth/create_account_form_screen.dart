// lib/screens/auth/create_account_form_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_application_1/routes.dart';

class CreateAccountFormScreen extends StatefulWidget {
  const CreateAccountFormScreen({super.key});

  @override
  State<CreateAccountFormScreen> createState() =>
      _CreateAccountFormScreenState();
}

class _CreateAccountFormScreenState extends State<CreateAccountFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _pw2Ctrl = TextEditingController();

  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    _pw2Ctrl.dispose();
    super.dispose();
  }

  String? _vEmail(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Email is required';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s);
    if (!ok) return 'Enter a valid email';
    return null;
  }

  String? _vPw(String? v) {
    final s = (v ?? '');
    if (s.length < 6) return 'Minimum 6 characters';
    return null;
  }

  String? _vPw2(String? v) {
    if (v != _pwCtrl.text) return 'Passwords do not match';
    return null;
  }

  String _friendlyAuthError(Object e) {
    if (e is! FirebaseAuthException) return 'Sign up failed. Please try again.';
    switch (e.code) {
      case 'email-already-in-use':
        return 'Email is already in use';
      case 'invalid-email':
        return 'Invalid email';
      case 'weak-password':
        return 'Password is too weak';
      case 'operation-not-allowed':
        return 'Account creation is not allowed';
      default:
        return e.message ?? 'Sign up failed';
    }
  }

  Future<void> _submit() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    HapticFeedback.selectionClick();

    try {
      final email = _emailCtrl.text.trim();
      final password = _pwCtrl.text; // never store this
      final name = _nameCtrl.text.trim();
      final phone = _phoneCtrl.text.trim();

      // 1) Create Firebase Auth user
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = cred.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'internal-error',
          message: 'User creation returned null user.',
        );
      }

      // 2) Optional: displayName in Auth profile
      if (name.isNotEmpty) {
        await user.updateDisplayName(name);
      }

      // 3) Create/merge Firestore profile (no password saved)
      final now = FieldValue.serverTimestamp();
      final profile = <String, dynamic>{
        'email': user.email,
        'provider': 'password',
        'createdAt': now,
        'updatedAt': now,
      };
      if (name.isNotEmpty) profile['name'] = name;
      if (phone.isNotEmpty) profile['phone'] = phone;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(profile, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Account created!')));

      // 4) Send new users to language picker
      Navigator.pushNamedAndRemoveUntil(
        context,
        Routes.languageSelection,
        (r) => false,
      );
    } catch (e) {
      if (!mounted) return;
      final msg = _friendlyAuthError(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final purple = const Color(0xFF7C3AED);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: AutofillGroup(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _LabeledField(
                    label: 'Name',
                    child: TextFormField(
                      controller: _nameCtrl,
                      autofillHints: const [AutofillHints.name],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(hintText: 'Your name'),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _LabeledField(
                    label: 'Phone (optional)',
                    child: TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: '555-123-4567',
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _LabeledField(
                    label: 'Email',
                    child: TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      validator: _vEmail,
                      decoration: const InputDecoration(
                        hintText: 'you@example.com',
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _LabeledField(
                    label: 'Password',
                    child: TextFormField(
                      controller: _pwCtrl,
                      obscureText: _obscure,
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.next,
                      validator: _vPw,
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility : Icons.visibility_off,
                            color: Colors.white70,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _LabeledField(
                    label: 'Confirm Password',
                    child: TextFormField(
                      controller: _pw2Ctrl,
                      obscureText: _obscure,
                      autofillHints: const [AutofillHints.password],
                      validator: _vPw2,
                      decoration: const InputDecoration(hintText: '••••••••'),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child:
                          _loading
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Text(
                                'Create Account',
                                style: TextStyle(fontSize: 16),
                              ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      Navigator.pushReplacementNamed(context, Routes.signIn);
                    },
                    child: const Text('Already have an account? Sign in'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Theme(
          data: Theme.of(context).copyWith(
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF1A1F29),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              hintStyle: const TextStyle(color: Colors.white38),
            ),
          ),
          child: child,
        ),
      ],
    );
  }
}
