import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/routes.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<Map<String, dynamic>?> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final snap =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      return snap.data();
    } catch (_) {
      return null;
    }
  }

  Future<void> _logout() async {
    final navigator = Navigator.of(context);
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    navigator.pushNamedAndRemoveUntil(Routes.main, (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      backgroundColor: Colors.black,
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _loadProfile(),
        builder: (context, snap) {
          final data = snap.data ?? {};
          final first = (data['firstName'] ?? '').toString().trim();
          final last = (data['lastName'] ?? '').toString().trim();
          final fallbackName = [
            first,
            last,
          ].where((s) => s.isNotEmpty).join(' ');
          final name =
              (user?.displayName?.trim().isNotEmpty == true)
                  ? user!.displayName!
                  : (fallbackName.isNotEmpty ? fallbackName : 'User');

          final email = user?.email ?? data['email'] ?? '(none)';
          final phone = data['phoneNumber'] ?? '(none)';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFF7C3AED),
                    child: Text(
                      (name.isNotEmpty ? name[0] : 'U').toUpperCase(),
                      style: const TextStyle(fontSize: 24, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _infoTile('Email', email),
              _infoTile('Phone', phone),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.logout),
                label: const Text(
                  'Log out',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _infoTile(String label, String value, {bool mono = false}) {
    return Card(
      color: const Color(0xFF1A1F29),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        title: Text(label, style: const TextStyle(color: Colors.white70)),
        subtitle: Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontFamily: mono ? 'monospace' : null,
          ),
        ),
      ),
    );
  }
}
