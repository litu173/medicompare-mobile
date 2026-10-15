import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api.dart';
import '../format.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'account.dart';
import 'catalog.dart';

// ───────────────────────────── Cart ─────────────────────────────

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  Quote? _quote;
  String? _quotedFor;
  Object? _error;
  late final CartModel _cart = context.read<CartModel>();

  @override
  void initState() {
    super.initState();
    _cart.addListener(_requote);
    _requote();
  }

  @override
  void dispose() {
    _cart.removeListener(_requote);
    super.dispose();
  }

  /// Server prices, stock and delivery fee; re-run whenever the cart changes.
  Future<void> _requote() async {
    final key = jsonEncode(_cart.payload);
    if (key == _quotedFor && _error == null) return;
    _quotedFor = key;
    if (_cart.isEmpty) {
      setState(() => _quote = null);
      return;
    }
    try {
      final q = await context.read<Api>().quote(_cart.payload, district: 'Dhaka');
      if (mounted && key == _quotedFor) {
        setState(() {
          _quote = q;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartModel>();
    return Scaffold(
      appBar: AppBar(title: Text(cart.isEmpty ? 'Cart' : 'Cart (${cart.count})')),
      body: cart.isEmpty ? _empty(context) : _filled(context, cart),
    );
  }

  Widget _empty(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.shopping_cart_outlined, size: 48, color: Brand.muted),
            const SizedBox(height: 12),
            const Text('Your cart is empty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Muted('Search for a medicine and add the cheapest equivalent.', align: TextAlign.center, size: 14),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => context.read<TabsModel>().go(TabsModel.search),
              child: const Text('Search medicines'),
            ),
          ]),
        ),
      );

  Widget _filled(BuildContext context, CartModel cart) {
    final q = _quote;
    final byPack = {for (final i in q?.items ?? <QuoteLine>[]) i.packId: i};
    final meta = context.watch<MetaModel>().meta;
    final freeOver = q?.freeOver ?? meta?.freeDeliveryOver ?? 1000;
    final upToDate = q != null && _quotedFor == jsonEncode(cart.payload);

    return Column(children: [
      Expanded(
        child: RefreshIndicator(
          onRefresh: () {
            _quotedFor = null;
            return _requote();
          },
          child: ListView(padding: const EdgeInsets.all(16), children: [
            if (_error != null)
              Padding(padding: const EdgeInsets.only(bottom: 12), child: _Banner.error(_error.toString())),
            ListPanel(children: [
              for (final l in cart.lines) _CartLineTile(line: l, quoted: q == null ? null : byPack[l.packId], quoteLoaded: q != null),
            ]),
            const SizedBox(height: 16),
            if (q != null) ...[
              Panel(
                child: Column(children: [
                  _SumRow('Subtotal', taka(q.subtotal)),
                  const SizedBox(height: 6),
                  _SumRow('Delivery (Dhaka)', q.deliveryFee == 0 ? 'Free' : taka(q.deliveryFee)),
                  const Divider(height: 20),
                  _SumRow('Total', taka(q.total), bold: true),
                  if (q.subtotal < freeOver) ...[
                    const SizedBox(height: 8),
                    Text('Add ${taka(freeOver - q.subtotal)} more for free delivery.',
                        style: const TextStyle(fontSize: 12, color: Brand.c700)),
                  ],
                  const SizedBox(height: 4),
                  const Muted('Delivery outside Dhaka is calculated at checkout.', size: 11),
                ]),
              ),
            ],
          ]),
        ),
      ),
      SafeArea(
        top: false,
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: FilledButton(
            onPressed: upToDate && q.allAvailable
                ? () => Navigator.of(context, rootNavigator: true)
                    .push(MaterialPageRoute(builder: (_) => const CheckoutScreen()))
                : null,
            child: Text(q != null && !q.allAvailable ? 'Fix items above to continue' : 'Checkout'),
          ),
        ),
      ),
    ]);
  }
}

