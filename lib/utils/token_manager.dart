import 'dart:convert';
import 'package:http/http.dart' as http;

class TokenInfo {
  final String token;
  final DateTime expiresAt;

  TokenInfo({required this.token, required this.expiresAt});
}

class TokenManager {
  TokenManager({required this.serverHost, required this.clientId, required this.clientSecret});

  final String serverHost;
  final String clientId;
  final String clientSecret;

  

  Future<TokenInfo> getValidToken() async {
    final fresh = await _fetchNewToken();
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
    final int expiresIn = (data['expires_in'] is int)
        ? data['expires_in'] as int
        : int.tryParse('${data['expires_in']}') ?? 0;
    final DateTime expiresAt = DateTime.now().add(Duration(seconds: expiresIn));

    return TokenInfo(token: token, expiresAt: expiresAt);
  }
}


