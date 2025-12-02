import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final success = await authProvider.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        setState(() => _isLoading = false);
      }

      if (success) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    }
  }

  void _resetPassword() {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your email')));
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Text('Send password reset email to ${_emailController.text}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              final success = await authProvider.resetPassword(
                _emailController.text.trim(),
              );
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password reset email sent!')),
                );
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 40,
                    ),
                    child: Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        return Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Back button aligned to left
                              Align(
                                alignment: Alignment.centerLeft,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.arrow_back,
                                    color: Color(0xFF0066FF),
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Logo Section
                              _buildLogoSection(),

                              const SizedBox(height: 40),

                              // Title
                              const Text(
                                'Welcome Back!',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF0066FF),
                                  fontFamily: 'League Spartan',
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Subtitle
                              const Text(
                                'Sign in to continue',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                  fontFamily: 'League Spartan',
                                ),
                              ),

                              const SizedBox(height: 40),

                              // Email Field
                              TextFormField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  labelStyle: const TextStyle(
                                    fontFamily: 'League Spartan',
                                    color: Colors.black54,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.email_outlined,
                                    color: Color(0xFF0066FF),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.grey,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.grey,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF0066FF),
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!RegExp(
                                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                  ).hasMatch(value)) {
                                    return 'Invalid email address';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 20),

                              // Password Field
                              TextFormField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  labelStyle: const TextStyle(
                                    fontFamily: 'League Spartan',
                                    color: Colors.black54,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.lock_outline,
                                    color: Color(0xFF0066FF),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: const Color(0xFF0066FF),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.grey,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.grey,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF0066FF),
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                obscureText: _obscurePassword,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 10),

                              // Forgot Password Link
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _resetPassword,
                                  child: const Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      color: Color(0xFF0066FF),
                                      fontFamily: 'League Spartan',
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 30),

                              // Login Button
                              SizedBox(
                                width: 250,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed:
                                      (_isLoading || authProvider.isLoading)
                                      ? null
                                      : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0066FF),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: (_isLoading || authProvider.isLoading)
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'Sign In',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w500,
                                            fontFamily: 'League Spartan',
                                          ),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Sign Up Link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'New to CalmaWear?',
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontFamily: 'League Spartan',
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/signup');
                                    },
                                    child: const Text(
                                      'Create Account',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0066FF),
                                        fontFamily: 'League Spartan',
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // Error Display
                              if (authProvider.error != null) ...[
                                const SizedBox(height: 20),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.red),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        color: Colors.red,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _getErrorMessage(authProvider.error!),
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontFamily: 'League Spartan',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              // Bottom spacing
                              const SizedBox(height: 40),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        // Logo image
        Image.asset(
          'assets/images/blue-logo.png',
          width: 250,
          height: 250,
          fit: BoxFit.contain,
        ),

        const SizedBox(height: 10),
      ],
    );
  }

  String _getErrorMessage(String error) {
    if (error.contains('user-not-found')) {
      return 'No account found with this email';
    } else if (error.contains('wrong-password')) {
      return 'Incorrect password';
    } else if (error.contains('invalid-email')) {
      return 'Invalid email address';
    } else if (error.contains('network-request-failed')) {
      return 'Internet connection problem';
    } else if (error.contains('too-many-requests')) {
      return 'Too many attempts. Try again later';
    } else if (error.contains('user-disabled')) {
      return 'This account has been disabled';
    } else {
      return 'An error occurred. Please try again';
    }
  }
}
