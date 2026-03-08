import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/string_extensions.dart';
import '../../../data/models/monument_model.dart';
import '../../providers/history_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/comment_provider.dart';

class MonumentDetailScreen extends StatefulWidget {
  final Monument monument;
  const MonumentDetailScreen({super.key, required this.monument});

  @override
  State<MonumentDetailScreen> createState() => _MonumentDetailScreenState();
}

class _MonumentDetailScreenState extends State<MonumentDetailScreen> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  final TextEditingController _commentController = TextEditingController();
  int? _selectedNote;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().addMonumentToHistory(
            monumentId: widget.monument.id,
            monumentName: widget.monument.nom,
            location: widget.monument.ville,
            imageUrl: widget.monument.mainImage,
          );
      context
          .read<FavoriteProvider>()
          .refreshFavoriteStatus(widget.monument.id);
      context.read<CommentProvider>().loadComments(widget.monument.id);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  List<String> _buildImageList() {
    final all = <String>[];
    if (widget.monument.mainImage != null) all.add(widget.monument.mainImage!);
    if (widget.monument.images != null) {
      for (var img in widget.monument.images!) {
        if (!all.contains(img)) all.add(img);
      }
    }
    return all;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allImages = _buildImageList();
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(allImages, theme),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (allImages.length > 1)
                  _buildModernCarousel(allImages, theme),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(theme),
                      const SizedBox(height: 16),
                      _buildAboutSection(theme),
                      const SizedBox(height: 24),
                      _buildLocationSection(theme),
                      const SizedBox(height: 24),
                      _buildCommentsSection(theme),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildSliverAppBar(List<String> images, ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 350,
      pinned: true,
      backgroundColor: theme.colorScheme.surface,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: theme.colorScheme.surface, shape: BoxShape.circle),
        child: IconButton(
          icon: Icon(Icons.arrow_back,
              color: theme.colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Consumer<FavoriteProvider>(
          builder: (context, fav, _) {
            final isFav = fav.isFavorite(widget.monument.id);
            return Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: theme.colorScheme.surface, shape: BoxShape.circle),
              child: IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: Colors.red,
                  size: 20,
                ),
                onPressed: () async {
                  final success = await fav.toggleFavorite(widget.monument);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(!isFav
                          ? 'added_favorites'.tr(context)
                          : 'removed_favorites'.tr(context)),
                      duration: const Duration(seconds: 1),
                      backgroundColor: success
                          ? (!isFav ? Colors.green : Colors.orange)
                          : Colors.red,
                    ));
                  }
                },
              ),
            );
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(fit: StackFit.expand, children: [
          CachedNetworkImage(
            imageUrl: images.isNotEmpty
                ? images[_currentImageIndex.clamp(0, images.length - 1)]
                : '',
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
                color: theme.dividerTheme.color?.withOpacity(0.3),
                child: const Center(child: CircularProgressIndicator())),
            errorWidget: (_, __, ___) => Container(
                color: theme.dividerTheme.color?.withOpacity(0.3),
                child: const Icon(Icons.image, size: 80)),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    theme.scaffoldBackgroundColor.withOpacity(0.8),
                    theme.scaffoldBackgroundColor,
                  ],
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildModernCarousel(List<String> images, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(children: [
        Row(children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(children: [
              Icon(Icons.photo_library,
                  color: AppColors.primary, size: 16),
              const SizedBox(width: 6),
              Text('photo_gallery'.tr(context),
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary)),
            ]),
          ),
          const Spacer(),
          Text('${_currentImageIndex + 1}/${images.length}',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyMedium?.color)),
        ]),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(images.length, (i) {
            final active = i == _currentImageIndex;
            return GestureDetector(
              onTap: () => _pageController.animateToPage(i,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: active ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.primary
                      : AppColors.primary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 250,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (i) =>
                setState(() => _currentImageIndex = i),
            itemCount: images.length,
            itemBuilder: (_, i) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: images[i],
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                      color: theme.dividerTheme.color?.withOpacity(0.3),
                      child: const Center(
                          child: CircularProgressIndicator())),
                  errorWidget: (_, __, ___) => Container(
                      color: theme.dividerTheme.color?.withOpacity(0.3),
                      child: const Icon(Icons.error, size: 50)),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
      Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.location_city,
              size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            widget.monument.categorie?.toUpperCase() ?? 'HISTORICAL',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: 0.5),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      Text(widget.monument.nom,
          style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface)),
      const SizedBox(height: 8),
      Row(children: [
        Icon(Icons.location_on,
            size: 18, color: theme.textTheme.bodyMedium?.color),
        const SizedBox(width: 6),
        Text(widget.monument.location,
            style: TextStyle(
                fontSize: 14,
                color: theme.textTheme.bodyMedium?.color)),
      ]),
    ]);
  }

  Widget _buildAboutSection(ThemeData theme) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
      Text('about'.tr(context),
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface)),
      const SizedBox(height: 12),
      Text(
        widget.monument.description,
        textAlign: TextAlign.justify,
        style: TextStyle(
            fontSize: 14,
            color: theme.colorScheme.onSurface,
            height: 1.6),
      ),
    ]);
  }

  Widget _buildLocationSection(ThemeData theme) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('location'.tr(context),
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface)),
        if (widget.monument.localisation != null)
          GestureDetector(
            onTap: _openGoogleMaps,
            child: Row(children: [
              Text('open_in_maps'.tr(context),
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary)),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_ios,
                  size: 12, color: AppColors.primary),
            ]),
          ),
      ]),
      const SizedBox(height: 12),
      GestureDetector(
        onTap: _openGoogleMaps,
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8))
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(fit: StackFit.expand, children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFB2EBF2), Color(0xFF80DEEA)],
                  ),
                ),
                child: CustomPaint(painter: _MapPatternPainter()),
              ),
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
              Positioned(
                left: 24,
                right: 24,
                bottom: 24,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(widget.monument.ville,
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                                color: Colors.black45, blurRadius: 8)
                          ])),
                  const SizedBox(height: 4),
                  Text(widget.monument.nom,
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.95),
                          fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ]),
              ),
              Positioned(
                top: 60,
                left: MediaQuery.of(context).size.width / 2 - 60,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.primary.withOpacity(0.5),
                          blurRadius: 15,
                          spreadRadius: 3)
                    ],
                  ),
                  child: const Icon(Icons.location_on,
                      color: Colors.white, size: 28),
                ),
              ),
            ]),
          ),
        ),
      ),
    ]);
  }

  Future<void> _openGoogleMaps() async {
    final url = widget.monument.localisation;
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('location_unavailable'.tr(context)),
          backgroundColor: Colors.orange));
      return;
    }
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${'error'.tr(context)}: $e'),
            backgroundColor: Colors.red));
      }
    }
  }

  Widget _buildCommentsSection(ThemeData theme) {
    return Consumer<CommentProvider>(
      builder: (context, provider, _) {
        final comments = provider.getComments(widget.monument.id);
        final count = provider.getCommentsCount(widget.monument.id);

        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
            Row(children: [
              Text('comments'.tr(context),
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$count',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary)),
              ),
            ]),
            if (provider.isLoading)
              const SizedBox(
                  width: 18,
                  height: 18,
                  child:
                      CircularProgressIndicator(strokeWidth: 2)),
          ]),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _showAddCommentSheet(provider, theme),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: theme.dividerTheme.color!),
              ),
              child: Row(children: [
                Icon(Icons.chat_bubble_outline,
                    size: 20,
                    color: theme.textTheme.bodySmall?.color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('share_experience'.tr(context),
                      style: TextStyle(
                          fontSize: 14,
                          color: theme.textTheme.bodySmall?.color)),
                ),
                Icon(Icons.send,
                    size: 20, color: AppColors.primary),
              ]),
            ),
          ),
          const SizedBox(height: 24),
          if (provider.isLoading && comments.isEmpty)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator()))
          else if (comments.isEmpty)
            _buildEmptyState(theme)
          else
            ...comments
                .map((c) => _buildCommentCard(c, provider, theme))
                .toList(),
        ]);
      },
    );
  }

  Widget _buildCommentCard(Map<String, dynamic> comment,
      CommentProvider provider, ThemeData theme) {
    final int apiId = comment['id'] as int;
    final String username =
        comment['username'] ?? 'user'.tr(context);
    final String? avatarUrl = comment['user_avatar'];
    final String texte = comment['texte'] ?? '';
    final int? note = comment['note'] as int?;
    final bool ismine = provider.isMyComment(comment);

    String timeAgo = '';
    final rawDate = comment['created_at'];
    if (rawDate != null) {
      final d = DateTime.tryParse(rawDate);
      if (d != null) {
        final diff = DateTime.now().difference(d);
        if (diff.inSeconds < 60) {
          timeAgo = 'just_now'.tr(context);
        } else if (diff.inMinutes < 60) {
          timeAgo = 'minutes_ago'
              .tr(context)
              .replaceAll('{n}', '${diff.inMinutes}');
        } else if (diff.inHours < 24) {
          timeAgo = 'hours_ago'
              .tr(context)
              .replaceAll('{n}', '${diff.inHours}');
        } else {
          timeAgo = 'days_ago'
              .tr(context)
              .replaceAll('{n}', '${diff.inDays}');
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: ismine
            ? Border.all(
                color: AppColors.primary.withOpacity(0.35))
            : Border.all(color: theme.dividerTheme.color!),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Row(children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withOpacity(0.15),
            backgroundImage: avatarUrl != null
                ? NetworkImage(avatarUrl)
                : null,
            child: avatarUrl == null
                ? Text(
                    username.isNotEmpty
                        ? username[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 16),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Row(children: [
                Text(username,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface)),
                if (ismine) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'me_badge'.tr(context),
                      style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ]),
              Text(timeAgo,
                  style: TextStyle(
                      fontSize: 11,
                      color: theme.textTheme.bodySmall?.color)),
            ]),
          ),
          if (note != null)
            Row(
              children: List.generate(
                  5,
                  (i) => Icon(
                        i < note ? Icons.star : Icons.star_border,
                        size: 14,
                        color: const Color(0xFFFFC107),
                      )),
            ),
          if (ismine)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert,
                  size: 18,
                  color: theme.textTheme.bodySmall?.color),
              color: theme.colorScheme.surface,
              onSelected: (val) {
                if (val == 'delete') {
                  _confirmDelete(apiId, provider, theme);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    const Icon(Icons.delete_outline,
                        color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Text('delete_comment'.tr(context),
                        style:
                            const TextStyle(color: Colors.red)),
                  ]),
                ),
              ],
            ),
        ]),
        const SizedBox(height: 10),
        Text(texte,
            style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface,
                height: 1.5)),
      ]),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [
        Icon(Icons.chat_bubble_outline,
            size: 48,
            color: theme.textTheme.bodySmall?.color),
        const SizedBox(height: 12),
        Text(
          'no_comments'.tr(context),
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface),
        ),
        const SizedBox(height: 4),
        Text(
          'be_first_to_comment'.tr(context),
          style: TextStyle(
              fontSize: 14,
              color: theme.textTheme.bodyMedium?.color),
          textAlign: TextAlign.center,
        ),
      ]),
    );
  }

  void _showAddCommentSheet(
      CommentProvider provider, ThemeData theme) {
    _commentController.clear();
    _selectedNote = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24)),
          ),
          child:
              Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                  color: theme.dividerTheme.color,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Text('add_comment'.tr(context),
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final filled =
                    _selectedNote != null && i < _selectedNote!;
                return GestureDetector(
                  onTap: () =>
                      setModal(() => _selectedNote = i + 1),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      filled ? Icons.star : Icons.star_border,
                      size: 32,
                      color: const Color(0xFFFFC107),
                    ),
                  ),
                );
              }),
            ),
            if (_selectedNote != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(_ratingLabel(_selectedNote!),
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600)),
              ),
            const SizedBox(height: 14),
            TextField(
              controller: _commentController,
              maxLines: 4,
              maxLength: 500,
              autofocus: true,
              style: TextStyle(
                  color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'write_comment'.tr(context),
                hintStyle: TextStyle(
                    color: theme.textTheme.bodySmall?.color),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: theme.scaffoldBackgroundColor,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: Consumer<CommentProvider>(
                builder: (_, p, __) => ElevatedButton(
                  onPressed: p.isSubmitting
                      ? null
                      : () async {
                          if (_commentController.text
                              .trim()
                              .isEmpty) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(
                              content: Text(
                                  'please_write_comment'
                                      .tr(context)),
                              backgroundColor: Colors.orange,
                            ));
                            return;
                          }
                          final success = await p.addComment(
                            monumentId: widget.monument.id,
                            contenu: _commentController.text,
                            note: _selectedNote,
                          );
                          if (success && mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(
                              content: Text(
                                  'comment_added_success'
                                      .tr(context)),
                              backgroundColor: Colors.green,
                            ));
                          } else if (!success && mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(
                              content: Text(p.errorMessage ??
                                  'error_adding_comment'
                                      .tr(context)),
                              backgroundColor: Colors.red,
                            ));
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: p.isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white))
                      : Text('add_comment'.tr(context),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }

  String _ratingLabel(int note) {
    switch (note) {
      case 1: return 'rating_very_bad'.tr(context);
      case 2: return 'rating_bad'.tr(context);
      case 3: return 'rating_ok'.tr(context);
      case 4: return 'rating_good'.tr(context);
      case 5: return 'rating_excellent'.tr(context);
      default: return '';
    }
  }

  void _confirmDelete(
      int apiId, CommentProvider provider, ThemeData theme) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('delete_comment'.tr(context),
            style: TextStyle(color: theme.colorScheme.onSurface)),
        content: Text('confirm_delete_comment'.tr(context),
            style: TextStyle(
                color: theme.textTheme.bodyMedium?.color)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr(context))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final ok = await provider.deleteComment(
                monumentId: widget.monument.id,
                apiCommentId: apiId,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok
                      ? 'comment_deleted'.tr(context)
                      : 'error_deleting_comment'.tr(context)),
                  backgroundColor:
                      ok ? Colors.green : Colors.red,
                ));
              }
            },
            style: TextButton.styleFrom(
                foregroundColor: Colors.red),
            child: Text('delete_comment'.tr(context)),
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
            _navIcon(Icons.home_rounded, '/home'),
            _navIcon(Icons.account_balance_rounded, null),
            _navIcon(Icons.translate_rounded, '/translation'),
            _navIcon(Icons.chat_bubble_rounded, '/chatbot'),
            _navIcon(Icons.person_rounded, '/profile'),
          ],
        ),
      ),
    );
  }

  Widget _navIcon(IconData icon, String? route) {
    final isSelected = route == null;
    return GestureDetector(
      onTap: () {
        if (route != null) Navigator.pushNamed(context, route);
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

class _MapPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (double i = 0; i < size.height; i += 30) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
    for (double i = 0; i < size.width; i += 30) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    final road = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..strokeWidth = 3;
    canvas.drawLine(Offset(0, size.height * 0.3),
        Offset(size.width, size.height * 0.6), road);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}