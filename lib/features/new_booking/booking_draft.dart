import 'package:flutter_riverpod/flutter_riverpod.dart';

enum BookingMode { retailer, ideal }

enum MotorFilter { any, yes, no }

class IdealFilters {
  const IdealFilters({
    this.typeId,
    this.sizeId,
    this.motor = MotorFilter.any,
    this.priceMin,
    this.priceMax,
  });
  final String? typeId;
  final String? sizeId;
  final MotorFilter motor;
  final double? priceMin;
  final double? priceMax;

  IdealFilters copyWith({
    Object? typeId = _sentinel,
    Object? sizeId = _sentinel,
    MotorFilter? motor,
    Object? priceMin = _sentinel,
    Object? priceMax = _sentinel,
  }) =>
      IdealFilters(
        typeId: identical(typeId, _sentinel) ? this.typeId : typeId as String?,
        sizeId: identical(sizeId, _sentinel) ? this.sizeId : sizeId as String?,
        motor: motor ?? this.motor,
        priceMin: identical(priceMin, _sentinel)
            ? this.priceMin
            : priceMin as double?,
        priceMax: identical(priceMax, _sentinel)
            ? this.priceMax
            : priceMax as double?,
      );
}

const _sentinel = Object();

class CartItem {
  CartItem({
    required this.uid,
    required this.bikeId,
    this.insuranceId,
    this.accessories = const [],
    this.quantity = 1,
  });
  final String uid;
  final String bikeId;
  final String? insuranceId;
  final List<String> accessories;
  final int quantity;

  CartItem copyWith({
    String? insuranceId,
    List<String>? accessories,
    int? quantity,
  }) =>
      CartItem(
        uid: uid,
        bikeId: bikeId,
        insuranceId: insuranceId ?? this.insuranceId,
        accessories: accessories ?? this.accessories,
        quantity: quantity ?? this.quantity,
      );
}

class BookingDraft {
  const BookingDraft({
    this.mode = BookingMode.retailer,
    this.retailerId,
    this.bookingDate,
    this.bookingTime = '09:00',
    this.returnDate,
    this.notes,
    this.ideal = const IdealFilters(),
    this.currentBikeId,
    this.currentInsuranceId,
    this.currentAccessories = const [],
    this.currentQuantity = 1,
    this.cart = const [],
  });
  final BookingMode mode;
  final String? retailerId;
  final DateTime? bookingDate;
  final String bookingTime;
  final DateTime? returnDate;
  final String? notes;
  final IdealFilters ideal;
  final String? currentBikeId;
  final String? currentInsuranceId;
  final List<String> currentAccessories;
  final int currentQuantity;
  final List<CartItem> cart;

  BookingDraft copyWith({
    BookingMode? mode,
    Object? retailerId = _sentinel,
    Object? bookingDate = _sentinel,
    String? bookingTime,
    Object? returnDate = _sentinel,
    Object? notes = _sentinel,
    IdealFilters? ideal,
    Object? currentBikeId = _sentinel,
    Object? currentInsuranceId = _sentinel,
    List<String>? currentAccessories,
    int? currentQuantity,
    List<CartItem>? cart,
  }) =>
      BookingDraft(
        mode: mode ?? this.mode,
        retailerId: identical(retailerId, _sentinel)
            ? this.retailerId
            : retailerId as String?,
        bookingDate: identical(bookingDate, _sentinel)
            ? this.bookingDate
            : bookingDate as DateTime?,
        bookingTime: bookingTime ?? this.bookingTime,
        returnDate: identical(returnDate, _sentinel)
            ? this.returnDate
            : returnDate as DateTime?,
        notes: identical(notes, _sentinel) ? this.notes : notes as String?,
        ideal: ideal ?? this.ideal,
        currentBikeId: identical(currentBikeId, _sentinel)
            ? this.currentBikeId
            : currentBikeId as String?,
        currentInsuranceId: identical(currentInsuranceId, _sentinel)
            ? this.currentInsuranceId
            : currentInsuranceId as String?,
        currentAccessories: currentAccessories ?? this.currentAccessories,
        currentQuantity: currentQuantity ?? this.currentQuantity,
        cart: cart ?? this.cart,
      );

  /// Sum of quantities of `bikeId` already in the cart.
  int cartUsage(String bikeId) =>
      cart.where((i) => i.bikeId == bikeId).fold(0, (s, i) => s + i.quantity);
}

