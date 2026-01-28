import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class ErrorFallbackPage extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;

  const ErrorFallbackPage({
    super.key,
    required this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Color(0xFFFF6B35),
                  size: 60,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Something went wrong',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'We encountered an issue while starting the app. Please try again.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (error.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Error: ${_sanitizeError(error)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontFamilyFallback: const ['monospace', 'Courier New', 'Courier'],
                    ),
                  ),
                ),
              const SizedBox(height: 32),
              if (onRetry != null)
                ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Try Again',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // Navigate to a basic version of the app
                  Navigator.of(context).pushReplacementNamed('/home');
                },
                child: const Text(
                  'Continue Anyway',
                  style: TextStyle(
                    color: Color(0xFFFF6B35),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Sanitize error message for display
  String _sanitizeError(String error) {
    if (kDebugMode) {
      // In debug mode, show full error but still limit length for UI
      return error.length > 500 ? '${error.substring(0, 500)}...' : error;
    } else {
      // In release mode, sanitize and limit error details
      String sanitized = error
          .replaceAll(RegExp(r'file:///[^\s]*'), '[file path]') // Remove file paths
          .replaceAll(RegExp(r'package:[^\s]*'), '[package]') // Remove package paths
          .replaceAll(RegExp(r'#\d+\s+[^\n]*'), '') // Remove stack trace lines
          .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
          .trim();
      
      // Limit length and provide generic message if too long
      if (sanitized.length > 200) {
        return 'An unexpected error occurred. Please try again.';
      }
      
      return sanitized.isEmpty ? 'An error occurred' : sanitized;
    }
  }
}