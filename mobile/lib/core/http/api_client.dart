import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

// Provider must be overridden in ProviderScope (see main.dart)
final apiClientProvider = Provider<ApiClient>((ref) {
  throw UnimplementedError('apiClientProvider must be overridden');
});

class ApiClient {
  final http.Client _httpClient;
  final GoTrueClient _auth;
  final String baseUrl;
  bool _refreshing = false;

  ApiClient({
    required this.baseUrl,
    required GoTrueClient auth,
    http.Client? httpClient,
  })  : _auth = auth,
        _httpClient = httpClient ?? http.Client();

  Map<String, String> get _headers {
    final token = _auth.currentSession?.accessToken;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Attempt token refresh once on 401, then retry the original request.
  Future<http.Response> _withRefresh(
    Future<http.Response> Function() request,
  ) async {
    final response = await request();
    if (response.statusCode == 401 && !_refreshing) {
      _refreshing = true;
      try {
        await _auth.refreshSession();
        // Retry with new token
        final retry = await request();
        return retry;
      } catch (_) {
        // Refresh failed — return original 401
        return response;
      } finally {
        _refreshing = false;
      }
    }
    return response;
  }

  Future<Map<String, dynamic>> get(String path) async {
    final response = await _withRefresh(
      () => _httpClient.get(Uri.parse('$baseUrl$path'), headers: _headers),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final encoded = body != null ? jsonEncode(body) : null;
    final response = await _withRefresh(
      () => _httpClient.post(Uri.parse('$baseUrl$path'),
          headers: _headers, body: encoded),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final encoded = body != null ? jsonEncode(body) : null;
    final response = await _withRefresh(
      () => _httpClient.patch(Uri.parse('$baseUrl$path'),
          headers: _headers, body: encoded),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final encoded = body != null ? jsonEncode(body) : null;
    final response = await _withRefresh(
      () => _httpClient.put(Uri.parse('$baseUrl$path'),
          headers: _headers, body: encoded),
    );
    return _handleResponse(response);
  }

  Future<void> delete(String path) async {
    final response = await _withRefresh(
      () => _httpClient.delete(Uri.parse('$baseUrl$path'), headers: _headers),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    // 204 No Content — return empty map
    if (response.statusCode == 204 || response.body.isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return <String, dynamic>{};
      }
    }

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw ApiException(
        statusCode: response.statusCode,
        code: 'INVALID_RESPONSE',
        message: 'Resposta invalida do servidor',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final error = body['error'] as Map<String, dynamic>?;
    final code = error?['code'] as String? ?? 'UNKNOWN';
    final message = error?['message'] as String? ?? 'Erro desconhecido';

    throw ApiException(
      statusCode: response.statusCode,
      code: code,
      message: message,
    );
  }

  void dispose() {
    _httpClient.close();
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String code;
  final String message;

  const ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
  });

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}
