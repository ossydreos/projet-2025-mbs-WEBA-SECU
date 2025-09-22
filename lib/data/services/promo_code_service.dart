import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/promo_code.dart';

class PromoCodeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'promo_codes';

  Future<String> create(PromoCode promo) async {
    try {
      final doc = _firestore.collection(_collection).doc();
      await doc.set(promo.copyWith(id: doc.id).toMap());
      return doc.id;
    } catch (e, st) {
      developer.log(
        'Erreur création code promo: $e',
        name: 'PromoCodeService',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  Future<void> update(PromoCode promo) async {
    try {
      await _firestore.collection(_collection).doc(promo.id).update({
        ...promo.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, st) {
      developer.log(
        'Erreur mise à jour code promo: $e',
        name: 'PromoCodeService',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e, st) {
      developer.log(
        'Erreur suppression code promo: $e',
        name: 'PromoCodeService',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  Future<void> setActive(String id, bool isActive) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, st) {
      developer.log(
        'Erreur activation code promo: $e',
        name: 'PromoCodeService',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  Stream<List<PromoCode>> watchAll({bool? onlyActive}) {
    Query query = _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true);
    if (onlyActive != null) {
      query = query.where('isActive', isEqualTo: onlyActive);
    }
    return query.snapshots().map(
      (snap) => snap.docs
          .map((d) => PromoCode.fromMap(d.data() as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<PromoCode?> getByCode(String code) async {
    final snap = await _firestore
        .collection(_collection)
        .where('code', isEqualTo: code.toUpperCase())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return PromoCode.fromMap(snap.docs.first.data());
  }

  // Vérifier si un code est valide (actif, non expiré, quota non atteint)
  Future<bool> isUsable(PromoCode promo) async {
    final now = DateTime.now();
    if (!promo.isActive) return false;
    if (promo.expiresAt != null && promo.expiresAt!.isBefore(now)) return false;
    if (promo.maxUsers != null && promo.usedCount >= promo.maxUsers!)
      return false;
    return true;
  }

  // Redeem atomiquement un code (incrémente usedCount si encore valide)
  Future<void> redeemIfValid(String promoId) async {
    final ref = _firestore.collection(_collection).doc(promoId);
    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(ref);
      if (!snap.exists) {
        throw StateError('Code promo introuvable');
      }
      final data = snap.data() as Map<String, dynamic>;
      final promo = PromoCode.fromMap(data);
      final now = DateTime.now();
      if (!promo.isActive) throw StateError('Code désactivé');
      if (promo.expiresAt != null && promo.expiresAt!.isBefore(now)) {
        throw StateError('Code expiré');
      }
      if (promo.maxUsers != null && promo.usedCount >= promo.maxUsers!) {
        throw StateError('Quota atteint');
      }
      txn.update(ref, {
        'usedCount': promo.usedCount + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
