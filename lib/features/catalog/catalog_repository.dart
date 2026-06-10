import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../core/models/models.dart';

class CatalogRepository {
  CatalogRepository(this._api);
  final ApiClient _api;

  /// All catalog endpoints are public — no Authorization header needed.
  static final _noAuth = Options(extra: const {'auth': false});

  Future<List<Retailer>> retailers() async {
    final res = await _api.dio.get('/retailers', options: _noAuth);
    return ((res.data as List?) ?? [])
        .map((e) => Retailer.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Retailer> retailer(String id) async {
    final res = await _api.dio.get('/retailers/$id', options: _noAuth);
    return Retailer.fromJson(res.data as Map<String, dynamic>);
  }

  Future<RetailerStock> retailerStocks(String id) async {
    final res = await _api.dio.get('/retailers/$id/stocks', options: _noAuth);
    return RetailerStock.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<Bicycle>> bicycles() async {
    final res = await _api.dio.get('/bicycles', options: _noAuth);
    return ((res.data as List?) ?? [])
        .map((e) => Bicycle.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<BicType>> types() async {
    final res = await _api.dio.get('/types', options: _noAuth);
    return ((res.data as List?) ?? [])
        .map((e) => BicType.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<BicSize>> sizes() async {
    final res = await _api.dio.get('/sizes', options: _noAuth);
    return ((res.data as List?) ?? [])
        .map((e) => BicSize.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Accessory>> accessories() async {
    final res = await _api.dio.get('/accessories', options: _noAuth);
    return ((res.data as List?) ?? [])
        .map((e) => Accessory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Insurance>> insurances() async {
    final res = await _api.dio.get('/insurances', options: _noAuth);
    return ((res.data as List?) ?? [])
        .map((e) => Insurance.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
