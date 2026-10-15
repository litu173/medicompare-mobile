// JSON models for the /api/v1 endpoints. Field names follow the server (snake_case rows, camelCase computed data).

typedef Json = Map<String, dynamic>;

double? _d(Object? v) => (v as num?)?.toDouble();
int _i(Object? v) => (v as num?)?.toInt() ?? 0;
String? _s(Object? v) => v as String?;
bool _b(Object? v) => v == true || (v is num && v != 0);

class Medicine {
  Medicine.fromJson(Json j)
      : id = _i(j['id']),
        brandName = j['brand_name'] as String,
        type = _s(j['type']) ?? '',
        dosageForm = _s(j['dosage_form']) ?? '',
        formGroup = _s(j['form_group']) ?? '',
        genericName = _s(j['generic_name']) ?? '',
        genericSlug = _s(j['generic_slug']),
        strength = _s(j['strength']),
        manufacturerName = _s(j['manufacturer_name']) ?? '',
        manufacturerSlug = _s(j['manufacturer_slug']) ?? '',
        equivKey = _s(j['equiv_key']) ?? '',
        comparePrice = _d(j['compare_price']),
        compareUnit = _s(j['compare_unit']),
        listPrice = _d(j['list_price']),
        listLabel = _s(j['list_label']),
        stock = _i(j['stock']),
        priceSuspect = _b(j['price_suspect']),
        packId = (j['pack_id'] as num?)?.toInt(),
        image = _s(j['image']),
        cheaperCount = _i(j['cheaperCount']);

  final int id;
  final String brandName, type, dosageForm, formGroup, genericName, manufacturerName, manufacturerSlug, equivKey;
  final String? genericSlug, strength, compareUnit, listLabel;
  final double? comparePrice, listPrice;
  final int stock;
  final bool priceSuspect;
  final int? packId;

  /// Product photo path (e.g. /media/products/x.jpg) or null; resolve with [mediaUrl].
  final String? image;

  /// Only set on company listings.
  final int cheaperCount;

  bool get outOfStock => stock <= 0 || comparePrice == null;
  String get cartDescription => [strength, dosageForm, manufacturerName].whereType<String>().where((s) => s.isNotEmpty).join(' · ');

  static List<Medicine> listFrom(Object? v) => (v as List? ?? []).map((e) => Medicine.fromJson(e)).toList();
}

class Pack {
  Pack.fromJson(Json j)
      : id = _i(j['id']),
        label = j['label'] as String,
        qty = _i(j['qty']),
        price = _d(j['price']) ?? 0;
  final int id, qty;
  final String label;
  final double price;
}

class SearchGroup {
  SearchGroup.fromJson(Json j)
      : equivKey = j['equivKey'] as String,
        genericName = _s(j['genericName']) ?? '',
        genericSlug = _s(j['genericSlug']),
        strength = _s(j['strength']),
        form = _s(j['form']) ?? '',
        total = _i(j['total']),
        minPrice = _d(j['minPrice']),
        maxPrice = _d(j['maxPrice']),
        unit = _s(j['unit']),
        items = Medicine.listFrom(j['items']),
        matchedIds = (j['matchedIds'] as List? ?? []).map(_i).toSet();
  final String equivKey, genericName, form;
  final String? genericSlug, strength, unit;
  final int total;
  final double? minPrice, maxPrice;
  final List<Medicine> items;
  final Set<int> matchedIds;
}

class GenericRef {
  GenericRef.fromJson(Json j)
      : id = _i(j['id']),
        name = j['name'] as String,
        slug = j['slug'] as String,
        brandCount = _i(j['brand_count']);
  final int id, brandCount;
  final String name, slug;
}

class SearchResult {
  SearchResult.fromJson(Json j)
      : groups = (j['groups'] as List).map((e) => SearchGroup.fromJson(e)).toList(),
        generics = (j['generics'] as List).map((e) => GenericRef.fromJson(e)).toList(),
        forms = (j['forms'] as List).map((e) => (form: e['form'] as String, n: _i(e['n']))).toList();
  final List<SearchGroup> groups;
  final List<GenericRef> generics;
  final List<({String form, int n})> forms;
}

