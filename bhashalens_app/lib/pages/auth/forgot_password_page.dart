import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bhashalens_app/services/supabase_auth_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final authService = Provider.of<SupabaseAuthService>(
      context,
      listen: false,
    );
    final String? error = await authService.resetPasswordForEmail(
      _emailController.text.trim(),
    );

    if (mounted) {
      if (error == null) {
        setState(() {
          _successMessage =
              'Password reset email sent! Check your inbox and click the link to reset your password.';
        });

        // Show additional information about deep linking
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'If you have the app installed, clicking the link will open BhashaLens directly!',
            ),
            duration: Duration(seconds: 4),
            backgroundColor: Colors.blue,
          ),
        );
      } else {
        setState(() {
          _errorMessage = error;
        });
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Enter your Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              if (_successMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _successMessage!,
                    style: const TextStyle(color: Colors.green),
                  ),
                ),
              ElevatedButton(
                onPressed: _isLoading ? null : _resetPassword,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Reset Password'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Go back to login
                },
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
