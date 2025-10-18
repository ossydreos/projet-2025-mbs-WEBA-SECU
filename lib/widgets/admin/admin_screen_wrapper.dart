import 'package:flutter/material.dart';
import 'package:my_mobility_services/data/services/admin_global_notification_service.dart';

class AdminScreenWrapper extends StatefulWidget {
  final Widget child;
  final String title;

  const AdminScreenWrapper({
    super.key,
    required this.child,
    required this.title,
  });

  @override
  State<AdminScreenWrapper> createState() => _AdminScreenWrapperState();
}

class _AdminScreenWrapperState extends State<AdminScreenWrapper> {
  static final AdminGlobalNotificationService _notificationService =
      AdminGlobalNotificationService();

  @override
  void initState() {
    super.initState();
    // ❌ DÉSACTIVÉ TEMPORAIREMENT - Test OneSignal uniquement
    // Initialiser le service de notifications globales
    // WidgetsBinding.instance.addPostFrameCallback((_) async {
    //   // Initialiser d'abord le service global (pour les notifications locales)
    //   await _notificationService.initializeGlobal();
    //   // Puis mettre à jour le contexte (pour l'interface admin)
    //   _notificationService.initialize(context);
    //   print('🔔 AdminScreenWrapper: Service initialisé');
    // });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Mettre à jour le contexte à chaque changement de page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificationService.updateContext(context);
    });
  }

  @override
  void dispose() {
    // Ne pas disposer le service ici car il doit rester actif
    // Le service sera disposé uniquement lors de la déconnexion
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
