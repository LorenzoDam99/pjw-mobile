/// Plain Dart models matching the BE response shapes.
/// Manual fromJson to skip codegen — fewer moving parts for a fast build.
library;

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

class User {
  User({
    required this.id,
    required this.email,
    this.username = '',
    this.firstName = '',
    this.lastName = '',
    this.fullName = '',
    this.role = 'user',
    this.retailerId,
  });
  final String id;
  final String email;
  final String username;
  final String firstName;
  final String lastName;
  final String fullName;
  final String role;
  final String? retailerId;

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: j['id'] as String? ?? '',
        email: j['email'] as String? ?? '',
        username: j['username'] as String? ?? '',
        firstName: j['firstName'] as String? ?? '',
        lastName: j['lastName'] as String? ?? '',
        fullName: j['fullName'] as String? ?? '',
        role: j['role'] as String? ?? 'user',
        retailerId: j['retailerId'] as String?,
      );
}

class BicType {
  BicType({required this.id, required this.name});
  final String id;
  final String name;
  factory BicType.fromJson(Map<String, dynamic> j) =>
      BicType(id: j['id'] as String? ?? '', name: j['name'] as String? ?? '');
}

class BicSize {
  BicSize({required this.id, required this.name});
  final String id;
  final String name;
  factory BicSize.fromJson(Map<String, dynamic> j) =>
      BicSize(id: j['id'] as String? ?? '', name: j['name'] as String? ?? '');
}

class Bicycle {
  Bicycle({
    required this.id,
    required this.brand,
    required this.motor,
    required this.unitPrice,
    required this.type,
    required this.size,
    this.notes,
  });
  final String id;
  final String brand;
  final bool motor;
  final double unitPrice;
  final BicType? type;
  final BicSize? size;
  final String? notes;

  factory Bicycle.fromJson(Map<String, dynamic> j) => Bicycle(
        id: j['id'] as String? ?? '',
        brand: j['brand'] as String? ?? '',
        motor: j['motor'] as bool? ?? false,
        unitPrice: _toDouble(j['unitPrice']),
        type: j['type'] is Map<String, dynamic>
            ? BicType.fromJson(j['type'] as Map<String, dynamic>)
            : null,
        size: j['size'] is Map<String, dynamic>
            ? BicSize.fromJson(j['size'] as Map<String, dynamic>)
            : null,
        notes: j['notes'] as String?,
      );
}

class Accessory {
  Accessory({required this.id, required this.name, required this.unitPrice});
  final String id;
  final String name;
  final double unitPrice;
  factory Accessory.fromJson(Map<String, dynamic> j) => Accessory(
        id: j['id'] as String? ?? '',
        name: j['name'] as String? ?? '',
        unitPrice: _toDouble(j['unitPrice']),
      );
}

class Insurance {
  Insurance({
    required this.id,
    required this.name,
    required this.unitPrice,
    this.description = '',
  });
  final String id;
  final String name;
  final double unitPrice;
  final String description;
  factory Insurance.fromJson(Map<String, dynamic> j) => Insurance(
        id: j['id'] as String? ?? '',
        name: j['name'] as String? ?? '',
        unitPrice: _toDouble(j['unitPrice']),
        description: j['description'] as String? ?? '',
      );
}

class Retailer {
  Retailer({
    required this.id,
    required this.name,
    this.address,
    this.city,
    this.email,
    this.phoneNumber,
    this.latitude,
    this.longitude,
    this.disabled = false,
  });
  final String id;
  final String name;
  final String? address;
  final String? city;
  final String? email;
  final String? phoneNumber;
  final double? latitude;
  final double? longitude;
  final bool disabled;

  factory Retailer.fromJson(Map<String, dynamic> j) => Retailer(
        id: j['id'] as String? ?? '',
        name: j['name'] as String? ?? '',
        address: j['address'] as String?,
        city: j['city'] as String?,
        email: j['email'] as String?,
        phoneNumber: j['phoneNumber'] as String?,
        latitude: (j['latitude'] as num?)?.toDouble(),
        longitude: (j['longitude'] as num?)?.toDouble(),
        disabled: j['disabled'] as bool? ?? false,
      );
}

class StockItem {
  StockItem({required this.bicycle, required this.quantity});
  final Bicycle bicycle;
  final int quantity;
  factory StockItem.fromJson(Map<String, dynamic> j) => StockItem(
        bicycle: Bicycle.fromJson(j['bicycle'] as Map<String, dynamic>),
        quantity: _toInt(j['quantity']),
      );
}

class RetailerStock {
  RetailerStock({required this.retailer, required this.bicycles});
  final Retailer retailer;
  final List<StockItem> bicycles;
  factory RetailerStock.fromJson(Map<String, dynamic> j) => RetailerStock(
        retailer: Retailer.fromJson(j),
        bicycles: ((j['bicycles'] as List?) ?? [])
            .map((e) => StockItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class Booking {
  Booking({
    required this.id,
    required this.status,
    required this.bookingDate,
    required this.returnDate,
    required this.totalPrice,
    required this.bicycle,
    required this.retailer,
    this.user,
    this.insurance,
    this.accessories = const [],
    this.notes,
  });
  final String id;
  final String status;
  final DateTime bookingDate;
  final DateTime returnDate;
  final double totalPrice;
  final Bicycle bicycle;
  final Retailer retailer;
  final User? user;
  final Insurance? insurance;
  final List<Accessory> accessories;
  final String? notes;

  factory Booking.fromJson(Map<String, dynamic> j) => Booking(
        id: j['id'] as String? ?? '',
        status: j['status'] as String? ?? 'pending',
        bookingDate: DateTime.parse(j['bookingDate'] as String),
        returnDate: DateTime.parse(j['returnDate'] as String),
        totalPrice: _toDouble(j['totalPrice']),
        // BE may return either `bicycle` or `bicycles` (singular field, single object)
        bicycle: Bicycle.fromJson(
          ((j['bicycles'] ?? j['bicycle']) as Map<String, dynamic>?) ??
              const {},
        ),
        retailer: Retailer.fromJson(
            (j['retailer'] as Map<String, dynamic>?) ?? const {}),
        user: j['user'] is Map<String, dynamic>
            ? User.fromJson(j['user'] as Map<String, dynamic>)
            : null,
        insurance: j['insurance'] is Map<String, dynamic>
            ? Insurance.fromJson(j['insurance'] as Map<String, dynamic>)
            : null,
        accessories: ((j['accessories'] as List?) ?? [])
            .map((e) => Accessory.fromJson(e as Map<String, dynamic>))
            .toList(),
        notes: j['notes'] as String?,
      );
}