class _CartLineTile extends StatelessWidget {
  const _CartLineTile({required this.line, required this.quoted, required this.quoteLoaded});
  final CartLine line;
  final QuoteLine? quoted;
  final bool quoteLoaded;

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartModel>();
    final q = quoted;
    final gone = quoteLoaded && q == null;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: InkWell(
              onTap: () => openMedicine(context, line.medicineId),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(line.brandName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                Muted(q?.description ?? line.description),
                Muted('${line.packLabel} · ${taka(q?.price ?? line.price)} each'),
              ]),
            ),
          ),
          IconButton(
            tooltip: 'Remove',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.delete_outline, size: 20, color: Brand.muted),
            onPressed: () => cart.remove(line.packId),
          ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          QtyStepper(compact: true, value: line.qty, onChanged: (v) => cart.setQty(line.packId, v)),
          const Spacer(),
          Text(taka(q?.lineTotal ?? line.price * line.qty), style: const TextStyle(fontWeight: FontWeight.w600)),
        ]),
        if (gone)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text('No longer available — please remove', style: TextStyle(fontSize: 12, color: Brand.danger)),
          )
        else if (q != null && !q.available)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              q.maxQty == 0 ? 'Out of stock — pick an alternative' : 'Only ${q.maxQty} available',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Brand.danger),
            ),
          ),
        if (q?.cheaper case final c?)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Material(
              color: Brand.c50,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => openMedicine(context, c.medicineId),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(children: [
                    const Icon(Icons.trending_down_rounded, size: 16, color: Brand.c700),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('${c.brandName} (${c.manufacturer}) is ${c.savePct}% cheaper',
                          style: const TextStyle(fontSize: 12, color: Brand.c700, fontWeight: FontWeight.w500)),
                    ),
                    const Icon(Icons.chevron_right, size: 16, color: Brand.c700),
                  ]),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

class _SumRow extends StatelessWidget {
  const _SumRow(this.label, this.value, {this.bold = false});
  final String label, value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: bold ? 17 : 14, fontWeight: bold ? FontWeight.w700 : FontWeight.w400);
    return Row(children: [
      Expanded(child: Text(label, style: style.copyWith(color: bold ? Brand.ink : const Color(0xFF4B5563)))),
      Text(value, style: style),
    ]);
  }
}

class _Banner extends StatelessWidget {
  const _Banner.error(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Row(children: [
          const Icon(Icons.error_outline, size: 18, color: Brand.danger),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: Color(0xFF991B1B)))),
        ]),
      );
}

