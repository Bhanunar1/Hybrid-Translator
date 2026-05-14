import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:image_picker/image_picker.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../services/auth_service.dart';
import '../map/map_screen.dart';
import '../settings/settings_screen.dart';

import 'offline_storage_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _uploadingImage = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final auth = context.read<AuthService>();
    await auth.fetchMe();
    await auth.fetchStats();
  }

  Future<void> _pickImage() async {
    final auth = context.read<AuthService>();
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 800);
    if (image != null) {
      setState(() => _uploadingImage = true);
      final bytes = await image.readAsBytes();
      await auth.uploadProfileImage(bytes);
      setState(() => _uploadingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final theme = Theme.of(context);
    final user = auth.currentUser;
    final stats = auth.stats;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: theme.colorScheme.primary,
        child: NestedScrollView(
          physics: const BouncingScrollPhysics(),
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // ── Cinematic Header ──────────────────────────────────────────────────
              SliverAppBar(
              expandedHeight: 320,
              pinned: true,
              stretch: true,
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset('assets/profile.jpg', fit: BoxFit.cover),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          colors: [Colors.black.withAlpha(60), Colors.black.withAlpha(180)],
                        ),
                      ),
                    ),
                    // Avatar + Name overlay
                    Positioned(
                      bottom: 24, left: 20, right: 20,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: _uploadingImage ? null : _pickImage,
                            child: Stack(
                              children: [
                                Hero(
                                  tag: 'avatar',
                                  child: Container(
                                    width: 90, height: 90,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 3),
                                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(60), blurRadius: 16)],
                                    ),
                                    child: ClipOval(
                                      child: _buildAvatar(user, theme),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0, right: 0,
                                  child: Container(
                                    width: 28, height: 28,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: _uploadingImage
                                        ? const Padding(padding: EdgeInsets.all(5), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                        : const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  user?.fullName ?? 'Hylator Traveller',
                                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user?.email ?? '',
                                  style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 12),
                                ),
                                const SizedBox(height: 8),
                                if (user?.nationality?.isNotEmpty == true)
                                  _Tag(label: user!.nationality!, color: Colors.greenAccent),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.storage_rounded),
                  tooltip: 'Offline Storage',
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OfflineStorageScreen())),
                ),
                IconButton(
                  icon: const Icon(Icons.settings_rounded),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                ),
                IconButton(
                  icon: const Icon(Icons.map_rounded),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MapScreen())),
                ),
              ],
              title: const Text('HYLATOR LOG', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 13)),
              centerTitle: true,
            ),

            // ── Tab Bar ──────────────────────────────────────────────────────────
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyTabDelegate(
                TabBar(
                  controller: _tabController,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Theme.of(context).colorScheme.primary,
                  tabs: const [
                    Tab(text: 'PASSPORT', icon: Icon(Icons.badge_rounded, size: 16)),
                    Tab(text: 'JOURNEY', icon: Icon(Icons.map_outlined, size: 16)),
                    Tab(text: 'METRICS', icon: Icon(Icons.insights_rounded, size: 16)),
                  ],
                ),
              ),
              ),
            ];
          },
          // ── Tab Content ──────────────────────────────────────────────────────
          body: TabBarView(
            controller: _tabController,
            children: [
              _PassportTab(user: user),
              _JourneyTab(user: user),
              _MetricsTab(stats: stats),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.read<AuthService>().logout(),
        icon: const Icon(Icons.logout_rounded),
        label: const Text('SIGN OUT', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildAvatar(User? user, ThemeData theme) {
    if (user?.profileImageUrl?.isNotEmpty == true) {
      return Image.network(
        'http://127.0.0.1:8000${user!.profileImageUrl}',
        fit: BoxFit.cover, width: 90, height: 90,
        errorBuilder: (_, __, ___) => _defaultAvatar(user, theme),
      );
    }
    return _defaultAvatar(user, theme);
  }

  Widget _defaultAvatar(User? user, ThemeData theme) {
    return Container(
      color: theme.colorScheme.primaryContainer,
      alignment: Alignment.center,
      child: Text(
        user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : '?',
        style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: theme.colorScheme.primary),
      ),
    );
  }
}

// ── Passport Tab ──────────────────────────────────────────────────────────────
class _PassportTab extends StatelessWidget {
  final User? user;
  const _PassportTab({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInDown(child: _SectionCard(
            title: 'PERSONAL DETAILS',
            icon: Icons.person_rounded,
            children: [
              _DetailRow(icon: Icons.cake_rounded, label: 'Date of Birth', value: user?.dob ?? 'Not set'),
              _DetailRow(icon: Icons.flag_rounded, label: 'Nationality', value: user?.nationality ?? 'Not set'),
              _DetailRow(icon: Icons.home_rounded, label: 'Home Country', value: user?.homeCountry ?? 'Not set'),
              _DetailRow(icon: Icons.email_rounded, label: 'Email', value: user?.email ?? ''),
            ],
          )),
          const SizedBox(height: 16),
          if (user?.bio?.isNotEmpty == true)
            FadeInUp(child: _SectionCard(
              title: 'BIO',
              icon: Icons.description_rounded,
              children: [
                Text(user!.bio ?? '', style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(180), height: 1.6)),
              ],
            )),
          const SizedBox(height: 16),
          FadeInUp(delay: const Duration(milliseconds: 300), child: _SectionCard(
            title: 'LANGUAGE PREFERENCES',
            icon: Icons.language_rounded,
            children: [
              _DetailRow(icon: Icons.volume_up_rounded, label: 'Source Language', value: user?.preferredSourceLang ?? 'English'),
              _DetailRow(icon: Icons.translate_rounded, label: 'Target Language', value: user?.preferredTargetLang ?? 'Telugu'),
            ],
          )),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ── Journey Tab ───────────────────────────────────────────────────────────────
class _JourneyTab extends StatelessWidget {
  final User? user;
  const _JourneyTab({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final history = user?.travelHistory?.split(',').where((e) => e.trim().isNotEmpty).toList() ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          FadeInDown(child: _SectionCard(
            title: 'CURRENT HEADING',
            icon: Icons.navigation_rounded,
            children: [
              Row(
                children: [
                  Pulse(infinite: user?.currentDestination != null, child: Icon(Icons.location_on_rounded, color: theme.colorScheme.primary, size: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      user?.currentDestination ?? 'No destination set',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ],
          )),
          const SizedBox(height: 16),

          // Live Map Preview
          FadeInUp(child: GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MapScreen())),
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: theme.colorScheme.primary.withAlpha(15),
                border: Border.all(color: theme.colorScheme.primary.withAlpha(40)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    Image.asset('assets/home.jpg', fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                    Container(color: Colors.black.withAlpha(120)),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Pulse(infinite: true, child: Icon(Icons.map_rounded, color: theme.colorScheme.primary, size: 48)),
                          const SizedBox(height: 8),
                          const Text('TAP TO OPEN LIVE MAP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 10)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )),
          const SizedBox(height: 16),

          FadeInUp(delay: const Duration(milliseconds: 200), child: _SectionCard(
            title: 'TRAVEL HISTORY',
            icon: Icons.history_rounded,
            children: [
              if (history.isEmpty)
                Text('No countries logged yet. Add via Settings.', style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(120), fontStyle: FontStyle.italic))
              else
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: history.map((c) => _Tag(label: c.trim(), color: theme.colorScheme.primary)).toList(),
                ),
            ],
          )),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ── Metrics Tab ───────────────────────────────────────────────────────────────
class _MetricsTab extends StatelessWidget {
  final UserStats? stats;
  const _MetricsTab({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = stats?.totalTranslations ?? 0;
    final cloud = stats?.cloudTranslations ?? 0;
    final offline = stats?.offlineTranslations ?? 0;
    final cloudPct = total > 0 ? cloud / total : 0.0;
    final offlinePct = total > 0 ? offline / total : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          FadeInDown(child: Row(
            children: [
              Expanded(child: _StatBox(label: 'TOTAL\nVOICES', value: total.toString(), color: theme.colorScheme.primary, icon: Icons.translate_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _StatBox(label: 'CLOUD\nTRANS', value: cloud.toString(), color: Colors.blue, icon: Icons.cloud_done_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _StatBox(label: 'LOCAL\nBOOST', value: offline.toString(), color: Colors.orange, icon: Icons.offline_bolt_rounded)),
            ],
          )),
          const SizedBox(height: 20),

          FadeInUp(child: _SectionCard(
            title: 'HYLATOR IMPACT METRICS',
            icon: Icons.insights_rounded,
            children: [
              const Text('Cloud Translation Rate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 8),
              LinearPercentIndicator(
                lineHeight: 14, percent: cloudPct.clamp(0.0, 1.0),
                backgroundColor: Colors.grey.withAlpha(50),
                progressColor: Colors.blue,
                barRadius: const Radius.circular(8),
                padding: EdgeInsets.zero,
                center: Text('${(cloudPct * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
              const SizedBox(height: 16),
              const Text('Offline Efficiency', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 8),
              LinearPercentIndicator(
                lineHeight: 14, percent: offlinePct.clamp(0.0, 1.0),
                backgroundColor: Colors.grey.withAlpha(50),
                progressColor: Colors.orange,
                barRadius: const Radius.circular(8),
                padding: EdgeInsets.zero,
                center: Text('${(offlinePct * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('AVG LATENCY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                    Text(
                      stats?.avgLatencyMs != null ? '${stats!.avgLatencyMs!.toStringAsFixed(0)}ms' : '—',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: theme.colorScheme.primary),
                    ),
                  ]),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('TOP LANGUAGE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                    Text(
                      stats?.favoriteLang ?? '—',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.green),
                    ),
                  ]),
                ],
              ),
            ],
          )),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ── Supporting Widgets ────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
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
            Icon(icon, size: 16, color: theme.colorScheme.primary),
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

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface.withAlpha(130), letterSpacing: 1)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const _StatBox({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey)),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Text(label.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
    );
  }
}

class _StickyTabDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _StickyTabDelegate(this.tabBar);

  @override double get minExtent => tabBar.preferredSize.height;
  @override double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_StickyTabDelegate oldDelegate) => false;
}
