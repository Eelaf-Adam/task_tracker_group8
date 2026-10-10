import 'package:flutter/material.dart';
import '../../routes.dart';
import '../../theme/app_theme.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({Key? key}) : super(key: key);

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final TextEditingController _emailController = TextEditingController(text: 'albart.ainstain@gmail.com');
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: const Color(0xFFF1F5F9),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppTheme.darkText),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text(
          'Sign In',
          style: TextStyle(color: AppTheme.darkText, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome Back',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.darkText),
              ),
              const SizedBox(height: 6),
              const Text(
                'Please enter your email address and password for login',
                style: TextStyle(fontSize: 13, color: AppTheme.greyText),
              ),
              const SizedBox(height: 28),

              // Email Field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(fontSize: 14, color: AppTheme.darkText, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),

              // Password Field
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppTheme.greyText, size: 20),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Forgot Password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(color: AppTheme.primaryColor, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Sign In Button
              ElevatedButton(
                onPressed: () {
                  // TODO: Hook up authentication / navigate to dashboard
                },
                child: const Text('Sign In'),
              ),
              const SizedBox(height: 24),

              // Divider "Sign in with"
              const Center(
                child: Text(
                  'Sign in with',
                  style: TextStyle(color: AppTheme.greyText, fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),

              // Social Icons Row (Apple & Google)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _socialButton(Icons.apple, () {}),
                  const SizedBox(width: 16),
                  _socialButton(Icons.g_mobiledata, () {}, isGoogle: true),
                ],
              ),
              const SizedBox(height: 32),

              // Footer: Sign Up link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Not Registered Yet? ', style: TextStyle(color: AppTheme.greyText, fontSize: 13)),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, AppRoutes.signup),
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _socialButton(IconData icon, VoidCallback onTap, {bool isGoogle = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 60,
        height: 50,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: isGoogle ? Colors.redAccent : AppTheme.darkText, size: isGoogle ? 32 : 24),
      ),
    );
  }
}