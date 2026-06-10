import 'dart:convert';

/// Decode a JWT payload (no signature verification — that's the BE's job).
Map<String, dynamic>? decodeJwt(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    var payload = parts[1];
    final pad = payload.length % 4;
    if (pad != 0) payload += '=' * (4 - pad);
    final decoded = utf8.decode(base64Url.decode(payload));
    return jsonDecode(decoded) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}