class Suggestions {
  Suggestions.fromJson(Json j)
      : brands = (j['brands'] as List)
            .map((e) => (
                  id: _i(e['id']),
                  name: e['brand_name'] as String,
                  detail: [e['strength'], e['dosage_form'], e['generic_name']].whereType<String>().join(' · '),
                ))
            .toList(),
        generics = (j['generics'] as List).map((e) => GenericRef.fromJson(e)).toList();
  final List<({int id, String name, String detail})> brands;
  final List<GenericRef> generics;
}

/// A generic's drug information (monograph).
class Generic {
  Generic.fromJson(Json j)
      : id = _i(j['id']),
        name = j['name'] as String,
        slug = j['slug'] as String,
        drugClass = _s(j['drug_class']),
        brandCount = _i(j['brand_count']),
        raw = j;
  final int id, brandCount;
  final String name, slug;
  final String? drugClass;
  final Json raw;

  static const sections = [
    ('indication_desc', 'Indications'),
    ('dosage', 'Dosage'),
    ('administration', 'How to take'),
    ('side_effects', 'Side effects'),
    ('precautions', 'Precautions & warnings'),
    ('contraindications', 'Contraindications'),
    ('pregnancy', 'Pregnancy & breastfeeding'),
    ('interaction', 'Interactions'),
    ('pediatric', 'Use in children'),
    ('overdose', 'Overdose'),
    ('pharmacology', 'Pharmacology'),
    ('storage', 'Storage'),
  ];

  List<(String, String)> get monograph => [
        for (final (key, title) in sections)
          if (raw[key] is String && (raw[key] as String).trim().isNotEmpty) (title, (raw[key] as String).trim()),
      ];
}

class Variant {
  Variant.fromJson(Json j)
      : equivKey = j['equiv_key'] as String,
        strength = _s(j['strength']),
        formGroup = _s(j['form_group']) ?? '',
        brands = _i(j['brands']),
        minPrice = _d(j['min_price']),
        unit = _s(j['unit']),
        anyId = _i(j['any_id']);
  final String equivKey, formGroup;
  final String? strength, unit;
  final int brands, anyId;
  final double? minPrice;
}

class MedicineDetail {
  MedicineDetail.fromJson(Json j)
      : medicine = Medicine.fromJson(j['medicine']),
        packs = (j['packs'] as List).map((e) => Pack.fromJson(e)).toList(),
        alternatives = Medicine.listFrom(j['alternatives']),
        generic = j['generic'] == null ? null : Generic.fromJson(j['generic']),
        variants = (j['variants'] as List? ?? []).map((e) => Variant.fromJson(e)).toList();
  final Medicine medicine;
  final List<Pack> packs;
  final List<Medicine> alternatives;
  final Generic? generic;
  final List<Variant> variants;

  /// This brand plus its alternatives, in the server's cheapest-first order.
  List<Medicine> get equivalents {
    final all = [medicine, ...alternatives];
    int rank(Medicine m) => m.comparePrice == null ? 1 : 0;
    all.sort((a, b) {
      final r = rank(a) - rank(b);
      if (r != 0) return r;
      final p = (a.comparePrice ?? 0).compareTo(b.comparePrice ?? 0);
      if (p != 0) return p;
      final s = (a.stock == 0 ? 1 : 0) - (b.stock == 0 ? 1 : 0);
      return s != 0 ? s : a.brandName.compareTo(b.brandName);
    });
    return all;
  }
}

class GenericDetail {
  GenericDetail.fromJson(Json j)
      : generic = Generic.fromJson(j['generic']),
        groups = (j['groups'] as List).map((g) => Medicine.listFrom(g)).toList();
  final Generic generic;
  final List<List<Medicine>> groups;
}

