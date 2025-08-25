import 'package:flutter/material.dart';

class CreateAccountScreen extends StatelessWidget {
  const CreateAccountScreen({Key? key}) : super(key: key);

  Widget _buildBtn(
    BuildContext ctx,
    IconData icon,
    String label,
    String route,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: Icon(icon, size: 24),
          label: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          onPressed: () => Navigator.pushNamed(ctx, route),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Create an account',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),

              // Social / SSO buttons
              _buildBtn(
                context,
                Icons.apple,
                'Continue with Apple',
                '/payment',
              ),
              _buildBtn(
                context,
                Icons.g_translate,
                'Continue with Google',
                '/payment',
              ),
              _buildBtn(
                context,
                Icons.facebook,
                'Continue with Facebook',
                '/payment',
              ),

              // Email goes to the form screen
              _buildBtn(
                context,
                Icons.email,
                'Continue with Email',
                '/createForm',
              ),

              // SSO also goes direct to payment
              _buildBtn(context, Icons.login, 'Continue with SSO', '/payment'),

              const SizedBox(height: 40),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/login'),
                child: const Text(
                  'Already have an account? Log in',
                  style: TextStyle(
                    color: Colors.white,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
