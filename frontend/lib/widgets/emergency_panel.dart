import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../services/translation_service.dart';
import 'dart:ui';

class EmergencyPanel extends StatefulWidget {
  const EmergencyPanel({super.key});

  @override
  State<EmergencyPanel> createState() => _EmergencyPanelState();
}

class _EmergencyPanelState extends State<EmergencyPanel> {
  String? _activeMessage;

  // ── Emergency Codes ───────────────────────────────────────────────────────────
  static const List<Map<String, dynamic>> _codes = [
    {
      'code': 'E01',
      'text': 'MEDICAL HELP',
      'icon': Icons.medical_services_rounded,
      'colorValue': 0xFFEF4444,
      'symbol': '🏥',
      'desc': 'Instant health alert'
    },
    {
      'code': 'E02',
      'text': 'CALL THE POLICE',
      'icon': Icons.security_rounded,
      'colorValue': 0xFF3B82F6,
      'symbol': '🚨',
      'desc': 'Direct officer signal'
    },
    {
      'code': 'E03',
      'text': 'I AM LOST',
      'icon': Icons.map_rounded,
      'colorValue': 0xFFF59E0B,
      'symbol': '📍',
      'desc': 'Navigation SOS'
    },
    {
      'code': 'E04',
      'text': 'WATER / FOOD',
      'icon': Icons.restaurant_rounded,
      'colorValue': 0xFF06B6D4,
      'symbol': '🍱',
      'desc': 'Essentials request'
    },
    {
      'code': 'E05',
      'text': 'DANGER NEARBY',
      'icon': Icons.gpp_maybe_rounded,
      'colorValue': 0xFFEA580C,
      'symbol': '⚠️',
      'desc': 'Proximity hazard'
    },
    {
      'code': 'E06',
      'text': 'UrgENT DOCTOR',
      'icon': Icons.local_hospital_rounded,
      'colorValue': 0xFF9333EA,
      'symbol': '🥼',
      'desc': 'Medical expert call'
    },
    {
      'code': 'E07',
      'text': 'AMBULANCE SOS',
      'icon': Icons.airport_shuttle_rounded,
      'colorValue': 0xFFDC2626,
      'symbol': '🚑',
      'desc': 'Priority transport'
    },
  ];

  Future<void> _triggerEmergency(TranslationService service, Map<String, dynamic> item) async {
    setState(() => _activeMessage = item['text'] as String);
    await service.playEmergencyCode(item['code'] as String);
    await Future.delayed(const Duration(seconds: 5));
    if (mounted) setState(() => _activeMessage = null);
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<TranslationService>(context, listen: false);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withAlpha(isDark ? 200 : 230),
          image: DecorationImage(
            image: const AssetImage('assets/sos.jpg'),
            fit: BoxFit.cover,
            opacity: isDark ? 0.3 : 0.1,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          border: Border.all(color: Colors.white.withAlpha(isDark ? 30 : 50), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 100 : 40),
              blurRadius: 40,
              offset: const Offset(0, -10),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(100),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),

            // SOS Banner
            _buildSafeHavenHeader(theme),
            
            const SizedBox(height: 12),

            // Active broadcast indicator
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _activeMessage != null
                  ? _buildActiveSignal(_activeMessage!, theme)
                  : const SizedBox(height: 0),
            ),

            const SizedBox(height: 24),

            // Grid
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 24),
                physics: const BouncingScrollPhysics(),
                itemCount: _codes.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.9,
                ),
                itemBuilder: (context, index) {
                  return _EmergencyTile(
                    item: _codes[index],
                    index: index,
                    onTap: () => _triggerEmergency(service, _codes[index]),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),

            // Secure Termination Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
                label: const Text('TERMINATE SOS SESSION', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error.withAlpha(20),
                  foregroundColor: theme.colorScheme.error,
                  elevation: 0,
                  side: BorderSide(color: theme.colorScheme.error.withAlpha(50)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildSafeHavenHeader(ThemeData theme) {
    return Column(
      children: [
        Container(
          width: 40, height: 4,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(color: Colors.white.withAlpha(100), borderRadius: BorderRadius.circular(2)),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Pulse(infinite: true, child: const Icon(Icons.gpp_maybe_rounded, color: Colors.red, size: 28)),
            const SizedBox(width: 12),
            const Text('HYLATOR GUARD', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 8),
        Text('INSTANT DISTRESS SIGNAL HUB', style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(150), fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildActiveSignal(String message, ThemeData theme) {
    return FadeIn(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.red.withAlpha(40),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.red.withAlpha(100), width: 2),
        ),
        child: Column(
          children: [
            Pulse(infinite: true, child: const Icon(Icons.emergency_share_rounded, color: Colors.red, size: 48)),
            const SizedBox(height: 16),
            Text(message.toUpperCase(), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 2)),
            const SizedBox(height: 8),
            const Text('BROADCASTING TO NEARBY NODES...', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _EmergencyTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final int index;
  final VoidCallback onTap;

  const _EmergencyTile({required this.item, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Color(item['colorValue'] as int);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FadeInUp(
      delay: Duration(milliseconds: 100 * index),
      child: Container(
        decoration: BoxDecoration(
          color: color.withAlpha(isDark ? 30 : 15),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withAlpha(80), width: 1.5),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            splashColor: color.withAlpha(50),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withAlpha(40),
                      shape: BoxShape.circle,
                    ),
                    child: Text(item['symbol'] as String, style: const TextStyle(fontSize: 32)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item['text'] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11, height: 1.1),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['desc'] as String,
                    style: TextStyle(color: color.withAlpha(150), fontSize: 9, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
