import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_mobility_services/data/services/ride_chat_service.dart';
import 'package:my_mobility_services/design/tokens/app_tokens.dart';
import 'package:my_mobility_services/design/widgets/primitives/custom_badge.dart';
import 'package:my_mobility_services/design/widgets/primitives/glass_container.dart';
import 'package:my_mobility_services/data/models/reservation.dart';
import 'package:my_mobility_services/l10n/generated/app_localizations.dart';

/// Trip Card V2 with improved layout and custom reservation support
class TripCardV2 extends StatefulWidget {
  final ReservationType type; // Type de réservation (reservation ou offer)
  final String reservationId;
  final String vehicleTitle;
  final String fromAddress;
  final String toAddress;
  final DateTime startAt;
  final DateTime? endAt; // required visually if type == offer
  final String status; // "En cours" | "Confirmé" | "Terminé"
  final String paymentLabel; // e.g. "Espèces"
  final String priceFormatted;
  final bool isUpcoming;
  final VoidCallback? onChat;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback? onSelectionToggle;

  const TripCardV2({
    super.key,
    required this.type,
    required this.reservationId,
    required this.vehicleTitle,
    required this.fromAddress,
    required this.toAddress,
    required this.startAt,
    this.endAt,
    required this.status,
    required this.paymentLabel,
    required this.priceFormatted,
    required this.isUpcoming,
    this.onChat,
    this.onTap,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.onSelectionToggle,
  });

  @override
  State<TripCardV2> createState() => _TripCardV2State();
}

