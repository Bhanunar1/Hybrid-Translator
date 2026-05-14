import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../services/auth_service.dart';
import '../../services/translation_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _dobController;
  late TextEditingController _nationalityController;
  late TextEditingController _homeController;
  late TextEditingController _destController;
  late TextEditingController _historyController;
  
  String? _selectedSourceLang;
  String? _selectedTargetLang;
  bool _isSaving = false;
  bool _hasChanges = false;

  static final List<String> _languages = TranslationService.supportedLanguages.map((l) => l.name).toList();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthService>().currentUser;
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _dobController = TextEditingController(text: user?.dob ?? '');
    _nationalityController = TextEditingController(text: user?.nationality ?? '');
    _homeController = TextEditingController(text: user?.homeCountry ?? '');
    _destController = TextEditingController(text: user?.currentDestination ?? '');
    _historyController = TextEditingController(text: user?.travelHistory ?? '');
    _selectedSourceLang = user?.preferredSourceLang ?? 'English';
    _selectedTargetLang = user?.preferredTargetLang ?? 'Telugu';

    for (final c in [_nameController, _bioController, _dobController, _nationalityController, _homeController, _destController, _historyController]) {
      c.addListener(() => setState(() => _hasChanges = true));
    }
  }

  @override
  void dispose() {
    for (final c in [_nameController, _bioController, _dobController, _nationalityController, _homeController, _destController, _historyController]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final success = await context.read<AuthService>().updatePreferences(
      fullName: _nameController.text.trim(),
      bio: _bioController.text.trim(),
      dob: _dobController.text.trim(),
      nationality: _nationalityController.text.trim(),
      homeCountry: _homeController.text.trim(),
      currentDestination: _destController.text.trim(),
      travelHistory: _historyController.text.trim(),
      sourceLang: _selectedSourceLang,
      targetLang: _selectedTargetLang,
    );

    setState(() { _isSaving = false; _hasChanges = false; });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '✅ Profile updated successfully!' : '❌ Update failed. Try again.'),
          backgroundColor: success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      if (success) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('SETTINGS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 13)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.primary,
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isSaving ? null : _save,
              child: Text('SAVE', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w900)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            FadeInDown(child: _Section(
              title: 'IDENTITY',
              icon: Icons.person_rounded,
              children: [
                _Field(label: 'Full Name', controller: _nameController, icon: Icons.badge_rounded, validator: (v) => v!.isEmpty ? 'Required' : null),
                _Field(label: 'Personal Bio', controller: _bioController, icon: Icons.description_rounded, maxLines: 3),
                _Field(label: 'Date of Birth', controller: _dobController, icon: Icons.cake_rounded, hint: 'e.g. 1995-05-12'),
              ],
            )),
            const SizedBox(height: 16),

            FadeInDown(delay: const Duration(milliseconds: 100), child: _Section(
              title: 'IDENTITY & HERITAGE',
              icon: Icons.flag_rounded,
              children: [
                _Field(label: 'Nationality', controller: _nationalityController, icon: Icons.flag_rounded),
                _Field(label: 'Home Country', controller: _homeController, icon: Icons.home_rounded),
              ],
            )),
            const SizedBox(height: 16),

            FadeInDown(delay: const Duration(milliseconds: 200), child: _Section(
              title: 'JOURNEY',
              icon: Icons.map_rounded,
              children: [
                _Field(label: 'Current Destination', controller: _destController, icon: Icons.navigation_rounded),
                _Field(label: 'Travel History (comma separated)', controller: _historyController, icon: Icons.history_rounded, hint: 'e.g. India, USA, Japan, UK'),
              ],
            )),
            const SizedBox(height: 16),

            FadeInDown(delay: const Duration(milliseconds: 300), child: _Section(
              title: 'LANGUAGE PREFERENCES',
              icon: Icons.language_rounded,
              children: [
                _buildDropdown(theme, 'Source Language', _selectedSourceLang, (v) => setState(() { _selectedSourceLang = v; _hasChanges = true; }), Icons.mic_rounded),
                const SizedBox(height: 12),
                _buildDropdown(theme, 'Target Language', _selectedTargetLang, (v) => setState(() { _selectedTargetLang = v; _hasChanges = true; }), Icons.translate_rounded),
              ],
            )),
            const SizedBox(height: 16),

            FadeInDown(delay: const Duration(milliseconds: 400), child: _buildAccountSystemSection(context, theme)),
            
            const SizedBox(height: 40),

            FadeInUp(child: SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 4,
                ),
                child: _isSaving
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('SAVE HYLATOR PROFILE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            )),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(ThemeData theme, String label, String? value, ValueChanged<String?> onChanged, IconData icon) {
    final safeValue = (_languages.contains(value)) ? value : _languages.first;
    return DropdownButtonFormField<String>(
      value: safeValue,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: theme.colorScheme.primary.withAlpha(10),
      ),
      borderRadius: BorderRadius.circular(20),
      items: _languages.map((l) => DropdownMenuItem(value: l, child: Text(l, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildAccountSystemSection(BuildContext context, ThemeData theme) {
    return _Section(
      title: 'ACCOUNT & SYSTEM',
      icon: Icons.admin_panel_settings_rounded,
      children: [
        _SystemTile(
          icon: Icons.info_rounded,
          title: 'About Hylator Project',
          subtitle: 'Learn about the hybrid translation journey',
          onTap: () => _showAboutDialog(context, theme),
        ),
        _SystemTile(
          icon: Icons.contact_support_rounded,
          title: 'Contact Support',
          subtitle: 'Reach out to the sanctuary keepers',
          onTap: () => _showContactDialog(context, theme),
        ),
        _SystemTile(
          icon: Icons.verified_user_rounded,
          title: 'Verify Account Identity',
          subtitle: 'Securely verify your password',
          onTap: () => _showVerifyPasswordDialog(context, theme),
        ),
        const _SystemTile(
          icon: Icons.api_rounded,
          title: 'Technologies Version',
          subtitle: 'Hylator App v4.0.0 (Production) • FastAPI Backend',
        ),
        const Divider(height: 32),
        _SystemTile(
          icon: Icons.logout_rounded,
          title: 'Sign Out',
          subtitle: 'Leave the sanctuary',
          color: Colors.orange,
          onTap: () async {
            await context.read<AuthService>().logout();
            if (context.mounted) {
              Navigator.pop(context);
            }
          },
        ),
        _SystemTile(
          icon: Icons.delete_forever_rounded,
          title: 'Delete My Account',
          subtitle: 'Permanently erase all your data',
          color: Colors.red,
          onTap: () => _showDeleteAccountDialog(context, theme),
        ),
      ],
    );
  }

  void _showAboutDialog(BuildContext context, ThemeData theme) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Row(children: [Icon(Icons.eco_rounded, color: Colors.green), SizedBox(width: 8), Text('About Hylator')]),
      content: const Text('Hylator is an advanced hybrid translation application designed for travelers. It bridges language barriers through a combination of cloud and local machine learning models, offering a seamless "Traveller Log" and emergency SOS system inspired by nature.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE'))],
    ));
  }

  void _showContactDialog(BuildContext context, ThemeData theme) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Row(children: [Icon(Icons.contact_support_rounded, color: Colors.blue), SizedBox(width: 8), Text('Contact Support')]),
      content: const Text('Need assistance on your journey?\n\nReach us at: support@hylator.com\nEmergency Line: +1-800-HYLATOR'),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE'))],
    ));
  }

  void _showVerifyPasswordDialog(BuildContext context, ThemeData theme) {
    final pwdController = TextEditingController();
    bool isVerifying = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Verify Identity', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter your password to verify your account identity.', style: TextStyle(fontSize: 13)),
              const SizedBox(height: 16),
              TextField(
                controller: pwdController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: isVerifying ? null : () => Navigator.pop(ctx), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: isVerifying ? null : () async {
                if (pwdController.text.isEmpty) return;
                setState(() => isVerifying = true);
                final success = await context.read<AuthService>().verifyPassword(pwdController.text);
                setState(() => isVerifying = false);
                if (success) {
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Identity Verified Successfully!'), backgroundColor: Colors.green));
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Incorrect password'), backgroundColor: Colors.red));
                  }
                }
              },
              child: isVerifying ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('VERIFY'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, ThemeData theme) {
    bool isDeleting = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Row(children: [Icon(Icons.warning_rounded, color: Colors.red), SizedBox(width: 8), Text('Delete Account', style: TextStyle(color: Colors.red))]),
          content: const Text('Are you absolutely sure you want to delete your Hylator account? This action cannot be undone and all your travel logs will be lost forever.'),
          actions: [
            TextButton(onPressed: isDeleting ? null : () => Navigator.pop(ctx), child: const Text('CANCEL')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: isDeleting ? null : () async {
                setState(() => isDeleting = true);
                final success = await context.read<AuthService>().deleteAccount();
                if (success) {
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) Navigator.pop(context); // Close settings screen
                } else {
                  setState(() => isDeleting = false);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Failed to delete account'), backgroundColor: Colors.red));
                  }
                }
              },
              child: isDeleting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('DELETE FOREVER'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SystemTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? color;
  final VoidCallback? onTap;

  const _SystemTile({required this.icon, required this.title, required this.subtitle, this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fgColor = color ?? theme.colorScheme.onSurface;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: fgColor.withAlpha(20), shape: BoxShape.circle),
        child: Icon(icon, color: fgColor, size: 20),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: fgColor, fontSize: 14)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withAlpha(150))),
      trailing: onTap != null ? const Icon(Icons.chevron_right_rounded, size: 20) : null,
      onTap: onTap,
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _Section({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(80)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 14, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: theme.colorScheme.primary, letterSpacing: 1.5)),
          ]),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final int maxLines;
  final String? hint;
  final String? Function(String?)? validator;

  const _Field({required this.label, required this.controller, required this.icon, this.maxLines = 1, this.hint, this.validator});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          filled: true,
          fillColor: theme.colorScheme.primary.withAlpha(10),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(100))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.colorScheme.primary, width: 2)),
        ),
      ),
    );
  }
}
