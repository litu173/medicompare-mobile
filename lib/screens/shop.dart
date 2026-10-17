import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../actions.dart';
import '../api.dart';
import '../format.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'account.dart';
import 'catalog.dart';
import '../i18n.dart';

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

  /// Replaces a cart line with its cheaper equivalent, keeping the same number of units.
  void _switch(CartLine line, QuoteLine q) {
    final c = q.cheaper;
    if (c == null || c.packId == null || c.price == null || c.packLabel == null) return;
    HapticFeedback.mediumImpact();
    final samePieces = isPerPiece(line.packLabel) && isPerPiece(c.packLabel);
    _cart.remove(line.packId);
    _cart.add(CartLine(
      packId: c.packId!,
      medicineId: c.medicineId,
      brandName: c.brandName,
      description: c.manufacturer,
      packLabel: c.packLabel!,
      price: c.price!,
      qty: samePieces ? line.qty : line.qty.clamp(1, 99),
    ));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(tr('Switched to {name} · same medicine, {n}% cheaper', {'name': c.brandName, 'n': c.savePct}))));
  }

  void _switchAll(Quote q) {
    for (final l in [..._cart.lines]) {
      final ql = q.items.where((i) => i.packId == l.packId).firstOrNull;
      if (ql?.cheaper?.packId != null) _switch(l, ql!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartModel>();
    return Scaffold(
      appBar: AppBar(title: Text(cart.isEmpty ? tr('Cart') : '${tr('Cart')} · ${cart.count}')),
      body: cart.isEmpty ? _empty(context) : _filled(context, cart),
    );
  }

  Widget _empty(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(32, 0, 32, 120),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Illustration('empty_cart', height: 190),
            SizedBox(height: 16),
            Text(tr('Your cart is empty'), style: Txt.display(26, weight: FontWeight.w600)),
            SizedBox(height: 6),
            Muted(tr('Search a medicine and pick the cheapest equal brand.'), align: TextAlign.center, size: 15),
            SizedBox(height: 22),
            SizedBox(
              width: 230,
              child: FilledButton.icon(
                onPressed: () => context.read<TabsModel>().focusSearch(),
                icon: Icon(Icons.search_rounded),
                label: Text(tr('Search medicines')),
              ),
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
    final switchable = q?.items.where((i) => i.cheaper?.packId != null).toList() ?? [];
    final potential = switchable.fold<double>(0, (s, i) => s + i.lineTotal * i.cheaper!.savePct / 100);

    return Column(children: [
      Expanded(
        child: RefreshIndicator(
          onRefresh: () {
            _quotedFor = null;
            return _requote();
          },
          child: ListView(padding: EdgeInsets.fromLTRB(20, 4, 20, 20), children: [
            if (_error != null) Padding(padding: EdgeInsets.only(bottom: 12), child: _Banner.error(_error.toString())),
            if (potential >= 1) ...[
              NightCard(
                padding: EdgeInsets.all(18),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(tr('SWITCH & SAVE'), style: Txt.eyebrow(color: Brand.gold2)),
                      SizedBox(height: 4),
                      Text.rich(TextSpan(style: Txt.ui(14, color: Colors.white, height: 1.4), children: [
                        TextSpan(text: tr('Same medicines, cheaper brands. Save about ')),
                        TextSpan(text: taka(potential.round()), style: Txt.display(18, color: Brand.gold2, weight: FontWeight.w600)),
                      ])),
                    ]),
                  ),
                  SizedBox(width: 10),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Brand.gold,
                      foregroundColor: Brand.night,
                      minimumSize: Size(0, 44),
                      padding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onPressed: () => _switchAll(q!),
                    child: Text(tr('Switch all'), style: Txt.ui(14, weight: FontWeight.w800, color: Brand.night)),
                  ),
                ]),
              ),
              SizedBox(height: 16),
            ],
            for (final l in cart.lines)
              Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: _CartLineCard(
                  line: l,
                  quoted: q == null ? null : byPack[l.packId],
                  quoteLoaded: q != null,
                  onSwitch: (ql) => _switch(l, ql),
                ),
              ),
            if (q != null) ...[
              SizedBox(height: 4),
              Panel(
                child: Column(children: [
                  _SumRow(tr('Subtotal'), taka(q.subtotal)),
                  SizedBox(height: 8),
                  _SumRow(tr('Delivery (Dhaka)'), q.deliveryFee == 0 ? tr('Free') : taka(q.deliveryFee)),
                  Divider(height: 24),
                  _SumRow(tr('Total'), taka(q.total), bold: true),
                  if (q.subtotal < freeOver) ...[
                    SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: (q.subtotal / freeOver).clamp(0, 1).toDouble(),
                        minHeight: 8,
                        backgroundColor: Brand.c50,
                        color: Brand.gold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(tr('Add {amount} more for free delivery', {'amount': taka(freeOver - q.subtotal)}),
                        style: Txt.ui(12, weight: FontWeight.w700, color: Brand.goldDeep)),
                  ],
                  SizedBox(height: 6),
                  Muted(tr('Delivery outside Dhaka is calculated at checkout.'), size: 11),
                ]),
              ),
            ],
          ]),
        ),
      ),
      _BottomBar(
        child: FilledButton(
          onPressed: upToDate && q.allAvailable
              ? () => Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (_) => CheckoutScreen()))
              : null,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(q != null && !q.allAvailable ? tr('Fix items above to continue') : tr('Checkout')),
            if (q != null && q.allAvailable) ...[
              SizedBox(width: 8),
              Text('· ${taka(q.total)}'),
              SizedBox(width: 6),
              Icon(Icons.arrow_forward_rounded, size: 20),
            ],
          ]),
        ),
      ),
    ]);
  }
}

