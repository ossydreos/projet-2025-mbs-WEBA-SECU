import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:my_mobility_services/l10n/generated/app_localizations.dart';
import 'package:flutter/cupertino.dart';

/// Service d'adaptation d'interface utilisateur pour iOS
/// Gère automatiquement les différences entre iOS et Android
class IOSUIAdapter {
  static IOSUIAdapter? _instance;
  IOSUIAdapter._internal();

  static IOSUIAdapter get instance {
    _instance ??= IOSUIAdapter._internal();
    return _instance!;
  }

  /// Détermine si on utilise le design iOS natif
  bool get useIOSDesign => Platform.isIOS;

  /// Crée un bouton adapté à la plateforme
  Widget adaptiveButton({
    required VoidCallback onPressed,
    required Widget child,
    bool isPrimary = true,
    EdgeInsetsGeometry? padding,
  }) {
    if (useIOSDesign) {
      return CupertinoButton(
        onPressed: onPressed,
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isPrimary
            ? CupertinoColors.activeBlue
            : CupertinoColors.systemGrey,
        borderRadius: BorderRadius.circular(8),
        child: child,
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        backgroundColor: isPrimary
            ? Theme.of(navigatorKey.currentContext!).primaryColor
            : Colors.grey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: child,
    );
  }

  /// Crée une barre de navigation adaptée
  Widget adaptiveNavigationBar({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool automaticallyImplyLeading = true,
  }) {
    if (useIOSDesign) {
      return CupertinoNavigationBar(
        middle: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: actions != null && actions.isNotEmpty
            ? Row(mainAxisSize: MainAxisSize.min, children: actions)
            : null,
        leading: leading,
        automaticallyImplyLeading: automaticallyImplyLeading,
      );
    }

    return AppBar(
      title: Text(title),
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
    );
  }

  /// Crée une alerte adaptée à la plateforme
  Future<void> showAdaptiveAlert({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) async {
    if (useIOSDesign) {
      await showCupertinoDialog<bool>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            if (cancelText != null)
              CupertinoDialogAction(
                onPressed: () {
                  Navigator.of(context).pop(false);
                  onCancel?.call();
                },
                child: Text(cancelText),
              ),
            if (confirmText != null)
              CupertinoDialogAction(
                onPressed: () {
                  Navigator.of(context).pop(true);
                  onConfirm?.call();
                },
                child: Text(confirmText),
              ),
          ],
        ),
      );
    } else {
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            if (cancelText != null)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                  onCancel?.call();
                },
                child: Text(cancelText),
              ),
            if (confirmText != null)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                  onConfirm?.call();
                },
                child: Text(confirmText),
              ),
          ],
        ),
      );
    }
  }

  /// Crée une feuille d'action adaptée (action sheet)
  Future<void> showAdaptiveActionSheet({
    required BuildContext context,
    required String title,
    required List<Widget> actions,
    VoidCallback? onCancel,
  }) async {
    if (useIOSDesign) {
      await showCupertinoModalPopup(
        context: context,
        builder: (context) => CupertinoActionSheet(
          title: Text(title),
          actions: actions
              .map(
                (action) => CupertinoActionSheetAction(
                  onPressed: () => Navigator.of(context).pop(),
                  child: action,
                ),
              )
              .toList(),
          cancelButton: CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              onCancel?.call();
            },
            child: Text(AppLocalizations.of(context).cancel),
          ),
        ),
      );
    } else {
      await showModalBottomSheet(
        context: context,
        builder: (context) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ...actions,
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onCancel?.call();
                },
                child: Text(AppLocalizations.of(context).cancel),
              ),
            ],
          ),
        ),
      );
    }
  }

  /// Crée un indicateur de chargement adapté
  Widget adaptiveLoadingIndicator({double size = 20}) {
    if (useIOSDesign) {
      return CupertinoActivityIndicator(radius: size / 2);
    }
    return SizedBox(
      width: size,
      height: size,
      child: const CircularProgressIndicator(strokeWidth: 2),
    );
  }

  /// Crée un switch adapté à la plateforme
  Widget adaptiveSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
    Color? activeColor,
  }) {
    if (useIOSDesign) {
      return CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeColor: activeColor ?? CupertinoColors.activeGreen,
      );
    }

    return Switch(value: value, onChanged: onChanged, activeColor: activeColor);
  }

  /// Crée un curseur adapté à la plateforme
  Widget adaptiveSlider({
    required double value,
    required ValueChanged<double> onChanged,
    double min = 0,
    double max = 1,
    int? divisions,
    Color? activeColor,
  }) {
    if (useIOSDesign) {
      return CupertinoSlider(
        value: value,
        onChanged: onChanged,
        min: min,
        max: max,
        divisions: divisions,
        activeColor: activeColor ?? CupertinoColors.activeBlue,
      );
    }

    return Slider(
      value: value,
      onChanged: onChanged,
      min: min,
      max: max,
      divisions: divisions,
      activeColor: activeColor,
    );
  }

  /// Animation de page adaptée à iOS
  Widget adaptivePageTransition({
    required Widget child,
    required Animation<double> animation,
  }) {
    if (useIOSDesign) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
        child: child,
      );
    }

    return FadeTransition(opacity: animation, child: child);
  }

  /// Padding recommandé pour iOS (respecte la safe area)
  EdgeInsets get adaptiveScreenPadding {
    if (useIOSDesign) {
      return const EdgeInsets.fromLTRB(
        16,
        16 + 44,
        16,
        16 + 34,
      ); // top: status + nav, bottom: home indicator
    }
    return const EdgeInsets.all(16);
  }

  /// Taille de police adaptée à iOS (légèrement plus grande)
  double get adaptiveTitleFontSize {
    return useIOSDesign ? 20 : 18;
  }

  /// Rayon de bordure adapté à iOS (plus arrondi)
  double get adaptiveBorderRadius {
    return useIOSDesign ? 12 : 8;
  }
}

/// Extension pour faciliter l'utilisation
extension IOSUIExtensions on BuildContext {
  IOSUIAdapter get iosAdapter => IOSUIAdapter.instance;
}

/// Clé globale du navigateur pour l'adapter
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
