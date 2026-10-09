import 'package:flutter/material.dart';
import '../../core/settings/settings_service.dart';
import '../chat/chat_service.dart';
import '../chat/models.dart';
import '../memory/memory_dialog.dart';
import '../memory/memory_service.dart';
import '../settings/settings_dialog.dart';

class HistorySidebar extends StatelessWidget {
  final ChatService chatService;
  final SettingsService settingsService;
  final MemoryService memoryService;

  const HistorySidebar({
    super.key,
    required this.chatService,
    required this.settingsService,
    required this.memoryService,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: const Color(0xFF171717),
      child: Column(
        children: [
          // Header / New Chat Button
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => chatService.startNewConversation(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                  color: const Color(0xFF212121),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.edit_note, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'New chat',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Spacer(),
                    Icon(Icons.add, color: Colors.white54, size: 18),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Conversation List
          Expanded(
            child: ListenableBuilder(
              listenable: chatService,
              builder: (context, _) {
                final conversations = chatService.conversations;
                final current = chatService.currentConversation;

                if (conversations.isEmpty) {
                  return const Center(
                    child: Text(
                      'No chats yet',
                      style: TextStyle(color: Colors.white30, fontSize: 13),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: conversations.length,
                  itemBuilder: (context, index) {
                    final conv = conversations[index];
                    final isSelected = current?.id == conv.id;

                    return _ConversationTile(
                      conversation: conv,
                      isSelected: isSelected,
                      onTap: () => chatService.selectConversation(conv.id),
                      onDelete: () => chatService.deleteConversation(conv.id),
                    );
                  },
                );
              },
            ),
          ),

          const Divider(color: Colors.white12, height: 1),

          // Footer: Memories & Settings
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Column(
              children: [
                ListenableBuilder(
                  listenable: memoryService,
                  builder: (context, _) {
                    final count = memoryService.memories.length;
                    return _SidebarFooterButton(
                      icon: Icons.psychology,
                      title: 'Memory ($count)',
                      badge: count > 0 ? '$count facts' : null,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => MemoryDialog(memoryService: memoryService),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 4),
                ListenableBuilder(
                  listenable: settingsService,
                  builder: (context, _) {
                    final configured = settingsService.hasValidApiKey;
                    return _SidebarFooterButton(
                      icon: Icons.settings,
                      title: 'Settings',
                      badge: configured ? null : 'Key needed',
                      badgeColor: configured ? null : Colors.amber.shade800,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => SettingsDialog(settingsService: settingsService),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatefulWidget {
  final Conversation conversation;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ConversationTile({
    required this.conversation,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_ConversationTile> createState() => _ConversationTileState();
}

class _ConversationTileState extends State<_ConversationTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? const Color(0xFF212121)
              : _isHovered
                  ? const Color(0xFF1E1E1E)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          title: Text(
            widget.conversation.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: widget.isSelected ? Colors.white : Colors.white70,
              fontSize: 13,
              fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          trailing: (_isHovered || widget.isSelected)
              ? IconButton(
                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.white38),
                  hoverColor: Colors.red.withValues(alpha: 0.15),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: widget.onDelete,
                )
              : null,
          onTap: widget.onTap,
        ),
      ),
    );
  }
}

class _SidebarFooterButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? badge;
  final Color? badgeColor;
  final VoidCallback onTap;

  const _SidebarFooterButton({
    required this.icon,
    required this.title,
    this.badge,
    this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.white70),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const Spacer(),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor ?? const Color(0xFF10A37F).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
