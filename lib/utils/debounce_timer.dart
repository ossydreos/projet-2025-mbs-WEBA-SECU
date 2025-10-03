import 'dart:async';

/// Timer qui retarde l'exécution d'une fonction jusqu'à ce qu'un délai spécifié
/// se soit écoulé sans nouvelle demande d'exécution
class DebounceTimer {
  Timer? _timer;
  final Duration _delay;

  DebounceTimer(this._delay);

  /// Annule le timer précédent et démarre un nouveau timer
  void call(void Function() callback) {
    _timer?.cancel();
    _timer = Timer(_delay, callback);
  }

  /// Annule le timer en cours
  void cancel() {
    _timer?.cancel();
  }

  /// Libère les ressources utilisées par le timer
  void dispose() {
    cancel();
  }

  /// Vérifie si le timer est actif
  bool get isActive => _timer?.isActive ?? false;
}

/// Extension pour faciliter l'utilisation du debounce sur les fonctions
extension DebounceExtension on void Function() {
  Timer runAfterDelay(Duration delay) {
    return Timer(delay, this);
  }
}
