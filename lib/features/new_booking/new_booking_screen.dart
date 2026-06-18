import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../bookings/bookings_providers.dart';
import '../bookings/bookings_repository.dart';
import '../catalog/catalog_providers.dart';
import 'booking_draft.dart';

class NewBookingScreen extends ConsumerStatefulWidget {
  const NewBookingScreen({super.key});
  @override
  ConsumerState<NewBookingScreen> createState() => _NewBookingScreenState();
}

class _NewBookingScreenState extends ConsumerState<NewBookingScreen> {
  bool _submitting = false;
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final notes = ref.read(bookingDraftProvider).notes;
    if (notes != null) _notesCtrl.text = notes;
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  int _halfDays(DateTime? s, DateTime? e) {
    if (s == null || e == null || e.isBefore(s)) return 0;
    return (e.difference(s).inDays + 1) * 2;
  }

  Bicycle? _findBike(String? id, List<Bicycle> bikes) =>
      id == null ? null : bikes.firstWhere(
            (b) => b.id == id,
            orElse: () => Bicycle(
              id: '',
              brand: '—',
              motor: false,
              unitPrice: 0,
              type: null,
              size: null,
            ),
          );

  double _itemTotal({
    required CartItem item,
    required Bicycle? bike,
    required Insurance? insurance,
    required List<Accessory> all,
    required int halfDays,
  }) {
    final bikeP = (bike?.unitPrice ?? 0) * halfDays;
    final ins = insurance?.unitPrice ?? 0;
    final acc = item.accessories.fold<double>(
      0,
      (s, id) =>
          s +
          (all.firstWhere(
            (a) => a.id == id,
            orElse: () => Accessory(id: '', name: '', unitPrice: 0),
          ).unitPrice),
    );
    return (bikeP + ins + acc) * item.quantity;
  }

