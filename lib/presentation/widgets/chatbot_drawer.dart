// ══════════════════════════════════════════════════════
// lib/presentation/widgets/chatbot_drawer.dart
// VERSION DARK MODE
// ══════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/string_extensions.dart';
import '../providers/conversation_provider.dart';
import '../../data/models/conversation_model.dart';

class ChatBotDrawer extends StatefulWidget {
  const ChatBotDrawer({super.key});

  @override
  State<ChatBotDrawer> createState() => _ChatBotDrawerState();
}

class _ChatBotDrawerState extends State<ChatBotDrawer> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    return Drawer(
      backgroundColor: colorScheme.surface,
      width: 260,
      elevation: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),

              _buildSearchBar(),
              const SizedBox(height: 20),

              Text(
                'your_chats'.tr(context).toUpperCase(),
                style: TextStyle(
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),

              Expanded(child: _buildConversationsList()),

              Divider(height: 1, thickness: 1, color: theme.dividerColor),
              const SizedBox(height: 12),

              _buildBottomItem(
                icon: Icons.edit_outlined,
                label: 'new_chat'.tr(context),
                onTap: () async {
                  await context
                      .read<ConversationProvider>()
                      .createNewConversation();
                  if (mounted) Navigator.pop(context);
                },
              ),

              _buildBottomItem(
                icon: Icons.close,
                label: 'close'.tr(context),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.auto_awesome, color: Colors.white, size: 22),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ai_tourist_guide'.tr(context),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'chat_bot'.tr(context),
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, size: 22),
          onPressed: () => Navigator.pop(context),
          color: colorScheme.onSurface,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
            color: theme.colorScheme.onSurface, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'search'.tr(context),
          hintStyle: TextStyle(
              color: isDark ? Colors.grey[500] : Colors.grey[400],
              fontSize: 14),
          prefixIcon: Icon(Icons.search,
              color: isDark ? Colors.grey[500] : Colors.grey[400],
              size: 18),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close,
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                      size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    _searchController.clear();
                    context.read<ConversationProvider>().clearSearch();
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        onChanged: (query) {
          context.read<ConversationProvider>().setSearchQuery(query);
          setState(() {});
        },
      ),
    );
  }

  Widget _buildConversationsList() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Consumer<ConversationProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return Center(
            child: CircularProgressIndicator(
                color: AppColors.primary, strokeWidth: 2),
          );
        }

        if (provider.conversations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline,
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                    size: 44),
                const SizedBox(height: 12),
                Text(
                  _searchController.text.isEmpty
                      ? 'no_conversations'.tr(context)
                      : 'no_results'.tr(context),
                  style: TextStyle(
                      color: isDark ? Colors.grey[600] : Colors.grey[400],
                      fontSize: 13),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: provider.conversations.length,
          itemBuilder: (context, index) {
            final conv = provider.conversations[index];
            return _buildConversationItem(conv, provider);
          },
        );
      },
    );
  }

  Widget _buildConversationItem(
    Conversation conversation,
    ConversationProvider provider,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = provider.currentConversation?.id == conversation.id;

    return InkWell(
      onTap: () async {
        await provider.selectConversation(conversation.id);
        if (mounted) Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: isSelected
            ? BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Row(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                color: isSelected ? AppColors.primary : AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conversation.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isSelected
                            ? AppColors.primary
                            : colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(conversation.updatedAt),
                      style: TextStyle(
                          color: isDark ? Colors.grey[500] : Colors.grey[400],
                          fontSize: 11),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert,
                    color: isDark ? Colors.grey[500] : Colors.grey[400],
                    size: 18),
                color: colorScheme.surface,
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                onSelected: (value) {
                  if (value == 'rename') _showRenameDialog(conversation);
                  if (value == 'delete') _showDeleteDialog(conversation);
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'rename',
                    child: Row(children: [
                      Icon(Icons.edit_outlined,
                          size: 16,
                          color: isDark ? Colors.grey[400] : Colors.grey[700]),
                      const SizedBox(width: 10),
                      Text('rename'.tr(context),
                          style: TextStyle(
                              color: colorScheme.onSurface, fontSize: 13)),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      const Icon(Icons.delete_outline,
                          size: 16, color: Colors.red),
                      const SizedBox(width: 10),
                      Text('delete'.tr(context),
                          style: const TextStyle(
                              color: Colors.red, fontSize: 13)),
                    ]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        child: Row(
          children: [
            Icon(icon,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                size: 20),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(Conversation conversation) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    final controller = TextEditingController(text: conversation.title);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('rename_conversation'.tr(context),
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: 'new_title'.tr(context),
            hintStyle: TextStyle(
                color: isDark ? Colors.grey[500] : Colors.grey[400]),
            filled: true,
            fillColor: isDark ? Colors.grey[800] : const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr(context),
                style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await context
                    .read<ConversationProvider>()
                    .renameConversation(
                        conversation.id, controller.text.trim());
                if (mounted) Navigator.pop(context);
              }
            },
            child: Text('rename'.tr(context),
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(Conversation conversation) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('delete_conversation'.tr(context),
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface)),
        content: Text('this_action_is_irreversible'.tr(context),
            style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr(context),
                style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () async {
              await context
                  .read<ConversationProvider>()
                  .deleteConversation(conversation.id);
              if (mounted) Navigator.pop(context);
            },
            child: Text('delete'.tr(context),
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'today'.tr(context);
    if (diff.inDays == 1) return 'yesterday'.tr(context);
    if (diff.inDays < 7) return '${diff.inDays} ${'days_ago'.tr(context)}';
    return '${date.day}/${date.month}/${date.year}';
  }
}