// ───────────────────────────── Checkout ─────────────────────────────

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _form = GlobalKey<FormState>();
  final _scroll = ScrollController();
  final _name = TextEditingController(),
      _phone = TextEditingController(),
      _email = TextEditingController(),
      _area = TextEditingController(),
      _line = TextEditingController(),
      _note = TextEditingController(),
      _password = TextEditingController();
  String? _division, _district;
  String _payment = 'cod';
  bool _createAccount = false, _saveAddress = true, _submitting = false;
  String? _error;
  Quote? _quote;
  List<Address> _addresses = [];
  int? _addressId;

  Api get _api => context.read<Api>();

  @override
  void initState() {
    super.initState();
    context.read<MetaModel>().get().catchError((Object e) {
      if (mounted) setState(() => _error = e.toString());
      return Future<Meta>.error(e);
    }).ignore();
    _prefill();
    _requote();
  }

  /// Fills contact details and the default saved address for a signed-in user.
  void _prefill() {
    final u = context.read<AuthModel>().user;
    if (u != null) {
      _name.text = u.name;
      _phone.text = u.phone ?? '';
      _email.text = u.email;
      _api.addresses().then((list) {
        if (!mounted || list.isEmpty) return;
        setState(() => _addresses = list);
        _useAddress(list.firstWhere((a) => a.isDefault, orElse: () => list.first));
      }).ignore();
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _area, _line, _note, _password]) {
      c.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  void _useAddress(Address a) {
    setState(() {
      _addressId = a.id;
      _name.text = a.name;
      _phone.text = a.phone;
      _division = a.division;
      _district = a.district;
      _area.text = a.area;
      _line.text = a.line;
    });
    _requote();
  }

  Future<void> _requote() async {
    final cart = context.read<CartModel>();
    try {
      final q = await _api.quote(cart.payload, district: _district ?? 'Dhaka');
      if (mounted) setState(() => _quote = q);
    } catch (_) {}
  }

  String? _required(String? v, int min, String msg) => (v ?? '').trim().length < min ? msg : null;

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) {
      setState(() => _error = 'Please check the highlighted fields.');
      return;
    }
    final cart = context.read<CartModel>();
    final auth = context.read<AuthModel>();
    final device = context.read<DeviceOrders>();
    final phone = normalizePhone(_phone.text);
    setState(() => _submitting = true);
    try {
      final res = await _api.placeOrder({
        'name': _name.text.trim(),
        'phone': phone,
        'email': _email.text.trim().toLowerCase(),
        'division': _division,
        'district': _district,
        'area': _area.text.trim(),
        'line': _line.text.trim(),
        'note': _note.text.trim(),
        'payment': _payment,
        'createAccount': !auth.signedIn && _createAccount,
        'password': _password.text,
        'saveAddress': auth.signedIn && _saveAddress && _addressId == null,
        'cart': cart.payload,
      });
      final code = res['code'] as String;
      if (res['token'] is String) await auth.adoptToken(res['token'] as String);
      device.remember(code, phone);
      cart.clear();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => OrderScreen(code: code, phone: phone, justPlaced: true)),
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
      _scroll.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta = context.watch<MetaModel>().meta;
    final auth = context.watch<AuthModel>();
    final q = _quote;
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: meta == null
          ? (_error != null ? ErrorView(_error!) : const Center(child: CircularProgressIndicator()))
          : Form(
              key: _form,
              child: ListView(controller: _scroll, padding: const EdgeInsets.all(16), children: [
                if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: _Banner.error(_error!)),
                if (!auth.signedIn)
                  Panel(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(children: [
                      const Expanded(child: Text('Have an account?', style: TextStyle(fontSize: 14))),
                      TextButton(
                        onPressed: () async {
                          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
                          if (mounted) _prefill();
                        },
                        child: const Text('Sign in'),
                      ),
                    ]),
                  ),
                if (!auth.signedIn) const SizedBox(height: 12),
                if (_addresses.isNotEmpty) ...[
                  const _H('Saved addresses'),
                  ListPanel(children: [
                    for (final a in _addresses)
                      RadioListTile<int?>(
                        value: a.id,
                        // ignore: deprecated_member_use
                        groupValue: _addressId,
                        // ignore: deprecated_member_use
                        onChanged: (_) => _useAddress(a),
                        title: Text(a.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text('${a.oneLine} · ${a.phone}', style: const TextStyle(fontSize: 12)),
                      ),
                    RadioListTile<int?>(
                      value: null,
                      // ignore: deprecated_member_use
                      groupValue: _addressId,
                      // ignore: deprecated_member_use
                      onChanged: (_) => setState(() => _addressId = null),
                      title: const Text('Use a new address', style: TextStyle(fontSize: 14)),
                    ),
                  ]),
                  const SizedBox(height: 16),
                ],
                const _H('Delivery details'),
                Panel(
                  child: Column(children: [
                    TextFormField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Recipient name'),
                      validator: (v) => _required(v, 2, "Please enter the recipient's name"),
                      onChanged: (_) => _addressId = null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Mobile number', hintText: '01XXXXXXXXX'),
                      validator: (v) => bdPhone.hasMatch(normalizePhone(v ?? ''))
                          ? null
                          : 'Enter a valid Bangladeshi mobile number (01XXXXXXXXX)',
                      onChanged: (_) => _addressId = null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      readOnly: auth.signedIn,
                      decoration: InputDecoration(labelText: auth.signedIn ? 'Email' : 'Email (optional)'),
                      validator: (v) {
                        final s = (v ?? '').trim();
                        if (s.isEmpty) return _createAccount && !auth.signedIn ? 'Email is needed to create an account' : null;
                        return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s) ? null : 'Enter a valid email';
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _division,
                      key: ValueKey('div-$_division'),
                      decoration: const InputDecoration(labelText: 'Division'),
                      items: [for (final d in meta.divisions.keys) DropdownMenuItem(value: d, child: Text(d))],
                      validator: (v) => v == null ? 'Choose a division' : null,
                      onChanged: (v) {
                        setState(() {
                          _division = v;
                          _district = null;
                          _addressId = null;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _district,
                      key: ValueKey('dist-$_division-$_district'),
                      decoration: const InputDecoration(labelText: 'District'),
                      items: [
                        for (final d in meta.divisions[_division] ?? const <String>[]) DropdownMenuItem(value: d, child: Text(d)),
                      ],
                      validator: (v) => v == null ? 'Choose a district' : null,
                      onChanged: _division == null
                          ? null
                          : (v) {
                              setState(() {
                                _district = v;
                                _addressId = null;
                                if (meta.thanas[v]?.isNotEmpty ?? false) _area.clear();
                              });
                              _requote();
                            },
                    ),
                    const SizedBox(height: 12),
                    ThanaField(
                      thanas: meta.thanas[_district] ?? const [],
                      controller: _area,
                      onChanged: () => _addressId = null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _line,
                      decoration: const InputDecoration(labelText: 'House, road, landmark'),
                      validator: (v) => _required(v, 4, 'Enter house, road and other details'),
                      onChanged: (_) => _addressId = null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _note,
                      maxLength: 500,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Note for delivery (optional)'),
                    ),
                    if (auth.signedIn && _addressId == null)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: _saveAddress,
                        onChanged: (v) => setState(() => _saveAddress = v ?? false),
                        title: const Text('Save this address', style: TextStyle(fontSize: 14)),
                      ),
                  ]),
                ),
                const SizedBox(height: 16),
                const _H('Payment'),
                ListPanel(children: [
                  for (final p in meta.paymentMethods)
                    RadioListTile<String>(
                      value: p.id,
                      // ignore: deprecated_member_use
                      groupValue: _payment,
                      // ignore: deprecated_member_use
                      onChanged: p.enabled ? (v) => setState(() => _payment = v!) : null,
                      title: Text(p.label,
                          style: TextStyle(fontSize: 14, color: p.enabled ? Brand.ink : const Color(0xFF9CA3AF))),
                      subtitle: Text(p.note, style: const TextStyle(fontSize: 12)),
                    ),
                ]),
                if (!auth.signedIn) ...[
                  const SizedBox(height: 16),
                  Panel(
                    padding: const EdgeInsets.fromLTRB(4, 4, 16, 12),
                    child: Column(children: [
                      CheckboxListTile(
                        controlAffinity: ListTileControlAffinity.leading,
                        value: _createAccount,
                        onChanged: (v) => setState(() => _createAccount = v ?? false),
                        title: const Text('Create an account', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Track orders and save addresses. Otherwise you check out as a guest.',
                            style: TextStyle(fontSize: 12)),
                      ),
                      if (_createAccount)
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: TextFormField(
                            controller: _password,
                            obscureText: true,
                            decoration: const InputDecoration(labelText: 'Password (8+ characters)'),
                            validator: (v) => _createAccount && (v ?? '').length < 8
                                ? 'Password must be at least 8 characters'
                                : null,
                          ),
                        ),
                    ]),
                  ),
                ],
                const SizedBox(height: 16),
                const _H('Order summary'),
                Panel(
                  child: q == null
                      ? const Center(child: CircularProgressIndicator())
                      : Column(children: [
                          for (final i in q.items)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text('${i.brandName} × ${i.qty}', style: const TextStyle(fontSize: 14)),
                                    Muted(i.packLabel),
                                  ]),
                                ),
                                Text(taka(i.lineTotal), style: const TextStyle(fontSize: 14)),
                              ]),
                            ),
                          const Divider(height: 16),
                          _SumRow('Subtotal', taka(q.subtotal)),
                          const SizedBox(height: 6),
                          _SumRow('Delivery${_district != null ? ' ($_district)' : ''}',
                              q.deliveryFee == 0 ? 'Free' : taka(q.deliveryFee)),
                          const Divider(height: 20),
                          _SumRow('Total', taka(q.total), bold: true),
                        ]),
                ),
                const SizedBox(height: 12),
                const Muted('Prescription upload is available on the website checkout. We will call you to confirm your order.',
                    size: 11, align: TextAlign.center),
                const SizedBox(height: 16),
              ]),
            ),
      bottomNavigationBar: meta == null
          ? null
          : SafeArea(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : Text('Place order${q != null ? ' · ${taka(q.total)}' : ''}'),
                ),
              ),
            ),
    );
  }
}

