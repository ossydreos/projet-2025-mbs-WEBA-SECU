import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import 'package:my_mobility_services/services/contact_launcher_service.dart';
import 'package:my_mobility_services/data/models/support_message.dart';
import 'package:my_mobility_services/data/models/ride_chat_thread.dart';
import 'package:my_mobility_services/data/services/ride_chat_service.dart';

class RideChatScreen extends StatefulWidget {
  final String reservationId;
  final bool isAdmin;
  final String? userIdForAdmin; // si admin, nécessaire pour ouvrir/creer thread
  final String? clientName; // affichage côté admin

  const RideChatScreen({
    super.key,
    required this.reservationId,
    this.isAdmin = false,
    this.userIdForAdmin,
    this.clientName,
  });

  @override
  State<RideChatScreen> createState() => _RideChatScreenState();
}

class _RideChatScreenState extends State<RideChatScreen> {
  final RideChatService _service = RideChatService();
  final TextEditingController _controller = TextEditingController();
  RideChatThread? _thread;

  @override
  void initState() {
    super.initState();
    _initThread();
  }

  Future<void> _initThread() async {
    try {
      if (widget.isAdmin) {
        final t = await _service.openOrCreateThread(
          reservationId: widget.reservationId,
          userId: widget.userIdForAdmin,
        );
        setState(() => _thread = t);
        await _service.markAsReadForAdmin(t.id);
        await _service.markMessagesAsReadForAdmin(t.id);
      } else {
        final t = await _service.openOrCreateThread(
          reservationId: widget.reservationId,
        );
        setState(() => _thread = t);
        await _service.markAsReadForUser(t.id);
        await _service.markMessagesAsReadForUser(t.id);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.hot),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isAdmin
        ? (widget.clientName ?? 'Chat course')
        : 'Chat course';

    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(
          title: title,
          actions: [
            IconButton(
              tooltip: 'Appeler',
              icon: const Icon(Icons.phone, color: Colors.white),
              onPressed: _makePhoneCall,
            ),
          ],
        ),
        body: _thread == null
            ? const Center(child: CircularProgressIndicator())
            : StreamBuilder<RideChatThread?>(
                stream: _service.watchThreadById(_thread!.id),
                builder: (context, threadSnapshot) {
                  final currentThread = threadSnapshot.data ?? _thread;
                  if (currentThread == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    if (widget.isAdmin) {
                      await _service.markAsReadForAdmin(currentThread.id);
                      await _service.markMessagesAsReadForAdmin(currentThread.id);
                    } else {
                      await _service.markAsReadForUser(currentThread.id);
                      await _service.markMessagesAsReadForUser(currentThread.id);
                    }
                  });

                  return Column(
                    children: [
                      Expanded(
                        child: StreamBuilder<List<SupportMessage>>(
                          stream: _service.watchMessages(currentThread.id),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.error, color: Colors.red, size: 48),
                                    const SizedBox(height: 16),
                                    Text('Erreur: ${snapshot.error}'),
                                  ],
                                ),
                              );
                            }
                            if (!snapshot.hasData) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            final messages = snapshot.data!;
                            if (messages.isEmpty) {
                              return const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
                                    SizedBox(height: 16),
                                    Text('Aucun message pour le moment'),
                                    Text('Écrivez votre premier message ci-dessous'),
                                  ],
                                ),
                              );
                            }

                            return ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final m = messages[index];
                                final isMine = widget.isAdmin
                                    ? m.senderRole == SupportSenderRole.admin
                                    : m.senderId == FirebaseAuth.instance.currentUser?.uid;
                                return Align(
                                  alignment:
                                      isMine ? Alignment.centerRight : Alignment.centerLeft,
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    constraints: const BoxConstraints(maxWidth: 320),
                                    decoration: BoxDecoration(
                                      color: isMine
                                          ? AppColors.accent.withOpacity(0.9)
                                          : AppColors.glass,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: AppColors.glassStroke),
                                      boxShadow: Fx.glow,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          m.text,
                                          style: TextStyle(
                                            color: isMine ? Colors.white : AppColors.textStrong,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              _formatTime(m.createdAt),
                                              style: TextStyle(
                                                color: isMine ? Colors.white70 : Colors.white54,
                                                fontSize: 10,
                                              ),
                                            ),
                                            if (isMine) ...[
                                              const SizedBox(width: 6),
                                              Icon(
                                                (widget.isAdmin && m.readByUser) || (!widget.isAdmin && m.readByAdmin)
                                                    ? Icons.done_all
                                                    : Icons.check,
                                                size: 14,
                                                color: (widget.isAdmin && m.readByUser) || (!widget.isAdmin && m.readByAdmin)
                                                    ? Colors.lightBlueAccent
                                                    : Colors.white70,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      if (!currentThread.isClosed) _buildInputBar(),
                    ],
                  );
                },
              ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: TextStyle(color: AppColors.textStrong),
                  decoration: const InputDecoration(
                    hintText: 'Écrire un message...'
                  ),
                  minLines: 1,
                  maxLines: 4,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _send,
                icon: const Icon(Icons.send),
                color: AppColors.accent,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _thread == null) return;
    if (_thread!.isClosed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cette conversation est terminée.')),
      );
      return;
    }
    _controller.clear();
    await _service.sendMessage(
      threadId: _thread!.id,
      text: text,
      senderRole: widget.isAdmin ? SupportSenderRole.admin : SupportSenderRole.user,
    );
  }

  Future<void> _makePhoneCall() async {
    try {
      final contactService = ContactLauncherService(context);
      await contactService.launchPhoneCall();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'appel: $e'), backgroundColor: AppColors.hot),
      );
    }
  }
}


