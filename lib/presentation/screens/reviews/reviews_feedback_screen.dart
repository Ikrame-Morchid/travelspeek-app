import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/l10n/string_extensions.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/token_service.dart';
import '../../widgets/app_drawer.dart';

class ReviewsFeedbackScreen extends StatefulWidget {
  final int initialTab;

  const ReviewsFeedbackScreen({
    super.key,
    this.initialTab = 0,
  });

  @override
  State<ReviewsFeedbackScreen> createState() => _ReviewsFeedbackScreenState();
}

class _ReviewsFeedbackScreenState extends State<ReviewsFeedbackScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  int _rating = 0;
  String _selectedCategory = 'general';
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  final ApiService _apiService = ApiService.instance;

  bool _isLoading = true;
  List<Map<String, dynamic>> _reviews = [];
  Map<String, dynamic>? _stats;
  String _sortBy = 'recent';

  final List<Map<String, dynamic>> _categories = [
    {'value': 'general', 'label': 'general_category', 'icon': '💬'},
    {'value': 'bug', 'label': 'bug_report', 'icon': '🐛'},
    {'value': 'feature', 'label': 'feature', 'icon': '✨'},
    {'value': 'design', 'label': 'design_category', 'icon': '🎨'},
    {'value': 'performance', 'label': 'performance_category', 'icon': '⚡'},
    {'value': 'other', 'label': 'other_category', 'icon': '📝'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _loadReviews();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);
    try {
      final reviewsResponse =
          await _apiService.get('/feedbacks', requiresAuth: false);
      final statsResponse =
          await _apiService.get('/feedbacks/stats', requiresAuth: false);
      if (reviewsResponse.statusCode == 200 &&
          statsResponse.statusCode == 200) {
        setState(() {
          _reviews = List<Map<String, dynamic>>.from(
              json.decode(reviewsResponse.body));
          _stats = json.decode(statsResponse.body);
          _sortReviews();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${'error'.tr(context)}: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  void _sortReviews() {
    if (_sortBy == 'recent') {
      _reviews.sort((a, b) =>
          (b['created_at'] ?? '').compareTo(a['created_at'] ?? ''));
    } else {
      _reviews.sort(
          (a, b) => (b['rating'] ?? 0).compareTo(a['rating'] ?? 0));
    }
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('please_select_a_rating'.tr(context)),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final accessToken = await TokenService.instance.getAccessToken();
      debugPrint('🔍 TOKEN: $accessToken');
      final response = await _apiService.post(
        '/feedbacks',
        {
          'rating': _rating,
          'category': _selectedCategory,
          'comment': _commentController.text.trim().isEmpty
              ? null
              : _commentController.text.trim(),
        },
        requiresAuth: true,
      );
      setState(() => _isSubmitting = false);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('review_submitted_successfully'.tr(context)),
            backgroundColor: Colors.green,
          ));
          setState(() {
            _rating = 0;
            _selectedCategory = 'general';
            _commentController.clear();
          });
          await _loadReviews();
          _tabController.animateTo(1);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('failed_to_submit_review'.tr(context)),
            backgroundColor: Colors.red,
          ));
        }
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${'error'.tr(context)}: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  String _getRatingLabel() {
    switch (_rating) {
      case 1: return '😞 Très mauvais';
      case 2: return '😕 Mauvais';
      case 3: return '😐 Correct';
      case 4: return '😊 Bien';
      case 5: return '🤩 Excellent !';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      endDrawer: const AppDrawer(),
      backgroundColor: colorScheme.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          const SizedBox(height: 12),
          _buildTabs(),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildWriteReviewTab(),
                _buildAllReviewsTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return AppBar(
      backgroundColor: colorScheme.surface,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'reviews_feedback'.tr(context),
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.refresh, color: colorScheme.onSurface),
          onPressed: _loadReviews,
        ),
        Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.more_vert, color: colorScheme.onSurface),
            onPressed: () => Scaffold.of(context).openEndDrawer(),
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 46,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(23),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(23),
        ),
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: colorScheme.onSurface,
        labelStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.rate_review, size: 16),
                const SizedBox(width: 6),
                Text('write_review'.tr(context)),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, size: 16),
                const SizedBox(width: 6),
                Text('all_reviews'.tr(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // WRITE REVIEW TAB
  // ═══════════════════════════════════════════════
  Widget _buildWriteReviewTab() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmall = screenHeight < 700;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05,
        vertical: 4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Banner ──────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isSmall ? 14 : 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'help_us_improve'.tr(context),
                        style: TextStyle(
                          fontSize: isSmall ? 15 : 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'share_your_experience_with_travel_speak'.tr(context),
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.feedback,
                    size: isSmall ? 36 : 44, color: Colors.white24),
              ],
            ),
          ),

          SizedBox(height: isSmall ? 12 : 16),

          // ── Note ────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              vertical: isSmall ? 16 : 20,
              horizontal: 16,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey[100]!,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'how_would_you_rate_your_experience'.tr(context),
                  style: TextStyle(
                    fontSize: isSmall ? 13 : 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isSmall ? 12 : 16),
                _buildRatingStars(isSmall),
                if (_rating > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    _getRatingLabel(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: isSmall ? 12 : 16),

          // ── Catégorie ────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isSmall ? 14 : 16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey[100]!,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'what_is_your_feedback_about'.tr(context),
                  style: TextStyle(
                    fontSize: isSmall ? 13 : 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: isSmall ? 10 : 14),
                _buildCategoryGrid(isDark, colorScheme, screenWidth),
              ],
            ),
          ),

          SizedBox(height: isSmall ? 12 : 16),

          // ── Commentaire ──────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isSmall ? 14 : 16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey[100]!,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'additional_comments_optional'.tr(context),
                  style: TextStyle(
                    fontSize: isSmall ? 13 : 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: isSmall ? 10 : 14),
                TextField(
                  controller: _commentController,
                  maxLines: isSmall ? 4 : 5,
                  maxLength: 500,
                  style: TextStyle(
                      fontSize: 14, color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText:
                        'tell_us_more_about_your_experience'.tr(context),
                    hintStyle: TextStyle(
                      color: isDark
                          ? Colors.grey[500]
                          : Colors.grey[400],
                      fontSize: 13,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.grey[700]!
                            : Colors.grey[200]!,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.grey[700]!
                            : Colors.grey[200]!,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 2),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withOpacity(0.03)
                        : Colors.grey[50],
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: isSmall ? 16 : 20),

          // ── Bouton submit ────────────────────────
          SizedBox(
            width: double.infinity,
            height: isSmall ? 48 : 54,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.send_rounded,
                            size: 18, color: Colors.white),
                        const SizedBox(width: 10),
                        Text(
                          'submit_feedback'.tr(context),
                          style: TextStyle(
                            fontSize: isSmall ? 14 : 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildRatingStars(bool isSmall) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final starSize = isSmall ? 38.0 : 44.0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starNumber = index + 1;
        final isSelected = starNumber <= _rating;
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              _rating =
                  _rating == starNumber ? starNumber - 1 : starNumber;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(
                isSelected ? Icons.star : Icons.star_border,
                key: ValueKey('star-$starNumber-$isSelected'),
                size: starSize,
                color: isSelected
                    ? Colors.orange
                    : (isDark ? Colors.grey[700] : Colors.grey[300]),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCategoryGrid(
      bool isDark, ColorScheme colorScheme, double screenWidth) {
    // ✅ childAspectRatio adapté pour afficher le texte complet
    final ratio = screenWidth < 360 ? 2.2 : 2.6;
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: ratio,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: _categories.map((category) {
        final isSelected = _selectedCategory == category['value'];
        return GestureDetector(
          onTap: () => setState(
              () => _selectedCategory = category['value'] as String),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(category['icon'] as String,
                    style: const TextStyle(fontSize: 15)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    (category['label'] as String).tr(context),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ═══════════════════════════════════════════════
  // ALL REVIEWS TAB
  // ═══════════════════════════════════════════════
  Widget _buildAllReviewsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _loadReviews,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.05,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_stats != null) _buildOverallRating(),
            const SizedBox(height: 20),
            if (_stats != null) _buildRatingDistribution(),
            const SizedBox(height: 20),
            _buildSortOptions(),
            const SizedBox(height: 16),
            _buildReviewsList(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallRating() {
    final total = _stats!['total'] ?? 0;
    final avgRating = _stats!['average_rating'] ?? 0.0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      avgRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 7, left: 4),
                      child: Text('/5',
                          style: TextStyle(
                              fontSize: 18, color: Colors.white70)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: List.generate(
                    5,
                    (index) => Icon(
                      index < avgRating.round()
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$total ${'ratings'.tr(context)}',
                  style: const TextStyle(
                      fontSize: 13, color: Colors.white70),
                ),
              ],
            ),
          ),
          const Icon(Icons.star_rounded, size: 80, color: Colors.white24),
        ],
      ),
    );
  }

  Widget _buildRatingDistribution() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final distribution =
        _stats!['rating_distribution'] as Map<String, dynamic>? ?? {};
    final total = _stats!['total'] ?? 1;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[100]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'rating_distribution'.tr(context),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 14),
          for (int i = 5; i >= 1; i--)
            _buildRatingBar(
                i, (distribution['$i'] ?? 0) as int, total),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int stars, int count, int total) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final percentage = total > 0 ? (count / total) : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text('$stars',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          const Icon(Icons.star, size: 12, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color:
                        isDark ? Colors.grey[800] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: percentage,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 24,
            child: Text(
              '$count',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortOptions() {
    return Row(
      children: [
        Expanded(
          child: _buildSortButton(
            label: 'most_recent'.tr(context),
            value: 'recent',
            icon: Icons.access_time,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSortButton(
            label: 'highest_rated'.tr(context),
            value: 'rating',
            icon: Icons.star,
          ),
        ),
      ],
    );
  }

  Widget _buildSortButton({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () => setState(() {
        _sortBy = value;
        _sortReviews();
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.grey[400] : Colors.grey[600])),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.grey[300] : Colors.grey[700]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsList() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    if (_reviews.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(Icons.rate_review,
                  size: 70,
                  color: isDark ? Colors.grey[700] : Colors.grey[300]),
              const SizedBox(height: 14),
              Text(
                'no_reviews_yet'.tr(context),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'be_the_first_to_write_a_review'.tr(context),
                style: TextStyle(
                    fontSize: 13,
                    color:
                        isDark ? Colors.grey[400] : Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      children: _reviews.map((r) => _buildReviewCard(r)).toList(),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final rating = review['rating'] ?? 0;
    final comment = review['comment'] ?? '';
    final userId = review['user_id'];
    final username = review['username'] ??
        (userId != null
            ? '${'user'.tr(context)} $userId'
            : 'anonymous'.tr(context));
    final createdAt = review['created_at'] ?? '';
    final category = review['category'] ?? 'general';
    final timeAgo = _getTimeAgo(createdAt);
    final categoryData = _categories.firstWhere(
      (c) => c['value'] == category,
      orElse: () => _categories[0],
    );
    final initial =
        username.isNotEmpty ? username[0].toUpperCase() : 'U';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[100]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            username,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(categoryData['icon'] as String,
                            style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Row(
                          children: List.generate(
                            5,
                            (index) => Icon(
                              index < rating
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 13,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          timeAgo,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? Colors.grey[400]
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              comment,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getTimeAgo(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      if (difference.inDays > 365) {
        return '${(difference.inDays / 365).floor()}y ${'ago'.tr(context)}';
      } else if (difference.inDays > 30) {
        return '${(difference.inDays / 30).floor()}mo ${'ago'.tr(context)}';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d ${'ago'.tr(context)}';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ${'ago'.tr(context)}';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ${'ago'.tr(context)}';
      } else {
        return 'just_now'.tr(context);
      }
    } catch (e) {
      return '';
    }
  }

  Widget _buildBottomNavBar() {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
      height: 68,
      decoration: BoxDecoration(
        color: AppColors.navBarBackground,
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
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
    final isSelected = index == 4;
    return GestureDetector(
      onTap: () {
        if (index == 0) Navigator.pushNamed(context, '/home');
        if (index == 1) Navigator.pushNamed(context, '/monuments');
        if (index == 2) Navigator.pushNamed(context, '/translation');
        if (index == 3) Navigator.pushNamed(context, '/chatbot');
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