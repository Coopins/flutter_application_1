import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/routes.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _changePassword(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    final messenger = ScaffoldMessenger.of(context);

    if (user == null || user.email == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No email on file for this account.')),
      );
      return;
    }

    // Check the provider supports password reset.
    final providers = user.providerData.map((p) => p.providerId).toList();
    if (!providers.contains('password')) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Password reset isn’t available for this sign-in method.',
          ),
        ),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
      messenger.showSnackBar(
        SnackBar(content: Text('Reset email sent to ${user.email!}')),
      );
    } on FirebaseAuthException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message ?? 'Failed.')));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to send email.')),
      );
    }
  }

  Future<void> _editDisplayName(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final controller = TextEditingController(text: user.displayName ?? '');
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Edit display name'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(hintText: 'Your name'),
            onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (newName == null) return;
    if (newName.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Name cannot be empty.')),
      );
      return;
    }

    try {
      await user.updateDisplayName(newName);

      // Best-effort split into first/last for Firestore.
      final parts = newName.split(' ');
      final first = parts.isNotEmpty ? parts.first : newName;
      final last = parts.length > 1 ? parts.sublist(1).join(' ') : '';

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'displayName': newName,
        'firstName': first,
        'lastName': last,
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      HapticFeedback.lightImpact();
      messenger.showSnackBar(const SnackBar(content: Text('Name updated.')));
      navigator.pop(); // return to previous? (keeps us on settings if removed)
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not update name.')),
      );
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete account?'),
            content: const Text(
              'This action is permanent and will remove your account and data.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    try {
      // Remove user doc (best effort). You may also want to clean subcollections in a Cloud Function.
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .delete()
          .catchError((_) {});
      await user.delete();
      messenger.showSnackBar(const SnackBar(content: Text('Account deleted.')));
      navigator.pushNamedAndRemoveUntil(Routes.main, (r) => false);
    } on FirebaseAuthException catch (e) {
      final msg =
          (e.code == 'requires-recent-login')
              ? 'Please log out and log back in, then try again.'
              : (e.message ?? 'Could not delete account.');
      messenger.showSnackBar(SnackBar(content: Text(msg)));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not delete account.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader('Account'),
          _tile(
            icon: Icons.key,
            label: 'Change password',
            subtitle: 'Send a reset email',
            onTap: () => _changePassword(context),
          ),
          _tile(
            icon: Icons.badge,
            label: 'Edit display name',
            onTap: () => _editDisplayName(context),
          ),
          _tile(
            icon: Icons.translate,
            label: 'Language selection',
            onTap:
                () => Navigator.of(context).pushNamed(Routes.languageSelection),
          ),
          const SizedBox(height: 8),
          const _SectionHeader('Danger zone'),
          _tile(
            icon: Icons.delete_forever,
            label: 'Delete account',
            subtitle: 'This cannot be undone',
            color: Colors.redAccent,
            onTap: () => _deleteAccount(context),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String label,
    String? subtitle,
    Color? color,
    required VoidCallback onTap,
  }) {
    return Card(
      color: const Color(0xFF1A1F29),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(icon, color: color ?? Colors.white),
        title: Text(label, style: const TextStyle(color: Colors.white)),
        subtitle:
            subtitle == null
                ? null
                : Text(subtitle, style: const TextStyle(color: Colors.white70)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white70),
        onTap: onTap,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
          letterSpacing: 0.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