class _H extends StatelessWidget {
  const _H(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 2),
        child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      );
}

// ───────────────────────────── Order ─────────────────────────────

class OrderScreen extends StatelessWidget {
  const OrderScreen({super.key, required this.code, this.phone, this.justPlaced = false});
  final String code;
  final String? phone;
  final bool justPlaced;

  @override
  Widget build(BuildContext context) {
    final api = context.read<Api>();
    final device = context.read<DeviceOrders>();
    final phone = this.phone ?? device.phoneFor(code);
    return Scaffold(
      appBar: AppBar(title: Text(justPlaced ? 'Order placed' : 'Order $code')),
      body: Loader<OrderDetail>(
        load: () async {
          final o = await api.order(code, phone: phone);
          if (phone != null) device.remember(o.code, phone);
          return o;
        },
        builder: (context, o, reload) => RefreshIndicator(
          onRefresh: reload,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            if (justPlaced) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Brand.c600, borderRadius: BorderRadius.circular(16)),
                child: Column(children: [
                  const Icon(Icons.check_circle_outline, color: Colors.white, size: 40),
                  const SizedBox(height: 8),
                  const Text('Order placed!', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(text: "We'll call ${o.phone} to confirm. Keep your order ID: "),
                      TextSpan(text: o.code, style: const TextStyle(fontWeight: FontWeight.w700)),
                    ]),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
            ],
            Panel(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Muted('Order'),
                      SelectableText(o.code,
                          style: const TextStyle(fontFamily: 'Menlo', fontWeight: FontWeight.w600, fontSize: 16)),
                    ]),
                  ),
                  StatusBadge(o.status),
                ]),
                const SizedBox(height: 16),
                StatusTimeline(o.status),
                const SizedBox(height: 12),
                Muted('Placed ${formatDate(o.createdAt)}'),
                if (o.riderName != null || o.trackingNote != null) ...[
                  const SizedBox(height: 12),
                  _RiderBox(o),
                ],
                if (o.events.isNotEmpty) ...[
                  const Divider(height: 28),
                  const Text('Updates', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  for (final e in o.events.reversed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 5),
                          child: Icon(Icons.circle, size: 8, color: Brand.c600),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(statusLabel(e.status), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                            if (e.note != null && e.note!.isNotEmpty) Muted(e.note!, size: 13),
                            Muted(formatDate(e.at), size: 11),
                          ]),
                        ),
                      ]),
                    ),
                ],
              ]),
            ),
            const SizedBox(height: 16),
            Panel(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Items', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                for (final i in o.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text.rich(TextSpan(children: [
                            TextSpan(text: i.brandName, style: const TextStyle(fontWeight: FontWeight.w500)),
                            TextSpan(text: ' × ${i.qty}', style: const TextStyle(color: Brand.muted)),
                          ]), style: const TextStyle(fontSize: 14)),
                          Muted('${i.packLabel} · ${i.description}'),
                        ]),
                      ),
                      Text(taka(i.unitPrice * i.qty), style: const TextStyle(fontSize: 14)),
                    ]),
                  ),
                const Divider(height: 8),
                const SizedBox(height: 8),
                _SumRow('Subtotal', taka(o.subtotal)),
                const SizedBox(height: 6),
                _SumRow('Delivery', o.deliveryFee == 0 ? 'Free' : taka(o.deliveryFee)),
                const Divider(height: 20),
                _SumRow('Total', taka(o.total), bold: true),
              ]),
            ),
            const SizedBox(height: 16),
            Panel(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Delivery', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(o.name, style: const TextStyle(fontSize: 14)),
                Muted(o.phone, size: 14),
                Muted(o.address, size: 14),
                if (o.note != null) ...[const SizedBox(height: 4), Muted('Note: ${o.note}', size: 14)],
                const Divider(height: 24),
                const Text('Payment', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Muted(
                  '${context.read<MetaModel>().meta?.paymentMethods.where((p) => p.id == o.paymentMethod).firstOrNull?.label ?? o.paymentMethod.toUpperCase()} · ${o.paymentStatus}',
                  size: 14,
                ),
              ]),
            ),
            if (justPlaced) ...[
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((r) => r.isFirst);
                  context.read<TabsModel>().go(TabsModel.home);
                },
                child: const Text('Continue shopping'),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

