import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../core/providers.dart';
import 'catalog_repository.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepository(ref.watch(apiClientProvider));
});

final retailersProvider = FutureProvider<List<Retailer>>((ref) async {
  return ref.watch(catalogRepositoryProvider).retailers();
});

final retailerProvider =
    FutureProvider.family<Retailer, String>((ref, id) async {
  return ref.watch(catalogRepositoryProvider).retailer(id);
});

final retailerStocksProvider =
    FutureProvider.family<RetailerStock, String>((ref, id) async {
  return ref.watch(catalogRepositoryProvider).retailerStocks(id);
});

final bicyclesProvider = FutureProvider<List<Bicycle>>((ref) async {
  return ref.watch(catalogRepositoryProvider).bicycles();
});

final typesProvider = FutureProvider<List<BicType>>((ref) async {
  return ref.watch(catalogRepositoryProvider).types();
});

final sizesProvider = FutureProvider<List<BicSize>>((ref) async {
  return ref.watch(catalogRepositoryProvider).sizes();
});

final accessoriesProvider = FutureProvider<List<Accessory>>((ref) async {
  return ref.watch(catalogRepositoryProvider).accessories();
});

final insurancesProvider = FutureProvider<List<Insurance>>((ref) async {
  return ref.watch(catalogRepositoryProvider).insurances();
});