/// Sticky bar above the floating tab bar.
class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.child, this.clearNav = true});
  final Widget child;
  final bool clearNav;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, clearNav ? 96 + MediaQuery.paddingOf(context).bottom : 12),
        decoration: BoxDecoration(
          color: Brand.bg,
          boxShadow: [BoxShadow(color: Brand.night.withValues(alpha: 0.06), blurRadius: 20, offset: Offset(0, -6))],
        ),
        child: child,
      );
}

class _CartLineCard extends StatelessWidget {
  const _CartLineCard({required this.line, required this.quoted, required this.quoteLoaded, required this.onSwitch});
  final CartLine line;
  final QuoteLine? quoted;
  final bool quoteLoaded;
  final ValueChanged<QuoteLine> onSwitch;

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartModel>();
    final q = quoted;
    final gone = quoteLoaded && q == null;
    return Dismissible(
      key: ValueKey('line-${line.packId}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 24),
        decoration: BoxDecoration(color: Color(0xFFFFE9E3), borderRadius: BorderRadius.circular(22)),
        child: Icon(Icons.delete_outline_rounded, color: Brand.danger),
      ),
      onDismissed: (_) => cart.remove(line.packId),
      child: Panel(
        padding: EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            InkWell(
              onTap: () => openMedicine(context, line.medicineId),
              child: ProductThumb(q?.image, size: 60, form: q?.description ?? line.description),
            ),
            SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () => openMedicine(context, line.medicineId),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(line.brandName, style: Txt.ui(16, weight: FontWeight.w800)),
                  Muted(q?.description ?? line.description, maxLines: 1),
                  SizedBox(height: 2),
                  Muted('${line.packLabel} · ${taka(q?.price ?? line.price)} each'),
                ]),
              ),
            ),
            IconButton(
              tooltip: tr('Remove'),
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.close_rounded, size: 20, color: Brand.muted),
              onPressed: () => cart.remove(line.packId),
            ),
          ]),
          SizedBox(height: 10),
          Row(children: [
            QtyStepper(compact: true, value: line.qty, onChanged: (v) => cart.setQty(line.packId, v)),
            Spacer(),
            PriceText(q?.lineTotal ?? line.price * line.qty, size: 20),
          ]),
          if (gone)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(tr('No longer available · please remove'), style: Txt.ui(12, color: Brand.danger, weight: FontWeight.w700)),
            )
          else if (q != null && !q.available)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                q.maxQty == 0 ? tr('Out of stock · switch to an alternative') : tr('Only {n} available', {'n': q.maxQty}),
                style: Txt.ui(12, weight: FontWeight.w700, color: Brand.danger),
              ),
            ),
          if (q?.cheaper case final c?)
            Container(
              margin: EdgeInsets.only(top: 12),
              padding: EdgeInsets.fromLTRB(12, 10, 8, 10),
              decoration: BoxDecoration(color: Brand.c50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Brand.c100)),
              child: Row(children: [
                Icon(Icons.trending_down_rounded, size: 20, color: Brand.c700),
                SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => openMedicine(context, c.medicineId),
                    child: Text.rich(TextSpan(style: Txt.ui(12.5, color: Brand.c900, height: 1.35), children: [
                      TextSpan(text: c.brandName, style: Txt.ui(12.5, weight: FontWeight.w800, color: Brand.c900)),
                      TextSpan(text: ' (${c.manufacturer}) is the same medicine and ${c.savePct}% cheaper'),
                    ])),
                  ),
                ),
                if (c.packId != null)
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Brand.c600,
                      foregroundColor: Colors.white,
                      minimumSize: Size(0, 34),
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      shape: StadiumBorder(),
                    ),
                    onPressed: () => onSwitch(q!),
                    child: Text(tr('Switch'), style: Txt.ui(13, weight: FontWeight.w800, color: Colors.white)),
                  ),
              ]),
            ),
        ]),
      ),
    );
  }
}