/// Customer-facing status names ("shipped" reads as "Out for delivery", as on the web).
String statusLabel(String s) => switch (s) {
      'shipped' => 'Out for delivery',
      '' => '',
      _ => s[0].toUpperCase() + s.substring(1),
    };

class _RiderBox extends StatelessWidget {
  const _RiderBox(this.o);
  final OrderDetail o;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Brand.c50, borderRadius: BorderRadius.circular(12)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.delivery_dining_outlined, color: Brand.c700),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (o.riderName != null)
                Text('Rider: ${o.riderName}${o.riderPhone != null ? ' · ${o.riderPhone}' : ''}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Brand.c700)),
              if (o.trackingNote != null && o.trackingNote!.isNotEmpty)
                Text(o.trackingNote!, style: const TextStyle(fontSize: 13, color: Brand.c700)),
            ]),
          ),
        ]),
      );
}

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      'delivered' => (Brand.c100, Brand.c700),
      'cancelled' => (const Color(0xFFFEE2E2), const Color(0xFFB91C1C)),
      _ => (const Color(0xFFFEF3C7), const Color(0xFF92400E)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Text(statusLabel(status),
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

class StatusTimeline extends StatelessWidget {
  const StatusTimeline(this.status, {super.key});
  final String status;
  static const steps = ['placed', 'confirmed', 'packed', 'shipped', 'delivered'];

  @override
  Widget build(BuildContext context) {
    if (status == 'cancelled') {
      return const Text('This order was cancelled.',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Brand.danger));
    }
    final idx = steps.indexOf(status);
    Color bar(bool on) => on ? Brand.c600 : const Color(0xFFE5E7EB);
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (final (i, s) in steps.indexed)
        Expanded(
          child: Column(children: [
            Row(children: [
              Expanded(child: Container(height: 2, color: i == 0 ? Colors.transparent : bar(i <= idx))),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(shape: BoxShape.circle, color: i <= idx ? Brand.c600 : const Color(0xFFE5E7EB)),
                child: Icon(Icons.check, size: 14, color: i <= idx ? Colors.white : const Color(0xFF9CA3AF)),
              ),
              Expanded(child: Container(height: 2, color: i == steps.length - 1 ? Colors.transparent : bar(i < idx))),
            ]),
            const SizedBox(height: 4),
            Text(
              statusLabel(s),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: i <= idx ? FontWeight.w500 : FontWeight.w400,
                color: i <= idx ? Brand.ink : const Color(0xFF9CA3AF),
              ),
            ),
          ]),
        ),
    ]);
  }
}

