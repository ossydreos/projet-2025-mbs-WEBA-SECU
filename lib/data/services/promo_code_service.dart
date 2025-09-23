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
    } catch (e) {
      throw Exception('Erreur lors de la création du code promo: $e');
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
    } catch (e) {
      throw Exception('Erreur lors de la récupération des codes promo: $e');
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
    } catch (e) {
      throw Exception('Erreur lors de la récupération du code promo: $e');
    }
  }

  // Valider un code promo
  Future<PromoCodeValidationResult> validatePromoCode(
    String code,
    double totalPrice,
  ) async {
    try {
      final promoCode = await getPromoCodeByCode(code);

      if (promoCode == null) {
        return PromoCodeValidationResult(
          isValid: false,
          message: 'Code promo introuvable',
        );
      }

      // Vérifier si le code a expiré
      if (promoCode.expiresAt != null &&
          DateTime.now().isAfter(promoCode.expiresAt!)) {
        return PromoCodeValidationResult(
          isValid: false,
          message: 'Ce code promo a expiré',
        );
      }

      // Vérifier si le code a atteint sa limite d'utilisation
      if (promoCode.maxUsers != null &&
          promoCode.usedCount >= promoCode.maxUsers!) {
        return PromoCodeValidationResult(
          isValid: false,
          message: 'Ce code promo a atteint sa limite d\'utilisation',
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
    } catch (e) {
      return PromoCodeValidationResult(
        isValid: false,
        message: 'Erreur lors de la validation: $e',
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
    } catch (e) {
      throw Exception('Erreur lors de l\'application du code promo: $e');
    }
  }

  // Mettre à jour un code promo
  Future<void> updatePromoCode(PromoCode promoCode) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(promoCode.id)
          .update(promoCode.copyWith(updatedAt: DateTime.now()).toMap());
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du code promo: $e');
    }
  }

  // Supprimer un code promo
  Future<void> deletePromoCode(String promoCodeId) async {
    try {
      await _firestore.collection(_collection).doc(promoCodeId).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression du code promo: $e');
    }
  }

  // Activer/Désactiver un code promo
  Future<void> togglePromoCodeStatus(String promoCodeId, bool isActive) async {
    try {
      await _firestore.collection(_collection).doc(promoCodeId).update({
        'isActive': isActive,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la modification du statut: $e');
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
