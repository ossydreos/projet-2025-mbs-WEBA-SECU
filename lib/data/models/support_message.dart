import 'package:cloud_firestore/cloud_firestore.dart';

enum SupportSenderRole { user, admin }

class SupportMessage {
  final String id;
  final String threadId;
  final String senderId;
  final SupportSenderRole senderRole;
  final String text;
  final DateTime createdAt;
  final bool readByUser;
  final bool readByAdmin;

  const SupportMessage({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.senderRole,
    required this.text,
    required this.createdAt,
    required this.readByUser,
    required this.readByAdmin,
  });

  Map<String, dynamic> toMap() {
    return {
      'threadId': threadId,
      'senderId': senderId,
      'senderRole': senderRole.name,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
      'readByUser': readByUser,
      'readByAdmin': readByAdmin,
    };
  }

  factory SupportMessage.fromMap(Map<String, dynamic> map, String id) {
    return SupportMessage(
      id: id,
      threadId: map['threadId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderRole: (map['senderRole'] as String?) == 'admin'
          ? SupportSenderRole.admin
          : SupportSenderRole.user,
      text: map['text'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readByUser: map['readByUser'] ?? false,
      readByAdmin: map['readByAdmin'] ?? false,
    );
  }
}


