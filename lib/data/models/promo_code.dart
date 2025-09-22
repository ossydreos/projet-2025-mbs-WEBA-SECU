import 'package:cloud_firestore/cloud_firestore.dart';

enum DiscountType { amount, percent }

class PromoCode {
  final String id;
  final String name;
  final String code;
  final DiscountType type;
  final double value; // amount in currency or percent (0-100)
  final DateTime? expiresAt;
  final int? maxUsers;
  final int usedCount;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  PromoCode({
    required this.id,
    required this.name,
    required this.code,
    required this.type,
    required this.value,
    required this.expiresAt,
    required this.maxUsers,
    this.usedCount = 0,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  }) {
    _validate();
  }

  void _validate() {
    if (name.trim().isEmpty) {
      throw ArgumentError('Le nom ne peut pas être vide');
    }
    if (code.trim().isEmpty) {
      throw ArgumentError('Le code ne peut pas être vide');
    }
    if (type == DiscountType.percent) {
      if (value <= 0 || value > 100) {
        throw ArgumentError('Le pourcentage doit être entre 0 et 100');
      }
    } else {
      if (value <= 0) {
        throw ArgumentError('Le montant doit être > 0');
      }
    }
    if (maxUsers != null && maxUsers! < 1) {
      throw ArgumentError('maxUsers doit être >= 1');
    }
    if (usedCount < 0) {
      throw ArgumentError('usedCount invalide');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code.toUpperCase(),
      'type': type.name,
      'value': value,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'maxUsers': maxUsers,
      'usedCount': usedCount,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory PromoCode.fromMap(Map<String, dynamic> map) {
    return PromoCode(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      code: (map['code'] ?? '').toString(),
      type: DiscountType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => DiscountType.amount,
      ),
      value: (map['value'] ?? 0.0).toDouble(),
      expiresAt: map['expiresAt'] != null
          ? (map['expiresAt'] as Timestamp).toDate()
          : null,
      maxUsers: map['maxUsers'],
      usedCount: map['usedCount'] ?? 0,
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  PromoCode copyWith({
    String? id,
    String? name,
    String? code,
    DiscountType? type,
    double? value,
    DateTime? expiresAt,
    int? maxUsers,
    int? usedCount,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PromoCode(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      type: type ?? this.type,
      value: value ?? this.value,
      expiresAt: expiresAt ?? this.expiresAt,
      maxUsers: maxUsers ?? this.maxUsers,
      usedCount: usedCount ?? this.usedCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
