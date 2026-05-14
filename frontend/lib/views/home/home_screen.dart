import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../services/translation_service.dart';
import '../../widgets/emergency_panel.dart';
import '../settings/settings_screen.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _micPulseController;
  final TextEditingController _typeController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _micPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _micPulseController.dispose();
    _typeController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onTypeChanged(String text, TranslationService service) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (text.trim().isNotEmpty) {
        service.translateTypedText(text.trim());
      }
    });
  }

  void _showLanguagePicker(BuildContext context, bool isSource) {
    final service = Provider.of<TranslationService>(context, listen: false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.7,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.withAlpha(100), borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 24),
              Text(isSource ? 'Origin Language' : 'Destination Language', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.primary)),
              const SizedBox(height: 16),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: TranslationService.supportedLanguages.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 70),
                  itemBuilder: (ctx2, index) {
                    final lang = TranslationService.supportedLanguages[index];
                    final isSelected = (isSource ? service.sourceLang : service.targetLang) == lang;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      leading: Text(lang.flag, style: const TextStyle(fontSize: 32)),
                      title: Text(lang.name, style: TextStyle(fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500, color: isSelected ? theme.colorScheme.primary : null)),
                      trailing: isSelected ? Icon(Icons.eco_rounded, color: theme.colorScheme.primary) : null,
                      onTap: () {
                      if (isSource) {
                        service.updateSourceLang(lang);
                      } else {
                        service.updateTargetLang(lang);
                      }
                      Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<TranslationService>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/home.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Container(color: Colors.black.withAlpha(isDark ? 140 : 80)), // Atmospheric overlay
          Positioned(
            top: -50,
            right: -50,
            child: Opacity(opacity: 0.1, child: Icon(Icons.forest_rounded, size: 300, color: theme.colorScheme.primary)),
          ),

          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildAppBar(context, theme, isDark),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // Phrasebook Section
                          FadeInUp(delay: const Duration(milliseconds: 200), child: _buildPhrasebook(service, theme)),
                          const SizedBox(height: 24),
                          
                          // Language Hub (Map Style)
                          FadeInDown(child: _buildLanguageHub(context, service, theme)),
                          const SizedBox(height: 24),
                          
                          // Main Translation Module
                          FadeInUp(delay: const Duration(milliseconds: 200), child: _buildLeafCard(service, theme, isDark)),
                          
                          const SizedBox(height: 24),
                          
                          // Input Mode
                          FadeInUp(delay: const Duration(milliseconds: 300), child: _buildModeToggle(service, theme)),
                          
                          const SizedBox(height: 24),
                          
                          // Emergency Portal
                          FadeInUp(delay: const Duration(milliseconds: 400), child: _buildEmergencyPortal(context, service, theme)),
                          
                          const SizedBox(height: 100),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Tools Overlay
          Positioned(
            top: 20, right: 20,
            child: IconButton(
              icon: Icon(Icons.settings_suggest_rounded, color: theme.colorScheme.primary, size: 28),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
          ),
          
          if (!service.isTypingMode)
            Positioned(bottom: 60, left: 0, right: 0, child: _buildNatureMic(service, theme)),
          
          if (service.isTypingMode)
            Positioned(
              bottom: 20, left: 0, right: 0, 
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: _buildDynamicTypingBar(context, service, theme, isDark),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, ThemeData theme, bool isDark) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: theme.colorScheme.surface.withAlpha(200),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Row(
          children: [
            const Icon(Icons.eco_rounded, color: Colors.green, size: 24),
            const SizedBox(width: 8),
            Text('HYLATOR TRANS', style: TextStyle(fontWeight: FontWeight.w900, color: theme.colorScheme.primary, letterSpacing: 1.2, fontSize: 18, shadows: [Shadow(color: theme.colorScheme.primary.withAlpha(100), blurRadius: 10)])),
          ],
        ),
      ),
      actions: [
        IconButton(onPressed: () => Navigator.pushNamed(context, '/history'), icon: const Icon(Icons.history_rounded)),
        IconButton(onPressed: () => Navigator.pushNamed(context, '/profile'), icon: const Icon(Icons.account_circle_rounded)),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildPhrasebook(TranslationService service, ThemeData theme) {
    final phrases = [
      {'text': 'Where is the sanctuary?', 'icon': Icons.home_rounded},
      {'text': 'I need a local guide', 'icon': Icons.map_rounded},
      {'text': 'How much for the journey?', 'icon': Icons.payments_rounded},
      {'text': 'Thank you for the hospitality', 'icon': Icons.favorite_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('THE SANCTUARY PHRASEBOOK', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: phrases.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final p = phrases[index];
              return InkWell(
                onTap: () {
                  _typeController.text = p['text'] as String;
                  _onTypeChanged(p['text'] as String, service);
                },
                child: Container(
                  width: 160,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: theme.colorScheme.primary.withAlpha(40)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(p['icon'] as IconData, size: 24, color: theme.colorScheme.primary),
                      const SizedBox(height: 8),
                      Text(p['text'] as String, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold), maxLines: 2),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageHub(BuildContext context, TranslationService service, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withAlpha(15),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: theme.colorScheme.primary.withAlpha(50)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _LangSelector(label: 'SOURCE', lang: service.sourceLang, onTap: () => _showLanguagePicker(context, true), theme: theme),
          GestureDetector(
            onTap: service.swapLanguages,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
              child: const Icon(Icons.sync_rounded, color: Colors.white, size: 28),
            ),
          ),
          _LangSelector(label: 'TARGET', lang: service.targetLang, onTap: () => _showLanguagePicker(context, false), theme: theme),
        ],
      ),
    );
  }

  Widget _buildLeafCard(TranslationService service, ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: theme.colorScheme.primary.withAlpha(60)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(isDark ? 80 : 10), blurRadius: 30, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          // Source
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Tag(label: 'ORIGIN', color: theme.colorScheme.primary),
                const SizedBox(height: 12),
                Text(service.sourceText, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, height: 1.4)),
              ],
            ),
          ),
          Divider(height: 1, color: theme.colorScheme.outlineVariant.withAlpha(60)),
          // Destination
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha(10),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _Tag(label: 'HARMONIZED', color: Colors.teal),
                    const Spacer(),
                    if (service.translatedText.isNotEmpty)
                      IconButton(onPressed: service.speakTranslation, icon: const Icon(Icons.volume_up_rounded, size: 20, color: Colors.teal)),
                  ],
                ),
                const SizedBox(height: 12),
                if (service.isTranslating)
                   const LinearProgressIndicator(minHeight: 2, borderRadius: BorderRadius.all(Radius.circular(10)))
                else
                  Text(
                    service.translatedText.isEmpty ? 'Awaiting signal...' : service.translatedText,
                    style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.primary, height: 1.2),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle(TranslationService service, ThemeData theme) {
    bool isType = service.isTypingMode;
    return Row(
      children: [
        Expanded(child: _NatureTab(icon: Icons.mic_rounded, label: 'Voice', active: !isType, onTap: () => service.setTypingMode(false), theme: theme)),
        const SizedBox(width: 16),
        Expanded(child: _NatureTab(icon: Icons.keyboard_rounded, label: 'Type', active: isType, onTap: () => service.setTypingMode(true), theme: theme)),
      ],
    );
  }

  Widget _buildEmergencyPortal(BuildContext context, TranslationService service, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.red.shade700, Colors.red.shade900]),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          const Icon(Icons.gpp_maybe_rounded, color: Colors.white, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
              Text('EMERGENCY PROTOCOL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
              Text('Instant SOS distress signals', style: TextStyle(color: Colors.white70, fontSize: 11)),
            ]),
          ),
          Switch.adaptive(
            value: service.isEmergencyMode,
            activeColor: Colors.white,
            onChanged: (v) {
              service.toggleEmergencyMode();
              if (v) showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, builder: (_) => const EmergencyPanel());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNatureMic(TranslationService service, ThemeData theme) {
    bool active = service.isListening;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: GestureDetector(
            onTap: active ? service.stopListening : service.startListening,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (active)
                  Pulse(
                    infinite: true,
                    child: Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.red.withAlpha(50), width: 4))),
                  ),
                AnimatedBuilder(
                  animation: _micPulseController,
                  builder: (_, __) => Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active ? Colors.red : theme.colorScheme.primary,
                      boxShadow: [
                        BoxShadow(
                          color: (active ? Colors.red : theme.colorScheme.primary).withAlpha(100), 
                          blurRadius: active ? 40 * _micPulseController.value : 20, 
                          spreadRadius: active ? 15 * _micPulseController.value : 2
                        )
                      ],
                    ),
                    child: Icon(active ? Icons.waves_rounded : Icons.mic_rounded, color: Colors.white, size: 40),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        FadeIn(
          animate: active,
          child: Text(
            active ? 'HYLATOR IS TUNING IN...' : 'TAP TO BROADCAST',
            style: TextStyle(fontWeight: FontWeight.w900, color: theme.colorScheme.primary, letterSpacing: 2, fontSize: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicTypingBar(BuildContext context, TranslationService service, ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(isDark ? 80 : 20), blurRadius: 24, offset: const Offset(0, 8)),
        ],
        border: Border.all(color: theme.colorScheme.primary.withAlpha(40)),
      ),
      child: TextField(
        controller: _typeController,
        onChanged: (v) => _onTypeChanged(v, service),
        decoration: InputDecoration(
          hintText: 'Share your thoughts with the world...',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
          filled: true,
          fillColor: theme.colorScheme.primary.withAlpha(15),
          prefixIcon: const Icon(Icons.short_text_rounded),
        ),
      ),
    );
  }
}

class _LangSelector extends StatelessWidget {
  final String label;
  final dynamic lang;
  final VoidCallback onTap;
  final ThemeData theme;
  const _LangSelector({required this.label, required this.lang, required this.onTap, required this.theme});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Text(lang.flag, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 4),
          Text(lang.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
          Text(label, style: TextStyle(fontSize: 9, color: theme.colorScheme.onSurface.withAlpha(100), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(100), border: Border.all(color: color.withAlpha(100))),
      child: Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
    );
  }
}

class _NatureTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final ThemeData theme;
  const _NatureTab({required this.icon, required this.label, required this.active, required this.onTap, required this.theme});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: active ? theme.colorScheme.primary : theme.colorScheme.primary.withAlpha(15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: active ? Colors.white : theme.colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: active ? Colors.white : theme.colorScheme.primary, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}
