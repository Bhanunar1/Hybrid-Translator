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

  static const List<Map<String, dynamic>> _codes = [
    {
      'code': 'E01',
      'text': 'I NEED MEDICAL HELP',
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
      'text': 'I NEED WATER / FOOD',
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
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withAlpha(isDark ? 220 : 255),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          border: Border.all(color: Colors.white.withAlpha(isDark ? 30 : 50), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(80),
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
            _buildSOSHeader(theme),
            
            const SizedBox(height: 12),

            // Active broadcast indicator
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _activeMessage != null
                  ? _buildActiveBroadcastBanner(_activeMessage!)
                  : const SizedBox(height: 0),
            ),

            const SizedBox(height: 24),

            // Grid
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
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
            ),
            
            const SizedBox(height: 24),

            // Secure Termination Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
                label: const Text('TERMINATE SESSION', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.surfaceVariant.withAlpha(100),
                  foregroundColor: theme.colorScheme.onSurface,
                  elevation: 0,
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

  Widget _buildSOSHeader(ThemeData theme) {
    return Column(
      children: [
        Text(
          'PROTOCOL: EMERGENCY',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.w900,
            fontSize: 10,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'S.O.S COMMAND CENTER',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
      ],
    );
  }

  Widget _buildActiveBroadcastBanner(String msg) {
    return FadeIn(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.red.withAlpha(100), blurRadius: 20, spreadRadius: 2),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.record_voice_over_rounded, color: Colors.white, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('BROADCASTING...', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                  Text(
                    msg,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, height: 1.1),
                  ),
                ],
              ),
            ),
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
                    style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12, height: 1.1),
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
