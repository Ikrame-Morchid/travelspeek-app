import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/string_extensions.dart';
import '../../providers/monument_provider.dart';
import '../../providers/language_provider.dart';
import '../../../data/models/monument_model.dart';
import '../../../data/repositories/search_repository.dart';
import 'monument_detail_screen.dart';

class MonumentsGridScreen extends StatefulWidget {
  const MonumentsGridScreen({super.key});

  @override
  State<MonumentsGridScreen> createState() => _MonumentsGridScreenState();
}

class _MonumentsGridScreenState extends State<MonumentsGridScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedFilter;

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
      provider.searchMonuments('');
    } else {
      provider.fuzzySearch(value);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    final provider = context.read<MonumentProvider>();
    provider.clearFuzzySearch();
    provider.searchMonuments('');
    setState(() {});
  }

  void _selectSuggestion(SearchSuggestion s) {
    _searchController.text = s.nom;
    context.read<MonumentProvider>().selectSuggestion(s.nom);
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
        appBar: AppBar(
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back,
                color: theme.colorScheme.onSurface),
            onPressed: _handleBack,
          ),
          title: Text(
            'moroccan_monuments'.tr(context),
            style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
        ),
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
                    children: [
                      _buildSearchBar(provider, theme),
                      const SizedBox(height: 16),
                      if (!provider.fuzzyActive) ...[
                        _buildFilters(provider, theme),
                        const SizedBox(height: 20),
                      ],
                      provider.fuzzyActive
                          ? _buildFuzzyResults(provider, theme)
                          : _buildMonumentGrid(
                              provider.monuments, theme),
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

  Widget _buildSearchBar(
      MonumentProvider provider, ThemeData theme) {
    return Column(
      children: [
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
          child: Row(
            children: [
              const SizedBox(width: 18),
              provider.isFuzzySearching
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary))
                  : Icon(Icons.search,
                      color: theme.textTheme.bodySmall?.color,
                      size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _searchController,
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
            ],
          ),
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
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(8),
                                child: s.image != null
                                    ? Image.network(s.image!,
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (_, __, ___) =>
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
                                            fontWeight:
                                                FontWeight.w600,
                                            color: theme
                                                .colorScheme
                                                .onSurface)),
                                    Text(s.ville,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: theme.textTheme
                                                .bodyMedium
                                                ?.color)),
                                  ],
                                ),
                              ),
                              Icon(Icons.north_west,
                                  size: 14,
                                  color: theme
                                      .textTheme.bodySmall?.color),
                            ],
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8)),
      child: Icon(Icons.account_balance,
          color: AppColors.primary, size: 20),
    );
  }

  Widget _buildFuzzyResults(
      MonumentProvider provider, ThemeData theme) {
    if (provider.searchResults.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.search_off,
                size: 64,
                color: theme.textTheme.bodySmall?.color),
            const SizedBox(height: 16),
            Text('no_monuments_found'.tr(context),
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface)),
          ],
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
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: provider.searchResults.length,
          itemBuilder: (context, i) =>
              _buildFuzzyCard(provider.searchResults[i]),
        ),
      ],
    );
  }

  Widget _buildFuzzyCard(SearchResult result) {
    return GestureDetector(
      onTap: () => _goToDetail(context, result: result),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              result.image != null
                  ? Image.network(result.image!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[300],
                          child:
                              const Icon(Icons.image, size: 50)))
                  : Container(
                      color: Colors.grey[300],
                      child:
                          const Icon(Icons.image, size: 50)),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7)
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius:
                                BorderRadius.circular(12)),
                        child: Text(
                            '${result.score.toInt()}%',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const Spacer(),
                    Text(result.nom,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.location_on,
                          size: 13, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(result.ville,
                          style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70)),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(
      MonumentProvider provider, ThemeData theme) {
    final filters = ['all'.tr(context), ...provider.cities];

    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isAll = filter == 'all'.tr(context);
          final isSelected = _selectedFilter == filter ||
              (_selectedFilter == null && isAll);
          final count = isAll
              ? provider.allMonuments.length
              : provider.allMonuments
                  .where((m) => m.ville == filter)
                  .length;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = isAll ? null : filter;
              });
              provider.filterByCity(_selectedFilter);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.8)
                      ])
                    : null,
                color: isSelected
                    ? null
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : theme.dividerTheme.color!,
                    width: isSelected ? 2 : 1),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                            color:
                                AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2))
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(filter,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : theme.colorScheme.onSurface)),
                  if (count > 0 && !isAll) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withOpacity(0.3)
                            : AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('$count',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.primary)),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonumentGrid(
      List<Monument> monuments, ThemeData theme) {
    if (monuments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(Icons.search_off,
                  size: 64,
                  color: theme.textTheme.bodySmall?.color),
              const SizedBox(height: 16),
              Text('no_monuments_found'.tr(context),
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface)),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: monuments.length,
      itemBuilder: (context, i) =>
          _buildMonumentCard(monuments[i]),
    );
  }

  // Les cartes de monuments ont des images en arrière-plan donc
  // on conserve les textes en blanc sur les overlays
  Widget _buildMonumentCard(Monument monument) {
    return GestureDetector(
      onTap: () => _goToDetail(context, monument: monument),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              monument.mainImage != null
                  ? Image.network(monument.mainImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[300],
                          child:
                              const Icon(Icons.image, size: 50)))
                  : Container(
                      color: Colors.grey[300],
                      child:
                          const Icon(Icons.image, size: 50)),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7)
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle),
                        child: Icon(
                            monument.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: Colors.red,
                            size: 18),
                      ),
                    ),
                    const Spacer(),
                    Text(monument.nom,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.location_on,
                          size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Expanded(
                          child: Text(monument.ville,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis)),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
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
            _buildNavIcon(Icons.home_rounded, 0, '/home'),
            _buildNavIcon(
                Icons.account_balance_rounded, 1, null),
            _buildNavIcon(
                Icons.translate_rounded, 2, '/translation'),
            _buildNavIcon(
                Icons.chat_bubble_rounded, 3, '/chatbot'),
            _buildNavIcon(Icons.person_rounded, 4, '/profile'),
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
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}