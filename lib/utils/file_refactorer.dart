/// Utilitaire pour analyser et proposer des refactorings de fichiers trop gros
class FileRefactorer {
  
  /// Critères pour identifier les fichiers problématiques
  static const int maxLinesPerFile = 500;
  static const int maxMethodsPerClass = 15;
  static const int maxImportsPerFile = 20;

  /// Analyse un fichier et propose des extractions possibles
  static RefactoringAnalysis analyzeFile(String filePath, List<String> content) {
    final analysis = RefactoringAnalysis(filePath);
    
    // Analyse lignes
    analysis.totalLines = content.length;
    analysis.needsRefactoring = content.length > maxLinesPerFile;
    
    // Analyse imports
    analysis.importCount = content.where((line) => line.trim().startsWith('import')).length;
    analysis.tooManyImports = analysis.importCount > maxImportsPerFile;
    
    // Détecte patterns à extraire
    analysis.extractionSuggestions = _findExtractionCandidates(content);
    
    return analysis;
  }

  /// Trouve les patterns récurrents qui peuvent être extraits
  static List<ExtractionCandidate> _findExtractionCandidates(List<String> content) {
    final candidates = <ExtractionCandidate>[];
    
    // Recherche classes avec trop de méthodes
    int classMethodCount = 0;
    String currentClass = '';
    
    for (int i = 0; i < content.length; i++) {
      final line = content[i].trim();
      
      // Détection classe
      if (line.startsWith('class ') && line.contains(' {')) {
        currentClass = line.split(' ')[1].split('(')[0].trim();
        classMethodCount = 0;
      }
      
      // Détection méthodes
      if (line.contains('()') || line.contains('async ') || line.contains('Future<')) {
        if (!line.contains('class') && !line.contains('import') && line.contains('{')) {
          classMethodCount++;
        }
      }
      
      // Si trop de méthodes dans une classe
      if (classMethodCount > maxMethodsPerClass) {
        candidates.add(ExtractionCandidate(
          name: '${currentClass}_Extractor',
          type: ExtractionType.widgetMethods,
          reason: 'Classe $currentClass a trop de méthodes ($classMethodCount)',
          linesToExtract: classMethodCount,
        ));
        classMethodCount = 0; // Reset pour éviter les doublons
      }
    }
    
    // Préféré: Recherche méthodes statiques utilitaires
    final utilityMethods = <String>[];
    for (final line in content) {
      if (line.contains('static ') && !line.contains('const ')) {
        utilityMethods.add(line);
      }
    }
    
    if (utilityMethods.length > 3) {
      candidates.add(ExtractionCandidate(
        name: 'UtilityMethods_Extractor', 
        type: ExtractionType.utilityMethods,
        reason: 'Trop de méthodes statiques (${utilityMethods.length})',
        linesToExtract: utilityMethods.length,
      ));
    }
    
    return candidates;
  }
}

class RefactoringAnalysis {
  final String filePath;
  int totalLines = 0;
  int importCount = 0;
  bool needsRefactoring = false;
  bool tooManyImports = false;
  List<ExtractionCandidate> extractionSuggestions = [];

  RefactoringAnalysis(this.filePath);
  
  int get score => [
    if (!needsRefactoring) 20 else -20,
    if (!tooManyImports) 10 else -10,
    if (extractionSuggestions.isEmpty) 10 else -extractionSuggestions.length * 5,
  ].fold(0, (a, b) => a + b);
}

class ExtractionCandidate {
  final String name;
  final ExtractionType type;
  final String reason;
  final int linesToExtract;
  
  ExtractionCandidate({
    required this.name,
    required this.type,
    required this.reason,
    required this.linesToExtract,
  });
}

enum ExtractionType {
  widgetMethods,
  utilityMethods,
  serviceClass,
  constants,
}
