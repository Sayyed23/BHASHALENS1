import 'dart:async';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _canSkip = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _animationController.forward();

    // Allow skipping after 1 second
    Timer(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _canSkip = true;
        });
      }
    });

    // Auto-complete after 1.5 seconds
    Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _skipSplash() {
    if (_canSkip) {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final logoSize = (size.width * 0.4).clamp(150.0, 200.0);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      body: GestureDetector(
        onTap: _skipSplash,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: _animation,
                child: Container(
                  width: logoSize,
                  height: logoSize,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.translate,
                    color: Colors.white,
                    size: 80,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FadeTransition(
                opacity: _animation,
                child: const Text(
                  'BhashaLens',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF6B35),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FadeTransition(
                opacity: _animation,
                child: const Text(
                  'Breaking Language Barriers',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF757575),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
                ),
              ),
              const SizedBox(height: 20),
              if (_canSkip)
                FadeTransition(
                  opacity: _animation,
                  child: const Text(
                    'Tap to continue',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9E9E9E),
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
