import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_mobility_services/data/models/support_message.dart';
import 'package:my_mobility_services/data/models/support_thread.dart';
import 'package:my_mobility_services/data/services/support_chat_service.dart';
import 'package:my_mobility_services/l10n/generated/app_localizations.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';

class SupportChatScreen extends StatefulWidget {
  final bool isAdmin;
  final String? userIdForAdmin; // legacy
  final String? threadId; // ouvre un thread spécifique
  final String? clientName; // nom du client pour l'affichage côté admin

  const SupportChatScreen({
    super.key, 
    this.isAdmin = false, 
    this.userIdForAdmin, 
    this.threadId,
    this.clientName,
  });

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final SupportChatService _service = SupportChatService();
  final TextEditingController _controller = TextEditingController();
  SupportThread? _thread;
  String? _targetUserName; // Nom du client pour l'affichage côté admin

  @override
  void initState() {
    super.initState();
    _initThread();
  }

  Future<void> _initThread() async {
    print('_initThread démarré - isAdmin: ${widget.isAdmin}, userIdForAdmin: ${widget.userIdForAdmin}');
    try {
      if (widget.threadId != null) {
        final d = await FirebaseFirestore.instance
            .collection(SupportChatService.threadsCollection)
            .doc(widget.threadId)
            .get();
        if (d.exists) {
          final t = SupportThread.fromMap(d.data()!, d.id);
          setState(() => _thread = t);
          if (widget.isAdmin) {
            // Utiliser le nom du client fourni ou charger depuis Firestore
            if (widget.clientName != null) {
              setState(() => _targetUserName = widget.clientName);
            } else {
              await _loadUserNameForAdmin(t.userId);
            }
          }
          if (widget.isAdmin) {
            await _service.markAsReadForAdmin(t.id);
            await _service.markMessagesAsReadForAdmin(t.id);
          } else {
            await _service.markAsReadForUser(t.id);
            await _service.markMessagesAsReadForUser(t.id);
          }
        }
      } else if (widget.isAdmin) {
        if (widget.userIdForAdmin != null) {
          // L'admin ouvre un thread sur un user précis
          print('Admin cherche thread pour user: ${widget.userIdForAdmin}');
          final q = await FirebaseFirestore.instance
              .collection(SupportChatService.threadsCollection)
              .where('userId', isEqualTo: widget.userIdForAdmin)
              .limit(1)
              .get();
          if (q.docs.isNotEmpty) {
            final d = q.docs.first;
            print('Thread trouvé: ${d.id}');
            final t = SupportThread.fromMap(d.data(), d.id);
            setState(() => _thread = t);
            await _loadUserNameForAdmin(t.userId);
            await _service.markAsReadForAdmin(t.id);
            await _service.markMessagesAsReadForAdmin(t.id);
          } else {
            print('Aucun thread trouvé pour cet user');
          }
        } else {
          // Admin sans user spécifique - prendre le premier thread disponible
          print('Admin cherche le premier thread disponible');
          final q = await FirebaseFirestore.instance
              .collection(SupportChatService.threadsCollection)
              .limit(1)
              .get();
          if (q.docs.isNotEmpty) {
            final d = q.docs.first;
            print('Premier thread trouvé: ${d.id}');
            final t = SupportThread.fromMap(d.data(), d.id);
            setState(() => _thread = t);
            await _loadUserNameForAdmin(t.userId);
            await _service.markAsReadForAdmin(t.id);
            await _service.markMessagesAsReadForAdmin(t.id);
          } else {
            // Aucun thread existant - créer un thread de démonstration
            print('Aucun thread existant, création d\'un thread demo');
            final ref = FirebaseFirestore.instance.collection(SupportChatService.threadsCollection).doc();
            final now = DateTime.now();
            final thread = SupportThread(
              id: ref.id,
              userId: 'admin_demo',
              createdAt: now,
              updatedAt: now,
              unreadForUser: 0,
              unreadForAdmin: 0,
              isClosed: false,
            );
            await ref.set(thread.toMap());
            print('Thread demo créé: ${ref.id}');
            setState(() => _thread = thread);
          }
        }
      } else {
        // Client
        print('Client - création/récupération du thread');
        final t = await _service.openOrCreateThreadForCurrentUser();
        print('Thread client: ${t.id}');
        setState(() => _thread = t);
        await _service.markAsReadForUser(t.id);
        await _service.markMessagesAsReadForUser(t.id);
      }
    } catch (e) {
      print('Erreur initThread: $e');
      // En cas d'erreur, créer un thread de secours
      final ref = FirebaseFirestore.instance.collection(SupportChatService.threadsCollection).doc();
      final now = DateTime.now();
      final thread = SupportThread(
        id: ref.id,
        userId: widget.isAdmin ? 'admin_demo' : (FirebaseAuth.instance.currentUser?.uid ?? 'unknown'),
        createdAt: now,
        updatedAt: now,
        unreadForUser: 0,
        unreadForAdmin: 0,
        isClosed: false,
      );
      await ref.set(thread.toMap());
      print('Thread de secours créé: ${ref.id}');
      setState(() => _thread = thread);
    }
  }

