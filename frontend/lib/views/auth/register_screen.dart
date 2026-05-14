import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../services/auth_service.dart';
import 'dart:ui';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    setState(() => _errorMessage = null);

    final name = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    final phone = _phoneController.text.trim();

    // Validation
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all required fields.');
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }
    if (password != confirm) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    setState(() => _isLoading = true);
    final auth = context.read<AuthService>();
    final result = await auth.register(email, password, name, phone);

    if (mounted) {
      setState(() => _isLoading = false);
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Account created! Please sign in.'),
            backgroundColor: Color(0xFF22C55E),
          ),
        );
        if (mounted) Navigator.pop(context);
      } else {
        setState(() => _errorMessage = result.error ?? 'Registration failed.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF1A1C2C), const Color(0xFF0D0E14)]
                      : [const Color(0xFFEEF2FF), Colors.white],
                ),
              ),
            ),
          ),

          // Blurred decorations
          Positioned(top: -80, right: -80,
            child: _Blob(color: theme.colorScheme.primary.withAlpha(40), size: 260)),
          Positioned(bottom: -80, left: -80,
            child: _Blob(color: theme.colorScheme.secondary.withAlpha(30), size: 220)),

          // Form
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeInDown(
                duration: const Duration(milliseconds: 700),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      padding: const EdgeInsets.all(36),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black.withAlpha(100) : Colors.white.withAlpha(150),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: isDark ? Colors.white.withAlpha(20) : Colors.white.withAlpha(120),
                        ),
                        boxShadow: [BoxShadow(color: Colors.black.withAlpha(24), blurRadius: 30, offset: const Offset(0, 14))],
                      ),
                      child: Column(
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withAlpha(24),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.person_add_rounded, size: 42, color: theme.colorScheme.primary),
                          ),
                          const SizedBox(height: 20),
                          Text('Create Account',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            )),
                          const SizedBox(height: 6),
                          Text('Join Hybrid Translator Pro',
                            style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.black45)),
                          const SizedBox(height: 32),

                          // Error banner
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.red.withAlpha(20),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.withAlpha(80)),
                              ),
                              child: Row(children: [
                                const Icon(Icons.error_outline_rounded, color: Colors.red, size: 18),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_errorMessage!,
                                  style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500))),
                              ]),
                            ),
                            const SizedBox(height: 20),
                          ],

                          _field(_fullNameController, 'Full Name', Icons.badge_rounded, isDark, theme),
                          const SizedBox(height: 16),
                          _field(_emailController, 'Email Address', Icons.alternate_email_rounded, isDark, theme,
                            keyboardType: TextInputType.emailAddress),
                          const SizedBox(height: 16),
                          _field(_phoneController, 'Phone (optional)', Icons.phone_rounded, isDark, theme,
                            keyboardType: TextInputType.phone),
                          const SizedBox(height: 16),
                          _passwordField(_passwordController, 'Password', _obscurePassword, isDark, theme,
                            () => setState(() => _obscurePassword = !_obscurePassword)),
                          const SizedBox(height: 16),
                          _passwordField(_confirmController, 'Confirm Password', _obscureConfirm, isDark, theme,
                            () => setState(() => _obscureConfirm = !_obscureConfirm)),
                          const SizedBox(height: 28),

                          // Submit
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleRegister,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: _isLoading
                                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                  : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Already have an account?',
                                style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, bool isDark, ThemeData theme,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B)),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: theme.colorScheme.primary.withAlpha(180)),
        filled: true,
        fillColor: isDark ? Colors.white.withAlpha(12) : Colors.grey.withAlpha(12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
      ),
    );
  }

  Widget _passwordField(TextEditingController ctrl, String label, bool obscure, bool isDark, ThemeData theme, VoidCallback toggle) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B)),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Icons.lock_outline_rounded, color: theme.colorScheme.primary.withAlpha(180)),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded),
          onPressed: toggle,
          color: isDark ? Colors.white38 : Colors.black38,
        ),
        filled: true,
        fillColor: isDark ? Colors.white.withAlpha(12) : Colors.grey.withAlpha(12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  const _Blob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}