class _SumRow extends StatelessWidget {
  const _SumRow(this.label, this.value, {this.bold = false});
  final String label, value;
  final bool bold;

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
          child: Text(label,
              style: bold ? Txt.ui(16, weight: FontWeight.w800) : Txt.ui(14, color: Brand.muted, weight: FontWeight.w600)),
        ),
        Text(value, style: bold ? Txt.display(22, weight: FontWeight.w600) : Txt.ui(14, weight: FontWeight.w700)),
      ]);
}

class _Banner extends StatelessWidget {
  const _Banner.error(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(color: Color(0xFFFFEFEA), borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Icon(Icons.error_outline_rounded, size: 20, color: Brand.danger),
          SizedBox(width: 10),
          Expanded(child: Text(text, style: Txt.ui(14, color: Brand.danger, weight: FontWeight.w600))),
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
      setState(() => _error = tr('Please check the highlighted fields.'));
      return;
    }
    final cart = context.read<CartModel>();
    final auth = context.read<AuthModel>();
    final device = context.read<DeviceOrders>();
    final savings = context.read<SavingsModel>();
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
      savings.refresh().ignore();
      HapticFeedback.heavyImpact();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => OrderScreen(code: code, phone: phone, justPlaced: true)),
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
      _scroll.animateTo(0, duration: Duration(milliseconds: 250), curve: Curves.easeOut);
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
      appBar: AppBar(title: Text(tr('Checkout'))),
      body: meta == null
          ? (_error != null ? ErrorView(_error!) : SkeletonList())
          : Form(
              key: _form,
              child: ListView(controller: _scroll, padding: EdgeInsets.fromLTRB(20, 4, 20, 24), children: [
                if (_error != null) Padding(padding: EdgeInsets.only(bottom: 14), child: _Banner.error(_error!)),
                if (!auth.signedIn)
                  Panel(
                    padding: EdgeInsets.fromLTRB(18, 8, 8, 8),
                    child: Row(children: [
                      Icon(Icons.person_outline_rounded, color: Brand.c600),
                      SizedBox(width: 10),
                      Expanded(child: Text(tr('Checking out as a guest'), style: Txt.ui(14, weight: FontWeight.w700))),
                      TextButton(
                        onPressed: () async {
                          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => LoginScreen()));
                          if (mounted) _prefill();
                        },
                        child: Text(tr('Sign in')),
                      ),
                    ]),
                  ),
                if (!auth.signedIn) SizedBox(height: 18),
                if (_addresses.isNotEmpty) ...[
                  _Step(1, tr('Saved addresses')),
                  ListPanel(children: [
                    for (final a in _addresses)
                      RadioListTile<int?>(
                        value: a.id,
                        // ignore: deprecated_member_use
                        groupValue: _addressId,
                        // ignore: deprecated_member_use
                        onChanged: (_) => _useAddress(a),
                        title: Text(a.name),
                        subtitle: Text('${a.oneLine} · ${a.phone}'),
                      ),
                    RadioListTile<int?>(
                      value: null,
                      // ignore: deprecated_member_use
                      groupValue: _addressId,
                      // ignore: deprecated_member_use
                      onChanged: (_) => setState(() => _addressId = null),
                      title: Text(tr('Use a new address')),
                    ),
                  ]),
                  SizedBox(height: 20),
                ],
                _Step(_addresses.isEmpty ? 1 : 2, tr('Delivery details')),
                Panel(
                  child: Column(children: [
                    TextFormField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(labelText: tr('Recipient name'), prefixIcon: Icon(Icons.person_outline_rounded)),
                      validator: (v) => _required(v, 2, "Please enter the recipient's name"),
                      onChanged: (_) => _addressId = null,
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                          labelText: tr('Mobile number'), hintText: tr('01XXXXXXXXX'), prefixIcon: Icon(Icons.phone_outlined)),
                      validator: (v) =>
                          bdPhone.hasMatch(normalizePhone(v ?? '')) ? null : tr('Enter a valid Bangladeshi mobile number (01XXXXXXXXX)'),
                      onChanged: (_) => _addressId = null,
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      readOnly: auth.signedIn,
                      decoration: InputDecoration(
                          labelText: auth.signedIn ? tr('Email') : tr('Email (optional)'), prefixIcon: Icon(Icons.mail_outline_rounded)),
                      validator: (v) {
                        final s = (v ?? '').trim();
                        if (s.isEmpty) return _createAccount && !auth.signedIn ? tr('Email is needed to create an account') : null;
                        return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s) ? null : tr('Enter a valid email');
                      },
                    ),
                    SizedBox(height: 12),
                    PickerField(
                      label: tr('Division'),
                      icon: Icons.map_outlined,
                      options: meta.divisions.keys.toList(),
                      value: _division,
                      errorText: tr('Choose a division'),
                      onChanged: (v) => setState(() {
                        _division = v;
                        _district = null;
                        _area.clear();
                        _addressId = null;
                      }),
                    ),
                    SizedBox(height: 12),
                    PickerField(
                      label: tr('District'),
                      icon: Icons.location_city_outlined,
                      options: meta.divisions[_division] ?? <String>[],
                      value: _district,
                      enabled: _division != null,
                      errorText: tr('Choose a district'),
                      onChanged: (v) {
                        setState(() {
                          _district = v;
                          _addressId = null;
                          if (meta.thanas[v]?.isNotEmpty ?? false) _area.clear();
                        });
                        _requote();
                      },
                    ),
                    SizedBox(height: 12),
                    ThanaField(thanas: meta.thanas[_district] ?? [], controller: _area, onChanged: () => _addressId = null),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _line,
                      decoration: InputDecoration(labelText: tr('House, road, landmark'), prefixIcon: Icon(Icons.home_outlined)),
                      validator: (v) => _required(v, 4, tr('Enter house, road and other details')),
                      onChanged: (_) => _addressId = null,
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _note,
                      maxLength: 500,
                      maxLines: 2,
                      decoration: InputDecoration(labelText: tr('Note for delivery (optional)'), prefixIcon: Icon(Icons.edit_note_rounded)),
                    ),
                    if (auth.signedIn && _addressId == null)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: _saveAddress,
                        onChanged: (v) => setState(() => _saveAddress = v ?? false),
                        title: Text(tr('Save this address')),
                      ),
                  ]),
                ),
                SizedBox(height: 20),
                _Step(_addresses.isEmpty ? 2 : 3, tr('Payment')),
                ListPanel(children: [
                  for (final p in meta.paymentMethods)
                    RadioListTile<String>(
                      value: p.id,
                      // ignore: deprecated_member_use
                      groupValue: _payment,
                      // ignore: deprecated_member_use
                      onChanged: p.enabled ? (v) => setState(() => _payment = v!) : null,
                      secondary: Icon(p.id == 'cod' ? Icons.payments_outlined : Icons.account_balance_wallet_outlined,
                          color: p.enabled ? Brand.c600 : Brand.muted),
                      title: Text(p.label, style: Txt.ui(15, weight: FontWeight.w700, color: p.enabled ? Brand.ink : Brand.muted)),
                      subtitle: Text(p.note),
                    ),
                ]),
                if (!auth.signedIn) ...[
                  SizedBox(height: 16),
                  Panel(
                    padding: EdgeInsets.fromLTRB(4, 4, 16, 12),
                    child: Column(children: [
                      CheckboxListTile(
                        controlAffinity: ListTileControlAffinity.leading,
                        value: _createAccount,
                        onChanged: (v) => setState(() => _createAccount = v ?? false),
                        title: Text(tr('Create an account')),
                        subtitle: Text(tr('Track orders, see your savings and save addresses.')),
                      ),
                      if (_createAccount)
                        Padding(
                          padding: EdgeInsets.only(left: 12),
                          child: TextFormField(
                            controller: _password,
                            obscureText: true,
                            decoration: InputDecoration(labelText: tr('Password (8+ characters)'), prefixIcon: Icon(Icons.lock_outline)),
                            validator: (v) => _createAccount && (v ?? '').length < 8 ? tr('Password must be at least 8 characters') : null,
                          ),
                        ),
                    ]),
                  ),
                ],
                SizedBox(height: 20),
                _Step(_addresses.isEmpty ? 3 : 4, tr('Review')),
                Panel(
                  child: q == null
                      ? Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
                      : Column(children: [
                          for (final i in q.items)
                            Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: Row(children: [
                                ProductThumb(i.image, size: 44, form: i.description),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text('${i.brandName} × ${i.qty}', style: Txt.ui(14, weight: FontWeight.w700)),
                                    Muted(i.packLabel),
                                  ]),
                                ),
                                Text(taka(i.lineTotal), style: Txt.ui(14, weight: FontWeight.w700)),
                              ]),
                            ),
                          Divider(height: 16),
                          _SumRow(tr('Subtotal'), taka(q.subtotal)),
                          SizedBox(height: 8),
                          _SumRow('${tr('Delivery')}${_district != null ? ' ($_district)' : ''}', q.deliveryFee == 0 ? tr('Free') : taka(q.deliveryFee)),
                          Divider(height: 24),
                          _SumRow(tr('Total'), taka(q.total), bold: true),
                        ]),
                ),
                SizedBox(height: 14),
                Muted(tr('We will call you to confirm. Prescription upload is available on the website checkout.'),
                    size: 11, align: TextAlign.center),
              ]),
            ),
      bottomNavigationBar: meta == null
          ? null
          : SafeArea(
              child: _BottomBar(
                clearNav: false,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.lock_outline_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('${tr('Place order')}${q != null ? ' · ${taka(q.total)}' : ''}'),
                        ]),
                ),
              ),
            ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step(this.n, this.text);
  final int n;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: 10, left: 2),
        child: Row(children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Brand.night, shape: BoxShape.circle),
            child: Text('$n', style: Txt.ui(12, weight: FontWeight.w800, color: Brand.gold2)),
          ),
          SizedBox(width: 10),
          Text(text, style: Txt.display(20, weight: FontWeight.w600)),
        ]),
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
      appBar: AppBar(title: Text(justPlaced ? tr('Order placed') : tr('Track order'))),
      body: Loader<(OrderDetail, double)>(
        load: () async {
          final o = await api.order(code, phone: phone);
          if (phone != null) device.remember(o.code, phone);
          double saved = 0;
          try {
            final s = await api.savings(phone == null ? [] : [(code: o.code, phone: phone)]);
            saved = s.byOrder[o.code] ?? 0;
          } catch (_) {}
          return (o, saved);
        },
        builder: (context, data, reload) {
          final (o, saved) = data;
          final supportPhone = context.watch<MetaModel>().meta?.supportPhone;
          return RefreshIndicator(
            onRefresh: reload,
            child: ListView(padding: EdgeInsets.fromLTRB(20, 4, 20, 24), children: [
              if (justPlaced) ...[
                Panel(
                  color: Brand.c50,
                  child: Column(children: [
                    Illustration('order_success', height: 170, semanticLabel: 'Happy customer with the parcel'),
                    SizedBox(height: 8),
                    Text(tr('ধন্যবাদ! Thank you'), style: Txt.bn(16, color: Brand.c700)),
                    Text(tr('Order placed'), style: Txt.display(30, weight: FontWeight.w600)),
                    SizedBox(height: 6),
                    Muted("We'll call ${o.phone} to confirm. Keep your order ID handy.", size: 14, align: TextAlign.center),
                  ]),
                ),
                SizedBox(height: 16),
              ],
              if (saved >= 1) ...[
                NightCard(
                  child: Row(children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(gradient: Brand.goldGradient, shape: BoxShape.circle),
                      child: Icon(Icons.savings_outlined, color: Brand.night),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(tr('YOU SAVED'), style: Txt.eyebrow(color: Brand.gold2)),
                        PriceText(saved, size: 28, color: Colors.white),
                        Text(tr('vs the typical price of the same medicines'),
                            style: Txt.ui(12, color: Colors.white.withValues(alpha: 0.7))),
                      ]),
                    ),
                    IconButton(
                      tooltip: tr('Share'),
                      onPressed: () => shareSavings(context, saved),
                      icon: Icon(Icons.ios_share_rounded, color: Brand.gold2),
                    ),
                  ]),
                ),
                SizedBox(height: 16),
              ],
              Panel(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(tr('ORDER ID'), style: Txt.eyebrow(color: Brand.muted)),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(o.code, style: Txt.ui(20, weight: FontWeight.w800, spacing: 1)),
                        ),
                      ]),
                    ),
                    IconButton(
                      tooltip: tr('Copy order ID'),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: o.code));
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Order ID copied'))));
                      },
                      icon: Icon(Icons.copy_rounded, size: 20),
                    ),
                    StatusBadge(o.status),
                  ]),
                  SizedBox(height: 4),
                  Muted('Placed ${formatDate(o.createdAt)}'),
                  SizedBox(height: 18),
                  StatusTimeline(o.status, events: o.events),
                  if (o.riderName != null || o.trackingNote != null) ...[
                    SizedBox(height: 16),
                    _RiderBox(o),
                  ],
                ]),
              ),
              SizedBox(height: 16),
              Panel(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(tr('Items'), style: Txt.display(20, weight: FontWeight.w600)),
                  SizedBox(height: 14),
                  for (final i in o.items)
                    Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Row(children: [
                        ProductThumb(i.image, size: 46, form: i.description),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('${i.brandName} × ${i.qty}', style: Txt.ui(14, weight: FontWeight.w700)),
                            Muted('${i.packLabel} · ${i.description}', maxLines: 1),
                          ]),
                        ),
                        Text(taka(i.unitPrice * i.qty), style: Txt.ui(14, weight: FontWeight.w700)),
                      ]),
                    ),
                  Divider(height: 16),
                  _SumRow(tr('Subtotal'), taka(o.subtotal)),
                  SizedBox(height: 8),
                  _SumRow(tr('Delivery'), o.deliveryFee == 0 ? tr('Free') : taka(o.deliveryFee)),
                  Divider(height: 24),
                  _SumRow(tr('Total'), taka(o.total), bold: true),
                ]),
              ),
              SizedBox(height: 16),
              Panel(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(tr('Delivery'), style: Txt.display(20, weight: FontWeight.w600)),
                  SizedBox(height: 8),
                  Text(o.name, style: Txt.ui(15, weight: FontWeight.w700)),
                  Muted(o.phone, size: 14),
                  Muted(o.address, size: 14),
                  if (o.note != null) ...[SizedBox(height: 4), Muted('Note: ${o.note}', size: 14)],
                  Divider(height: 26),
                  Text(tr('Payment'), style: Txt.display(20, weight: FontWeight.w600)),
                  SizedBox(height: 4),
                  Muted(
                    '${context.read<MetaModel>().meta?.paymentMethods.where((p) => p.id == o.paymentMethod).firstOrNull?.label ?? o.paymentMethod.toUpperCase()} · ${o.paymentStatus}',
                    size: 14,
                  ),
                ]),
              ),
              if (supportPhone != null) ...[
                SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => callNumber(context, supportPhone),
                  icon: Icon(Icons.support_agent_rounded),
                  label: Text(tr('Talk to a pharmacist')),
                ),
              ],
              if (justPlaced) ...[
                SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((r) => r.isFirst);
                    context.read<TabsModel>().go(TabsModel.home);
                  },
                  child: Text(tr('Continue shopping')),
                ),
              ],
            ]),
          );
        },
      ),
    );
  }
}

