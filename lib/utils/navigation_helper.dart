import 'package:flutter/material.dart';

/// Utilitaire centralisé pour la navigation commune
/// Réduit la duplication des patterns Navigator.of(context)
class NavigationHelper {
  /// Navigation push standard avec animation personnalisée
  static Future<T?> push<T extends Object?>(
    BuildContext context,
    Widget page, {
    String? routeName,
    bool fadeTransition = false,
    Duration transitionDuration = const Duration(milliseconds: 300),
  }) {
    if (fadeTransition) {
      return Navigator.of(context).push(
        PageRouteBuilder<T>(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: transitionDuration,
          settings: RouteSettings(name: routeName),
        ),
      );
    }

    return Navigator.of(context).push(
      MaterialPageRoute<T>(
        builder: (context) => page,
        settings: RouteSettings(name: routeName),
      ),
    );
  }

  /// Pop avec résultat optionnel
  static void pop<T extends Object?>(
    BuildContext context, [
    T? result,
  ]) {
    Navigator.of(context).pop(result);
  }

  /// Pop jusqu'à une route spécifique
  static void popUntil(BuildContext context, RoutePredicate predicate) {
    Navigator.of(context).popUntil(predicate);
  }

  /// Pop et push en une fois
  static Future<T?> popAndPush<T extends Object?, R extends Object?>(
    BuildContext context,
    Widget page, {
    T? result,
    String? routeName,
  }) {
    return Navigator.of(context).pushReplacement(
      MaterialPageRoute<T>(
        builder: (context) => page,
        settings: RouteSettings(name: routeName),
      ),
      result: result,
    );
  }

  /// Push sans possibilité de revenir
  static Future<T?> pushReplacement<T extends Object?, TO extends Object?>(
    BuildContext context,
    Widget page, {
    String? routeName,
  }) {
    return Navigator.of(context).pushReplacement(
      MaterialPageRoute<T>(
        builder: (context) => page,
        settings: RouteSettings(name: routeName),
      ),
    );
  }

  /// Push et clear tout l'historique
  static Future<T?> pushAndClearStack<T extends Object?>(
    BuildContext context,
    Widget page, {
    String? routeName,
  }) {
    return Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<T>(
        builder: (context) => page,
        settings: RouteSettings(name: routeName),
      ),
      (route) => false,
    );
  }

  /// Vérifier si on peut revenir en arrière
  static bool canPop(BuildContext context) {
    return Navigator.of(context).canPop();
  }
}
