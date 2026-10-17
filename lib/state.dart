import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';
import 'models.dart';

/// Session token (Keychain / Keystore) and the signed-in user.
class AuthModel extends ChangeNotifier {
  AuthModel(this.api, {FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage() {
    api.tokenProvider = () => _token;
  }

  static const _key = 'session_token';
  final Api api;
  final FlutterSecureStorage _storage;
  String? _token;
  User? user;
  bool ready = false;

  bool get signedIn => user != null;

  Future<void> load() async {
    try {
      _token = await _storage.read(key: _key);
      if (_token != null) user = await api.me();
    } on ApiException catch (e) {
      if (e.unauthorized) await _clear();
    } catch (_) {
      // Storage unavailable; continue signed out.
    }
    ready = true;
    notifyListeners();
  }

  Future<void> _adopt(String token, User u) async {
    _token = token;
    user = u;
    await _storage.write(key: _key, value: token);
    notifyListeners();
  }

  /// Uses a token returned by checkout when the guest chose "create an account".
  Future<void> adoptToken(String token) async {
    _token = token;
    await _storage.write(key: _key, value: token);
    try {
      user = await api.me();
    } catch (_) {}
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final r = await api.login(email.trim().toLowerCase(), password);
    await _adopt(r.token, r.user);
  }

  Future<void> register({required String name, required String email, String phone = '', required String password}) async {
    final r = await api.register({'name': name, 'email': email.trim().toLowerCase(), 'phone': phone, 'password': password});
    await _adopt(r.token, r.user);
  }

  /// Forgets the session without contacting the server (used when switching servers).
  Future<void> forget() => _clear();

  Future<void> logout() async {
    try {
      await api.logout();
    } catch (_) {}
    await _clear();
  }

  Future<void> _clear() async {
    _token = null;
    user = null;
    await _storage.delete(key: _key);
    notifyListeners();
  }
}

class CartLine {
  CartLine({
    required this.packId,
    required this.medicineId,
    required this.brandName,
    required this.description,
    required this.packLabel,
    required this.price,
    required this.qty,
  });

  CartLine.fromJson(Map<String, dynamic> j)
      : packId = j['packId'] as int,
        medicineId = j['medicineId'] as int,
        brandName = j['brandName'] as String,
        description = j['description'] as String? ?? '',
        packLabel = j['packLabel'] as String? ?? '',
        price = (j['price'] as num).toDouble(),
        qty = j['qty'] as int;

  final int packId, medicineId;
  final String brandName, description, packLabel;

  /// Last price seen; the server quote is authoritative.
  final double price;
  int qty;

  Map<String, dynamic> toJson() => {
        'packId': packId,
        'medicineId': medicineId,
        'brandName': brandName,
        'description': description,
        'packLabel': packLabel,
        'price': price,
        'qty': qty,
      };
}

/// Cart persisted on the device, like the web's localStorage cart.
class CartModel extends ChangeNotifier {
  static const _key = 'cart_v1';
  final List<CartLine> lines = [];
  SharedPreferences? _prefs;

  int get count => lines.length;
  bool get isEmpty => lines.isEmpty;
  List<Map<String, int>> get payload => [for (final l in lines) {'packId': l.packId, 'qty': l.qty}];

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_key);
    if (raw != null) {
      try {
        lines.addAll((jsonDecode(raw) as List).map((e) => CartLine.fromJson(e)));
      } catch (_) {}
    }
    notifyListeners();
  }

  void _save() {
    _prefs?.setString(_key, jsonEncode(lines.map((l) => l.toJson()).toList()));
    notifyListeners();
  }

  void add(CartLine line) {
    final existing = lines.where((l) => l.packId == line.packId).firstOrNull;
    if (existing != null) {
      existing.qty = (existing.qty + line.qty).clamp(1, 99);
    } else {
      lines.add(line..qty = line.qty.clamp(1, 99));
    }
    _save();
  }

  void setQty(int packId, int qty) {
    if (qty <= 0) return remove(packId);
    for (final l in lines) {
      if (l.packId == packId) l.qty = qty.clamp(1, 99);
    }
    _save();
  }

  void remove(int packId) {
    lines.removeWhere((l) => l.packId == packId);
    _save();
  }

  void clear() {
    lines.clear();
    _save();
  }
}

/// Guest orders placed or tracked on this device, so they can be reopened without an account.
class DeviceOrders extends ChangeNotifier {
  static const _key = 'device_orders_v1';
  List<({String code, String phone})> orders = [];
  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getStringList(_key) ?? [];
    orders = [
      for (final s in raw)
        if (s.contains('|')) (code: s.split('|')[0], phone: s.split('|')[1]),
    ];
    notifyListeners();
  }

  void remember(String code, String phone) {
    orders = [(code: code, phone: phone), ...orders.where((o) => o.code != code)].take(20).toList();
    _prefs?.setStringList(_key, [for (final o in orders) '${o.code}|${o.phone}']);
    notifyListeners();
  }

  String? phoneFor(String code) => orders.where((o) => o.code == code).firstOrNull?.phone;
}

/// Checkout reference data, fetched once.
class MetaModel extends ChangeNotifier {
  MetaModel(this.api);
  final Api api;
  Meta? meta;
  Future<Meta>? _pending;

  void reset() {
    meta = null;
    _pending = null;
  }

  Future<Meta> get() {
    if (meta != null) return Future.value(meta);
    return _pending ??= api.meta().then((m) {
      meta = m;
      notifyListeners();
      return m;
    }).whenComplete(() => _pending = null);
  }
}

/// Backend address chosen on the device (Settings → Server address); null uses the built-in default.
class ServerModel extends ChangeNotifier {
  static const _key = 'server_address';
  SharedPreferences? _prefs;

  String get address => apiBase;
  bool get isCustom => apiBaseOverride != null;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    apiBaseOverride = _prefs!.getString(_key);
  }

  /// Saves [url] (already normalised), or clears the override when null.
  Future<void> set(String? url) async {
    apiBaseOverride = url == defaultApiBase ? null : url;
    if (apiBaseOverride == null) {
      await _prefs?.remove(_key);
    } else {
      await _prefs?.setString(_key, apiBaseOverride!);
    }
    notifyListeners();
  }
}

/// Which bottom tab is showing; lets screens jump to the cart or account tab.
class TabsModel extends ChangeNotifier {
  int index = 0;

  /// Bumped when Home asks the Search tab to focus its field.
  int searchFocusRequest = 0;

  void go(int i) {
    index = i;
    notifyListeners();
  }

  void focusSearch() {
    searchFocusRequest++;
    go(search);
  }

  static const home = 0, search = 1, cart = 2, orders = 3, account = 4;
}

/// Lifetime savings for this customer (account orders plus guest orders placed on this device).
class SavingsModel extends ChangeNotifier {
  SavingsModel(this.api, this.device);
  final Api api;
  final DeviceOrders device;
  Savings savings = const Savings.none();

  Future<void> refresh() async {
    try {
      savings = await api.savings(device.orders);
      notifyListeners();
    } catch (_) {
      // Offline or server unreachable: keep the last known value.
    }
  }
}

/// First-launch onboarding flag.
class OnboardingModel extends ChangeNotifier {
  static const _key = 'onboarded_v1';
  SharedPreferences? _prefs;
  bool done = true;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    done = _prefs!.getBool(_key) ?? false;
  }

  void finish() {
    done = true;
    _prefs?.setBool(_key, true);
    notifyListeners();
  }
}
