import 'package:flutter/material.dart';
import '../../routes.dart';
import '../../theme/app_theme.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController(text: 'albart.ainstain@gmail.com');
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Simulate network authentication request
    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Successfully signed in! Welcome back.'),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
  }

  void _handleForgotPassword() {
    final resetEmailController = TextEditingController(text: _emailController.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Reset Password',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your email address and we will send you a link to reset your password.',
              style: TextStyle(fontSize: 13, color: AppTheme.greyText),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'Enter your email',
                prefixIcon: Icon(Icons.email_outlined, size: 20, color: AppTheme.greyText),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.greyText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(130, 44),
            ),
            onPressed: () {
              final email = resetEmailController.text.trim();
              if (email.isEmpty || !email.contains('@')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid email address')),
                );
                return;
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Password reset link sent to $email'),
                  backgroundColor: AppTheme.primaryColor,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Send Link'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSocialAuth(String provider) async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Signed in with $provider successfully!'),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
  }

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
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushReplacementNamed(context, AppRoutes.welcome);
                }
              },
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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Form(
                key: _formKey,
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
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(fontSize: 14, color: AppTheme.darkText, fontWeight: FontWeight.w500),
                      decoration: const InputDecoration(
                        hintText: 'Enter your email',
                        prefixIcon: Icon(Icons.email_outlined, color: AppTheme.greyText, size: 20),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter your email address';
                        }
                        if (!val.contains('@') || !val.contains('.')) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(fontSize: 14, color: AppTheme.darkText, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.greyText, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: AppTheme.greyText,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (val.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),

                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _handleForgotPassword,
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(color: AppTheme.primaryColor, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Sign In Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleSignIn,
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Sign In'),
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
                        _socialButton(
                          icon: Icons.apple,
                          label: 'Apple',
                          onTap: () => _handleSocialAuth('Apple'),
                        ),
                        const SizedBox(width: 16),
                        _socialButton(
                          icon: Icons.g_mobiledata,
                          label: 'Google',
                          isGoogle: true,
                          onTap: () => _handleSocialAuth('Google'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Footer: Sign Up link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Not Registered Yet? ', style: TextStyle(color: AppTheme.greyText, fontSize: 13)),
                        InkWell(
                          borderRadius: BorderRadius.circular(4),
                          onTap: () {
                            Navigator.pushNamed(context, AppRoutes.signup);
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                            child: Text(
                              'Sign Up',
                              style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _socialButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isGoogle = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 68,
          height: 52,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            color: isGoogle ? Colors.redAccent : AppTheme.darkText,
            size: isGoogle ? 34 : 26,
          ),
        ),
      ),
    );
  }
}