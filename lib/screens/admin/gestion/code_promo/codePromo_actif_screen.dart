import 'package:flutter/material.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import 'package:my_mobility_services/l10n/generated/app_localizations.dart';
import 'package:my_mobility_services/data/models/promo_code.dart';
import 'package:my_mobility_services/data/services/promo_code_service.dart';

class ActivePromoCodesScreen extends StatelessWidget {
  ActivePromoCodesScreen({super.key});

  final _service = PromoCodeService();

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(title: AppLocalizations.of(context).promoCodes),
        body: StreamBuilder<List<PromoCode>>(
          stream: _service.getPromoCodesStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = snapshot.data ?? const <PromoCode>[];
            if (items.isEmpty) {
              return const Center(child: Text('Aucun code pour le moment'));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: items.length,
              itemBuilder: (context, i) => _PromoTile(
                promo: items[i],
                onToggle: (active) =>
                    _service.togglePromoCodeStatus(items[i].id, active),
                onDelete: () => _service.deletePromoCode(items[i].id),
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final created = await Navigator.pushNamed(
              context,
              '/admin/promo/create',
            );
            if (created == true && context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).codeCreated)));
            }
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _PromoTile extends StatelessWidget {
  const _PromoTile({
    required this.promo,
    required this.onToggle,
    required this.onDelete,
  });

  final PromoCode promo;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final subtitle = StringBuffer()
      ..write(
        promo.type == DiscountType.percent
            ? '${promo.value.toStringAsFixed(0)}%'
            : '${promo.value.toStringAsFixed(2)}',
      )
      ..write(' • ')
      ..write(
        promo.expiresAt != null
            ? 'Expire: ${promo.expiresAt!.toString().split(' ').first}'
            : 'Sans expiration',
      )
      ..write(' • ')
      ..write(
        'Utilisés: ${promo.usedCount}${promo.maxUsers != null ? ' / ${promo.maxUsers}' : ''}',
      );

    return GlassContainer(
      padding: const EdgeInsets.all(14),
      borderRadius: BorderRadius.circular(16),
      child: Row(
        children: [
          Icon(Icons.local_offer, color: AppColors.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${promo.name} • ${promo.code}',
                  style: TextStyle(
                    color: AppColors.textStrong,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle.toString(),
                  style: TextStyle(color: AppColors.textWeak, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(value: promo.isActive, onChanged: (v) => onToggle(v)),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: AppColors.hot,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
