import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';

enum UserRole { user, admin }

class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? phoneNumber;
  final UserRole role;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.phoneNumber,
    required this.role,
    required this.createdAt,
    this.updatedAt,
    required this.isActive,
  }) {
    _validate();
  }

  // Validation des données
  void _validate() {
    if (uid.isEmpty) {
      throw ArgumentError('UID ne peut pas être vide');
    }
    if (email.isEmpty || !_isValidEmail(email)) {
      throw ArgumentError('Email invalide: $email');
    }
    if (phoneNumber != null && phoneNumber!.isNotEmpty && !_isValidPhoneNumber(phoneNumber!)) {
      throw ArgumentError('Numéro de téléphone invalide: $phoneNumber');
    }
  }

  // Validation email
  static bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  // Validation numéro de téléphone
  static bool _isValidPhoneNumber(String phone) {
    return RegExp(r'^\+?[1-9]\d{1,14}$').hasMatch(phone);
  }

  // Convertir en Map pour Firebase
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'role': role.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isActive': isActive,
    };
  }

  // Créer depuis un document Firebase
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'],
      phoneNumber: map['phoneNumber'],
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.user,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      isActive: map['isActive'] ?? true,
    );
  }

  // Copier avec modifications
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? phoneNumber,
    UserRole? role,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  // Vérifier si l'utilisateur est admin
  bool get isAdmin => role == UserRole.admin;

  // Obtenir le rôle localisé
  String getLocalizedRole(context) {
    final localizations = AppLocalizations.of(context);
    switch (role) {
      case UserRole.user:
        return localizations.userRoleUser;
      case UserRole.admin:
        return localizations.userRoleAdmin;
    }
  }
  
  // Version legacy pour compatibilité
  String get roleInFrench {
    switch (role) {
      case UserRole.user:
        return 'Utilisateur';
      case UserRole.admin:
        return 'Administrateur';
    }
  }
}