/// Customer-facing status names ("shipped" reads as "Out for delivery", as on the web).
String statusLabel(String s) => switch (s) {
      'placed' => tr('Order placed'),
      'shipped' => tr('Out for delivery'),
      '' => '',
      _ => tr(s[0].toUpperCase() + s.substring(1)),
    };

class _RiderBox extends StatelessWidget {
  const _RiderBox(this.o);
  final OrderDetail o;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(color: Brand.c50, borderRadius: BorderRadius.circular(18)),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: Brand.surface, shape: BoxShape.circle),
            child: Icon(Icons.delivery_dining_rounded, color: Brand.c600),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (o.riderName != null) Text('${o.riderName} is bringing your order', style: Txt.ui(14, weight: FontWeight.w800)),
              if (o.trackingNote != null && o.trackingNote!.isNotEmpty) Muted(o.trackingNote!, size: 13),
              if (o.paymentMethod == 'cod' && o.paymentStatus != 'paid') Muted('Keep ${taka(o.total)} ready (cash on delivery)', size: 13),
            ]),
          ),
          if (o.riderPhone != null)
            IconButton.filled(
              tooltip: 'Call ${o.riderName ?? 'rider'}',
              style: IconButton.styleFrom(backgroundColor: Brand.c600),
              onPressed: () => callNumber(context, o.riderPhone!),
              icon: Icon(Icons.call_rounded, color: Colors.white),
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
      'cancelled' => (Color(0xFFFFE9E3), Brand.danger),
      'shipped' => (Color(0xFFE3EDFF), Color(0xFF1D4ED8)),
      _ => (Brand.goldBg, Brand.goldDeep),
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Text(statusLabel(status), style: Txt.ui(12, weight: FontWeight.w800, color: fg)),
    );
  }
}

