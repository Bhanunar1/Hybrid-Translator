import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shimmer/shimmer.dart';
import '../../services/translation_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/emergency_panel.dart';
import '../../utils/color_extensions.dart';
import 'dart:ui';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // ── Language picker ──────────────────────────────────────────────────────────
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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(100),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isSource ? 'Source Language' : 'Target Language',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: TranslationService.supportedLanguages.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 70),
                  itemBuilder: (ctx2, index) {
                    final lang = TranslationService.supportedLanguages[index];
                    final current = isSource ? service.sourceLang : service.targetLang;
                    final isSelected = current == lang;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected ? theme.colorScheme.primary.withAlpha(26) : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Text(lang.flag, style: const TextStyle(fontSize: 28)),
                      ),
                      title: Text(
                        lang.name,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                          color: isSelected ? theme.colorScheme.primary : null,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
                          : null,
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

  void _openEmergencyPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const EmergencyPanel(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<TranslationService>(context);
    final auth = Provider.of<AuthService>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          // Futuristic Background Elements
          if (!isDark)
            Positioned(
              top: -100,
              right: -50,
              child: _CircularBlob(color: theme.colorScheme.primary.withAlpha(26), size: 300),
            ),
          
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(context, auth, service, theme),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 8),
                    
                    // Dashboard Metrics Grid
                    FadeInDown(
                      duration: const Duration(milliseconds: 600),
                      child: _buildMetricsGrid(service, theme),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Language Selection Hub
                    FadeInDown(
                      delay: const Duration(milliseconds: 200),
                      child: _buildLanguageHub(context, service, theme),
                    ),
                    
                    if (service.isDownloading) 
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: FadeIn(child: _buildDownloadBar(service, theme)),
                      ),
                      
                    const SizedBox(height: 24),
                    
                    // Main Translation Engine UI
                    FadeInUp(
                      delay: const Duration(milliseconds: 400),
                      child: _buildTranslationEngine(service, theme),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // SOS Activation
                    FadeInUp(
                      delay: const Duration(milliseconds: 600),
                      child: _buildEmergencyToggle(context, service),
                    ),
                    
                    const SizedBox(height: 100), // Space for Mic button
                  ]),
                ),
              ),
            ],
          ),

          // Floating Command Center (Mic)
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: FadeInUp(
              delay: const Duration(milliseconds: 800),
              child: _buildMicCommandCenter(service, theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, AuthService auth, TranslationService service, ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 110,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: theme.colorScheme.surface.withAlpha(230),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'HYBRID TRANS',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                fontSize: 18,
                color: theme.colorScheme.primary,
              ),
            ),
            Text(
              'PRO AUTHENTICATED',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                letterSpacing: 1.0,
                fontSize: 8,
                color: theme.colorScheme.onSurface.withAlpha(128),
              ),
            ),
          ],
        ),
      ),
      actions: [
        _buildStatusBadge(service.currentMode),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () async {
            await auth.logout();
          },
          icon: const Icon(Icons.power_settings_new_rounded, size: 22),
          style: IconButton.styleFrom(
            backgroundColor: theme.colorScheme.errorContainer.withAlpha(isDarkTheme(theme) ? 50 : 100),
            foregroundColor: theme.colorScheme.error,
          ),
        ),
        const SizedBox(width: 20),
      ],
    );
  }

  bool isDarkTheme(ThemeData theme) => theme.brightness == Brightness.dark;

  Widget _buildMetricsGrid(TranslationService service, ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            Expanded(child: _MetricItem(
              icon: Icons.speed_rounded, 
              label: 'Latency', 
              value: '124ms', 
              color: Colors.blue,
              theme: theme,
            )),
            const SizedBox(width: 12),
            Expanded(child: _MetricItem(
              icon: Icons.auto_awesome_rounded, 
              label: 'Accuracy', 
              value: '99.2%', 
              color: Colors.purple,
              theme: theme,
            )),
            const SizedBox(width: 12),
            Expanded(child: _MetricItem(
              icon: Icons.language_rounded, 
              label: 'Engine', 
              value: service.currentMode == TranslationMode.online ? 'Cloud AI' : 'ML Kit', 
              color: Colors.orange,
              theme: theme,
            )),
          ],
        );
      },
    );
  }

  Widget _buildLanguageHub(BuildContext context, TranslationService service, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withAlpha(isDarkTheme(theme) ? 30 : 50),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: _LangTile(
              label: 'DECODE',
              lang: service.sourceLang,
              theme: theme,
              onTap: () => _showLanguagePicker(context, true),
            ),
          ),
          
          // Advanced Swapper
          GestureDetector(
            onTap: () {
              final tmp = service.sourceLang;
              service.updateSourceLang(service.targetLang);
              service.updateTargetLang(tmp);
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withAlpha(100),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: const Icon(Icons.sync_rounded, color: Colors.white, size: 24),
            ),
          ),
          
          Expanded(
            child: _LangTile(
              label: 'ENCODE',
              lang: service.targetLang,
              theme: theme,
              onTap: () => _showLanguagePicker(context, false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranslationEngine(TranslationService service, ThemeData theme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(100)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDarkTheme(theme) ? 50 : 10),
            blurRadius: 30,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Column(
          children: [
            // Source Area
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Label(text: 'INPUT SIGNAL', color: theme.colorScheme.primary),
                  const SizedBox(height: 12),
                  Text(
                    service.sourceText,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            
            // Separator with pulse effect
            Container(
              height: 1,
              width: double.infinity,
              color: theme.colorScheme.outlineVariant.withAlpha(100),
            ),
            
            // Result Area
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.primary.withAlpha(10),
                    theme.colorScheme.primary.withAlpha(30),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Label(text: 'TRANSLATED OUTPUT', color: theme.colorScheme.secondary),
                  const SizedBox(height: 12),
                  if (service.isDownloading || (service.isListening && service.translatedText.isEmpty))
                    Shimmer.fromColors(
                      baseColor: theme.colorScheme.primary.withAlpha(50),
                      highlightColor: theme.colorScheme.primary.withAlpha(100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 24,
                            width: 200,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            height: 24,
                            width: 150,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: service.speakTranslation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.translatedText.isEmpty ? 'Waiting for voice signal...' : service.translatedText,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: service.translatedText.isEmpty 
                                ? theme.colorScheme.onSurface.withAlpha(80)
                                : theme.colorScheme.primary,
                              height: 1.2,
                            ),
                          ),
                          if (service.translatedText.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Row(
                                children: [
                                  Icon(Icons.volume_up_rounded, color: theme.colorScheme.primary, size: 20),
                                  const SizedBox(width: 8),
                                  Text('Tap to replay', style: TextStyle(color: theme.colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMicCommandCenter(TranslationService service, ThemeData theme) {
    bool isListening = service.isListening;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              if (service.isListening) {
                service.stopListening();
              } else {
                service.startListening();
              }
            },
            onDoubleTap: service.stopListening,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isListening 
                        ? [const Color(0xFFEF4444), const Color(0xFFB91C1C)]
                        : [theme.colorScheme.primary, theme.colorScheme.primary.darken(20)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isListening ? Colors.red : theme.colorScheme.primary).withAlpha(150),
                        blurRadius: 30,
                        spreadRadius: 5,
                      )
                    ],
                  ),
                  child: Icon(
                    isListening ? Icons.graphic_eq_rounded : Icons.mic_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: (isListening ? Colors.red : theme.colorScheme.primary).withAlpha(40),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isListening ? 'PROCESSING SIGNAL...' : 'CLICK TO ANALYZE VOICE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: isListening ? Colors.red : theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyToggle(BuildContext context, TranslationService service) {
    final bool active = service.isEmergencyMode;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: active 
          ? LinearGradient(
              colors: [Colors.red.withAlpha(40), Colors.red.withAlpha(10)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : null,
        color: active ? null : Colors.grey.withAlpha(20),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: active ? Colors.red.withAlpha(150) : Colors.transparent,
          width: 2,
        ),
        boxShadow: active ? [
          BoxShadow(
            color: Colors.red.withAlpha(40),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ] : [],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: active ? Colors.red : Colors.grey.withAlpha(40),
              shape: BoxShape.circle,
            ),
            child: Icon(
              active ? Icons.notification_important_rounded : Icons.warning_amber_rounded,
              color: active ? Colors.white : Colors.grey.shade600,
              size: 24,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  active ? 'S.O.S ACTIVE' : 'EMERGENCY PROTOCOL',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 1.2,
                    color: active ? Colors.red : Colors.grey.shade800,
                  ),
                ),
                Text(
                  active ? 'Broadcasting distress signals' : 'Global hazard communication',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: active ? Colors.red.withAlpha(180) : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: active,
            onChanged: (val) {
              service.toggleEmergencyMode();
              if (val) {
                Future.delayed(const Duration(milliseconds: 300), () {
                  _openEmergencyPanel(context);
                });
              }
            },
            activeColor: Colors.red,
            activeTrackColor: Colors.red.withAlpha(100),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(TranslationMode mode) {
    final Color color;
    final String label;

    switch (mode) {
      case TranslationMode.online:
        color = const Color(0xFF22C55E); label = 'ONLINE READY'; break;
      case TranslationMode.offline:
        color = const Color(0xFFF59E0B); label = 'OFFLINE MODE'; break;
      case TranslationMode.emergency:
        color = const Color(0xFFEF4444); label = 'SOS ACTIVE'; break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 9,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildDownloadBar(TranslationService service, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withAlpha(15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Syncing Language Neural Weights...',
                style: TextStyle(fontSize: 12, color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
              ),
              Text('45%', style: TextStyle(fontSize: 12, color: theme.colorScheme.primary, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              minHeight: 8,
              backgroundColor: theme.colorScheme.primary.withAlpha(30),
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final ThemeData theme;

  const _MetricItem({required this.icon, required this.label, required this.value, required this.color, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 12),
          Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, fontSize: 14)),
          Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withAlpha(128))),
        ],
      ),
    );
  }
}

class _LangTile extends StatelessWidget {
  final String label;
  final LanguageItem lang;
  final ThemeData theme;
  final VoidCallback onTap;

  const _LangTile({required this.label, required this.lang, required this.theme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Text(lang.flag, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              Text(
                lang.name.toUpperCase(),
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 12),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 8, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface.withAlpha(100)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  final Color color;
  const _Label({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 1.2),
      ),
    );
  }
}

class _CircularBlob extends StatelessWidget {
  final Color color;
  final double size;
  const _CircularBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: Container(color: Colors.transparent)),
    );
  }
}

