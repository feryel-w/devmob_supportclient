import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_theme.dart';
import '../services/auth_service.dart';
import 'signup_screen.dart';
import 'dashboard_screen.dart';
import 'admin_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
  if (!_formKey.currentState!.validate()) return;
  setState(() => _isLoading = true);
  try {
    await _authService.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    // Vérifier le rôle
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final role = await _authService.getUserRole(uid);

    if (!mounted) return;

    if (role == 'admin' || role == 'support') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  } on FirebaseAuthException catch (e) {
    if (!mounted) return;
    String message = 'Une erreur est survenue';
    if (e.code == 'user-not-found')    message = 'Aucun compte trouvé';
    if (e.code == 'wrong-password')    message = 'Mot de passe incorrect';
    if (e.code == 'invalid-email')     message = 'E-mail invalide';
    if (e.code == 'too-many-requests') message = 'Trop de tentatives';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.priorityHigh),
    );
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

  Future<void> _handleForgotPassword() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrez votre e-mail d\'abord')),
      );
      return;
    }
    try {
      await _authService.resetPassword(_emailController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('E-mail de réinitialisation envoyé !')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de l\'envoi')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 60),

                // Logo
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.headset_mic_outlined,
                    color: Colors.white,
                    size: 40,
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'SupportDesk',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your issues, resolved fast',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),

                const SizedBox(height: 48),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Email address',
                    prefixIcon: Icon(Icons.email_outlined, size: 18),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Champ requis';
                    if (!value.contains('@')) return 'E-mail invalide';
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline, size: 18),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 18,
                      ),
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Champ requis';
                    if (value.length < 6) return 'Minimum 6 caractères';
                    return null;
                  },
                ),

                const SizedBox(height: 14),

                // Remember me + Forgot password
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _rememberMe = !_rememberMe),
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppTheme.surfaceBorder),
                              color: _rememberMe
                                  ? AppTheme.primary
                                  : Colors.transparent,
                            ),
                            child: _rememberMe
                                ? const Icon(Icons.check,
                                    size: 11, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Remember me',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _handleForgotPassword,
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryLight,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Sign in button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text('Sign in'),
                  ),
                ),

                const SizedBox(height: 24),

                // Create account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'New here? ',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SignupScreen()),
                      ),
                      child: const Text(
                        'Create an account',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.primaryLight,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Divider
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: AppTheme.surfaceBorder),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Or continue with',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textHint,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: AppTheme.surfaceBorder),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Google + Microsoft buttons
                Row(
                  children: [
                    Expanded(
                      child: _SocialButton(
                        label: 'Google',
                        icon: Icons.g_mobiledata,
                        onTap: () {},
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SocialButton(
                        label: 'Microsoft',
                        icon: Icons.window,
                        onTap: () {},
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.surfaceBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.textPrimary, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}