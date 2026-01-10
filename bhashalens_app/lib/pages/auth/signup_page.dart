import 'package:bhashalens_app/services/firebase_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match.';
        _isLoading = false;
      });
      return;
    }

    final authService = Provider.of<FirebaseAuthService>(
      context,
      listen: false,
    );
    final user = await authService.signUpWithEmailAndPassword(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (mounted) {
      if (user != null) {
        // Handle successful signup (e.g., show verification message or navigate to home)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign up successful! Please log in.')),
        );
        Navigator.of(
          context,
        ).pushReplacementNamed('/login'); // Navigate to login after signup
      } else {
        setState(() {
          _errorMessage = 'Failed to sign up. Please try again.';
        });
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<FirebaseAuthService>(
        context,
        listen: false,
      );
      final user = await authService.signInWithGoogle();

      if (mounted) {
        if (user != null) {
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Google Sign-In cancelled'),
              backgroundColor: Colors.orangeAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Simplify the error message for the user
          if (e.toString().contains('MissingPluginException')) {
            _errorMessage =
                "Google Sign-In is not supported on Windows Desktop.";
          } else {
            _errorMessage = e.toString().contains('firebase_auth')
                ? e.toString().split('] ').last
                : e.toString();
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color bgDark = Color(0xFF101822);
    const Color cardDark = Color(0xFF1E293B);
    const Color primaryTeal = Color(
      0xFF26C6DA,
    ); // Using consistent Primary color
    const Color textGrey = Color(0xFF9DA8B9);

    return Scaffold(
      backgroundColor: bgDark,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Sign Up',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'BhashaLens - Your language companion',
                textAlign: TextAlign.center,
                style: TextStyle(color: textGrey, fontSize: 14),
              ),
              const SizedBox(height: 48),

              // Email Input
              Container(
                decoration: BoxDecoration(
                  color: cardDark.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Email',
                    hintStyle: TextStyle(color: Colors.white38),
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: Colors.white38,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Password Input
              Container(
                decoration: BoxDecoration(
                  color: cardDark.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Password',
                    hintStyle: TextStyle(color: Colors.white38),
                    prefixIcon: Icon(Icons.lock_outline, color: Colors.white38),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Confirm Password Input
              Container(
                decoration: BoxDecoration(
                  color: cardDark.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Confirm Password',
                    hintStyle: TextStyle(color: Colors.white38),
                    prefixIcon: Icon(Icons.lock_reset, color: Colors.white38),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Sign Up Button
              ElevatedButton(
                onPressed: _isLoading ? null : _signUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(
                    0xFF136DEC,
                  ), // Slightly darker blue for Signup as per mockup
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: const StadiumBorder(),
                  elevation: 8,
                  shadowColor: const Color(0xFF136DEC).withValues(alpha: 0.4),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 16),

              // Google Sign In
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _signInWithGoogle,
                icon: Image.asset('assets/google_logo.png', height: 20),
                label: const Text('Sign up with Google'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.transparent,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: const StadiumBorder(),
                ),
              ),

              const SizedBox(height: 32),

              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Already have an account? ",
                    style: TextStyle(color: textGrey),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop(); // Go back to login
                    },
                    child: const Text(
                      "Login",
                      style: TextStyle(
                        color: primaryTeal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
