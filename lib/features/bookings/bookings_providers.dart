import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../core/providers.dart';
import 'bookings_repository.dart';

final bookingsRepositoryProvider = Provider<BookingsRepository>((ref) {
  return BookingsRepository(ref.watch(apiClientProvider));
});

final bookingsListProvider = FutureProvider<List<Booking>>((ref) async {
  return ref.watch(bookingsRepositoryProvider).list();
});

final bookingDetailProvider =
    FutureProvider.family<Booking, String>((ref, id) async {
  return ref.watch(bookingsRepositoryProvider).getById(id);
});
