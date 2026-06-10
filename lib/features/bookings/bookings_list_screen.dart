import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_controller.dart';
import 'booking_status.dart';
import 'bookings_providers.dart';

class BookingsListScreen extends ConsumerStatefulWidget {
  const BookingsListScreen({super.key});
  @override
  ConsumerState<BookingsListScreen> createState() => _BookingsListScreenState();
}

class _BookingsListScreenState extends ConsumerState<BookingsListScreen> {
  final Set<String> _statuses = {};
  DateTime? _from;
  DateTime? _to;

  void _toggle(String s) {
    setState(() {
      if (_statuses.contains(s)) {
        _statuses.remove(s);
      } else {
        _statuses.add(s);
      }
    });
  }

  Future<void> _pickFrom() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _from ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5),
      locale: const Locale('it'),
    );
    if (d != null) setState(() => _from = d);
  }

  Future<void> _pickTo() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _to ?? now,
      firstDate: _from ?? DateTime(2020),
      lastDate: DateTime(now.year + 5),
      locale: const Locale('it'),
    );
    if (d != null) setState(() => _to = d);
  }

  bool _matches(Booking b) {
    if (_statuses.isNotEmpty && !_statuses.contains(b.status)) return false;
    final bd = b.bookingDate;
    if (_from != null && bd.isBefore(DateTime(_from!.year, _from!.month, _from!.day))) {
      return false;
    }
    if (_to != null) {
      final endOfDay = DateTime(_to!.year, _to!.month, _to!.day, 23, 59, 59);
      if (bd.isAfter(endOfDay)) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(bookingsListProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Le mie prenotazioni'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Esci',
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();
              if (mounted) context.go('/login');
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/bookings/new'),
        icon: const Icon(Icons.add),
        label: const Text('Nuova'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(bookingsListProvider.future),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Errore nel caricamento: $e',
                  style: TextStyle(color: AppTheme.destructive)),
            ),
          ]),
          data: (bookings) {
            final filtered = bookings.where(_matches).toList();
            final now = DateTime.now();
            bool isPast(Booking b) =>
                b.status != 'pending' &&
                b.bookingDate.isBefore(now) &&
                b.returnDate.isBefore(now);
            final current = filtered.where((b) => !isPast(b)).toList()
              ..sort((a, b) => a.bookingDate.compareTo(b.bookingDate));
            final past = filtered.where(isPast).toList()
              ..sort((a, b) => b.bookingDate.compareTo(a.bookingDate));

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              children: [
                _Filters(
                  statuses: _statuses,
                  onToggle: _toggle,
                  from: _from,
                  to: _to,
                  onPickFrom: _pickFrom,
                  onPickTo: _pickTo,
                  onReset: () {
                    setState(() {
                      _statuses.clear();
                      _from = null;
                      _to = null;
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (bookings.isEmpty)
                  _EmptyState(
                    title: 'Non hai ancora nessuna prenotazione',
                    cta: 'Prenota una bici',
                    onTap: () => context.push('/bookings/new'),
                  )
                else if (filtered.isEmpty)
                  _EmptyState(
                    title: 'Nessuna prenotazione corrisponde ai filtri',
                    cta: 'Reset filtri',
                    onTap: () => setState(() {
                      _statuses.clear();
                      _from = null;
                      _to = null;
                    }),
                  )
                else ...[
                  if (current.isNotEmpty) ...[
                    _SectionHeader(
                      eyebrow: 'IN CORSO E FUTURE',
                      title: 'Le tue prenotazioni',
                      count: current.length,
                    ),
                    const SizedBox(height: 8),
                    ...current.map((b) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _BookingCard(booking: b),
                        )),
                  ],
                  if (past.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _SectionHeader(
                      eyebrow: 'ARCHIVIO',
                      title: 'Passate',
                      count: past.length,
                    ),
                    const SizedBox(height: 8),
                    ...past.map((b) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _BookingCard(booking: b, dim: true),
                        )),
                  ],
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.statuses,
    required this.onToggle,
    required this.from,
    required this.to,
    required this.onPickFrom,
    required this.onPickTo,
    required this.onReset,
  });
  final Set<String> statuses;
  final void Function(String) onToggle;
  final DateTime? from;
  final DateTime? to;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy', 'it_IT');
    final hasFilters = statuses.isNotEmpty || from != null || to != null;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('STATO', style: eyebrowStyle()),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: bookingStatusFilters.map((s) {
              final active = statuses.contains(s);
              return GestureDetector(
                onTap: () => onToggle(s),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: active ? AppTheme.fg : AppTheme.surface,
                    border: Border.all(
                        color: active ? AppTheme.fg : AppTheme.border),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    (bookingStatusLabel[s] ?? s).toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: active ? Colors.white : AppTheme.muted,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DateField(
                  label: 'DAL',
                  value: from == null ? null : df.format(from!),
                  onTap: onPickFrom,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DateField(
                  label: 'AL',
                  value: to == null ? null : df.format(to!),
                  onTap: onPickTo,
                ),
              ),
              if (hasFilters)
                IconButton(
                  onPressed: onReset,
                  icon: const Icon(Icons.refresh, size: 18),
                  tooltip: 'Reset',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField(
      {required this.label, required this.value, required this.onTap});
  final String label;
  final String? value;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        child: Text(
          value ?? 'gg/mm/aaaa',
          style: TextStyle(
            color: value == null ? AppTheme.muted : AppTheme.fg,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.eyebrow,
    required this.title,
    required this.count,
  });
  final String eyebrow;
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(eyebrow, style: eyebrowStyle()),
              const SizedBox(height: 2),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 18)),
            ],
          ),
        ),
        Text(
          '$count ${count == 1 ? 'prenotazione' : 'prenotazioni'}',
          style: TextStyle(
              color: AppTheme.muted, fontSize: 11, letterSpacing: 1.2),
        ),
      ],
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, this.dim = false});
  final Booking booking;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('d MMM', 'it_IT');
    final color = bookingStatusColor(booking.status);
    return Opacity(
      opacity: dim ? 0.85 : 1,
      child: Material(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.push('/bookings/${booking.id}'),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Text(
                        labelFor(booking.status).toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: color,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '€${booking.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${booking.bicycle.type?.name ?? 'Bici'} · ${booking.bicycle.brand}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  'Taglia ${booking.bicycle.size?.name ?? '—'}'
                  '${booking.bicycle.motor ? ' · E-Bike' : ''}',
                  style: TextStyle(color: AppTheme.muted, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 14, color: AppTheme.muted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        booking.retailer.name,
                        style: TextStyle(color: AppTheme.muted, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 14, color: AppTheme.muted),
                    const SizedBox(width: 4),
                    Text(
                      '${df.format(booking.bookingDate)} → ${df.format(booking.returnDate)}',
                      style: TextStyle(color: AppTheme.muted, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.cta, required this.onTap});
  final String title;
  final String cta;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, color: AppTheme.muted, size: 36),
          const SizedBox(height: 12),
          Text(title,
              style: TextStyle(color: AppTheme.muted, fontSize: 14),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onTap, child: Text(cta)),
        ],
      ),
    );
  }
}