  Future<void> _loadUserNameForAdmin(String userId) async {
    try {
      final snap = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (snap.exists) {
        final data = snap.data() as Map<String, dynamic>;
        final nameField = (data['name'] ?? '').toString();
        final display = (data['displayName'] ?? '').toString();
        final first = (data['firstName'] ?? '').toString();
        final last = (data['lastName'] ?? '').toString();
        final merged = (nameField.isNotEmpty ? nameField : (display.isNotEmpty ? display : '$first $last')).trim();
        if (merged.isNotEmpty) {
          setState(() => _targetUserName = merged);
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isAdmin && _thread != null ? (_targetUserName ?? 'Support') : 'Support';
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(
          title: title,
          actions: [
            if (widget.isAdmin && _thread != null)
              StreamBuilder<SupportThread?>(
                stream: _service.watchThreadById(_thread!.id),
                builder: (context, snap) {
                  final closed = snap.data?.isClosed ?? _thread!.isClosed;
                  return TextButton.icon(
                    onPressed: () async {
                      final newClosed = !closed;
                      await _service.setThreadClosed(threadId: _thread!.id, isClosed: newClosed);
                      setState(() => _thread = _thread!.copyWith(isClosed: newClosed));
                    },
                    icon: Icon(closed ? Icons.lock_open : Icons.lock, color: Colors.white),
                    label: Text(closed ? 'Rouvrir' : 'Terminer', style: const TextStyle(color: Colors.white)),
                  );
                },
              ),
          ],
        ),
        body: _thread == null
            ? const Center(child: CircularProgressIndicator())
            : StreamBuilder<SupportThread?>(
                stream: _service.watchThreadById(_thread!.id),
                builder: (context, threadSnapshot) {
                  final currentThread = threadSnapshot.data ?? _thread;
                  if (currentThread == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  // Marquer les messages comme lus en temps réel quand on est dans la conversation
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
                        print('StreamBuilder - hasData: ${snapshot.hasData}, hasError: ${snapshot.hasError}');
                        if (snapshot.hasError) {
                          print('Erreur stream: ${snapshot.error}');
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error, color: Colors.red, size: 48),
                                const SizedBox(height: 16),
                                Text('Erreur: ${snapshot.error}'),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _thread = null;
                                    });
                                    _initThread();
                                  },
                                  child: Text(AppLocalizations.of(context).retry),
                                ),
                              ],
                            ),
                          );
                        }
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final messages = snapshot.data!;
                        print('Messages reçus: ${messages.length}');
                        
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
                  if (!(currentThread.isClosed)) _buildInputBar(),
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
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context).writeMessage
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
    // Empêcher l'envoi si le ticket est fermé
    if (_thread!.isClosed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).ticketFinished)),
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
}


