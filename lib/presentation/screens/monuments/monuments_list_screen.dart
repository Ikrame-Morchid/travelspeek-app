import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/string_extensions.dart';
import '../../providers/monument_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/history_provider.dart';
import '../../../data/models/monument_model.dart';
import '../../../data/repositories/search_repository.dart';
import 'monument_detail_screen.dart';

class MonumentsListScreen extends StatefulWidget {
  const MonumentsListScreen({super.key});

  @override
  State<MonumentsListScreen> createState() =>
      _MonumentsListScreenState();
}

class _MonumentsListScreenState extends State<MonumentsListScreen> {
  final TextEditingController _searchController =
      TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _lastSavedQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lang = context.read<LanguageProvider>().currentLanguage;
      context.read<MonumentProvider>().loadMonuments(lang: lang);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _handleBack() {
    final provider = context.read<MonumentProvider>();
    if (_searchController.text.isNotEmpty || provider.fuzzyActive) {
      _clearSearch();
    } else {
      Navigator.pop(context);
    }
  }

  void _onSearchChanged(String value) {
    final provider = context.read<MonumentProvider>();
    if (value.trim().isEmpty) {
      provider.clearFuzzySearch();
    } else {
      provider.fuzzySearch(value);
    }
  }

  void _saveSearchToHistory(String query, int resultCount) {
    if (query.trim().isEmpty || query == _lastSavedQuery) return;
    _lastSavedQuery = query;
    context.read<HistoryProvider>().addSearchToHistory(
          query: query,
          resultCount: resultCount,
        );
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<MonumentProvider>().clearFuzzySearch();
    setState(() {});
  }

  void _selectSuggestion(SearchSuggestion s) {
    _searchController.text = s.nom;
    context.read<MonumentProvider>().selectSuggestion(s.nom);
    _saveSearchToHistory(s.nom, 1);
    setState(() {});
  }