class BookingDraftController extends StateNotifier<BookingDraft> {
  BookingDraftController() : super(const BookingDraft());

  void patch({
    BookingMode? mode,
    Object? retailerId = _sentinel,
    Object? bookingDate = _sentinel,
    String? bookingTime,
    Object? returnDate = _sentinel,
    Object? notes = _sentinel,
    IdealFilters? ideal,
    Object? currentBikeId = _sentinel,
    Object? currentInsuranceId = _sentinel,
    List<String>? currentAccessories,
    int? currentQuantity,
    List<CartItem>? cart,
  }) {
    state = state.copyWith(
      mode: mode,
      retailerId: retailerId,
      bookingDate: bookingDate,
      bookingTime: bookingTime,
      returnDate: returnDate,
      notes: notes,
      ideal: ideal,
      currentBikeId: currentBikeId,
      currentInsuranceId: currentInsuranceId,
      currentAccessories: currentAccessories,
      currentQuantity: currentQuantity,
      cart: cart,
    );
  }

  void setIdeal({
    Object? typeId = _sentinel,
    Object? sizeId = _sentinel,
    MotorFilter? motor,
    Object? priceMin = _sentinel,
    Object? priceMax = _sentinel,
  }) {
    state = state.copyWith(
      ideal: state.ideal.copyWith(
        typeId: typeId,
        sizeId: sizeId,
        motor: motor,
        priceMin: priceMin,
        priceMax: priceMax,
      ),
    );
  }

  void selectRetailer(String? id) {
    state = state.copyWith(
      retailerId: id,
      cart: const [],
      currentBikeId: null,
      currentInsuranceId: null,
      currentAccessories: const [],
      currentQuantity: 1,
    );
  }

  void selectBike(String? id) {
    state = state.copyWith(
      currentBikeId: id,
      currentInsuranceId: null,
      currentAccessories: const [],
      currentQuantity: 1,
    );
  }

  void toggleCurrentAccessory(String id) {
    final acc = [...state.currentAccessories];
    if (acc.contains(id)) {
      acc.remove(id);
    } else {
      acc.add(id);
    }
    state = state.copyWith(currentAccessories: acc);
  }

  void resetCurrent() {
    state = state.copyWith(
      currentBikeId: null,
      currentInsuranceId: null,
      currentAccessories: const [],
      currentQuantity: 1,
    );
  }

  void addCurrentToCart() {
    final s = state;
    final bikeId = s.currentBikeId;
    if (bikeId == null) return;
    final uid = 'c${DateTime.now().millisecondsSinceEpoch}';
    final item = CartItem(
      uid: uid,
      bikeId: bikeId,
      insuranceId: s.currentInsuranceId,
      accessories: List.from(s.currentAccessories),
      quantity: s.currentQuantity < 1 ? 1 : s.currentQuantity,
    );
    state = s.copyWith(
      cart: [...s.cart, item],
      currentBikeId: null,
      currentInsuranceId: null,
      currentAccessories: const [],
      currentQuantity: 1,
    );
  }

  void updateCartItem(String uid,
      {int? quantity, String? insuranceId, List<String>? accessories}) {
    state = state.copyWith(
      cart: state.cart
          .map((it) => it.uid == uid
              ? it.copyWith(
                  quantity: quantity,
                  insuranceId: insuranceId,
                  accessories: accessories,
                )
              : it)
          .toList(),
    );
  }

  void removeCartItem(String uid) {
    state = state.copyWith(
        cart: state.cart.where((it) => it.uid != uid).toList());
  }

  void clear() => state = const BookingDraft();
}

final bookingDraftProvider =
    StateNotifierProvider<BookingDraftController, BookingDraft>(
        (ref) => BookingDraftController());

/// Pickup slot ranges. Stored value = start hour HH:00.
const retailerOpenHour = 9;
const retailerCloseHour = 18;

List<({String value, String label})> pickupSlots() {
  final list = <({String value, String label})>[];
  for (var h = retailerOpenHour; h < retailerCloseHour; h++) {
    final start = h.toString().padLeft(2, '0');
    final end = (h + 1).toString().padLeft(2, '0');
    list.add((value: '$start:00', label: '$start:00 - $end:00'));
  }
  return list;
}

String pickupSlotLabel(String time) {
  final s = pickupSlots().firstWhere(
    (s) => s.value == time,
    orElse: () => (value: time, label: time),
  );
  return s.label;
}
