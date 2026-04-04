import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiClient {
  final http.Client _httpClient;
  final GoTrueClient _auth;
  final String baseUrl;

  ApiClient({
    required this.baseUrl,
    required GoTrueClient auth,
    http.Client? httpClient,
  })  : _auth = auth,
        _httpClient = httpClient ?? http.Client();

  Map<String, String> _headers({bool hasBody = false}) {
    final token = _auth.currentSession?.accessToken;
    return {
      if (hasBody) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> get(String path) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl$path'),
      headers: _headers(),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final encoded = body != null ? jsonEncode(body) : null;
    final response = await _httpClient.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers(hasBody: encoded != null),
      body: encoded,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final encoded = body != null ? jsonEncode(body) : null;
    final response = await _httpClient.patch(
      Uri.parse('$baseUrl$path'),
      headers: _headers(hasBody: encoded != null),
      body: encoded,
    );
    return _handleResponse(response);
  }

  Future<void> delete(String path) async {
    final response = await _httpClient.delete(
      Uri.parse('$baseUrl$path'),
      headers: _headers(),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) return;
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
    final errors = body['errors'] as List<dynamic>?;
    final firstError = errors?.isNotEmpty == true
        ? errors!.first as Map<String, dynamic>
        : null;
    final code = firstError?['code'] as String? ?? 'UNKNOWN';
    final message = firstError?['message'] as String? ?? 'Erro desconhecido';
    throw ApiException(statusCode: response.statusCode, code: code, message: message);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
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

    // Backend returns { errors: [{ code, message, field? }] }
    final errors = body['errors'] as List<dynamic>?;
    final firstError = errors?.isNotEmpty == true
        ? errors!.first as Map<String, dynamic>
        : null;
    final code = firstError?['code'] as String? ?? 'UNKNOWN';
    final message = firstError?['message'] as String? ?? 'Erro desconhecido';

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
