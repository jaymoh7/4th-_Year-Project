import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _checkVerification();
  }

  void _checkVerification() async {
    final authVM = context.read<AuthViewModel>();
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    final isVerified = await authVM.checkEmailVerification();
    if (isVerified && mounted) {
      Navigator.pushReplacementNamed(context, '/');
    } else {
      _checkVerification(); // Keep checking
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.orange[100],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mark_email_unread,
                size: 60,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Verify Your Email',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'We\'ve sent a verification email to:\n${authVM.currentUser?.email ?? ''}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please check your email and click the verification link to continue.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Waiting for verification...'),
            const SizedBox(height: 32),
            TextButton(
              onPressed: _isResending
                  ? null
                  : () async {
                setState(() => _isResending = true);
                await authVM.sendVerificationEmail();
                setState(() => _isResending = false);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Verification email resent!'),
                    ),
                  );
                }
              },
              child: _isResending
                  ? const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text('Resend Email'),
            ),
            TextButton(
              onPressed: () {
                authVM.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text('Use different account'),
            ),
          ],
        ),
      ),
    );
  }
}