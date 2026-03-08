import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/string_extensions.dart';
import '../../../data/models/historique_model.dart';
import '../../providers/history_provider.dart';
import '../../providers/monument_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().loadHistory();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Map<String, List<Historique>> _groupByDate(List<Historique> items) {
    final Map<String, List<Historique>> grouped = {};
    final now = DateTime.now();
    for (final item in items) {
      final d = item.createdAt;
      String key;
      if (d.year == now.year &&
          d.month == now.month &&
          d.day == now.day) {
        key = 'today';
      } else {
        final yesterday = now.subtract(const Duration(days: 1));
        if (d.year == yesterday.year &&
            d.month == yesterday.month &&
            d.day == yesterday.day) {
          key = 'yesterday';
        } else {
          const months = [
            '',
            'jan',
            'fév',
            'mar',
            'avr',
            'mai',
            'juin',
            'juil',
            'août',
            'sep',
            'oct',
            'nov',
            'déc'
          ];
          key = '${d.day} ${months[d.month]} ${d.year}';
        }
      }
      grouped.putIfAbsent(key, () => []).add(item);
    }
    return grouped;
  }

  void _openMonument(Historique item) {
    if (item.resourceId == null) {
      Navigator.pushNamed(context, '/monuments');
      return;
    }

    final monumentProvider = context.read<MonumentProvider>();
    final list = monumentProvider.allMonuments
        .where((m) => m.id == item.resourceId)
        .toList();

    if (list.isNotEmpty) {
      Navigator.pushNamed(context, '/monument-detail',
          arguments: list.first);
    } else {
      monumentProvider.loadMonuments().then((_) {
        if (!mounted) return;
        final l = monumentProvider.allMonuments
            .where((m) => m.id == item.resourceId)
            .toList();
        if (l.isNotEmpty) {
          Navigator.pushNamed(context, '/monument-detail',
              arguments: l.first);
        } else {
          Navigator.pushNamed(context, '/monuments');
        }
      });
    }
  }

  void _openTranslationDetail(Historique item) {
    final theme = Theme.of(context);
    final parts = item.subtitle?.split('→') ?? [];
    final from = parts.isNotEmpty ? parts[0].trim() : '?';
    final to = parts.length > 1 ? parts[1].trim() : '?';

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: theme.colorScheme.surface,
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
                _chip(from, theme),
                const SizedBox(width: 6),
                Icon(Icons.arrow_forward,
                    size: 14,
                    color: theme.textTheme.bodyMedium?.color),
                const SizedBox(width: 6),
                _chip(to, theme),
                const Spacer(),
                Text(item.timeAgo,
                    style: TextStyle(
                        fontSize: 11,
                        color: theme.textTheme.bodyMedium?.color)),
              ]),
              const SizedBox(height: 16),
              Divider(color: theme.dividerTheme.color),
              const SizedBox(height: 12),
              Text(
                'original_text'.tr(context),
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodyMedium?.color),
              ),
              const SizedBox(height: 6),
              Text(item.title,
                  style: TextStyle(
                      fontSize: 15,
                      color: theme.colorScheme.onSurface)),
              if (item.details != null &&
                  item.details!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'translation_label'.tr(context),
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodyMedium?.color),
                ),
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
                  child: Text(
                    'close'.tr(context),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(theme),
      body: Consumer<HistoryProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return Center(
                child: CircularProgressIndicator(
                    color: AppColors.primary));
          }
          return Column(
            children: [
              _buildTabBar(theme),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTranslationsTab(provider, theme),
                    _buildSearchesTab(provider, theme),
                    _buildMonumentsTab(provider, theme),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back,
            color: theme.colorScheme.onSurface),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text('history'.tr(context),
          style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.bold)),
      actions: [
        IconButton(
          icon: Icon(Icons.delete_outline,
              color: theme.textTheme.bodyMedium?.color),
          onPressed: _showClearDialog,
        ),
      ],
    );
  }

  Widget _buildTabBar(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surface,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: theme.textTheme.bodyMedium?.color,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        labelStyle: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600),
        tabs: [
          Tab(text: 'translations'.tr(context)),
          Tab(text: 'searches'.tr(context)),
          Tab(text: 'monuments'.tr(context)),
        ],
      ),
    );
  }

  Widget _buildTranslationsTab(
      HistoryProvider provider, ThemeData theme) {
    final items = provider.history
        .where((h) => h.type == ActivityType.translation)
        .toList();
    if (items.isEmpty) {
      return _emptyState(
        icon: Icons.translate,
        title: 'no_translations_yet'.tr(context),
        subtitle: 'translation_history_will_appear_here'.tr(context),
        theme: theme,
      );
    }
    final grouped = _groupByDate(items);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: grouped.entries
          .map((e) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _dateSeparator(e.key, theme),
                  ...e.value.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _translationCard(
                            item, provider, theme),
                      )),
                  const SizedBox(height: 8),
                ],
              ))
          .toList(),
    );
  }

  Widget _translationCard(
      Historique item, HistoryProvider provider, ThemeData theme) {
    final parts = item.subtitle?.split('→') ?? [];
    final from = parts.isNotEmpty ? parts[0].trim() : '?';
    final to = parts.length > 1 ? parts[1].trim() : '?';

    return Dismissible(
      key: Key('tr_${item.id}'),
      direction: DismissDirection.endToStart,
      background: _dismissBg(),
      onDismissed: (_) => provider.deleteItem(item),
      child: GestureDetector(
        onTap: () => _openTranslationDetail(item),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDeco(theme),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Row(children: [
              _iconBox(Icons.translate, Colors.green),
              const SizedBox(width: 12),
              _chip(from, theme),
              const SizedBox(width: 6),
              Icon(Icons.arrow_forward,
                  size: 14,
                  color: theme.textTheme.bodyMedium?.color),
              const SizedBox(width: 6),
              _chip(to, theme),
              const Spacer(),
              Text(item.timeAgo,
                  style: TextStyle(
                      fontSize: 11,
                      color: theme.textTheme.bodyMedium?.color)),
            ]),
            const SizedBox(height: 10),
            Divider(height: 1, color: theme.dividerTheme.color),
            const SizedBox(height: 10),
            Text(item.title,
                style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500)),
            if (item.details != null &&
                item.details!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(item.details!,
                    style: TextStyle(
                        fontSize: 14,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600)),
              ),
            ],
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.touch_app,
                  size: 12,
                  color: theme.textTheme.bodySmall?.color),
              const SizedBox(width: 4),
              Text(
                'tap_to_see_detail'.tr(context),
                style: TextStyle(
                    fontSize: 11,
                    color: theme.textTheme.bodySmall?.color),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _buildSearchesTab(
      HistoryProvider provider, ThemeData theme) {
    final items = provider.history
        .where((h) => h.type == ActivityType.search)
        .toList();
    if (items.isEmpty) {
      return _emptyState(
        icon: Icons.search,
        title: 'no_searches_yet'.tr(context),
        subtitle: 'search_history_will_appear_here'.tr(context),
        theme: theme,
      );
    }
    final grouped = _groupByDate(items);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: grouped.entries
          .map((e) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _dateSeparator(e.key, theme),
                  ...e.value.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child:
                            _searchCard(item, provider, theme),
                      )),
                  const SizedBox(height: 8),
                ],
              ))
          .toList(),
    );
  }

  Widget _searchCard(
      Historique item, HistoryProvider provider, ThemeData theme) {
    return Dismissible(
      key: Key('s_${item.id}'),
      direction: DismissDirection.endToStart,
      background: _dismissBg(),
      onDismissed: (_) => provider.deleteItem(item),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDeco(theme),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.search,
                size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(item.title,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface)),
              const SizedBox(height: 4),
              Text(
                  '${item.subtitle ?? ''} • ${item.timeAgo}',
                  style: TextStyle(
                      fontSize: 12,
                      color: theme.textTheme.bodyMedium?.color)),
            ]),
          ),
          GestureDetector(
            onTap: () => Navigator.pushNamed(
                context, '/monuments-list',
                arguments: {'query': item.title}),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.search,
                  size: 16, color: AppColors.primary),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildMonumentsTab(
      HistoryProvider provider, ThemeData theme) {
    final items = provider.history
        .where((h) => h.type == ActivityType.monument)
        .toList();
    if (items.isEmpty) {
      return _emptyState(
        icon: Icons.account_balance,
        title: 'no_monuments_yet'.tr(context),
        subtitle: 'monuments_you_visit_will_appear_here'.tr(context),
        theme: theme,
      );
    }
    final grouped = _groupByDate(items);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: grouped.entries
          .map((e) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _dateSeparator(e.key, theme),
                  ...e.value.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _monumentCard(
                            item, provider, theme),
                      )),
                  const SizedBox(height: 8),
                ],
              ))
          .toList(),
    );
  }

  Widget _monumentCard(
      Historique item, HistoryProvider provider, ThemeData theme) {
    return Dismissible(
      key: Key('m_${item.id}'),
      direction: DismissDirection.endToStart,
      background: _dismissBg(),
      onDismissed: (_) => provider.deleteItem(item),
      child: GestureDetector(
        onTap: () => _openMonument(item),
        child: Container(
          decoration: _cardDeco(theme),
          child: Row(children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(12)),
              child: item.imageUrl != null
                  ? Image.network(item.imageUrl!,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _imgPlaceholder(theme))
                  : _imgPlaceholder(theme),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(item.title,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  if (item.subtitle != null) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.location_on,
                          size: 12,
                          color: theme.textTheme.bodyMedium?.color),
                      const SizedBox(width: 3),
                      Text(item.subtitle!,
                          style: TextStyle(
                              fontSize: 12,
                              color: theme.textTheme.bodyMedium
                                  ?.color)),
                    ]),
                  ],
                  const SizedBox(height: 6),
                  Text(item.timeAgo,
                      style: TextStyle(
                          fontSize: 11,
                          color:
                              AppColors.primary.withOpacity(0.7))),
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(Icons.arrow_forward_ios,
                  size: 14,
                  color: theme.textTheme.bodyMedium?.color),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _dateSeparator(String label, ThemeData theme) {
    final isToday = label == 'today';
    final displayLabel = label == 'today'
        ? 'today'.tr(context)
        : label == 'yesterday'
            ? 'yesterday'.tr(context)
            : label;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: isToday
                ? AppColors.primary.withOpacity(0.12)
                : theme.dividerTheme.color?.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(displayLabel,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isToday
                      ? AppColors.primary
                      : theme.textTheme.bodyMedium?.color)),
        ),
        const SizedBox(width: 8),
        Expanded(
            child: Divider(
                color: theme.dividerTheme.color, thickness: 1)),
      ]),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required ThemeData theme,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
          Icon(icon,
              size: 70,
              color: theme.dividerTheme.color?.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface)),
          const SizedBox(height: 8),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  color: theme.textTheme.bodyMedium?.color)),
        ]),
      ),
    );
  }

  BoxDecoration _cardDeco(ThemeData theme) => BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      );

  Widget _dismissBg() => Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
            color: Colors.red[400],
            borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      );

  Widget _iconBox(IconData icon, Color color) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16, color: color),
      );

  Widget _chip(String label, ThemeData theme) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: theme.dividerTheme.color?.withOpacity(0.3),
            borderRadius: BorderRadius.circular(6)),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface)),
      );

  Widget _imgPlaceholder(ThemeData theme) => Container(
        width: 90,
        height: 90,
        color: theme.dividerTheme.color?.withOpacity(0.3),
        child: Icon(Icons.account_balance,
            size: 30,
            color: theme.textTheme.bodyMedium?.color),
      );

  void _showClearDialog() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text('clear_history'.tr(context),
            style: TextStyle(color: theme.colorScheme.onSurface)),
        content: Text(
            'this_will_delete_all_your_history_data_this_action'
                .tr(context),
            style: TextStyle(
                color: theme.textTheme.bodyMedium?.color)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr(context))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<HistoryProvider>().clearAll();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content:
                        Text('history_cleared'.tr(context))));
              }
            },
            style:
                TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('clear'.tr(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      margin:
          const EdgeInsets.only(left: 20, right: 20, bottom: 20),
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
            _nav(Icons.home_rounded, '/home'),
            _nav(Icons.account_balance_rounded, '/monuments'),
            _nav(Icons.translate_rounded, '/translation'),
            _nav(Icons.chat_bubble_rounded, '/chatbot'),
            _nav(Icons.person_rounded, '/profile'),
          ],
        ),
      ),
    );
  }

  Widget _nav(IconData icon, String route) => GestureDetector(
        onTap: () => Navigator.pushNamed(context, route),
        child: Container(
            width: 52,
            height: 52,
            color: Colors.transparent,
            child:
                Icon(icon, color: Colors.white, size: 24)),
      );
}