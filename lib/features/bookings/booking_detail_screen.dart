import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../catalog/catalog_providers.dart';
import 'booking_status.dart';
import 'bookings_providers.dart';
import 'bookings_repository.dart';

class BookingDetailScreen extends ConsumerStatefulWidget {
  const BookingDetailScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends ConsumerState<BookingDetailScreen> {
  bool _cancelling = false;

  Future<void> _showEditSheet(Booking b) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditBookingSheet(
        booking: b,
        onSaved: () {
          ref.invalidate(bookingsListProvider);
          ref.invalidate(bookingDetailProvider(b.id));
        },
      ),
    );
  }

  Future<void> _cancel(Booking b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annulla prenotazione?'),
        content: const Text("L'azione non può essere annullata."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('No')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppTheme.destructive),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sì, annulla')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _cancelling = true);
    try {
      await ref.read(bookingsRepositoryProvider).cancel(b.id);
      ref.invalidate(bookingsListProvider);
      ref.invalidate(bookingDetailProvider(b.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prenotazione annullata')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Errore nell'annullamento"),
            backgroundColor: AppTheme.destructive,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(bookingDetailProvider(widget.id));
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Prenotazione'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Errore: $e', style: TextStyle(color: AppTheme.destructive)),
        ),
        data: (b) {
          final df = DateFormat('EEEE d MMMM y', 'it_IT');
          final canEdit = b.status == 'pending' &&
              b.bookingDate.difference(DateTime.now()).inHours >= 48;
          final canCancel = canEdit;
          final color = bookingStatusColor(b.status);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  border: Border.all(color: AppTheme.border),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: color.withOpacity(0.3)),
                          ),
                          child: Text(
                            labelFor(b.status).toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: color,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '€${b.totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 22),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(b.bicycle.brand,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 22)),
                    Text(
                        '${b.bicycle.type?.name ?? '—'} · Taglia ${b.bicycle.size?.name ?? '—'}'
                        '${b.bicycle.motor ? ' · E-Bike' : ''}',
                        style: TextStyle(color: AppTheme.muted, fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _Section(
                title: 'Punto vendita',
                children: [
                  _Row(icon: Icons.store, text: b.retailer.name),
                  if (b.retailer.address != null || b.retailer.city != null)
                    _Row(
                      icon: Icons.location_on_outlined,
                      text: [b.retailer.address, b.retailer.city]
                          .whereType<String>()
                          .join(', '),
                    ),
                  if (b.retailer.phoneNumber != null)
                    _Row(icon: Icons.phone, text: b.retailer.phoneNumber!),
                ],
              ),
              const SizedBox(height: 12),
              _Section(
                title: 'Date',
                children: [
                  _Row(
                      icon: Icons.event_available,
                      text: 'Ritiro: ${df.format(b.bookingDate)}'),
                  _Row(
                      icon: Icons.event,
                      text: 'Riconsegna: ${df.format(b.returnDate)}'),
                ],
              ),
              const SizedBox(height: 12),
              _Section(
                title: 'Assicurazione e accessori',
                children: [
                  _Row(
                      icon: Icons.shield_outlined,
                      text: b.insurance?.name ?? 'Nessuna'),
                  _Row(
                    icon: Icons.shopping_bag_outlined,
                    text: b.accessories.isEmpty
                        ? 'Nessuno'
                        : b.accessories.map((a) => a.name).join(', '),
                  ),
                ],
              ),
              if ((b.notes ?? '').isNotEmpty) ...[
                const SizedBox(height: 12),
                _Section(
                  title: 'Note',
                  children: [
                    Text(b.notes!, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              if (canEdit) ...[
                OutlinedButton.icon(
                  onPressed: () => _showEditSheet(b),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Modifica'),
                ),
                const SizedBox(height: 8),
              ],
              if (canCancel)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.destructive),
                  onPressed: _cancelling ? null : () => _cancel(b),
                  icon: const Icon(Icons.delete_outline),
                  label: Text(_cancelling
                      ? 'Annullamento...'
                      : 'Annulla prenotazione'),
                ),
              if (!canCancel && b.status == 'pending')
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    "Puoi annullare la prenotazione fino a 48 ore prima del ritiro.",
                    style:
                        TextStyle(color: AppTheme.muted, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: eyebrowStyle()),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.muted),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Edit bottom sheet
// ---------------------------------------------------------------------------

class _EditBookingSheet extends ConsumerStatefulWidget {
  const _EditBookingSheet({required this.booking, required this.onSaved});
  final Booking booking;
  final VoidCallback onSaved;

  @override
  ConsumerState<_EditBookingSheet> createState() => _EditBookingSheetState();
}

class _EditBookingSheetState extends ConsumerState<_EditBookingSheet> {
  late DateTime _pickupDate;
  late DateTime _returnDate;
  late String? _insuranceId;
  late List<String> _accessories;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _pickupDate = widget.booking.bookingDate;
    _returnDate = widget.booking.returnDate;
    _insuranceId = widget.booking.insurance?.id;
    _accessories = widget.booking.accessories.map((a) => a.id).toList();
  }

  int get _halfDays => (_returnDate.difference(_pickupDate).inDays + 1) * 2;

  double _calcTotal(List<Insurance> insurances, List<Accessory> allAcc) {
    final bikeP = widget.booking.bicycle.unitPrice * _halfDays;
    final ins = insurances
        .firstWhere((i) => i.id == _insuranceId,
            orElse: () => Insurance(id: '', name: '', unitPrice: 0))
        .unitPrice;
    final acc = _accessories.fold<double>(
      0,
      (s, id) => s +
          allAcc
              .firstWhere((a) => a.id == id,
                  orElse: () => Accessory(id: '', name: '', unitPrice: 0))
              .unitPrice,
    );
    return bikeP + ins + acc;
  }

  Future<void> _pickDate({required bool isPickup}) async {
    final today = DateTime.now();
    final initial = isPickup ? _pickupDate : _returnDate;
    final first = isPickup ? today : _pickupDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first) ? first : initial,
      firstDate: first,
      lastDate: DateTime(2099),
    );
    if (picked == null) return;
    setState(() {
      if (isPickup) {
        _pickupDate = DateTime(
          picked.year, picked.month, picked.day,
          _pickupDate.hour, _pickupDate.minute,
        );
        if (_returnDate.isBefore(_pickupDate)) {
          _returnDate = DateTime(
            picked.year, picked.month, picked.day, 18,
          );
        }
      } else {
        _returnDate = DateTime(picked.year, picked.month, picked.day, 18);
      }
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(bookingsRepositoryProvider).update(
            widget.booking.id,
            UpdateBookingPayload(
              bookingDate: _pickupDate,
              returnDate: _returnDate,
              insuranceId: _insuranceId,
              accessories: _accessories,
            ),
          );
      widget.onSaved();
      if (mounted) Navigator.of(context).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prenotazione aggiornata')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: AppTheme.destructive,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final insurancesAsync = ref.watch(insurancesProvider);
    final accessoriesAsync = ref.watch(accessoriesProvider);
    final df = DateFormat('EEE d MMM y', 'it_IT');

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Modifica prenotazione',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // ---- DATE ----
          Text('DATE', style: eyebrowStyle()),
          const SizedBox(height: 8),
          _DateRow(
            label: 'Ritiro',
            value: df.format(_pickupDate),
            onTap: () => _pickDate(isPickup: true),
          ),
          const SizedBox(height: 8),
          _DateRow(
            label: 'Riconsegna',
            value: df.format(_returnDate),
            onTap: () => _pickDate(isPickup: false),
          ),
          const SizedBox(height: 16),
          // ---- ASSICURAZIONE ----
          Text('ASSICURAZIONE', style: eyebrowStyle()),
          const SizedBox(height: 8),
          insurancesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Errore caricamento assicurazioni',
                style: TextStyle(color: AppTheme.destructive, fontSize: 12)),
            data: (insurances) => DropdownButtonFormField<String>(
              value: _insuranceId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              hint: const Text('Seleziona assicurazione'),
              items: insurances
                  .map((i) => DropdownMenuItem(
                        value: i.id,
                        child: Text('${i.name} — €${i.unitPrice.toStringAsFixed(2)}'),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _insuranceId = v),
            ),
          ),
          const SizedBox(height: 16),
          // ---- ACCESSORI ----
          Text('ACCESSORI', style: eyebrowStyle()),
          const SizedBox(height: 8),
          accessoriesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Errore caricamento accessori',
                style: TextStyle(color: AppTheme.destructive, fontSize: 12)),
            data: (accessories) => accessories.isEmpty
                ? Text('Nessun accessorio disponibile',
                    style: TextStyle(color: AppTheme.muted, fontSize: 13))
                : Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: accessories
                        .map((a) => FilterChip(
                              label: Text(
                                  '${a.name} +€${a.unitPrice.toStringAsFixed(2)}'),
                              selected: _accessories.contains(a.id),
                              onSelected: (on) => setState(() {
                                if (on) {
                                  _accessories = [..._accessories, a.id];
                                } else {
                                  _accessories = _accessories
                                      .where((id) => id != a.id)
                                      .toList();
                                }
                              }),
                            ))
                        .toList(),
                  ),
          ),
          const SizedBox(height: 16),
          // ---- STIMA TOTALE ----
          insurancesAsync.maybeWhen(
            data: (insurances) => accessoriesAsync.maybeWhen(
              data: (accessories) {
                final total = _calcTotal(insurances, accessories);
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    border: Border.all(color: AppTheme.border),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Text('STIMA TOTALE', style: eyebrowStyle()),
                      const Spacer(),
                      Text(
                        '€${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ],
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving || _insuranceId == null ? null : _save,
              child: Text(_saving ? 'Salvataggio...' : 'Salva modifiche'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.value,
    required this.onTap,
  });
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Text(label,
                style: TextStyle(color: AppTheme.muted, fontSize: 13)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
            ),
            Icon(Icons.calendar_today_outlined,
                size: 16, color: AppTheme.muted),
          ],
        ),
      ),
    );
  }
}
