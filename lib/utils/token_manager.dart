import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class TokenInfo {
  final String token;
  final DateTime expiresAt;

  TokenInfo({required this.token, required this.expiresAt});

  Map<String, dynamic> toJson() => {
        'token': token,
        'expiresAt': expiresAt.toIso8601String(),
      };

  static TokenInfo? fromJson(Map<String, dynamic> json) {
    try {
      final token = json['token'] as String?;
      final expires = json['expiresAt'] as String?;
      if (token == null || expires == null) return null;
      return TokenInfo(token: token, expiresAt: DateTime.parse(expires));
    } catch (_) {
      return null;
    }
  }
}

class TokenManager {
  TokenManager({required this.serverHost, required this.clientId, required this.clientSecret});

  final String serverHost;
  final String clientId;
  final String clientSecret;

  static const _prefsKey = 'auth_token_info_v1';

  Future<TokenInfo?> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_prefsKey);
    if (str == null) return null;
    try {
      final map = jsonDecode(str) as Map<String, dynamic>;
      return TokenInfo.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> _save(TokenInfo info) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(info.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  bool _isValid(TokenInfo info) {
    // margem de segurança de 60s
    return DateTime.now().isBefore(info.expiresAt.subtract(const Duration(seconds: 60)));
  }

  Future<TokenInfo> getValidToken() async {
    final cached = await _load();
    if (cached != null && _isValid(cached)) {
      return cached;
    }
    final fresh = await _fetchNewToken();
    await _save(fresh);
    return fresh;
  }

  Future<TokenInfo> _fetchNewToken() async {
    final uri = Uri.http(serverHost, '/api/token');
    final resp = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'id': clientId,
        'secret': clientSecret,
      }),
    );
    if (resp.statusCode != 200) {
      throw Exception('Falha ao obter token (${resp.statusCode})');
    }
    final Map<String, dynamic> data = jsonDecode(resp.body) as Map<String, dynamic>;
    final String token = (data['token'] ?? '') as String;
    final int? expiresIn = (data['expires_in'] is int)
        ? data['expires_in'] as int
        : int.tryParse('${data['expires_in']}');
    DateTime? expiresAt;
    if (expiresIn != null) {
      expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
    }
    // Fallback para claim exp do JWT, se necessário
    expiresAt ??= _parseJwtExpiry(token) ?? DateTime.now().add(const Duration(hours: 24));
    return TokenInfo(token: token, expiresAt: expiresAt);
  }

  DateTime? _parseJwtExpiry(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return null;
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final payloadBytes = base64Url.decode(normalized);
      final payloadJson = jsonDecode(utf8.decode(payloadBytes));
      if (payloadJson is! Map<String, dynamic>) return null;
      final exp = payloadJson['exp'];
      if (exp is int) {
        return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      }
      if (exp is String) {
        final expInt = int.tryParse(exp);
        if (expInt != null) {
          return DateTime.fromMillisecondsSinceEpoch(expInt * 1000);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}


