import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../services/auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  void _handleLogin() async {
    setState(() => _errorMessage = null);
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'The grove requires your credentials.');
      return;
    }

    final auth = context.read<AuthService>();
    setState(() => _isLoading = true);

    final success = await auth.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (!success) _errorMessage = auth.lastError ?? 'Access denied to the sanctuary.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // ── Nature Aesthetic Background ─────────────────────────────────────
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/profile.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Container(color: Colors.black.withAlpha(isDark ? 150 : 100)), // Readability overlay
          Positioned(
            top: -100,
            left: -100,
            child: Opacity(opacity: 0.1, child: Icon(Icons.public_rounded, size: 400, color: theme.colorScheme.primary)),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Opacity(opacity: 0.1, child: Icon(Icons.park_rounded, size: 300, color: theme.colorScheme.primary)),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: FadeInDown(
                    duration: const Duration(milliseconds: 1000),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Floating Hero Card
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withAlpha(220),
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(color: theme.colorScheme.primary.withAlpha(60)),
                            boxShadow: [
                              BoxShadow(color: theme.colorScheme.primary.withAlpha(40), blurRadius: 40, spreadRadius: 5, offset: const Offset(0, 10)),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Logo
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withAlpha(20),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.eco_rounded, size: 48, color: theme.colorScheme.primary),
                              ),
                              const SizedBox(height: 20),
                              Text('HYLATOR', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: theme.colorScheme.primary, letterSpacing: 4.0)),
                              Text('THE HYBRID JOURNEY', style: TextStyle(fontSize: 10, letterSpacing: 2.0, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface.withAlpha(120))),
                              
                              const SizedBox(height: 32),

                              if (_errorMessage != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(color: Colors.red.withAlpha(15), borderRadius: BorderRadius.circular(12)),
                                    child: Row(children: [
                                      const Icon(Icons.error_outline_rounded, color: Colors.red, size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold))),
                                    ]),
                                  ),
                                ),

                              _buildField(_emailController, 'Email Address', Icons.alternate_email_rounded, theme),
                              const SizedBox(height: 16),
                              _buildField(_passwordController, 'Access Key', Icons.key_rounded, theme, obscure: _obscurePassword, suffix: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_rounded : Icons.visibility_off_rounded, size: 18),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              )),
                              
                              const SizedBox(height: 32),

                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 8,
                                    shadowColor: theme.colorScheme.primary.withAlpha(100),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                  child: _isLoading 
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Text('ENTER SANCTUARY', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                                ),
                              ),
                              
                              const SizedBox(height: 24),
                              
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('New Seed?', style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(140), fontSize: 13)),
                                  TextButton(
                                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                                    child: const Text('Grow Account', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.green)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildField(TextEditingController ctrl, String hint, IconData icon, ThemeData theme, {bool obscure = false, Widget? suffix}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: theme.colorScheme.primary),
        suffixIcon: suffix,
        filled: true,
        fillColor: theme.colorScheme.primary.withAlpha(10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
      ),
    );
  }
}
