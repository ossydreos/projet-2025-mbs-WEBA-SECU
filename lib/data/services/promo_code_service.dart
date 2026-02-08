import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/promo_code.dart';

class PromoCodeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'promo_codes';

  // Créer un nouveau code promo
  Future<String> createPromoCode(PromoCode promoCode) async {
    try {
      final docRef = await _firestore
          .collection(_collection)
          .add(promoCode.toMap());
      return docRef.id;
    } catch (e, stackTrace) {
      // Log serveur pour debug
      developer.log(
        'Error creating promo code',
        name: 'PromoCodeService',
        error: e,
        stackTrace: stackTrace,
      );
      // Message générique
      throw Exception('Impossible de créer le code promo');
    }
  }

  // Récupérer tous les codes promo
  Future<List<PromoCode>> getAllPromoCodes() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => PromoCode.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e, stackTrace) {
      // Log serveur
      developer.log(
        'Error fetching all promo codes',
        name: 'PromoCodeService',
        error: e,
        stackTrace: stackTrace,
      );
      // Message générique
      throw Exception('Impossible de récupérer les codes promo');
    }
  }

  // Récupérer un code promo par son code
  Future<PromoCode?> getPromoCodeByCode(String code) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('code', isEqualTo: code.toUpperCase())
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      return PromoCode.fromMap({...doc.data(), 'id': doc.id});
    } catch (e, stackTrace) {
      // Log serveur
      developer.log(
        'Error fetching promo code by code',
        name: 'PromoCodeService',
        error: e,
        stackTrace: stackTrace,
      );
      // Retourne null au lieu d'exposer l'erreur
      return null;
    }
  }

  // Valider un code promo
  Future<PromoCodeValidationResult> validatePromoCode(
    String code,
    double totalPrice,
  ) async {
    try {
      final promoCode = await getPromoCodeByCode(code);

      // CWE-209 CORRIGÉ : Message unifié pour tous les cas d'invalidité
      // Empêche l'énumération des codes promo existants
      
      if (promoCode == null) {
        // Log serveur pour debug
        developer.log(
          'Promo code not found: $code',
          name: 'PromoCodeService',
        );
        return PromoCodeValidationResult(
          isValid: false,
          message: 'Code promo invalide',
        );
      }

      // Vérifier si le code a expiré
      if (promoCode.expiresAt != null &&
          DateTime.now().isAfter(promoCode.expiresAt!)) {
        // Log serveur
        developer.log(
          'Promo code expired: $code',
          name: 'PromoCodeService',
        );
        return PromoCodeValidationResult(
          isValid: false,
          message: 'Code promo invalide',
        );
      }

      // Vérifier si le code a atteint sa limite d'utilisation
      if (promoCode.maxUsers != null &&
          promoCode.usedCount >= promoCode.maxUsers!) {
        // Log serveur
        developer.log(
          'Promo code usage limit reached: $code',
          name: 'PromoCodeService',
        );
        return PromoCodeValidationResult(
          isValid: false,
          message: 'Code promo invalide',
        );
      }

      // Calculer la remise
      double discountAmount = 0.0;
      if (promoCode.type == DiscountType.percent) {
        discountAmount = (totalPrice * promoCode.value) / 100;
      } else {
        discountAmount = promoCode.value;
      }

      // S'assurer que la remise ne dépasse pas le prix total
      if (discountAmount > totalPrice) {
        discountAmount = totalPrice;
      }

      return PromoCodeValidationResult(
        isValid: true,
        promoCode: promoCode,
        discountAmount: discountAmount,
        message: 'Code promo valide',
      );
    } catch (e, stackTrace) {
      // Log complet côté serveur
      developer.log(
        'Error validating promo code',
        name: 'PromoCodeService',
        error: e,
        stackTrace: stackTrace,
      );
      // Message générique pour l'utilisateur
      return PromoCodeValidationResult(
        isValid: false,
        message: 'Code promo invalide',
      );
    }
  }

  // Appliquer un code promo (incrémenter le compteur d'utilisation)
  Future<void> applyPromoCode(String promoCodeId) async {
    try {
      await _firestore.collection(_collection).doc(promoCodeId).update({
        'usedCount': FieldValue.increment(1),
        'updatedAt': Timestamp.now(),
      });
    } catch (e, stackTrace) {
      // Log serveur
      developer.log(
        'Error applying promo code',
        name: 'PromoCodeService',
        error: e,
        stackTrace: stackTrace,
      );
      // Message générique
      throw Exception('Impossible d\'appliquer le code promo');
    }
  }

  // Mettre à jour un code promo
  Future<void> updatePromoCode(PromoCode promoCode) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(promoCode.id)
          .update(promoCode.copyWith(updatedAt: DateTime.now()).toMap());
    } catch (e, stackTrace) {
      // Log serveur
      developer.log(
        'Error updating promo code',
        name: 'PromoCodeService',
        error: e,
        stackTrace: stackTrace,
      );
      // Message générique
      throw Exception('Impossible de mettre à jour le code promo');
    }
  }

  // Supprimer un code promo
  Future<void> deletePromoCode(String promoCodeId) async {
    try {
      await _firestore.collection(_collection).doc(promoCodeId).delete();
    } catch (e, stackTrace) {
      // Log serveur
      developer.log(
        'Error deleting promo code',
        name: 'PromoCodeService',
        error: e,
        stackTrace: stackTrace,
      );
      // Message générique
      throw Exception('Impossible de supprimer le code promo');
    }
  }

  // Activer/Désactiver un code promo
  Future<void> togglePromoCodeStatus(String promoCodeId, bool isActive) async {
    try {
      await _firestore.collection(_collection).doc(promoCodeId).update({
        'isActive': isActive,
        'updatedAt': Timestamp.now(),
      });
    } catch (e, stackTrace) {
      // Log serveur
      developer.log(
        'Error toggling promo code status',
        name: 'PromoCodeService',
        error: e,
        stackTrace: stackTrace,
      );
      // Message générique
      throw Exception('Impossible de modifier le statut du code promo');
    }
  }

  // Stream des codes promo pour l'admin
  Stream<List<PromoCode>> getPromoCodesStream() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PromoCode.fromMap({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }
}

class PromoCodeValidationResult {
  final bool isValid;
  final PromoCode? promoCode;
  final double discountAmount;
  final String message;

  PromoCodeValidationResult({
    required this.isValid,
    this.promoCode,
    this.discountAmount = 0.0,
    required this.message,
  });
}