class Company {
  Company.fromJson(Json j)
      : id = _i(j['id']),
        name = j['name'] as String,
        slug = j['slug'] as String,
        brandCount = _i(j['brand_count']),
        genericCount = _i(j['generic_count']);
  final int id, brandCount, genericCount;
  final String name, slug;
}

class CompanyPage {
  CompanyPage.fromJson(Json j)
      : company = Company.fromJson(j['company']),
        page = _i(j['page']),
        pages = _i(j['pages']),
        items = Medicine.listFrom(j['items']);
  final Company company;
  final int page, pages;
  final List<Medicine> items;
}

class PriceGap {
  PriceGap.fromJson(Json j)
      : genericName = j['generic_name'] as String,
        strength = _s(j['strength']),
        formGroup = _s(j['form_group']) ?? '',
        brands = _i(j['brands']),
        minPrice = _d(j['min_price']) ?? 0,
        maxPrice = _d(j['max_price']) ?? 0,
        unit = _s(j['unit']),
        topId = _i(j['top_id']);
  final String genericName, formGroup;
  final String? strength, unit;
  final int brands, topId;
  final double minPrice, maxPrice;
}

class HomeData {
  HomeData.fromJson(Json j)
      : medicines = _i(j['stats']['medicines']),
        generics = _i(j['stats']['generics']),
        companies = _i(j['stats']['companies']),
        popular = (j['popular'] as List).cast<String>(),
        gaps = (j['gaps'] as List).map((e) => PriceGap.fromJson(e)).toList();
  final int medicines, generics, companies;
  final List<String> popular;
  final List<PriceGap> gaps;
}

class PaymentMethod {
  PaymentMethod.fromJson(Json j)
      : id = j['id'] as String,
        label = j['label'] as String,
        note = _s(j['note']) ?? '',
        enabled = _b(j['enabled']);
  final String id, label, note;
  final bool enabled;
}

class Meta {
  Meta.fromJson(Json j)
      : divisions = (j['divisions'] as Json).map((k, v) => MapEntry(k, (v as List).cast<String>())),
        thanas = ((j['thanas'] as Json?) ?? {}).map((k, v) => MapEntry(k, (v as List).cast<String>())),
        paymentMethods = (j['paymentMethods'] as List).map((e) => PaymentMethod.fromJson(e)).toList(),
        freeDeliveryOver = _d(j['delivery']?['freeOver']) ?? 1000;
  final Map<String, List<String>> divisions;

  /// Thanas (areas) per district; empty until the server provides them, in which case area is free text.
  final Map<String, List<String>> thanas;
  final List<PaymentMethod> paymentMethods;
  final double freeDeliveryOver;
}

class QuoteLine {
  QuoteLine.fromJson(Json j)
      : packId = _i(j['packId']),
        medicineId = _i(j['medicineId']),
        brandName = j['brandName'] as String,
        description = _s(j['description']) ?? '',
        packLabel = _s(j['packLabel']) ?? '',
        price = _d(j['price']) ?? 0,
        qty = _i(j['qty']),
        lineTotal = _d(j['lineTotal']) ?? 0,
        available = _b(j['available']),
        maxQty = _i(j['maxQty']),
        cheaper = j['cheaper'] == null
            ? null
            : (
                medicineId: _i(j['cheaper']['medicineId']),
                brandName: j['cheaper']['brandName'] as String,
                manufacturer: j['cheaper']['manufacturer'] as String,
                savePct: _i(j['cheaper']['savePct']),
              );
  final int packId, medicineId, qty, maxQty;
  final String brandName, description, packLabel;
  final double price, lineTotal;
  final bool available;
  final ({int medicineId, String brandName, String manufacturer, int savePct})? cheaper;
}

class Quote {
  Quote.fromJson(Json j)
      : items = (j['items'] as List).map((e) => QuoteLine.fromJson(e)).toList(),
        subtotal = _d(j['subtotal']) ?? 0,
        deliveryFee = _d(j['deliveryFee']) ?? 0,
        total = _d(j['total']) ?? 0,
        freeOver = _d(j['freeOver']),
        allAvailable = _b(j['allAvailable']);
  final List<QuoteLine> items;
  final double subtotal, deliveryFee, total;

