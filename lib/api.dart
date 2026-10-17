import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'models.dart';

/// Built-in backend origin: `--dart-define=API_BASE=…`, else the emulator/simulator host.
/// The Android emulator reaches the host machine at 10.0.2.2; the iOS simulator uses localhost.
String get defaultApiBase {
  const fromEnv = String.fromEnvironment('API_BASE');
  if (fromEnv.isNotEmpty) return fromEnv;
  if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:3000';
  return 'http://localhost:3000';
}

/// Server address chosen in Settings (saved on the device), overriding [defaultApiBase].
String? apiBaseOverride;

/// Backend origin used for every request.
String get apiBase => apiBaseOverride ?? defaultApiBase;

/// Normalises user input like "192.168.1.20:3000" to "http://192.168.1.20:3000"; null if it isn't a usable URL.
String? normalizeServerAddress(String input) {
  var s = input.trim();
  if (s.isEmpty) return null;
  if (!s.contains('://')) s = 'http://$s';
  final u = Uri.tryParse(s);
  if (u == null || !(u.scheme == 'http' || u.scheme == 'https') || u.host.isEmpty) return null;
  return Uri(scheme: u.scheme, host: u.host, port: u.hasPort ? u.port : null).toString();
}

/// Absolute URL for a server media path such as `/media/products/x.jpg`.
String? mediaUrl(String? path) =>
    path == null || path.isEmpty ? null : (path.startsWith('http') ? path : '$apiBase$path');

class ApiException implements Exception {
  ApiException(this.message, [this.status = 0]);
  final String message;
  final int status;

  bool get unauthorized => status == 401;

  @override
  String toString() => message;
}

/// Thin client for the Next.js `/api/v1` endpoints. Sends the session token as a Bearer header.
class Api {
  Api({http.Client? client, this.tokenProvider}) : _client = client ?? http.Client();

  final http.Client _client;
  String? Function()? tokenProvider;

  Uri _uri(String path, [Map<String, String?>? query]) {
    final q = {for (final e in (query ?? {}).entries) if (e.value != null && e.value!.isNotEmpty) e.key: e.value!};
    return Uri.parse('$apiBase/api/v1$path').replace(queryParameters: q.isEmpty ? null : q);
  }

  Map<String, String> get _headers {
    final token = tokenProvider?.call();
    return {
      'accept': 'application/json',
      'content-type': 'application/json',
      if (token != null) 'authorization': 'Bearer $token',
    };
  }

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    final http.Response res;
    try {
      res = await request().timeout(const Duration(seconds: 20));
    } catch (_) {
      throw ApiException('Could not reach Sashroy. Check your connection and try again.');
    }
    if (res.statusCode == 204) return null;
    dynamic body;
    try {
      body = jsonDecode(utf8.decode(res.bodyBytes));
    } catch (_) {
      body = null;
    }
    if (res.statusCode >= 400) {
      final msg = body is Map && body['error'] is String ? body['error'] as String : 'Something went wrong (${res.statusCode}).';
      throw ApiException(msg, res.statusCode);
    }
    return body;
  }

  Future<dynamic> get(String path, [Map<String, String?>? query]) =>
      _send(() => _client.get(_uri(path, query), headers: _headers));

  Future<dynamic> post(String path, [Object? body]) =>
      _send(() => _client.post(_uri(path), headers: _headers, body: jsonEncode(body ?? {})));

  Future<dynamic> delete(String path, [Map<String, String?>? query]) =>
      _send(() => _client.delete(_uri(path, query), headers: _headers));

  // Catalog
  Future<HomeData> home() async => HomeData.fromJson(await get('/home'));
  Future<Meta> meta() async => Meta.fromJson(await get('/meta'));
  Future<Suggestions> suggest(String q) async => Suggestions.fromJson(await get('/suggest', {'q': q}));
  Future<SearchResult> search(String q, {String? form}) async =>
      SearchResult.fromJson(await get('/search', {'q': q, 'form': form}));
  Future<MedicineDetail> medicine(int id) async => MedicineDetail.fromJson(await get('/medicines/$id'));
  Future<GenericDetail> generic(String slug) async => GenericDetail.fromJson(await get('/generics/$slug'));
  Future<List<Company>> companies() async =>
      ((await get('/companies'))['companies'] as List).map((e) => Company.fromJson(e)).toList();
  Future<CompanyPage> company(String slug, int page) async =>
      CompanyPage.fromJson(await get('/companies/$slug', {'page': '$page'}));

  // Cart & orders
  Future<Quote> quote(List<Map<String, int>> items, {String? district}) async =>
      Quote.fromJson(await post('/cart/quote', {'items': items, 'district': district}));
  Future<Map<String, dynamic>> placeOrder(Map<String, dynamic> body) async =>
      (await post('/orders', body)) as Map<String, dynamic>;
  Future<List<OrderSummary>> orders() async =>
      ((await get('/orders'))['orders'] as List).map((e) => OrderSummary.fromJson(e)).toList();
  Future<Savings> savings(List<({String code, String phone})> guest) async => Savings.fromJson(await post('/savings', {
        'orders': [for (final o in guest) {'code': o.code, 'phone': o.phone}],
      }));
  Future<OrderDetail> order(String code, {String? phone}) async =>
      OrderDetail.fromJson(await get('/orders/${Uri.encodeComponent(code)}', {'phone': phone}));

  // Auth & account
  Future<AuthResult> login(String email, String password) async =>
      AuthResult.fromJson(await post('/auth/login', {'email': email, 'password': password}));
  Future<AuthResult> register(Map<String, String> body) async => AuthResult.fromJson(await post('/auth/register', body));
  Future<void> logout() => post('/auth/logout');
  Future<User> me() async => User.fromJson((await get('/auth/me'))['user']);
  Future<User> updateProfile(String name, String phone) async =>
      User.fromJson((await _send(() => _client.patch(_uri('/auth/me'), headers: _headers, body: jsonEncode({'name': name, 'phone': phone}))))['user']);
  Future<void> changePassword(String current, String next) => post('/auth/password', {'current': current, 'next': next});
  Future<void> deleteAccount() => delete('/auth/me');
  Future<List<Address>> addresses() async => Address.listFrom((await get('/addresses'))['addresses']);
  Future<List<Address>> addAddress(Map<String, dynamic> body) async =>
      Address.listFrom((await post('/addresses', body))['addresses']);
  Future<List<Address>> deleteAddress(int id) async =>
      Address.listFrom((await delete('/addresses', {'id': '$id'}))['addresses']);
}
