import 'package:flutter/material.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import 'package:my_mobility_services/data/services/support_chat_service.dart';
import 'package:my_mobility_services/data/models/support_thread.dart';
import 'package:my_mobility_services/screens/support/support_chat_screen.dart';

class SupportHomeScreen extends StatelessWidget {
  const SupportHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const GlassAppBar(
          title: 'Support',
        ),
        body: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(text: 'Accueil'),
                  Tab(text: 'Messages'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildWelcomeHeader(),
                          const SizedBox(height: 24),
                          _buildRecentMessage(),
                          const SizedBox(height: 16),
                          _buildSendMessage(context),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                    const _SupportThreadsListScreen(embedded: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hello !',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Comment pouvons-nous vous aider ?',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentMessage() {
    return StreamBuilder<SupportThread?>(
      stream: SupportChatService().watchThreadForCurrentUser(),
      builder: (context, snapshot) {
        final thread = snapshot.data;
        final hasUnread = (thread?.unreadForUser ?? 0) > 0;
        
        // Ne pas marquer comme lu automatiquement - seulement quand on ouvre la conversation
        
        return GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Message récent',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              if (thread != null) ...[
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SupportChatScreen(threadId: thread.id),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.support_agent,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Conversation de support',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Support • ${_formatTime(thread.lastMessageAt ?? thread.createdAt)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (hasUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox.shrink(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSendMessage(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Envoyez-nous un message',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nous répondons généralement en quelques minutes',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () async {
              // Créer ou récupérer le thread
              final t = await SupportChatService().createNewThreadForCurrentUser();
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SupportChatScreen(threadId: t.id),
                  ),
                );
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Nouveau message',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // suppression de la section « Rechercher de l'aide »

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}min';
    } else {
      return 'Maintenant';
    }
  }
}

class _SupportBottomNav extends StatelessWidget {
  const _SupportBottomNav();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.25),
          border: const Border(top: BorderSide(color: AppColors.glassStroke)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _NavItem(
              icon: Icons.home_rounded,
              label: 'Accueil',
              onTap: () {},
            ),
            const SizedBox(width: 24),
            _NavItem(
              icon: Icons.messenger_outline,
              label: 'Messages',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const _SupportThreadsListScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _SupportThreadsListScreen extends StatelessWidget {
  final bool embedded; // si true, on cache l'appbar interne
  const _SupportThreadsListScreen({this.embedded = false});

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: embedded ? null : const GlassAppBar(title: 'Messages'),
        body: StreamBuilder<List<SupportThread>>(
          stream: SupportChatService().watchThreadsForCurrentUser(),
          builder: (context, snapshot) {
            final threads = snapshot.data ?? const <SupportThread>[];
            if (threads.isEmpty) {
              return const Center(child: Text('Aucun message', style: TextStyle(color: Colors.white70)));
            }
            return ListView.separated(
              itemCount: threads.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final t = threads[index];
                final hasUnread = t.unreadForUser > 0;
                
                // Ne pas marquer comme lu automatiquement - seulement quand on ouvre la conversation
                
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SupportChatScreen(threadId: t.id)),
                  ),
                  child: GlassContainer(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.accent,
                        radius: 22,
                        child: Icon(Icons.support_agent, color: Colors.white),
                      ),
                      title: const Text(
                        'Support',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'Mis à jour • ${_format(t.lastMessageAt ?? t.updatedAt)}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      trailing: hasUnread
                          ? const Icon(Icons.brightness_1, color: Colors.red, size: 10)
                          : null,
                    ),
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: embedded ? null : FloatingActionButton.extended(
          onPressed: () async {
            await SupportChatService().createNewThreadForCurrentUser();
          },
          backgroundColor: AppColors.accent,
          label: const Text('Nouveau message'),
          icon: const Icon(Icons.add),
        ),
      ),
    );
  }

  String _format(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}j';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}min';
    return 'Maintenant';
  }
}
