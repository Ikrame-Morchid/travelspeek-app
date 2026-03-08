import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/string_extensions.dart';
import '../../../data/models/historique_model.dart';
import '../../providers/home_provider.dart';
import '../../providers/monument_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/app_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String? _profileImagePath;
  
  // ✅ NOUVELLE SOLUTION : ScaffoldState stocké
  late GlobalKey<ScaffoldState> _scaffoldKey;

  @override
  void initState() {
    super.initState();
    _scaffoldKey = GlobalKey<ScaffoldState>(); // ✅ Initialiser dans initState
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.read<HomeProvider>().loadMockData();
      context.read<MonumentProvider>().loadMonuments();
      await context.read<UserProvider>().loadUserData();
      if (mounted) {
        context.read<HistoryProvider>().loadHistory();
        await _loadProfileImage();
      }
    });
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id') ?? 0;
    if (userId == 0) return;
    final imagePath = prefs.getString('profile_image_path_$userId');
    if (imagePath != null && await File(imagePath).exists()) {
      if (mounted) setState(() => _profileImagePath = imagePath);
    } else {
      if (mounted) setState(() => _profileImagePath = null);
    }
  }

  // ✅ MÉTHODE DIRECTE POUR OUVRIR LE DRAWER
  void _openDrawer() {
    print('🔍 Tentative ouverture drawer...');
    try {
      _scaffoldKey.currentState?.openEndDrawer();
      print('✅ Drawer ouvert');
    } catch (e) {
      print('❌ Erreur ouverture drawer: $e');
    }
  }

  List<Historique> _todayItems(List<Historique> all, ActivityType type) {
    final now = DateTime.now();
    return all
        .where((h) =>
            h.type == type &&
            h.createdAt.year == now.year &&
            h.createdAt.month == now.month &&
            h.createdAt.day == now.day)
        .take(3)
        .toList();
  }

  void _openMonument(Historique item) {
    if (item.resourceId == null) {
      Navigator.pushNamed(context, '/monuments');
      return;
    }
    final monumentProvider = context.read<MonumentProvider>();
    final monument = monumentProvider.allMonuments
            .where((m) => m.id == item.resourceId)
            .isNotEmpty
        ? monumentProvider.allMonuments
            .firstWhere((m) => m.id == item.resourceId)
        : null;

    if (monument != null) {
      Navigator.pushNamed(context, '/monument-detail', arguments: monument);
    } else {
      monumentProvider.loadMonuments().then((_) {
        if (!mounted) return;
        final m = monumentProvider.allMonuments
                .where((m) => m.id == item.resourceId)
                .isNotEmpty
            ? monumentProvider.allMonuments
                .firstWhere((m) => m.id == item.resourceId)
            : null;
        if (m != null) {
          Navigator.pushNamed(context, '/monument-detail', arguments: m);
        } else {
          Navigator.pushNamed(context, '/monuments');
        }
      });
    }
  }

  void _openTranslationDetail(Historique item, bool isDark) {
    final parts = item.subtitle?.split('→') ?? [];
    final from = parts.isNotEmpty ? parts[0].trim() : '?';
    final to = parts.length > 1 ? parts[1].trim() : '?';
    final dialogBg = isDark ? const Color(0xFF1A2530) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF2D2D2D);
    final subtitleColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final chipBg = isDark ? Colors.grey[700]! : Colors.grey[200]!;
    final chipText = isDark ? Colors.white : const Color(0xFF2D2D2D);

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.translate,
                      color: Colors.green, size: 20),
                ),
                const SizedBox(width: 12),
                _langChip(from, chipBg, chipText),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward,
                    size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                _langChip(to, chipBg, chipText),
                const Spacer(),
                Text(item.timeAgo,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey)),
              ]),
              const SizedBox(height: 16),
              Divider(color: isDark ? Colors.grey[700] : null),
              const SizedBox(height: 12),
              Text('original_text'.tr(context),
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: subtitleColor)),
              const SizedBox(height: 6),
              Text(item.title,
                  style: TextStyle(fontSize: 15, color: textColor)),
              if (item.details != null && item.details!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('translation_label'.tr(context),
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: subtitleColor)),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(item.details!,
                      style: TextStyle(
                          fontSize: 16,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600)),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('close'.tr(context),
                      style: const TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _langChip(String label, Color bg, Color textColor) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(6)),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textColor)),
      );

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final bgColor = isDark ? const Color(0xFF0F1923) : const Color(0xFFF8F9FA);

    return Scaffold(
      key: _scaffoldKey, // ✅ Clé attachée
      endDrawer: const AppDrawer(),
      backgroundColor: bgColor,
      body: _buildBody(isDark),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBody(bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF2D2D2D);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildHeader(isDark),
            const SizedBox(height: 20),
            Consumer<HomeProvider>(
              builder: (context, homeProvider, child) {
                if (homeProvider.isLoading) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('where_are_we_heading_today'.tr(context),
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: textColor)),
                    const SizedBox(height: 16),
                    _buildFeatureCardsGrid(isDark),
                    const SizedBox(height: 16),
                    _buildExploreMoroccoCard(),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            _buildRecentActivitySection(isDark),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF2D2D2D);
    final barColor = isDark ? Colors.white : const Color(0xFF2D2D2D);

    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final userName = userProvider.username;
        return Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: _profileImagePath == null
                  ? AppColors.primaryGradient
                  : null,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: _profileImagePath != null
                ? ClipOval(
                    child: Image.file(File(_profileImagePath!),
                        fit: BoxFit.cover))
                : Center(
                    child: Text(
                      userName.isNotEmpty
                          ? userName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${'hello'.tr(context)}, $userName!',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor)),
                  Text('welcome_back'.tr(context),
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500)),
                ]),
          ),
          // ✅ BOUTON MENU SIMPLIFIÉ
          InkWell(
            onTap: _openDrawer,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _bar(barColor),
                  const SizedBox(height: 4),
                  _bar(barColor),
                  const SizedBox(height: 4),
                  _bar(barColor),
                ],
              ),
            ),
          ),
        ]);
      },
    );
  }

  Widget _bar(Color color) => Container(
        width: 22,
        height: 2,
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(2)),
      );

  Widget _buildRecentActivitySection(bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF2D2D2D);
    final subtitleColor = isDark ? Colors.grey[400]! : Colors.grey[500]!;

    return Consumer<HistoryProvider>(
      builder: (context, historyProvider, _) {
        final translations = _todayItems(
            historyProvider.history, ActivityType.translation);
        final monuments =
            _todayItems(historyProvider.history, ActivityType.monument);
        final searches =
            _todayItems(historyProvider.history, ActivityType.search);
        final bool isEmpty =
            translations.isEmpty && monuments.isEmpty && searches.isEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('recent_activity'.tr(context),
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: textColor)),
                      Text(_todayLabel(context),
                          style: TextStyle(
                              fontSize: 11, color: subtitleColor)),
                    ]),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/history'),
                  child: Text('see_all'.tr(context),
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (historyProvider.isLoading)
              const Center(
                  child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator()))
            else if (isEmpty)
              _buildEmptyActivity(isDark)
            else ...[
              if (translations.isNotEmpty) ...[
                _categoryHeader(Icons.translate,
                    'translations_label'.tr(context), Colors.green),
                const SizedBox(height: 8),
                ...translations.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _activityCard(item, isDark),
                    )),
                const SizedBox(height: 12),
              ],
              if (monuments.isNotEmpty) ...[
                _categoryHeader(
                    Icons.account_balance,
                    'visited_monuments'.tr(context),
                    const Color(0xFFD97706)),
                const SizedBox(height: 8),
                ...monuments.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _activityCard(item, isDark),
                    )),
                const SizedBox(height: 12),
              ],
              if (searches.isNotEmpty) ...[
                _categoryHeader(Icons.search,
                    'searches_label'.tr(context),
                    const Color(0xFF7C3AED)),
                const SizedBox(height: 8),
                ...searches.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _activityCard(item, isDark),
                    )),
              ],
            ],
          ],
        );
      },
    );
  }

  String _todayLabel(BuildContext context) {
    final now = DateTime.now();
    const months = [
      '', 'jan', 'fév', 'mar', 'avr', 'mai', 'juin',
      'juil', 'août', 'sep', 'oct', 'nov', 'déc'
    ];
    return 'today_date_label'
        .tr(context)
        .replaceAll('{date}', '${now.day} ${months[now.month]}');
  }

  Widget _categoryHeader(IconData icon, String label, Color color) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 14, color: color),
      ),
      const SizedBox(width: 8),
      Text(label,
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700, color: color)),
    ]);
  }

  Widget _buildEmptyActivity(bool isDark) {
    final cardColor = isDark ? const Color(0xFF1A2530) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF2D2D2D);
    final subtitleColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
              color: const Color(0xFFE8F5F4),
              borderRadius: BorderRadius.circular(11)),
          child:
              const Icon(Icons.wb_sunny_outlined, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('no_activity_today'.tr(context),
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor)),
                const SizedBox(height: 3),
                Text('start_exploring'.tr(context),
                    style: TextStyle(fontSize: 12, color: subtitleColor)),
              ]),
        ),
      ]),
    );
  }

  Widget _activityCard(Historique item, bool isDark) {
    final cardColor = isDark ? const Color(0xFF1A2530) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF2D2D2D);
    final subtitleColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    IconData icon;
    Color iconBg;
    Color iconColor;

    switch (item.type) {
      case ActivityType.translation:
        icon = Icons.translate;
        iconBg = const Color(0xFFE8F5F4);
        iconColor = AppColors.primary;
        break;
      case ActivityType.monument:
        icon = Icons.account_balance;
        iconBg = const Color(0xFFFFF3E0);
        iconColor = const Color(0xFFD97706);
        break;
      case ActivityType.search:
        icon = Icons.search;
        iconBg = const Color(0xFFEDE7F6);
        iconColor = const Color(0xFF7C3AED);
        break;
      default:
        icon = Icons.history;
        iconBg = const Color(0xFFE8F5F4);
        iconColor = AppColors.primary;
    }

    return GestureDetector(
      onTap: () {
        switch (item.type) {
          case ActivityType.translation:
            _openTranslationDetail(item, isDark);
            break;
          case ActivityType.monument:
            _openMonument(item);
            break;
          case ActivityType.search:
            Navigator.pushNamed(context, '/monuments-list',
                arguments: {'query': item.title});
            break;
          default:
            break;
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(children: [
          item.type == ActivityType.monument && item.imageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Image.network(item.imageUrl!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _iconBox(icon, iconBg, iconColor)),
                )
              : _iconBox(icon, iconBg, iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('"${item.title}"',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text('${item.subtitle ?? ''} • ${item.timeAgo}',
                      style:
                          TextStyle(fontSize: 12, color: subtitleColor)),
                ]),
          ),
          Icon(Icons.arrow_forward_ios,
              size: 12,
              color: isDark ? Colors.grey[500] : Colors.grey[400]),
        ]),
      ),
    );
  }

  Widget _iconBox(IconData icon, Color bg, Color color) => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(11)),
        child: Icon(icon, color: color, size: 22),
      );

  Widget _buildFeatureCardsGrid(bool isDark) {
    final cardColor = isDark ? const Color(0xFF1A2530) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF2D2D2D);
    final subtitleColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return SizedBox(
      height: 280,
      child: Row(children: [
        Expanded(
          flex: 11,
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/translation'),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.85)
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.primary.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.mic,
                            color: Colors.white, size: 26),
                      ),
                      const Spacer(),
                      Text('speak_translate'.tr(context),
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.1)),
                      const SizedBox(height: 6),
                      Text('real_time_voice'.tr(context),
                          style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                              height: 1.3)),
                    ]),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 9,
          child: Column(children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/translation',
                    arguments: {'initialTab': 1}),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black
                              .withOpacity(isDark ? 0.2 : 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                              color: const Color(0xFFE8F5F4),
                              borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.camera_alt_outlined,
                              color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(height: 10),
                        Text('scan_text'.tr(context),
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textColor)),
                        const SizedBox(height: 2),
                        Text('visual_trans'.tr(context),
                            style: TextStyle(
                                fontSize: 10, color: subtitleColor)),
                      ]),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/chatbot'),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black
                              .withOpacity(isDark ? 0.2 : 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                              color: const Color(0xFFE8F5F4),
                              borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.chat_bubble_outline,
                              color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(height: 10),
                        Text('ask_ai'.tr(context),
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textColor)),
                        const SizedBox(height: 2),
                        Text('local_tips'.tr(context),
                            style: TextStyle(
                                fontSize: 10, color: subtitleColor)),
                      ]),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildExploreMoroccoCard() {
    return Consumer<MonumentProvider>(
      builder: (context, monumentProvider, child) {
        String? monumentImage;
        if (monumentProvider.allMonuments.isNotEmpty) {
          final m = monumentProvider.allMonuments.firstWhere(
            (m) => m.mainImage != null && m.mainImage!.isNotEmpty,
            orElse: () => monumentProvider.allMonuments.first,
          );
          monumentImage = m.mainImage;
        }
        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/monuments'),
          child: Container(
            height: 110,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(children: [
                Positioned.fill(
                  child: monumentImage != null
                      ? Image.network(monumentImage,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _moroccoFallback())
                      : _moroccoFallback(),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.black.withOpacity(0.65),
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 16),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: const Color(0xFF8B6F47),
                          borderRadius: BorderRadius.circular(16)),
                      child: Text('discovery'.tr(context),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('explore_morocco'.tr(context),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 3),
                            Text('ancient_wonders'.tr(context),
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 11)),
                          ]),
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_forward,
                          color: Color(0xFF2D2D2D), size: 18),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }

  Widget _moroccoFallback() => Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [Color(0xFF8B6F47), Color(0xFFA68A64)])),
        child: const Center(
            child: Icon(Icons.account_balance,
                size: 50, color: Colors.white54)),
      );

  Widget _buildBottomNavBar() {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
      height: 68,
      decoration: BoxDecoration(
        color: const Color(0xFF2D3E45),
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavIcon(Icons.home_rounded, 0),
            _buildNavIcon(Icons.account_balance_rounded, 1),
            _buildNavIcon(Icons.translate_rounded, 2),
            _buildNavIcon(Icons.chat_bubble_rounded, 3),
            _buildNavIcon(Icons.person_rounded, 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == 0) setState(() => _selectedIndex = 0);
        if (index == 1) Navigator.pushNamed(context, '/monuments');
        if (index == 2) Navigator.pushNamed(context, '/translation');
        if (index == 3) Navigator.pushNamed(context, '/chatbot');
        if (index == 4) Navigator.pushNamed(context, '/profile');
      },
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}