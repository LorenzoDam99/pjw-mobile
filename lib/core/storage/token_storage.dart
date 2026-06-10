import 'package:shared_preferences/shared_preferences.dart';

/// Token storage backed by SharedPreferences — same level of security as the
/// web app's localStorage (deliberate parity choice).
class TokenStorage {
  static const _accessKey = 'authToken';
  static const _refreshKey = 'refreshToken';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<String?> get access async => (await _prefs).getString(_accessKey);
  Future<String?> get refresh async => (await _prefs).getString(_refreshKey);

  Future<void> setAccess(String value) async {
    final p = await _prefs;
    await p.setString(_accessKey, value);
  }

  Future<void> setRefresh(String value) async {
    final p = await _prefs;
    await p.setString(_refreshKey, value);
  }

  Future<void> clear() async {
    final p = await _prefs;
    await p.remove(_accessKey);
    await p.remove(_refreshKey);
  }
}