class _TripCardV2State extends State<TripCardV2>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    
    return Semantics(
      label: _buildSemanticLabel(),
      button: true,
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isPressed = true);
          _animationController.forward();
          HapticFeedback.lightImpact();
        },
        onTap: () {
          setState(() => _isPressed = false);
          _animationController.reverse();
          
          // In selection mode, always toggle selection
          if (widget.isSelectionMode) {
            if (widget.onSelectionToggle != null) {
              widget.onSelectionToggle!();
            }
          } else {
            // Normal mode, handle tap
            widget.onTap?.call();
          }
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
          _animationController.reverse();
        },
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: RepaintBoundary(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: t.glassRadius,
                        border: widget.isSelectionMode 
                            ? Border.all(
                                color: widget.isSelected ? t.accent : t.glassStroke,
                                width: widget.isSelected ? 2 : 1,
                              )
                            : null,
                        boxShadow: widget.isSelectionMode && widget.isSelected
                            ? [
                                BoxShadow(
                                  color: t.accent.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: GlassContainer(
                        padding: EdgeInsets.all(t.spaceMd),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header row: Vehicle + Status + Price
                            _buildHeaderRow(t),
                            
                            SizedBox(height: t.spaceSm),
                            
                            // Address block (stacked, NO line)
                            _buildAddressBlock(t),
                            
                            SizedBox(height: t.spaceMd),
                            
                            // Meta block
                            _buildMetaBlock(t),
                            
                            SizedBox(height: t.spaceMd),
                            
                            // CTA row
                            _buildCTARow(t),
                          ],
                        ),
                      ),
                    ),
                    // Selection indicator — rounded iOS-like checkbox with glass styling
                    if (widget.isSelectionMode)
                      Positioned(
                        right: 4,
                        top: 0,
                        bottom: 0,
                        child: Semantics(
                          label: widget.isSelected
                              ? AppLocalizations.of(context).deselectTrip
                              : AppLocalizations.of(context).selectTrip,
                          button: true,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              if (widget.onSelectionToggle != null) {
                                widget.onSelectionToggle!();
                              }
                            },
                            child: SizedBox(
                              width: 52, // larger tap target
                              child: Center(
                                child: AnimatedScale(
                                  duration: const Duration(milliseconds: 120),
                                  curve: Curves.easeInOut,
                                  scale: widget.isSelected ? 1.0 : 0.96,
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 120),
                                    opacity: 1.0,
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: widget.isSelected
                                            ? t.accent.withOpacity(0.18)
                                            : t.glassTint.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.10),
                                          width: 1,
                                        ),
                                        boxShadow: widget.isSelected
                                            ? [
                                                BoxShadow(
                                                  color: t.accent.withOpacity(0.35),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Icon(
                                        widget.isSelected
                                            ? Icons.check_rounded
                                            : Icons.add_rounded,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderRow(AppTokens t) {
    return Row(
      children: [
        // Vehicle icon and title
        Expanded(
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: t.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.directions_car_rounded,
                  color: t.accent,
                  size: 20,
                ),
              ),
              SizedBox(width: t.spaceSm),
              Expanded(
                child: Text(
                  widget.vehicleTitle,
                  style: t.title2.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: t.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        
        // Status and Price on the right
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status chip
            _buildStatusChip(t),
            SizedBox(width: t.spaceSm),
            // Price
            Text(
              widget.priceFormatted,
              style: t.title2.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: t.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip(AppTokens t) {
    final statusColor = _getStatusColor(t);
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: t.spaceSm, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Text(
        widget.status,
        style: t.caption.copyWith(
          color: statusColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildAddressBlock(AppTokens t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // From address
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(
                Icons.location_on_rounded,
                size: 18,
                color: t.textTertiary,
              ),
            ),
            SizedBox(width: t.spaceXs),
            Expanded(
              child: Text(
                widget.fromAddress,
                style: t.body.copyWith(
                  color: t.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        
        SizedBox(height: t.spaceXs),
        
        // To address
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(
                Icons.flag_rounded,
                size: 18,
                color: t.textTertiary,
              ),
            ),
            SizedBox(width: t.spaceXs),
            Expanded(
              child: Text(
                widget.toAddress,
                style: t.body.copyWith(
                  color: t.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetaBlock(AppTokens t) {
    return Column(
      children: [
        // Payment method
        _buildMetaRow(
          Icons.payment_rounded,
          AppLocalizations.of(context).payment,
          widget.paymentLabel,
          t,
        ),
        
        SizedBox(height: 4), // Réduire l'espacement entre Paiement et Départ
        
        // Departure time (always shown)
        _buildMetaRow(
          Icons.schedule_rounded,
          AppLocalizations.of(context).departure,
          _formatDateTime(widget.startAt),
          t,
        ),
        
        // Arrival time (required for custom, optional for standard)
        if (widget.type == ReservationType.offer || widget.endAt != null) ...[
          SizedBox(height: 4), // Réduire l'espacement
          _buildMetaRow(
            Icons.flag_rounded,
            AppLocalizations.of(context).arrival,
            widget.endAt != null 
                ? _formatDateTime(widget.endAt!)
                : '—:—',
            t,
            isOptional: widget.endAt == null,
          ),
        ],
      ],
    );
  }

  Widget _buildMetaRow(IconData icon, String label, String value, AppTokens t, {bool isOptional = false}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: t.textTertiary,
        ),
        SizedBox(width: t.spaceXs),
        Text(
          '$label: ',
          style: t.caption.copyWith(
            color: t.textTertiary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: t.caption.copyWith(
              color: isOptional ? t.textTertiary.withOpacity(0.6) : t.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildCTARow(AppTokens t) {
    if (widget.isUpcoming) {
      // Only show CTA row for custom upcoming trips (badge + chat)
      if (widget.type == ReservationType.offer) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Custom badge on the left
            CustomBadge.personalisee(),

            // Chat button on the right
            _buildChatButton(t),
          ],
        );
      } else {
        // Normal upcoming trips: Chat button aligned to the right
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildChatButton(t),
          ],
        );
      }
    } else {
      // Completed trips: Only show custom badge if applicable
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          if (widget.type == ReservationType.offer) 
            CustomBadge.personalisee()
          else
            SizedBox.shrink(),
        ],
      );
    }
  }

  Widget _buildChatButton(AppTokens t) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    final baseButton = _AppButton.tinted(
      label: AppLocalizations.of(context).chat,
      icon: Icons.chat_rounded,
      onPressed: widget.onChat,
    );

    if (userId == null || widget.onChat == null) {
      return baseButton;
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(RideChatService.threadsCollection)
          .where('reservationId', isEqualTo: widget.reservationId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? const <QueryDocumentSnapshot>[];
        final data = docs.isNotEmpty
            ? docs.first.data() as Map<String, dynamic>
            : null;
        final unreadRaw = data?['unreadForUser'];
        final unreadCount = unreadRaw is int ? unreadRaw : 0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            baseButton,
            if (unreadCount > 0)
              Positioned(
                right: -6,
                top: -6,
                child: _buildUnreadBadge(t, unreadCount),
              ),
          ],
        );
      },
    );
  }

  Widget _buildUnreadBadge(AppTokens t, int count) {
    final display = count > 9 ? '9+' : '$count';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: count > 9 ? t.spaceXxs : t.spaceXxs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: Colors.redAccent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Text(
        display,
        style: t.caption.copyWith(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(AppTokens t) {
    switch (widget.status.toLowerCase()) {
      case 'confirmé':
      case 'en cours':
        return t.accent;
      case 'terminé':
        return t.textTertiary;
      case 'annulé':
        return Colors.red;
      default:
        return t.textSecondary;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month} à ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _buildSemanticLabel() {
    final arrivalInfo = widget.type == ReservationType.offer && widget.endAt != null 
        ? ', arrivée ${_formatDateTime(widget.endAt!)}'
        : '';
    
    return 'Trajet de ${widget.fromAddress} vers ${widget.toAddress}, statut ${widget.status}, départ ${_formatDateTime(widget.startAt)}$arrivalInfo, prix ${widget.priceFormatted}';
  }
}

/// App Button component (reused from main screen)
class _AppButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isTinted;
  final bool isSubtle;

  const _AppButton._({
    required this.label,
    this.icon,
    this.onPressed,
    this.isPrimary = false,
    this.isTinted = false,
    this.isSubtle = false,
  });

  factory _AppButton.primary({
    required String label,
    IconData? icon,
    VoidCallback? onPressed,
  }) {
    return _AppButton._(
      label: label,
      icon: icon,
      onPressed: onPressed,
      isPrimary: true,
    );
  }

  factory _AppButton.tinted({
    required String label,
    IconData? icon,
    VoidCallback? onPressed,
  }) {
    return _AppButton._(
      label: label,
      icon: icon,
      onPressed: onPressed,
      isTinted: true,
    );
  }

  factory _AppButton.subtle({
    required String label,
    IconData? icon,
    VoidCallback? onPressed,
  }) {
    return _AppButton._(
      label: label,
      icon: icon,
      onPressed: onPressed,
      isSubtle: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    
    Color backgroundColor;
    Color textColor;
    Color borderColor;
    
    if (isPrimary) {
      backgroundColor = t.accent;
      textColor = t.accentOn;
      borderColor = t.accent;
    } else if (isTinted) {
      backgroundColor = t.accent.withOpacity(0.1);
      textColor = t.accent;
      borderColor = t.accent.withOpacity(0.3);
    } else if (isSubtle) {
      backgroundColor = t.glassTint.withOpacity(0.3);
      textColor = t.textPrimary;
      borderColor = t.glassStroke;
    } else {
      backgroundColor = t.glassTint;
      textColor = t.textPrimary;
      borderColor = t.glassStroke;
    }
    
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: t.spaceMd,
          vertical: t.spaceSm,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: textColor),
              SizedBox(width: t.spaceXs),
            ],
            Text(
              label,
              style: t.caption.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// App Icon Button component
class _AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  const _AppIconButton({
    required this.icon,
    this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    
    final button = GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: t.glassTint.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.glassStroke),
        ),
        child: Icon(
          icon,
          color: t.textPrimary,
          size: 20,
        ),
      ),
    );
    
    return tooltip != null
        ? Tooltip(message: tooltip!, child: button)
        : button;
  }
}