  /// Free-delivery threshold from the server's delivery settings.
  final double? freeOver;
  final bool allAvailable;
}

class OrderSummary {
  OrderSummary.fromJson(Json j)
      : code = j['code'] as String,
        status = j['status'] as String,
        total = _d(j['total']) ?? 0,
        itemCount = _i(j['item_count']),
        createdAt = parseServerDate(j['created_at'] as String);
  final String code, status;
  final double total;
  final int itemCount;
  final DateTime createdAt;
}

/// SQLite `datetime('now')` values are UTC without a zone marker.
DateTime parseServerDate(String s) => DateTime.tryParse(s.contains('T') ? s : '${s.replaceFirst(' ', 'T')}Z')?.toLocal() ?? DateTime.now();

class OrderItem {
  OrderItem.fromJson(Json j)
      : medicineId = _i(j['medicine_id']),
        brandName = j['brand_name'] as String,
        description = _s(j['description']) ?? '',
        packLabel = _s(j['pack_label']) ?? '',
        unitPrice = _d(j['unit_price']) ?? 0,
        qty = _i(j['qty']);
  final int medicineId, qty;
  final String brandName, description, packLabel;
  final double unitPrice;
}

class OrderDetail {
  OrderDetail.fromJson(Json j)
      : code = j['order']['code'] as String,
        status = j['order']['status'] as String,
        name = j['order']['name'] as String,
        phone = j['order']['phone'] as String,
        address = [j['order']['line'], j['order']['area'], j['order']['district'], j['order']['division']]
            .whereType<String>()
            .join(', '),
        note = _s(j['order']['note']),
        paymentMethod = j['order']['payment_method'] as String,
        paymentStatus = _s(j['order']['payment_status']) ?? 'pending',
        subtotal = _d(j['order']['subtotal']) ?? 0,
        deliveryFee = _d(j['order']['delivery_fee']) ?? 0,
        total = _d(j['order']['total']) ?? 0,
        createdAt = parseServerDate(j['order']['created_at'] as String),
        riderName = _s(j['order']['rider_name']),
        riderPhone = _s(j['order']['rider_phone']),
        trackingNote = _s(j['order']['tracking_note']),
        items = (j['items'] as List).map((e) => OrderItem.fromJson(e)).toList(),
        events = [
          for (final e in (j['events'] as List? ?? []))
            (status: e['status'] as String, note: _s(e['note']), at: parseServerDate(e['created_at'] as String)),
        ];
  final String code, status, name, phone, address, paymentMethod, paymentStatus;
  final String? note, riderName, riderPhone, trackingNote;

  /// Timestamped status history, oldest first.
  final List<({String status, String? note, DateTime at})> events;
  final double subtotal, deliveryFee, total;
  final DateTime createdAt;
  final List<OrderItem> items;
}

class User {
  User.fromJson(Json j)
      : id = _i(j['id']),
        name = j['name'] as String,
        email = j['email'] as String,
        phone = _s(j['phone']),
        role = _s(j['role']) ?? 'customer';
  final int id;
  final String name, email, role;
  final String? phone;
}

class AuthResult {
  AuthResult.fromJson(Json j)
      : token = j['token'] as String,
        user = User.fromJson(j['user']);
  final String token;
  final User user;
}

class Address {
  Address.fromJson(Json j)
      : id = _i(j['id']),
        name = j['name'] as String,
        phone = j['phone'] as String,
        division = j['division'] as String,
        district = j['district'] as String,
        area = j['area'] as String,
        line = j['line'] as String,
        isDefault = _b(j['is_default']);
  final int id;
  final String name, phone, division, district, area, line;
  final bool isDefault;

  String get oneLine => '$line, $area, $district';

  static List<Address> listFrom(Object? v) => (v as List? ?? []).map((e) => Address.fromJson(e)).toList();
}