// ───────────────────────────── Track ─────────────────────────────

class TrackScreen extends StatefulWidget {
  const TrackScreen({super.key});

  @override
  State<TrackScreen> createState() => _TrackScreenState();
}

class _TrackScreenState extends State<TrackScreen> {
  final _form = GlobalKey<FormState>();
  final _code = TextEditingController(), _phone = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _track() async {
    if (!_form.currentState!.validate()) return;
    final code = _code.text.trim().toUpperCase();
    final phone = normalizePhone(_phone.text);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<Api>().order(code, phone: phone);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => OrderScreen(code: code, phone: phone)));
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final device = context.watch<DeviceOrders>();
    return Scaffold(
      appBar: AppBar(title: const Text('Track an order')),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: _Banner.error(_error!)),
          Panel(
            child: Column(children: [
              TextFormField(
                controller: _code,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Order ID', hintText: 'MCXXXXXXXXXX'),
                validator: (v) => (v ?? '').trim().length < 4 ? 'Enter your order ID' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Mobile number used for the order'),
                validator: (v) => bdPhone.hasMatch(normalizePhone(v ?? '')) ? null : 'Enter a valid mobile number',
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _busy ? null : _track, child: const Text('Track order')),
            ]),
          ),
          if (device.orders.isNotEmpty) ...[
            const SizedBox(height: 20),
            const _H('Orders on this device'),
            ListPanel(children: [
              for (final o in device.orders)
                ListTile(
                  title: Text(o.code, style: const TextStyle(fontFamily: 'Menlo', fontWeight: FontWeight.w600)),
                  subtitle: Text(o.phone),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => OrderScreen(code: o.code, phone: o.phone))),
                ),
            ]),
          ],
        ]),
      ),
    );
  }
}
