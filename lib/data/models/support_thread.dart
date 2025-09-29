import 'package:cloud_firestore/cloud_firestore.dart';

/// Un fil de discussion de support entre un utilisateur et les admins
class SupportThread {
  final String id;
  final String userId; // propriétaire côté client
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadForUser; // nombre de messages non lus côté client
  final int unreadForAdmin; // nombre de messages non lus côté admin
  final bool isClosed;

  const SupportThread({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadForUser = 0,
    this.unreadForAdmin = 0,
    this.isClosed = false,
  });

  SupportThread copyWith({
    String? id,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? lastMessage,
    DateTime? lastMessageAt,
    int? unreadForUser,
    int? unreadForAdmin,
    bool? isClosed,
  }) {
    return SupportThread(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadForUser: unreadForUser ?? this.unreadForUser,
      unreadForAdmin: unreadForAdmin ?? this.unreadForAdmin,
      isClosed: isClosed ?? this.isClosed,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
      'unreadForUser': unreadForUser,
      'unreadForAdmin': unreadForAdmin,
      'isClosed': isClosed,
    };
  }

  factory SupportThread.fromMap(Map<String, dynamic> map, String id) {
    return SupportThread(
      id: id,
      userId: map['userId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessage: map['lastMessage'],
      lastMessageAt: (map['lastMessageAt'] as Timestamp?)?.toDate(),
      unreadForUser: map['unreadForUser'] ?? 0,
      unreadForAdmin: map['unreadForAdmin'] ?? 0,
      isClosed: map['isClosed'] ?? false,
    );
  }
}


