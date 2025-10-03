import 'package:characters/characters.dart';

/// Détecteur automatique de redondances dans le code
/// Trouve automatiquement les patterns répétés
class RedundancyDetector {
  /// Analyse tous les fichiers et retourne les redondances trouvées
  static RedundancyReport analyzeCodebase(List<String> fileContents) {
    final report = RedundancyReport();

    List<ClassDefinition> allClasses = [];
    List<MethodDefinition> allMethods = [];

    for (final content in fileContents) {
      final classes = _extractClassDefinitions(content);
      final methods = _extractMethodDefinitions(content);

      allClasses.addAll(classes);
      allMethods.addAll(methods);
    }

    // Recherche classes similaires
    report.duplicateClasses = _findDuplicateClasses(allClasses);

    // Recherche méthodes similaires
    report.duplicateMethods = _findDuplicateMethods(allMethods);

    // Recherche patterns répétés
    report.duplicatePatterns = _findDuplicatePatterns(fileContents);

    return report;
  }

  static List<ClassDefinition> _extractClassDefinitions(String content) {
    final classes = <ClassDefinition>[];
    final lines = content.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      // Détecter les définitions de classes
      if (line.startsWith('class ') && line.contains(' {')) {
        final className = line.split(' ')[1].split('(')[0].trim();
        classes.add(ClassDefinition(className: className, lineNumber: i + 1));
      }
    }

    return classes;
  }

  static List<MethodDefinition> _extractMethodDefinitions(String content) {
    final methods = <MethodDefinition>[];
    final lines = content.split('\n');

    for (int i = 0; i < lines.length - 5; i++) {
      final line = lines[i].trim();

      // Détecter les méthodes (patterns simples)
      if (line.contains('()') ||
          line.contains('async ') ||
          line.contains('Future<')) {
        if (!line.contains('class') &&
            !line.contains('import') &&
            line.contains('{')) {
          final methodContent = _extractMethodBody(lines, i);
          if (methodContent.isNotEmpty) {
            methods.add(
              MethodDefinition(
                signature: line,
                content: methodContent,
                lineNumber: i + 1,
              ),
            );
          }
        }
      }
    }

    return methods;
  }

  static String _extractMethodBody(List<String> lines, int startLine) {
    final body = StringBuffer();
    int braceCount = 0;
    bool inMethod = false;

    for (int i = startLine; i < lines.length; i++) {
      final line = lines[i];

      for (final char in line.characters) {
        if (char == '{') {
          braceCount++;
          inMethod = true;
        }
        if (char == '}') {
          braceCount--;
        }
      }

      if (inMethod) {
        body.writeln(line);
      }

      if (inMethod && braceCount == 0) {
        break;
      }
    }

    return body.toString();
  }

  static List<DuplicateClass> _findDuplicateClasses(
    List<ClassDefinition> classes,
  ) {
    final duplicates = <DuplicateClass>[];
    final classGroups = <String, List<ClassDefinition>>{};

    for (final cls in classes) {
      if (classGroups.containsKey(cls.className)) {
        classGroups[cls.className]!.add(cls);
      } else {
        classGroups[cls.className] = [cls];
      }
    }

    for (final entry in classGroups.entries) {
      if (entry.value.length > 1) {
        duplicates.add(
          DuplicateClass(
            className: entry.key,
            occurrences: entry.value.length,
            locations: entry.value.map((c) => c.lineNumber).toList(),
          ),
        );
      }
    }

    return duplicates;
  }

  static List<DuplicateMethod> _findDuplicateMethods(
    List<MethodDefinition> methods,
  ) {
    final duplicates = <DuplicateMethod>[];

    for (int i = 0; i < methods.length; i++) {
      for (int j = i + 1; j < methods.length; j++) {
        if (_calculateSimilarity(methods[i].content, methods[j].content) >
            0.8) {
          duplicates.add(
            DuplicateMethod(
              signature: methods[i].signature,
              occurrences: 2,
              locations: [methods[i].lineNumber, methods[j].lineNumber],
            ),
          );
        }
      }
    }

    return duplicates;
  }

  static List<DuplicatePattern> _findDuplicatePatterns(
    List<String> fileContents,
  ) {
    final patterns = <DuplicatePattern>[];

    // Recherche patterns communs
    final commonPatterns = [
      'final.*=.*TextEditingController',
      'import.*constants\.dart',
      'static.*const.*String.*key',
      'try.*catch.*e.*\\.*',
      'setState.*\\(',
    ];

    for (final pattern in commonPatterns) {
      int count = 0;
      final locations = <int>[];

      for (int i = 0; i < fileContents.length; i++) {
        final lines = fileContents[i].split('\n');
        for (int j = 0; j < lines.length; j++) {
          if (RegExp(pattern).hasMatch(lines[j])) {
            count++;
            locations.add(j + 1);
          }
        }
      }

      if (count > 5) {
        // Seuil d'alerte
        patterns.add(
          DuplicatePattern(
            pattern: pattern,
            occurrences: count,
            locations: locations,
          ),
        );
      }
    }

    return patterns;
  }

  static double _calculateSimilarity(String text1, String text2) {
    // Simulation de calcul de similarité (algorithme simplifié)
    final words1 = text1.split(' ').toSet();
    final words2 = text2.split(' ').toSet();

    final intersection = words1.intersection(words2);
    final union = words1.union(words2);

    return intersection.length / union.length;
  }
}

/// Rapport de redondances détectées
class RedundancyReport {
  List<DuplicateClass> duplicateClasses = [];
  List<DuplicateMethod> duplicateMethods = [];
  List<DuplicatePattern> duplicatePatterns = [];

  int get totalDuplicates =>
      duplicateClasses.length +
      duplicateMethods.length +
      duplicatePatterns.length;

  String generateSummary() {
    final buffer = StringBuffer();
    buffer.writeln('🔍 ANALYSE DE REDONDANCE');
    buffer.writeln('========================');
    buffer.writeln('Classes dupliquées: ${duplicateClasses.length}');
    buffer.writeln('Méthodes dupliquées: ${duplicateMethods.length}');
    buffer.writeln('Patterns dupliqués: ${duplicatePatterns.length}');
    buffer.writeln('Total redondances: $totalDuplicates');
    return buffer.toString();
  }
}

/// Définition de classe pour analyse
class ClassDefinition {
  final String className;
  final int lineNumber;

  ClassDefinition({required this.className, required this.lineNumber});
}

/// Définition de méthode pour analyse
class MethodDefinition {
  final String signature;
  final String content;
  final int lineNumber;

  MethodDefinition({
    required this.signature,
    required this.content,
    required this.lineNumber,
  });
}

/// Classe dupliquée détectée
class DuplicateClass {
  final String className;
  final int occurrences;
  final List<int> locations;

  DuplicateClass({
    required this.className,
    required this.occurrences,
    required this.locations,
  });
}

/// Méthode dupliquée détectée
class DuplicateMethod {
  final String signature;
  final int occurrences;
  final List<int> locations;

  DuplicateMethod({
    required this.signature,
    required this.occurrences,
    required this.locations,
  });
}

/// Pattern dupliqué détecté
class DuplicatePattern {
  final String pattern;
  final int occurrences;
  final List<int> locations;

  DuplicatePattern({
    required this.pattern,
    required this.occurrences,
    required this.locations,
  });
}