  void _goToDetail(BuildContext context,
      {Monument? monument, SearchResult? result}) {
    final m = monument ??
        Monument(
          id: 0,
          nom: result!.nom,
          ville: result.ville,
          description: result.description,
          localisation: result.localisation,
          image: result.image,
          imageUrl: result.image,
          images: result.allImages,
          createdAt: DateTime.now(),
        );
    Navigator.push(context,
        MaterialPageRoute(
            builder: (_) => MonumentDetailScreen(monument: m)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentLang =
        context.watch<LanguageProvider>().currentLanguage;

    return WillPopScope(
      onWillPop: () async {
        if (_searchController.text.isNotEmpty ||
            context.read<MonumentProvider>().fuzzyActive) {
          _clearSearch();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: _buildAppBar(theme),
        body: Consumer<MonumentProvider>(
          builder: (context, provider, _) {
            if (provider.monuments.isNotEmpty &&
                provider.currentLanguage != currentLang) {
              Future.microtask(
                  () => provider.changeLanguage(currentLang));
            }
            if (provider.isLoading && !provider.hasMonuments) {
              return const Center(
                  child: CircularProgressIndicator());
            }
            if (provider.errorMessage != null &&
                !provider.hasMonuments) {
              return _buildError(provider.errorMessage!, theme);
            }

            if (provider.fuzzyActive &&
                _searchController.text.trim().isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _saveSearchToHistory(_searchController.text,
                    provider.searchResults.length);
              });
            }

            return GestureDetector(
              onTap: () {
                if (provider.suggestions.isNotEmpty) {
                  provider.clearFuzzySearch();
                }
              },
              child: RefreshIndicator(
                onRefresh: () => provider.refresh(),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSearchBar(provider, theme),
                      const SizedBox(height: 24),
                      if (provider.fuzzyActive)
                        _buildFuzzyResults(provider, theme)
                      else ...[
                        _buildSectionHeader(
                            'popular'.tr(context),
                            theme,
                            onSeeAll: () => Navigator.pushNamed(
                                context, '/monuments-grid')),
                        const SizedBox(height: 16),
                        _buildPopularList(
                            _getPopularMonuments(
                                provider.monuments),
                            theme),
                        const SizedBox(height: 24),
                        _buildSectionHeader(
                            'recommended'.tr(context),
                            theme,
                            onSeeAll: () => Navigator.pushNamed(
                                context, '/monuments-grid')),
                        const SizedBox(height: 16),
                        _buildRecommendedList(
                            _getRecommendedMonuments(
                                provider.monuments),
                            theme),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        bottomNavigationBar: _buildBottomNavBar(),
      ),
    );
  }

  List<Monument> _getPopularMonuments(List<Monument> all) {
    if (all.isEmpty) return [];
    final Map<String, List<Monument>> byCity = {};
    for (var m in all) {
      byCity.putIfAbsent(m.ville, () => []).add(m);
    }
    final popular = <Monument>[];
    for (var list in byCity.values) {
      if (list.isNotEmpty) popular.add(list.first);
      if (popular.length >= 10) break;
    }
    return popular;
  }

  List<Monument> _getRecommendedMonuments(List<Monument> all) {
    if (all.isEmpty) return [];
    final popularIds =
        _getPopularMonuments(all).map((m) => m.id).toSet();
    return all
        .where((m) => !popularIds.contains(m.id))
        .take(10)
        .toList();
  }

  Widget _buildSearchBar(
      MonumentProvider provider, ThemeData theme) {
    return Column(children: [
      Container(
        height: 54,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(27),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 15,
                offset: const Offset(0, 3))
          ],
        ),
        child: Row(children: [
          const SizedBox(width: 18),
          provider.isFuzzySearching
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primary))
              : Icon(Icons.search,
                  color: theme.textTheme.bodySmall?.color,
                  size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              decoration: InputDecoration(
                hintText: 'search_monuments'.tr(context),
                hintStyle: TextStyle(
                    fontSize: 14,
                    color: theme.textTheme.bodySmall?.color),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
              ),
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface),
              onChanged: _onSearchChanged,
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear,
                  color: theme.textTheme.bodySmall?.color,
                  size: 18),
              onPressed: _clearSearch,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            )
          else
            const SizedBox(width: 14),
        ]),
      ),
      if (provider.suggestions.isNotEmpty)
        Container(
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            children: provider.suggestions
                .map((s) => InkWell(
                      onTap: () => _selectSuggestion(s),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Row(children: [
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(8),
                            child: s.image != null
                                ? Image.network(s.image!,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _imagePlaceholder())
                                : _imagePlaceholder(),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                              Text(s.nom,
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: theme
                                          .colorScheme.onSurface)),
                              Text(s.ville,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: theme.textTheme
                                          .bodyMedium?.color)),
                            ]),
                          ),
                          Icon(Icons.north_west,
                              size: 14,
                              color:
                                  theme.textTheme.bodySmall?.color),
                        ]),
                      ),
                    ))
                .toList(),
          ),
        ),
    ]);
  }

  Widget _imagePlaceholder() => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(Icons.account_balance,
            color: AppColors.primary, size: 20),
      );

  Widget _buildFuzzyResults(
      MonumentProvider provider, ThemeData theme) {
    if (provider.searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(children: [
            Icon(Icons.search_off,
                size: 64,
                color: theme.textTheme.bodySmall?.color),
            const SizedBox(height: 16),
            Text('no_monuments_found'.tr(context),
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface)),
          ]),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'search_results_for'
                .tr(context)
                .replaceAll(
                    '{n}', '${provider.searchResults.length}')
                .replaceAll('{query}', _searchController.text),
            style: TextStyle(
                fontSize: 13,
                color: theme.textTheme.bodyMedium?.color),
          ),
        ),
        LayoutBuilder(builder: (context, constraints) {
          final w = (constraints.maxWidth - 12) / 2;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: w / (w * 1.2),
            ),
            itemCount: provider.searchResults.length,
            itemBuilder: (_, i) =>
                _buildFuzzyCard(provider.searchResults[i], theme),
          );
        }),
      ],
    );
  }

  Widget _buildFuzzyCard(SearchResult result, ThemeData theme) {
    return GestureDetector(
      onTap: () => _goToDetail(context, result: result),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: LayoutBuilder(builder: (_, constraints) {
          final imgH = constraints.maxWidth * 0.7;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16)),
                  child: result.image != null
                      ? Image.network(result.image!,
                          width: double.infinity,
                          height: imgH,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                              width: double.infinity,
                              height: imgH,
                              color: theme.dividerTheme.color
                                  ?.withOpacity(0.3),
                              child:
                                  const Icon(Icons.image, size: 40)))
                      : Container(
                          width: double.infinity,
                          height: imgH,
                          color: theme.dividerTheme.color
                              ?.withOpacity(0.3),
                          child:
                              const Icon(Icons.image, size: 40)),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius:
                            BorderRadius.circular(12)),
                    child: Text('${result.score.toInt()}%',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(result.nom,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Row(children: [
                        Icon(Icons.location_on,
                            size: 12,
                            color: theme.textTheme.bodyMedium?.color),
                        const SizedBox(width: 3),
                        Expanded(
                            child: Text(result.ville,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: theme.textTheme
                                        .bodyMedium?.color),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis)),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back,
            color: theme.colorScheme.onSurface),
        onPressed: _handleBack,
      ),
      title: Text('moroccan_monuments'.tr(context),
          style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme,
      {VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface)),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Text('show_all'.tr(context),
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary)),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios,
                    size: 12, color: AppColors.primary),
              ]),
            ),
          ),
      ],
    );
  }

  Widget _buildPopularList(
      List<Monument> monuments, ThemeData theme) {
    if (monuments.isEmpty) {
      return Center(
          child: Text('no_monuments_found'.tr(context),
              style: TextStyle(
                  color: theme.colorScheme.onSurface)));
    }
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: monuments.length,
        itemBuilder: (_, i) =>
            _buildPopularCard(monuments[i], theme),
      ),
    );
  }

  Widget _buildPopularCard(Monument monument, ThemeData theme) {
    return GestureDetector(
      onTap: () => _goToDetail(context, monument: monument),
      child: Container(
        width: 110,
        margin: const EdgeInsets.only(right: 12),
        child: Column(children: [
          Container(
            width: 110,
            height: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(fit: StackFit.expand, children: [
                monument.mainImage != null
                    ? Image.network(monument.mainImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                            color: theme.dividerTheme.color
                                ?.withOpacity(0.3),
                            child:
                                const Icon(Icons.image, size: 30)))
                    : Container(
                        color: theme.dividerTheme.color
                            ?.withOpacity(0.3),
                        child:
                            const Icon(Icons.image, size: 30)),
                Container(
                    decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.5)
                    ],
                  ),
                )),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          Text(monument.ville,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center),
          Text(monument.nom,
              style: TextStyle(
                  fontSize: 11,
                  color: theme.textTheme.bodyMedium?.color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  Widget _buildRecommendedList(
      List<Monument> monuments, ThemeData theme) {
    if (monuments.isEmpty) {
      return Center(
          child: Text('no_monuments_found'.tr(context),
              style: TextStyle(
                  color: theme.colorScheme.onSurface)));
    }
    return LayoutBuilder(builder: (context, constraints) {
      final w = (constraints.maxWidth - 12) / 2;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: w / (w * 1.2),
        ),
        itemCount: monuments.length,
        itemBuilder: (_, i) =>
            _buildRecommendedCard(monuments[i], theme),
      );
    });
  }

  Widget _buildRecommendedCard(
      Monument monument, ThemeData theme) {
    return GestureDetector(
      onTap: () => _goToDetail(context, monument: monument),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: LayoutBuilder(builder: (_, constraints) {
          final imgH = constraints.maxWidth * 0.7;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16)),
                  child: monument.mainImage != null
                      ? Image.network(monument.mainImage!,
                          width: double.infinity,
                          height: imgH,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                              width: double.infinity,
                              height: imgH,
                              color: theme.dividerTheme.color
                                  ?.withOpacity(0.3),
                              child:
                                  const Icon(Icons.image, size: 40)))
                      : Container(
                          width: double.infinity,
                          height: imgH,
                          color: theme.dividerTheme.color
                              ?.withOpacity(0.3),
                          child:
                              const Icon(Icons.image, size: 40)),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle),
                    child: Icon(
                        monument.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: Colors.red,
                        size: 16),
                  ),
                ),
              ]),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(monument.nom,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Row(children: [
                        Icon(Icons.location_on,
                            size: 12,
                            color:
                                theme.textTheme.bodyMedium?.color),
                        const SizedBox(width: 3),
                        Expanded(
                            child: Text(monument.ville,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: theme.textTheme
                                        .bodyMedium?.color),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis)),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildError(String message, ThemeData theme) {
    return Center(
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
        const Icon(Icons.error_outline,
            size: 64, color: Colors.red),
        const SizedBox(height: 16),
        Text(message,
            style: TextStyle(
                color: theme.colorScheme.onSurface)),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () =>
              context.read<MonumentProvider>().refresh(),
          child: Text('retry'.tr(context)),
        ),
      ]),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      margin: const EdgeInsets.only(
          left: 16, right: 16, bottom: 16),
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFF2D3E45),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavIcon(Icons.home_rounded, 0, '/home'),
            _buildNavIcon(
                Icons.account_balance_rounded, 1, null),
            _buildNavIcon(
                Icons.translate_rounded, 2, '/translation'),
            _buildNavIcon(
                Icons.chat_bubble_rounded, 3, '/chatbot'),
            _buildNavIcon(
                Icons.person_rounded, 4, '/profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavIcon(
      IconData icon, int index, String? route) {
    final isSelected = index == 1;
    return GestureDetector(
      onTap: () {
        if (route != null) Navigator.pushNamed(context, route);
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}