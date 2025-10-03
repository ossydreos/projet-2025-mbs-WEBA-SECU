import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:collection/collection.dart';

/// Service de cache optimisé spécifiquement pour iOS
/// Améliore les performances en gérant intelligemment la mémoire et le stockage
class IOSOptimizedCache {
  static IOSOptimizedCache? _instance;
  static const String _cachePrefix = 'ios_cache_';

  // Configuration différente selon la plateforme
  static const Duration _iosCacheDuration = Duration(hours: 6);
  static const Duration _androidCacheDuration = Duration(hours: 2);
  static const int _iosMaxMemoryItems = 50;
  static const int _androidMaxMemoryItems = 30;

  final Map<String, _CacheEntry> _memoryCache = {};
  String? _cacheDirectory;

  IOSOptimizedCache._internal();

  static IOSOptimizedCache get instance {
    _instance ??= IOSOptimizedCache._internal();
    return _instance!;
  }

  /// Durée de cache selon la plateforme
  Duration get _cacheDuration =>
      Platform.isIOS ? _iosCacheDuration : _androidCacheDuration;

  /// Nombre maximum d'éléments en mémoire selon la plateforme
  int get _maxMemoryItems =>
      Platform.isIOS ? _iosMaxMemoryItems : _androidMaxMemoryItems;

  /// Initialise le répertoire de cache
  Future<void> initialize() async {
    if (_cacheDirectory != null) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      _cacheDirectory = '${directory.path}/cache';

      // Crée le répertoire si nécessaire
      await Directory(_cacheDirectory!).create(recursive: true);
    } catch (e) {
      debugPrint('Erreur initialisation cache iOS: $e');
    }
  }

  /// Récupère un élément du cache avec gestion intelligente
  Future<T?> get<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final cacheKey = '$_cachePrefix$key';

    // Vérification en mémoire d'abord (plus rapide sur iOS)
    final memoryEntry = _memoryCache[cacheKey];
    if (memoryEntry != null && !_isExpired(memoryEntry)) {
      return fromJson(memoryEntry.data);
    }

    // Vérification disque si disponible
    if (_cacheDirectory != null) {
      try {
        final file = File('$_cacheDirectory/$cacheKey.json');
        if (await file.exists()) {
          final content = await file.readAsString();
          final data = json.decode(content) as Map<String, dynamic>;

          if (data['timestamp'] != null) {
            final timestamp = DateTime.fromMillisecondsSinceEpoch(
              data['timestamp'],
            );
            if (DateTime.now().difference(timestamp) < _cacheDuration) {
              // Remettre en mémoire pour iOS (optimisation)
              if (Platform.isIOS) {
                _memoryCache[cacheKey] = _CacheEntry(
                  data: data['data'],
                  timestamp: timestamp,
                );
                _cleanupMemoryIfNeeded();
              }

              return fromJson(data['data']);
            }
          }
        }
      } catch (e) {
        debugPrint('Erreur lecture cache disque: $e');
      }
    }

    return null;
  }

  /// Stocke un élément en cache avec optimisation iOS
  Future<void> set<T>(
    String key,
    T data,
    Map<String, dynamic> Function(T) toJson,
  ) async {
    final cacheKey = '$_cachePrefix$key';
    final timestamp = DateTime.now();
    final jsonData = toJson(data);

    // Gestion mémoire optimisée pour iOS
    if (Platform.isIOS) {
      _memoryCache[cacheKey] = _CacheEntry(
        data: jsonData,
        timestamp: timestamp,
      );
      _cleanupMemoryIfNeeded();
    }

    // Sauvegarde disque si disponible
    if (_cacheDirectory != null) {
      try {
        final file = File('$_cacheDirectory/$cacheKey.json');
        final cacheData = {
          'data': jsonData,
          'timestamp': timestamp.millisecondsSinceEpoch,
        };
        await file.writeAsString(json.encode(cacheData));
      } catch (e) {
        debugPrint('Erreur écriture cache disque: $e');
      }
    }
  }

  /// Nettoie intelligemment le cache mémoire sur iOS
  void _cleanupMemoryIfNeeded() {
    if (_memoryCache.length > _maxMemoryItems) {
      // Supprime les entrées les plus anciennes
      final sortedEntries = _memoryCache.entries.toList()
        ..sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));

      // Garde seulement les 70% les plus récents
      final keepCount = (_maxMemoryItems * 0.7).round();
      for (var i = 0; i < sortedEntries.length - keepCount; i++) {
        _memoryCache.remove(sortedEntries[i].key);
      }
    }
  }

  /// Vérifie si une entrée est expirée
  bool _isExpired(_CacheEntry entry) {
    return DateTime.now().difference(entry.timestamp) > _cacheDuration;
  }

  /// Nettoie tout le cache
  Future<void> clear() async {
    _memoryCache.clear();

    if (_cacheDirectory != null) {
      try {
        final directory = Directory(_cacheDirectory!);
        if (await directory.exists()) {
          await directory.delete(recursive: true);
          await directory.create();
        }
      } catch (e) {
        debugPrint('Erreur suppression cache: $e');
      }
    }
  }

  /// Nettoie les entrées expirées
  Future<void> cleanup() async {
    // Nettoie la mémoire
    _memoryCache.removeWhere((key, entry) => _isExpired(entry));

    // Nettoie le disque
    if (_cacheDirectory != null) {
      try {
        final directory = Directory(_cacheDirectory!);
        if (await directory.exists()) {
          final files = await directory.list().toList();
          for (final file in files) {
            if (file is File && file.path.endsWith('.json')) {
              try {
                final content = await file.readAsString();
                final data = json.decode(content) as Map<String, dynamic>;

                if (data['timestamp'] != null) {
                  final timestamp = DateTime.fromMillisecondsSinceEpoch(
                    data['timestamp'],
                  );
                  if (DateTime.now().difference(timestamp) > _cacheDuration) {
                    await file.delete();
                  }
                }
              } catch (e) {
                // Supprime les fichiers corrompus
                await file.delete();
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Erreur nettoyage cache disque: $e');
      }
    }
  }

  /// Statistiques du cache pour le debug
  Map<String, dynamic> getStats() {
    return {
      'memory_items': _memoryCache.length,
      'max_memory_items': _maxMemoryItems,
      'cache_duration_minutes': _cacheDuration.inMinutes,
      'platform': Platform.isIOS ? 'iOS' : 'Android',
    };
  }
}

/// Entrée du cache avec métadonnées
class _CacheEntry {
  final Map<String, dynamic> data;
  final DateTime timestamp;

  const _CacheEntry({required this.data, required this.timestamp});
}

/// Extension pour les types de données courantes
extension IOSCacheExtensions on IOSOptimizedCache {
  /// Cache spécialisé pour les suggestions de lieux
  Future<List<dynamic>?> getPlaceSuggestions(String query) async {
    return get(
      'places_$query',
      (data) => List<dynamic>.from(data['suggestions']),
    );
  }

  Future<void> setPlaceSuggestions(
    String query,
    List<dynamic> suggestions,
  ) async {
    await set('places_$query', suggestions, (data) => {'suggestions': data});
  }

  /// Cache spécialisé pour les coordonnées géographiques
  Future<Map<String, double>?> getCoordinates(String placeId) async {
    return get('coords_$placeId', (data) => Map<String, double>.from(data));
  }

  Future<void> setCoordinates(
    String placeId,
    Map<String, double> coordinates,
  ) async {
    await set('coords_$placeId', coordinates, (data) => data);
  }
}