/// Vertical tracker with an icon and timestamp for each step.
class StatusTimeline extends StatelessWidget {
  const StatusTimeline(this.status, {super.key, this.events = const []});
  final String status;
  final List<({String status, String? note, DateTime at})> events;
  static const steps = [
    ('placed', Icons.receipt_long_rounded, 'We received your order'),
    ('confirmed', Icons.verified_rounded, 'Confirmed by our pharmacist'),
    ('packed', Icons.inventory_2_rounded, 'Every item checked and packed'),
    ('shipped', Icons.delivery_dining_rounded, 'On the way to you'),
    ('delivered', Icons.home_rounded, 'Delivered. Get well soon!'),
  ];

  @override
  Widget build(BuildContext context) {
    if (status == 'cancelled') {
      final e = events.where((e) => e.status == 'cancelled').firstOrNull;
      return Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(color: Color(0xFFFFEFEA), borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Icon(Icons.cancel_outlined, color: Brand.danger),
          SizedBox(width: 10),
          Expanded(
            child: Text(e?.note != null ? tr('This order was cancelled: {note}', {'note': e!.note!}) : tr('This order was cancelled.'),
                style: Txt.ui(14, weight: FontWeight.w700, color: Brand.danger)),
          ),
        ]),
      );
    }
    final idx = steps.indexWhere((s) => s.$1 == status);
    final at = {for (final e in events) e.status: e.at};
    return Column(children: [
      for (final (i, (s, icon, detail)) in steps.indexed)
        IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(
              width: 40,
              child: Column(children: [
                AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i <= idx ? Brand.c600 : Brand.surface,
                    border: Border.all(color: i <= idx ? Brand.c600 : Brand.line, width: 2),
                    boxShadow: i == idx ? [BoxShadow(color: Brand.c600.withValues(alpha: 0.35), blurRadius: 12)] : null,
                  ),
                  child: Icon(icon, size: 18, color: i <= idx ? Colors.white : Brand.muted),
                ),
                if (i < steps.length - 1)
                  Expanded(child: Container(width: 2, margin: EdgeInsets.symmetric(vertical: 2), color: i < idx ? Brand.c600 : Brand.line)),
              ]),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 6, bottom: i < steps.length - 1 ? 18 : 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                      child: Text(statusLabel(s),
                          style: Txt.ui(15, weight: FontWeight.w800, color: i <= idx ? Brand.ink : Brand.muted)),
                    ),
                    if (at[s] != null) Text(formatShort(at[s]!), style: Txt.ui(11, color: Brand.muted, weight: FontWeight.w600)),
                  ]),
                  if (i <= idx) Muted(tr(detail), size: 13),
                ]),
              ),
            ),
          ]),
        ),
    ]);
  }
}

