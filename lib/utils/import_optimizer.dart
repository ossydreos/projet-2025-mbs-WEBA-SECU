/// Utilitaire pour optimiser les imports et détecter les dépendances inutiles
class ImportOptimizer {
  
  /// Imports Dart core souvent oubliés mais nécessaires
  static const List<String> coreDartImports = [
    'dart:async',
    'dart:convert',
    'dart:io',
    'dart:math',
  ];
  
  /// Imports Flutter les plus communs
  static const List<String> commonFlutterImports = [
    'package:flutter/material.dart',
    'package:flutter/services.dart',
    'package:flutter/widgets.dart',
  ];
  
  /// Imports Firebase les plus utilisés dans le projet
  static const List<String> commonFirebaseImports = [
    'package:firebase_core/firebase_core.dart',
    'package:firebase_auth/firebase_auth.dart',
    'package:cloud_firestore/cloud_firestore.dart',
    'package:firebase_messaging/firebase_messaging.dart',
  ];
  
  /// Imports du projet lui-même les plus utilisés
  static const List<String> commonProjectImports = [
    'package:my_mobility_services/data/models/reservation.dart',
    'package:my_mobility_services/data/services/reservation_service.dart',
    'package:my_mobility_services/theme/glassmorphism_theme.dart',
    'package:my_mobility_services/utils/date_time_formatter.dart',
    'package:my_mobility_services/utils/business_validators.dart',
    'package:my_mobility_services/services/firebase_service.dart',
  ];
  
  /// Analyse un fichier pour détecter les imports potentiellement inutiles
  static Set<String> analyzeFile(String fileContent) {
    final Set<String> suspectedUnusedImports = <String>{};
    
    // Pattern detection basés sur les expériences 
    final lines = fileContent.split('\n');
    final imports = lines.where((line) => line.trim().startsWith('import')).toList();
    final codeLines = lines.where((line) => 
      !line.trim().startsWith('import') && 
      !line.trim().startsWith('//') &&
      !line.trim().isEmpty).toList();
    
    for (final import in imports) {
      if (_isImportLikelyUnused(import, codeLines)) {
        suspectedUnusedImports.add(import);
      }
    }
    
    return suspectedUnusedImports;
  }
  
  /// Détermine si un import est probablement inutile
  static bool _isImportLikelyUnused(String import, List<String> codeLines) {
    final importLower = import.toLowerCase();
    
    // Détecter les imports suspects
    if (importLower.contains('dart:convert') && !_lineContainsAny(codeLines, ['jsonEncode', 'jsonDecode', 'utf8'])) {
      return true;
    }
    
    if (importLower.contains('dart:math') && !_lineContainsAny(codeLines, ['Random', 'min', 'max', 'sqrt', 'pow'])) {
      return true;
    }
    
    if (importLower.contains('dart:io') && !_lineContainsAny(codeLines, ['Platform', 'File', 'Directory', 'HttpServer'])) {
      return true;
    }
    
    if (importLower.contains('package:http/http.dart') && !_lineContainsAny(codeLines, ['http.get', 'http.post', 'Response', 'Request'])) {
      return true;
    }
    
    return false;
  }
  
  /// Helper pour vérifier si une liste de lignes contient certains patterns
  static bool _lineContainsAny(List<String> lines, List<String> patterns) {
    return lines.any((line) => patterns.any((pattern) => line.contains(pattern)));
  }
}
