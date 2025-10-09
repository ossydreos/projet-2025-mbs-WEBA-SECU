import 'package:cloud_firestore/cloud_firestore.dart';

/// Thread de chat lié à une réservation spécifique (conversation client <-> admin)
class RideChatThread {
  final String id;
  final String reservationId;
  final String userId; // propriétaire côté client
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadForUser; // nombre de messages non lus côté client
  final int unreadForAdmin; // nombre de messages non lus côté admin
  final bool isClosed;

  const RideChatThread({
    required this.id,
    required this.reservationId,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadForUser = 0,
    this.unreadForAdmin = 0,
    this.isClosed = false,
  });

  RideChatThread copyWith({
    String? id,
    String? reservationId,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? lastMessage,
    DateTime? lastMessageAt,
    int? unreadForUser,
    int? unreadForAdmin,
    bool? isClosed,
  }) {
    return RideChatThread(
      id: id ?? this.id,
      reservationId: reservationId ?? this.reservationId,
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
      'reservationId': reservationId,
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

  factory RideChatThread.fromMap(Map<String, dynamic> map, String id) {
    return RideChatThread(
      id: id,
      reservationId: map['reservationId'] ?? '',
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


