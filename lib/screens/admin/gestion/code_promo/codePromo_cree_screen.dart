import 'package:flutter/material.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import 'package:my_mobility_services/data/models/promo_code.dart';
import 'package:my_mobility_services/data/services/promo_code_service.dart';

class CreatePromoCodeScreen extends StatefulWidget {
  const CreatePromoCodeScreen({super.key});

  @override
  State<CreatePromoCodeScreen> createState() => _CreatePromoCodeScreenState();
}

class _CreatePromoCodeScreenState extends State<CreatePromoCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  final _maxUsersCtrl = TextEditingController();
  DateTime? _expiresAt;
  DiscountType _type = DiscountType.amount;
  bool _saving = false;

  final _service = PromoCodeService();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _valueCtrl.dispose();
    _maxUsersCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() => _expiresAt = picked);
    }
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Champ requis' : null;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final promo = PromoCode(
        id: '',
        name: _nameCtrl.text.trim(),
        code: _codeCtrl.text.trim().toUpperCase(),
        type: _type,
        value: double.parse(_valueCtrl.text.replaceAll(',', '.')),
        expiresAt: _expiresAt,
        maxUsers: _maxUsersCtrl.text.isEmpty
            ? null
            : int.parse(_maxUsersCtrl.text),
        createdAt: DateTime.now(),
        updatedAt: null,
        usedCount: 0,
        isActive: true,
      );
      await _service.create(promo);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Code promo créé')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(title: 'Créer un code promo'),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nom du code promo*',
                  style: TextStyle(
                    color: AppColors.textStrong,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameCtrl,
                  validator: _required,
                  decoration: const InputDecoration(
                    hintText: 'Ex: Code Promo 20',
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Code promo*',
                            style: TextStyle(
                              color: AppColors.textStrong,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _codeCtrl,
                            validator: _required,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              hintText: 'Ex: Promo20',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Type de réduction*',
                            style: TextStyle(
                              color: AppColors.textStrong,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<DiscountType>(
                            value: _type,
                            items: const [
                              DropdownMenuItem(
                                value: DiscountType.amount,
                                child: Text('Forfaitaire'),
                              ),
                              DropdownMenuItem(
                                value: DiscountType.percent,
                                child: Text('Pourcentage'),
                              ),
                            ],
                            isExpanded: true,
                            onChanged: (v) => setState(
                              () => _type = v ?? DiscountType.amount,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Montant de la remise*',
                            style: TextStyle(
                              color: AppColors.textStrong,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _valueCtrl,
                            validator: (v) {
                              if (_required(v) != null) return 'Champ requis';
                              final value = double.tryParse(
                                v!.replaceAll(',', '.'),
                              );
                              if (value == null || value <= 0)
                                return 'Valeur invalide';
                              if (_type == DiscountType.percent &&
                                  (value <= 0 || value > 100))
                                return 'Pourcentage 1-100';
                              return null;
                            },
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              hintText: _type == DiscountType.percent
                                  ? 'Ex: 20%'
                                  : 'Ex: 20.00',
                              suffixText: _type == DiscountType.percent
                                  ? '%'
                                  : 'CHF',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date d\'expiration',
                            style: TextStyle(
                              color: AppColors.textStrong,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: _pickDate,
                            borderRadius: BorderRadius.circular(16),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                hintText: 'Choisir une date',
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _expiresAt == null
                                        ? 'Aucune'
                                        : _expiresAt!
                                              .toString()
                                              .split(' ')
                                              .first,
                                  ),
                                  const Icon(Icons.calendar_today, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nombre maximal d\'utilisateurs',
                            style: TextStyle(
                              color: AppColors.textStrong,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _maxUsersCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'Ex: 100',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: GlassButton(
                    label: _saving ? 'Enregistrement...' : 'Sauvegarder',
                    onPressed: _saving ? null : _save,
                    icon: Icons.save,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
