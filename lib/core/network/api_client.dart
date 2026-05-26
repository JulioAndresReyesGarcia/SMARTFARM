import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:smartfarm_ai/core/config/app_config.dart';
import 'package:smartfarm_ai/core/network/api_exception.dart';

/// Singleton compartido para el modo distribuido.
class ApiClient {
  ApiClient._([http.Client? client]) : _http = client ?? http.Client();

  static final ApiClient instance = ApiClient._();

  factory ApiClient({http.Client? httpClient}) {
    if (httpClient != null) return ApiClient._(httpClient);
    return instance;
  }

  final http.Client _http;
  String? _token;

  void setToken(String? token) => _token = token;
  String? get token => _token;

  Map<String, String> _headers({bool jsonBody = false}) {
    final headers = <String, String>{
      'Accept': 'application/json',
      if (jsonBody) 'Content-Type': 'application/json',
    };
    final bearer = _token;
    if (bearer != null && bearer.isNotEmpty) {
      headers['Authorization'] = 'Bearer $bearer';
    }
    return headers;
  }

  Future<Map<String, dynamic>> getJson(String path) async {
    final response = await _http.get(
      AppConfig.apiUri(path),
      headers: _headers(),
    );
    return _decodeObject(response);
  }

  Future<List<dynamic>> getJsonList(String path) async {
    final response = await _http.get(
      AppConfig.apiUri(path),
      headers: _headers(),
    );
    final decoded = _decode(response);
    if (decoded is List) return decoded;
    throw ApiException('Respuesta inesperada del servidor', statusCode: response.statusCode);
  }

  Future<Map<String, dynamic>> postJson(String path, Map<String, dynamic> body) async {
    final response = await _http.post(
      AppConfig.apiUri(path),
      headers: _headers(jsonBody: true),
      body: jsonEncode(body),
    );
    return _decodeObject(response);
  }

  Future<Map<String, dynamic>> putJson(String path, Map<String, dynamic> body) async {
    final response = await _http.put(
      AppConfig.apiUri(path),
      headers: _headers(jsonBody: true),
      body: jsonEncode(body),
    );
    return _decodeObject(response);
  }

  Future<void> delete(String path) async {
    final response = await _http.delete(
      AppConfig.apiUri(path),
      headers: _headers(),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    _decode(response);
  }

  dynamic _decode(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }

    String message = 'Error del servidor (${response.statusCode})';
    String? code;
    try {
      final body = jsonDecode(response.body);
      if (body is Map) {
        message = body['error']?.toString() ?? message;
        code = body['code']?.toString();
      }
    } catch (_) {}

    throw ApiException(message, statusCode: response.statusCode, code: code);
  }

  Map<String, dynamic> _decodeObject(http.Response response) {
    final decoded = _decode(response);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded == null) return {};
    throw ApiException('Respuesta JSON inválida', statusCode: response.statusCode);
  }

  void dispose() => _http.close();
}