  Future<void> _pickBookingDate(BookingDraft draft) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = await showDatePicker(
      context: context,
      initialDate: draft.bookingDate ?? today,
      firstDate: today,
      lastDate: DateTime(2099, 12, 31),
      locale: const Locale('it'),
    );
    if (d == null) return;
    final notif = ref.read(bookingDraftProvider.notifier);
    notif.patch(bookingDate: d);
    // Push returnDate if before
    if (draft.returnDate != null && draft.returnDate!.isBefore(d)) {
      notif.patch(returnDate: d);
    }
  }

  Future<void> _pickReturnDate(BookingDraft draft) async {
    final min = draft.bookingDate ?? DateTime.now();
    final initial = draft.returnDate != null && !draft.returnDate!.isBefore(min)
        ? draft.returnDate!
        : min;
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: min,
      lastDate: DateTime(2099, 12, 31),
      locale: const Locale('it'),
    );
    if (d == null) return;
    ref.read(bookingDraftProvider.notifier).patch(returnDate: d);
  }

  Future<void> _submit(BookingDraft draft) async {
    if (draft.retailerId == null) {
      _toast('Seleziona un punto vendita');
      return;
    }
    if (draft.bookingDate == null || draft.returnDate == null) {
      _toast('Seleziona le date');
      return;
    }
    if (draft.cart.isEmpty) {
      _toast('Aggiungi almeno una bici al carrello');
      return;
    }
    if (draft.cart.any((it) => it.insuranceId == null || it.insuranceId!.isEmpty)) {
      _toast('Seleziona un\'assicurazione per ogni bici');
      return;
    }
    setState(() => _submitting = true);
    final parts = draft.bookingTime.split(':');
    final hour = int.parse(parts[0]);
    final pickup = DateTime(
      draft.bookingDate!.year,
      draft.bookingDate!.month,
      draft.bookingDate!.day,
      hour,
    );
    final ret = DateTime(
      draft.returnDate!.year,
      draft.returnDate!.month,
      draft.returnDate!.day,
      retailerCloseHour,
    );
    final repo = ref.read(bookingsRepositoryProvider);
    final futures = <Future<Booking?>>[];
    for (final item in draft.cart) {
      for (var i = 0; i < item.quantity; i++) {
        futures.add(repo
            .create(CreateBookingPayload(
              retailerId: draft.retailerId!,
              bikeId: item.bikeId,
              insuranceId: item.insuranceId,
              accessories: item.accessories,
              bookingDate: pickup,
              returnDate: ret,
              notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
            ))
            .then<Booking?>((b) => b)
            .catchError((_) => null));
      }
    }
    final results = await Future.wait(futures);
    final succeeded = results.whereType<Booking>().toList();
    final ok = succeeded.length;
    final fail = results.length - ok;
    if (succeeded.isNotEmpty) {
      repo
          .notifyConfirmed(succeeded.map((b) => b.id).toList())
          .catchError((_) {});
    }
    if (mounted) setState(() => _submitting = false);
    if (fail == 0) {
      ref.invalidate(bookingsListProvider);
      ref.read(bookingDraftProvider.notifier).clear();
      if (mounted) {
        _toast(ok == 1
            ? 'Prenotazione creata!'
            : '$ok prenotazioni create!');
        context.go('/bookings');
      }
    } else if (ok > 0) {
      ref.invalidate(bookingsListProvider);
      _toast('$ok create, $fail fallite');
    } else {
      _toast('Errore nella creazione delle prenotazioni');
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(bookingDraftProvider);
    final notifier = ref.read(bookingDraftProvider.notifier);
    final bicycles = ref.watch(bicyclesProvider);
    final insurances = ref.watch(insurancesProvider);
    final accessories = ref.watch(accessoriesProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Nuova prenotazione'),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Builder(builder: (context) {
              final bikesList = bicycles.maybeWhen(
                  data: (l) => l, orElse: () => const <Bicycle>[]);
              final insList = insurances.maybeWhen(
                  data: (l) => l, orElse: () => const <Insurance>[]);
              final accList = accessories.maybeWhen(
                  data: (l) => l, orElse: () => const <Accessory>[]);
              final halfDays =
                  _halfDays(draft.bookingDate, draft.returnDate);
              final total = draft.cart.fold<double>(
                0,
                (s, it) => s +
                    _itemTotal(
                      item: it,
                      bike: _findBike(it.bikeId, bikesList),
                      insurance: insList.firstWhere(
                        (i) => i.id == it.insuranceId,
                        orElse: () =>
                            Insurance(id: '', name: '', unitPrice: 0),
                      ),
                      all: accList,
                      halfDays: halfDays,
                    ),
              );
              final cartCount =
                  draft.cart.fold<int>(0, (s, i) => s + i.quantity);
              return Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('STIMA TOTALE', style: eyebrowStyle()),
                        Text('€${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(120, 48),
                    ),
                    onPressed: _submitting || draft.cart.isEmpty
                        ? null
                        : () => _submit(draft),
                    icon: _submitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(_submitting
                        ? 'Invio...'
                        : (cartCount > 1
                            ? 'Conferma $cartCount'
                            : 'Conferma')),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        children: [
          _StepCard(
            n: '01',
            title: 'Modalità di ricerca',
            child: Row(
              children: [
                Expanded(
                  child: _ModeButton(
                    label: 'Per punto vendita',
                    icon: Icons.store,
                    selected: draft.mode == BookingMode.retailer,
                    onTap: () {
                      notifier.patch(mode: BookingMode.retailer);
                      notifier.selectRetailer(null);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ModeButton(
                    label: 'Bici ideale',
                    icon: Icons.tune,
                    selected: draft.mode == BookingMode.ideal,
                    onTap: () {
                      notifier.patch(mode: BookingMode.ideal);
                      notifier.selectRetailer(null);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _StepCard(
            n: '02',
            title: 'Date e ora',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _PickerField(
                        label: 'Data ritiro',
                        value: draft.bookingDate == null
                            ? null
                            : DateFormat('d MMM y', 'it_IT')
                                .format(draft.bookingDate!),
                        onTap: () => _pickBookingDate(draft),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: draft.bookingTime,
                        decoration: const InputDecoration(labelText: 'Ora'),
                        items: pickupSlots()
                            .map((s) => DropdownMenuItem(
                                value: s.value, child: Text(s.label)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) notifier.patch(bookingTime: v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _PickerField(
                  label: 'Data riconsegna',
                  value: draft.returnDate == null
                      ? null
                      : DateFormat('d MMM y', 'it_IT')
                          .format(draft.returnDate!),
                  onTap: () => _pickReturnDate(draft),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.fg.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline,
                          size: 14, color: AppTheme.muted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Punti vendita aperti 09:00-18:00. Riconsegna entro le 18:00 della data scelta.',
                          style: TextStyle(
                              color: AppTheme.muted, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Mode-specific selector
          if (draft.mode == BookingMode.retailer)
            _RetailerMode(draft: draft, notifier: notifier)
          else
            _IdealMode(draft: draft, notifier: notifier),
          const SizedBox(height: 12),
          // Current bike configuration
          if (draft.retailerId != null && draft.currentBikeId != null)
            _CurrentBikeConfig(draft: draft, notifier: notifier),
          // Cart
          if (draft.cart.isNotEmpty) ...[
            const SizedBox(height: 12),
            _CartSection(draft: draft, notifier: notifier),
          ],
          const SizedBox(height: 12),
          _StepCard(
            n: draft.cart.isNotEmpty ? '05' : '04',
            title: 'Note',
            child: TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Note opzionali per il punto vendita',
              ),
              onChanged: (v) => notifier.patch(notes: v),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ============================================================================
// Mode: Per punto vendita
// ============================================================================
class _RetailerMode extends ConsumerWidget {
  const _RetailerMode({required this.draft, required this.notifier});
  final BookingDraft draft;
  final BookingDraftController notifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final retailers = ref.watch(retailersProvider);
    final stocks = draft.retailerId == null
        ? null
        : ref.watch(retailerStocksProvider(draft.retailerId!));
    final bikes = ref.watch(bicyclesProvider);

    return _StepCard(
      n: '03',
      title: 'Punto vendita e bici',
      child: retailers.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => _NetworkError(
            message: networkErrorMessage(e),
            onRetry: () => ref.refresh(retailersProvider.future)),
        data: (rs) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: draft.retailerId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Punto vendita'),
                items: rs
                    .map((r) => DropdownMenuItem(
                          value: r.id,
                          child: Text(r.name, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (v) => notifier.selectRetailer(v),
              ),
              const SizedBox(height: 12),
              if (draft.retailerId == null)
                Text('Scegli un punto vendita per vedere le bici disponibili.',
                    style: TextStyle(color: AppTheme.muted, fontSize: 13))
              else if (stocks == null)
                const SizedBox.shrink()
              else
                stocks.when(
                  loading: () => const Center(
                      child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(),
                  )),
                  error: (e, _) => _NetworkError(
                      message: networkErrorMessage(e),
                      onRetry: () => ref.refresh(
                          retailerStocksProvider(draft.retailerId!).future)),
                  data: (stock) => _BikeGrid(
                    items: stock.bicycles,
                    catalog: bikes.maybeWhen(
                        data: (l) => l, orElse: () => const []),
                    cartUsage: draft.cartUsage,
                    selectedBikeId: draft.currentBikeId,
                    onSelect: notifier.selectBike,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================================
// Mode: Bici ideale
// ============================================================================
class _IdealMode extends ConsumerWidget {
  const _IdealMode({required this.draft, required this.notifier});
  final BookingDraft draft;
  final BookingDraftController notifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final types = ref.watch(typesProvider);
    final sizes = ref.watch(sizesProvider);
    final bikes = ref.watch(bicyclesProvider);
    final retailers = ref.watch(retailersProvider);

    return _StepCard(
      n: '03',
      title: 'Trova la tua bici ideale',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: types.maybeWhen(
                  data: (ts) => DropdownButtonFormField<String>(
                    value: draft.ideal.typeId,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Tutti')),
                      ...ts.map((t) => DropdownMenuItem(
                          value: t.id, child: Text(t.name))),
                    ],
                    onChanged: (v) => notifier.setIdeal(typeId: v),
                  ),
                  orElse: () => const _DropdownSkeleton(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: sizes.maybeWhen(
                  data: (ss) => DropdownButtonFormField<String>(
                    value: draft.ideal.sizeId,
                    decoration: const InputDecoration(labelText: 'Taglia'),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Tutte')),
                      ...ss.map((s) => DropdownMenuItem(
                          value: s.id, child: Text(s.name))),
                    ],
                    onChanged: (v) => notifier.setIdeal(sizeId: v),
                  ),
                  orElse: () => const _DropdownSkeleton(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<MotorFilter>(
            value: draft.ideal.motor,
            decoration: const InputDecoration(labelText: 'Motore'),
            items: const [
              DropdownMenuItem(
                  value: MotorFilter.any, child: Text('Indifferente')),
              DropdownMenuItem(
                  value: MotorFilter.yes, child: Text('Elettrica')),
              DropdownMenuItem(
                  value: MotorFilter.no, child: Text('Muscolare')),
            ],
            onChanged: (v) {
              if (v != null) notifier.setIdeal(motor: v);
            },
          ),
          const SizedBox(height: 14),
          Text('RISULTATI', style: eyebrowStyle()),
          const SizedBox(height: 6),
          bikes.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => _NetworkError(
                message: networkErrorMessage(e),
                onRetry: () => ref.refresh(bicyclesProvider.future)),
            data: (allBikes) {
              final f = draft.ideal;
              final matchingIds = allBikes.where((b) {
                if (f.typeId != null && b.type?.id != f.typeId) return false;
                if (f.sizeId != null && b.size?.id != f.sizeId) return false;
                if (f.motor == MotorFilter.yes && !b.motor) return false;
                if (f.motor == MotorFilter.no && b.motor) return false;
                return true;
              }).map((b) => b.id).toSet();

              return retailers.when(
                loading: () => const SizedBox(
                    height: 60,
                    child: Center(child: CircularProgressIndicator())),
                error: (e, _) => _NetworkError(
                    message: networkErrorMessage(e),
                    onRetry: () => ref.refresh(retailersProvider.future)),
                data: (rs) => Column(
                  children: rs
                      .map((r) => _IdealRetailerCard(
                            retailer: r,
                            matchingIds: matchingIds,
                            allBikes: allBikes,
                            draft: draft,
                            notifier: notifier,
                          ))
                      .toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _IdealRetailerCard extends ConsumerWidget {
  const _IdealRetailerCard({
    required this.retailer,
    required this.matchingIds,
    required this.allBikes,
    required this.draft,
    required this.notifier,
  });
  final Retailer retailer;
  final Set<String> matchingIds;
  final List<Bicycle> allBikes;
  final BookingDraft draft;
  final BookingDraftController notifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stocks = ref.watch(retailerStocksProvider(retailer.id));
    return stocks.maybeWhen(
      data: (stock) {
        var items = stock.bicycles
            .where((s) => s.quantity > 0 && matchingIds.contains(s.bicycle.id))
            .toList();
        // Apply cart deduction only when this retailer is the active one
        final isActive = draft.retailerId == retailer.id;
        if (isActive) {
          items = items
              .map((it) => StockItem(
                    bicycle: it.bicycle,
                    quantity:
                        (it.quantity - draft.cartUsage(it.bicycle.id))
                            .clamp(0, 999999),
                  ))
              .where((it) => it.quantity > 0)
              .toList();
        }
        if (items.isEmpty) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(
                color: isActive ? AppTheme.fg : AppTheme.border,
                width: isActive ? 1.5 : 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () =>
                    notifier.selectRetailer(isActive ? null : retailer.id),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(retailer.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700)),
                          if (retailer.city != null)
                            Text(retailer.city!,
                                style: TextStyle(
                                    color: AppTheme.muted, fontSize: 12)),
                        ],
                      ),
                    ),
                    Text('${items.length} bici',
                        style: TextStyle(
                            color: AppTheme.muted,
                            fontSize: 11,
                            letterSpacing: 1.2)),
                    Icon(
                        isActive
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: AppTheme.muted),
                  ],
                ),
              ),
              if (isActive) ...[
                const SizedBox(height: 10),
                _BikeGrid(
                  items: items,
                  catalog: allBikes,
                  cartUsage: draft.cartUsage,
                  selectedBikeId: draft.currentBikeId,
                  onSelect: notifier.selectBike,
                  alreadyAdjusted: true,
                ),
              ],
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

// ============================================================================
// Bike grid (per-retailer)
// ============================================================================
class _BikeGrid extends StatelessWidget {
  const _BikeGrid({
    required this.items,
    required this.catalog,
    required this.cartUsage,
    required this.selectedBikeId,
    required this.onSelect,
    this.alreadyAdjusted = false,
  });
  final List<StockItem> items;
  final List<Bicycle> catalog;
  final int Function(String bikeId) cartUsage;
  final String? selectedBikeId;
  final void Function(String?) onSelect;
  final bool alreadyAdjusted;

  Bicycle _enrich(Bicycle stockBike) {
    final full = catalog.firstWhere(
      (b) => b.id == stockBike.id,
      orElse: () => stockBike,
    );
    // stocks API doesn't include unitPrice — take it from catalog
    return Bicycle(
      id: stockBike.id,
      brand: stockBike.brand,
      motor: stockBike.motor,
      unitPrice: full.unitPrice,
      type: stockBike.type ?? full.type,
      size: stockBike.size ?? full.size,
    );
  }

  @override
  Widget build(BuildContext context) {
    // sort: type → brand → size
    final enriched = items.map((it) {
      final adjusted = alreadyAdjusted
          ? it.quantity
          : (it.quantity - cartUsage(it.bicycle.id)).clamp(0, 999999);
      return (
        bicycle: _enrich(it.bicycle),
        quantity: adjusted,
      );
    }).where((x) => x.quantity > 0).toList()
      ..sort((a, b) {
        final t = (a.bicycle.type?.name ?? '')
            .compareTo(b.bicycle.type?.name ?? '');
        if (t != 0) return t;
        final br = a.bicycle.brand.compareTo(b.bicycle.brand);
        if (br != 0) return br;
        return (a.bicycle.size?.name ?? '')
            .compareTo(b.bicycle.size?.name ?? '');
      });

    final selected = enriched.firstWhere(
      (e) => e.bicycle.id == selectedBikeId,
      orElse: () => (
        bicycle: Bicycle(
            id: '', brand: '', motor: false, unitPrice: 0, type: null, size: null),
        quantity: 0, 
      ),
    );

    if (selected.bicycle.id.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.fg),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      (selected.bicycle.type?.name ?? 'BICI').toUpperCase(),
                      style: eyebrowStyle()),
                  const SizedBox(height: 2),
                  Text(
                    '${selected.bicycle.brand} · Taglia ${selected.bicycle.size?.name ?? '—'}'
                    '${selected.bicycle.motor ? ' · E-Bike' : ''}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '€${selected.bicycle.unitPrice.toStringAsFixed(2)} / mezza giornata · ${selected.quantity} disp.',
                    style: TextStyle(color: AppTheme.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () => onSelect(null),
              icon: const Icon(Icons.edit, size: 14),
              label: const Text('Cambia'),
            ),
          ],
        ),
      );
    }

    if (enriched.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text('Nessuna bici disponibile',
              style: TextStyle(color: AppTheme.muted, fontSize: 13)),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: enriched.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.4,
      ),
      itemBuilder: (ctx, i) {
        final e = enriched[i];
        return InkWell(
          onTap: () => onSelect(e.bicycle.id),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.border),
              borderRadius: BorderRadius.circular(10),
              color: AppTheme.surface,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                          (e.bicycle.type?.name ?? 'BICI').toUpperCase(),
                          style: eyebrowStyle(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (e.bicycle.motor)
                      Icon(Icons.bolt,
                          size: 14, color: AppTheme.amber),
                  ],
                ),
                const SizedBox(height: 2),
                Text(e.bicycle.brand,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                Text('Taglia ${e.bicycle.size?.name ?? '—'}',
                    style: TextStyle(color: AppTheme.muted, fontSize: 12)),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                          '€${e.bicycle.unitPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 13)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.border),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text('x${e.quantity}',
                          style: TextStyle(
                              color: AppTheme.muted,
                              fontSize: 10,
                              letterSpacing: 1.2)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// Current bike configuration
// ============================================================================
class _CurrentBikeConfig extends ConsumerWidget {
  const _CurrentBikeConfig({required this.draft, required this.notifier});
  final BookingDraft draft;
  final BookingDraftController notifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insurances = ref.watch(insurancesProvider);
    final accessories = ref.watch(accessoriesProvider);
    final stocks = ref.watch(retailerStocksProvider(draft.retailerId!));

    final maxQty = stocks.maybeWhen(
      data: (s) {
        final stockQ = s.bicycles
            .firstWhere(
              (it) => it.bicycle.id == draft.currentBikeId,
              orElse: () => StockItem(
                  bicycle: Bicycle(
                      id: '',
                      brand: '',
                      motor: false,
                      unitPrice: 0,
                      type: null,
                      size: null),
                  quantity: 0),
            )
            .quantity;
        return (stockQ - draft.cartUsage(draft.currentBikeId!))
            .clamp(0, 999999);
      },
      orElse: () => 1,
    );

    return _StepCard(
      n: '03b',
      title: 'Configura questa bici',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          insurances.maybeWhen(
            data: (list) {
              final effectiveId = draft.currentInsuranceId ??
                  (list.isNotEmpty ? list.first.id : null);
              if (effectiveId != null && draft.currentInsuranceId == null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  notifier.patch(currentInsuranceId: effectiveId);
                });
              }
              return DropdownButtonFormField<String>(
                value: effectiveId,
                decoration:
                    const InputDecoration(labelText: 'Assicurazione'),
                isExpanded: true,
                items: list
                    .map((i) => DropdownMenuItem(
                          value: i.id,
                          child: Text(
                              '${i.name} · €${i.unitPrice.toStringAsFixed(2)}',
                              overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) notifier.patch(currentInsuranceId: v);
                },
              );
            },
            orElse: () => const _DropdownSkeleton(),
          ),
          const SizedBox(height: 12),
          Text('ACCESSORI (OPZIONALI)', style: eyebrowStyle()),
          const SizedBox(height: 6),
          accessories.maybeWhen(
            data: (list) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: list.map((a) {
                final checked = draft.currentAccessories.contains(a.id);
                return FilterChip(
                  label: Text(
                      '${a.name} · €${a.unitPrice.toStringAsFixed(2)}'),
                  selected: checked,
                  onSelected: (_) => notifier.toggleCurrentAccessory(a.id),
                );
              }).toList(),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('QUANTITÀ (MAX $maxQty)', style: eyebrowStyle()),
                    const SizedBox(height: 4),
                    _QtyStepper(
                      value: draft.currentQuantity,
                      min: 1,
                      max: maxQty,
                      onChanged: (v) =>
                          notifier.patch(currentQuantity: v),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(120, 48),
                ),
                onPressed: maxQty < 1 ||
                        draft.bookingDate == null ||
                        draft.returnDate == null
                    ? null
                    : notifier.addCurrentToCart,
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Aggiungi'),
              ),
            ],
          ),
          if (draft.bookingDate == null || draft.returnDate == null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Imposta prima le date per poter aggiungere la bici.',
                style: TextStyle(color: AppTheme.muted, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// Cart
// ============================================================================
class _CartSection extends ConsumerWidget {
  const _CartSection({required this.draft, required this.notifier});
  final BookingDraft draft;
  final BookingDraftController notifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bikes = ref.watch(bicyclesProvider);
    final insurances = ref.watch(insurancesProvider);
    final accessories = ref.watch(accessoriesProvider);
    final stocks = draft.retailerId == null
        ? null
        : ref.watch(retailerStocksProvider(draft.retailerId!));

    int stockOf(String id) {
      return stocks?.maybeWhen(
            data: (s) => s.bicycles
                .firstWhere(
                  (it) => it.bicycle.id == id,
                  orElse: () => StockItem(
                      bicycle: Bicycle(
                          id: '',
                          brand: '',
                          motor: false,
                          unitPrice: 0,
                          type: null,
                          size: null),
                      quantity: 0),
                )
                .quantity,
            orElse: () => 0,
          ) ??
          0;
    }

    return _StepCard(
      n: '04',
      title: 'Carrello (${draft.cart.length})',
      child: Column(
        children: draft.cart.map((it) {
          final bike = bikes.maybeWhen(
              data: (b) => b.firstWhere((x) => x.id == it.bikeId,
                  orElse: () => Bicycle(
                      id: '',
                      brand: '—',
                      motor: false,
                      unitPrice: 0,
                      type: null,
                      size: null)),
              orElse: () => Bicycle(
                  id: '',
                  brand: '—',
                  motor: false,
                  unitPrice: 0,
                  type: null,
                  size: null));
          final ins = insurances.maybeWhen(
              data: (l) => l.firstWhere((i) => i.id == it.insuranceId,
                  orElse: () =>
                      Insurance(id: '', name: 'Nessuna', unitPrice: 0)),
              orElse: () =>
                  Insurance(id: '', name: 'Nessuna', unitPrice: 0));
          final accs = accessories.maybeWhen(
              data: (l) => l.where((a) => it.accessories.contains(a.id)).toList(),
              orElse: () => const <Accessory>[]);
          final maxQ = stockOf(it.bikeId) -
              draft.cartUsage(it.bikeId) +
              it.quantity;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              (bike.type?.name ?? 'BICI').toUpperCase(),
                              style: eyebrowStyle()),
                          Text(
                              '${bike.brand} · Taglia ${bike.size?.name ?? '—'}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700)),
                          Text(ins.name,
                              style: TextStyle(
                                  color: AppTheme.muted, fontSize: 12)),
                          if (accs.isNotEmpty)
                            Text(accs.map((a) => a.name).join(', '),
                                style: TextStyle(
                                    color: AppTheme.muted, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => notifier.removeCartItem(it.uid),
                      icon: Icon(Icons.delete_outline,
                          color: AppTheme.destructive, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _QtyStepper(
                      value: it.quantity,
                      min: 1,
                      max: maxQ,
                      dense: true,
                      onChanged: (v) =>
                          notifier.updateCartItem(it.uid, quantity: v),
                    ),
                    Text(
                      _formatTot(it, bike, ins, accs, draft),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatTot(CartItem it, Bicycle bike, Insurance ins,
      List<Accessory> accs, BookingDraft draft) {
    final s = draft.bookingDate;
    final e = draft.returnDate;
    if (s == null || e == null) return '—';
    final days = (e.difference(s).inSeconds / 86400).ceil().clamp(1, 9999);
    final half = days * 2;
    final bp = bike.unitPrice * half;
    final ip = ins.unitPrice;
    final ap = accs.fold<double>(0, (s, a) => s + a.unitPrice);
    final tot = (bp + ip + ap) * it.quantity;
    return '€${tot.toStringAsFixed(2)}';
  }
}

// ============================================================================
// Reusable bits
// ============================================================================
class _StepCard extends StatelessWidget {
  const _StepCard({required this.n, required this.title, required this.child});
  final String n;
  final String title;
  final Widget child;
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.fg.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('STEP $n', style: eyebrowStyle()),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField(
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
        decoration: InputDecoration(labelText: label),
        child: Text(value ?? 'Scegli',
            style: TextStyle(
              color: value == null ? AppTheme.muted : AppTheme.fg,
              fontSize: 14,
            )),
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.dense = false,
  });
  final int value;
  final int min;
  final int max;
  final void Function(int) onChanged;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final s = dense ? 28.0 : 32.0;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: value > min ? () => onChanged(value - 1) : null,
            child: SizedBox(
              width: s,
              height: s,
              child: Icon(Icons.remove,
                  size: 16,
                  color: value > min ? AppTheme.fg : AppTheme.border),
            ),
          ),
          SizedBox(
            width: 28,
            child: Center(
              child: Text('$value',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ),
          InkWell(
            onTap: value < max ? () => onChanged(value + 1) : null,
            child: SizedBox(
              width: s,
              height: s,
              child: Icon(Icons.add,
                  size: 16,
                  color: value < max ? AppTheme.fg : AppTheme.border),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppTheme.fg : AppTheme.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border:
                Border.all(color: selected ? AppTheme.fg : AppTheme.border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: selected ? Colors.white : AppTheme.muted),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppTheme.fg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DropdownSkeleton extends StatelessWidget {
  const _DropdownSkeleton();
  @override
  Widget build(BuildContext context) => Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppTheme.fg.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
      );
}

class _NetworkError extends StatelessWidget {
  const _NetworkError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_outlined, size: 32, color: AppTheme.muted),
          const SizedBox(height: 8),
          Text(message,
              style: TextStyle(color: AppTheme.muted, fontSize: 13),
              textAlign: TextAlign.center),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Riprova'),
          ),
        ],
      ),
    );
  }
}