// ───────────────────────────── Orders tab ─────────────────────────────

/// Account orders (signed in) plus guest orders remembered on this device, with a tracker form.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  Future<List<OrderSummary>>? _account;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  void _load() {
    final auth = context.read<AuthModel>();
    _account = auth.signedIn ? context.read<Api>().orders() : Future.value([]);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AuthModel>();
    final device = context.watch<DeviceOrders>();
    final savings = context.watch<SavingsModel>().savings;
    return Scaffold(
      appBar: AppBar(title: Text(tr('Orders'))),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(_load);
          await Future.wait([_account!.catchError((_) => <OrderSummary>[]), context.read<SavingsModel>().refresh()]);
        },
        child: FutureBuilder<List<OrderSummary>>(
          future: _account,
          builder: (context, snap) {
            final account = snap.data ?? <OrderSummary>[];
            final accountCodes = {for (final o in account) o.code};
            final guest = device.orders.where((o) => !accountCodes.contains(o.code)).toList();
            final empty = account.isEmpty && guest.isEmpty;
            return ListView(padding: EdgeInsets.fromLTRB(20, 4, 20, 120), children: [
              if (savings.total >= 1) ...[
                NightCard(
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(tr('TOTAL SAVED'), style: Txt.eyebrow(color: Brand.gold2)),
                        PriceText(savings.total, size: 30, color: Colors.white),
                      ]),
                    ),
                    TextButton.icon(
                      onPressed: () => shareSavings(context, savings.total),
                      style: TextButton.styleFrom(foregroundColor: Brand.gold2),
                      icon: Icon(Icons.ios_share_rounded, size: 18),
                      label: Text(tr('Share')),
                    ),
                  ]),
                ),
                SizedBox(height: 18),
              ],
              if (snap.connectionState == ConnectionState.waiting)
                Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
              else if (empty)
                Panel(
                  padding: EdgeInsets.all(24),
                  child: Column(children: [
                    Illustration('welcome_delivery', height: 150),
                    SizedBox(height: 10),
                    Text(tr('No orders yet'), style: Txt.display(22, weight: FontWeight.w600)),
                    SizedBox(height: 4),
                    Muted(tr('Orders you place appear here with a live tracker.'), align: TextAlign.center, size: 14),
                  ]),
                )
              else ...[
                if (account.isNotEmpty) ...[
                  SectionHeader(tr('My orders')),
                  ListPanel(children: [
                    for (final o in account)
                      ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: _OrderIcon(),
                        title: Text(o.code, style: Txt.ui(15, weight: FontWeight.w800, spacing: 0.5)),
                        subtitle: Text(
                            '${formatDate(o.createdAt, time: false)} · ${o.itemCount} item${o.itemCount == 1 ? tr('') : tr('s')} · ${taka(o.total)}'),
                        trailing: StatusBadge(o.status),
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => OrderScreen(code: o.code))),
                      ),
                  ]),
                  SizedBox(height: 20),
                ],
                if (guest.isNotEmpty) ...[
                  SectionHeader(tr('On this phone')),
                  ListPanel(children: [
                    for (final o in guest)
                      ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: _OrderIcon(),
                        title: Text(o.code, style: Txt.ui(15, weight: FontWeight.w800, spacing: 0.5)),
                        subtitle: Text(o.phone),
                        trailing: Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => OrderScreen(code: o.code, phone: o.phone))),
                      ),
                  ]),
                ],
              ],
              SizedBox(height: 20),
              Panel(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TrackScreen())),
                child: Row(children: [
                  _OrderIcon(icon: Icons.manage_search_rounded),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(tr('Track another order'), style: Txt.ui(15, weight: FontWeight.w800)),
                      Muted(tr('Use the order ID and mobile number'), size: 13),
                    ]),
                  ),
                  Icon(Icons.chevron_right_rounded),
                ]),
              ),
            ]);
          },
        ),
      ),
    );
  }
}

