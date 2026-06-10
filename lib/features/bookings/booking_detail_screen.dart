import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import 'booking_status.dart';
import 'bookings_providers.dart';

class BookingDetailScreen extends ConsumerStatefulWidget {
  const BookingDetailScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends ConsumerState<BookingDetailScreen> {
  bool _cancelling = false;

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
          final canCancel = b.status == 'pending' &&
              b.bookingDate.difference(DateTime.now()).inHours >= 48;
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
