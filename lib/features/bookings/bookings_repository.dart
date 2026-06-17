import '../../core/api/api_client.dart';
import '../../core/models/models.dart';

class CreateBookingPayload {
  CreateBookingPayload({
    required this.retailerId,
    required this.bikeId,
    required this.bookingDate,
    required this.returnDate,
    this.insuranceId,
    this.accessories = const [],
    this.notes,
  });
  final String retailerId;
  final String bikeId;
  final DateTime bookingDate;
  final DateTime returnDate;
  final String? insuranceId;
  final List<String> accessories;
  final String? notes;

  Map<String, dynamic> toJson() => {
        'retailerId': retailerId,
        'bikeId': bikeId,
        if (insuranceId != null && insuranceId!.isNotEmpty)
          'insuranceId': insuranceId,
        'accessories': accessories,
        'bookingDate': bookingDate.toUtc().toIso8601String(),
        'returnDate': returnDate.toUtc().toIso8601String(),
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
      };
}

class BookingsRepository {
  BookingsRepository(this._api);
  final ApiClient _api;

  Future<List<Booking>> list() async {
    final res = await _api.dio.get('/bookings');
    final raw = res.data;
    final List items;
    if (raw is List) {
      items = raw;
    } else if (raw is Map<String, dynamic>) {
      // Backend wraps the list in an envelope object — try common keys
      final wrapped = raw['data'] ?? raw['bookings'] ?? raw['items'] ?? raw['content'];
      items = wrapped is List ? wrapped : [];
    } else {
      items = [];
    }
    return items
        .map((e) => Booking.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Booking> getById(String id) async {
    final res = await _api.dio.get('/bookings/$id');
    return Booking.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Booking> create(CreateBookingPayload payload) async {
    final res = await _api.dio.post('/bookings', data: payload.toJson());
    if (res.statusCode == null || res.statusCode! >= 400) {
      throw ApiException(res.statusCode, 'Creazione prenotazione fallita');
    }
    return Booking.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Booking> cancel(String id) async {
    final res = await _api.dio
        .patch('/bookings/$id', data: const {'status': 'cancelled'});
    if (res.statusCode == null || res.statusCode! >= 400) {
      throw ApiException(res.statusCode, 'Annullamento fallito');
    }
    return Booking.fromJson(res.data as Map<String, dynamic>);
  }
}