class _OrderIcon extends StatelessWidget {
  const _OrderIcon({this.icon = Icons.receipt_long_rounded});
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: Brand.c50, borderRadius: BorderRadius.circular(14)),
        child: Icon(icon, color: Brand.c600),
      );
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
      context.read<DeviceOrders>().remember(code, phone);
      context.read<SavingsModel>().refresh().ignore();
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => OrderScreen(code: code, phone: phone)));
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(tr('Track an order'))),
        body: Form(
          key: _form,
          child: ListView(padding: EdgeInsets.fromLTRB(20, 4, 20, 120), children: [
            Center(child: Illustration('welcome_delivery', height: 170)),
            SizedBox(height: 16),
            if (_error != null) Padding(padding: EdgeInsets.only(bottom: 12), child: _Banner.error(_error!)),
            Panel(
              child: Column(children: [
                TextFormField(
                  controller: _code,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(labelText: tr('Order ID'), hintText: tr('MCXXXXXXXXXX'), prefixIcon: Icon(Icons.tag_rounded)),
                  validator: (v) => (v ?? '').trim().length < 4 ? tr('Enter your order ID') : null,
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(labelText: tr('Mobile number used for the order'), prefixIcon: Icon(Icons.phone_outlined)),
                  validator: (v) => bdPhone.hasMatch(normalizePhone(v ?? '')) ? null : tr('Enter a valid mobile number'),
                ),
                SizedBox(height: 18),
                FilledButton(onPressed: _busy ? null : _track, child: Text(tr('Track order'))),
              ]),
            ),
          ]),
        ),
      );
}
