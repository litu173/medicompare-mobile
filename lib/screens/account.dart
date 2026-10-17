import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../actions.dart';
import '../api.dart';
import '../format.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'shop.dart';

// ───────────────────────────── Login / Register ─────────────────────────────

class _AuthScaffold extends StatelessWidget {
  const _AuthScaffold({required this.title, required this.subtitle, required this.children, this.art = 'community'});
  final String title, subtitle, art;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(),
        body: ListView(padding: const EdgeInsets.fromLTRB(24, 0, 24, 40), children: [
          Center(child: Illustration(art, height: 130)),
          const SizedBox(height: 20),
          const Wordmark(size: 22),
          const SizedBox(height: 10),
          Text(title, style: Txt.display(32, weight: FontWeight.w600)),
          const SizedBox(height: 6),
          Muted(subtitle, size: 15),
          const SizedBox(height: 24),
          ...children,
        ]),
      );
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.text);
  final String? text;

  @override
  Widget build(BuildContext context) => text == null
      ? const SizedBox.shrink()
      : Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFFFFEFEA), borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            const Icon(Icons.error_outline_rounded, color: Brand.danger, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(text!, style: Txt.ui(14, color: Brand.danger, weight: FontWeight.w600))),
          ]),
        );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController(), _password = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<AuthModel>().login(_email.text, _password.text);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _AuthScaffold(
        title: 'Welcome back',
        subtitle: 'Sign in to track orders and use saved addresses.',
        children: [
          _ErrorText(_error),
          Form(
            key: _form,
            child: AutofillGroup(
              child: Column(children: [
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline_rounded)),
                  validator: (v) => (v ?? '').contains('@') ? null : 'Enter your email',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline_rounded)),
                  validator: (v) => (v ?? '').isEmpty ? 'Enter your password' : null,
                  onFieldSubmitted: (_) => _submit(),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: _busy ? null : _submit, child: const Text('Sign in')),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.of(context)
                .pushReplacement(MaterialPageRoute(builder: (_) => const RegisterScreen())),
            child: const Text('New here? Create an account'),
          ),
          const SizedBox(height: 8),
          const Muted('Signed up with Google on the website? Google sign-in in the app is coming soon.',
              size: 12, align: TextAlign.center),
        ],
      );
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(),
      _email = TextEditingController(),
      _phone = TextEditingController(),
      _password = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<AuthModel>().register(
            name: _name.text.trim(),
            email: _email.text,
            phone: normalizePhone(_phone.text),
            password: _password.text,
          );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _AuthScaffold(
        title: 'Create an account',
        subtitle: 'See how much you save, track orders and check out faster.',
        art: 'welcome_save',
        children: [
          _ErrorText(_error),
          Form(
            key: _form,
            child: AutofillGroup(
              child: Column(children: [
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline_rounded)),
                  validator: (v) => (v ?? '').trim().length < 2 ? 'Please enter your name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline_rounded)),
                  validator: (v) =>
                      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch((v ?? '').trim()) ? null : 'Enter a valid email',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  decoration: const InputDecoration(
                      labelText: 'Mobile number (optional)', hintText: '01XXXXXXXXX', prefixIcon: Icon(Icons.phone_outlined)),
                  validator: (v) {
                    final p = normalizePhone(v ?? '');
                    return p.isEmpty || bdPhone.hasMatch(p) ? null : 'Enter a valid Bangladeshi mobile number (01XXXXXXXXX)';
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: const InputDecoration(labelText: 'Password (8+ characters)', prefixIcon: Icon(Icons.lock_outline_rounded)),
                  validator: (v) => (v ?? '').length < 8 ? 'Password must be at least 8 characters' : null,
                ),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: _busy ? null : _submit, child: const Text('Create account')),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen())),
            child: const Text('Already have an account? Sign in'),
          ),
        ],
      );
}

// ───────────────────────────── Account ─────────────────────────────

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthModel>();
    final user = auth.user;
    return Scaffold(
      appBar: AppBar(title: Text(user == null ? 'Account' : 'My account')),
      body: !auth.ready
          ? const SkeletonList(count: 3)
          : user == null
              ? const _SignedOut()
              : _SignedIn(key: ValueKey(user.id), user: user),
    );
  }
}

/// Shortcuts shared by signed-in and signed-out accounts.
class _Shortcuts extends StatelessWidget {
  const _Shortcuts({this.signOut = false});
  final bool signOut;

  @override
  Widget build(BuildContext context) {
    final support = context.watch<MetaModel>().meta?.supportPhone;
    return ListPanel(children: [
      if (support != null)
        _MenuTile(Icons.support_agent_rounded, 'Talk to a pharmacist', 'Ask before switching brands', () => callNumber(context, support)),
      _MenuTile(Icons.favorite_border_rounded, 'Invite your family', 'Help them pay a fair price too', () => shareApp(context)),
      _MenuTile(Icons.local_shipping_outlined, 'Track an order', null,
          () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TrackScreen()))),
      const _ServerTile(),
      if (signOut)
        ListTile(
          leading: const _MenuIcon(Icons.logout_rounded, danger: true),
          title: Text('Sign out', style: Txt.ui(15, weight: FontWeight.w700, color: Brand.danger)),
          onTap: () => context.read<AuthModel>().logout(),
        ),
    ]);
  }
}

class _MenuIcon extends StatelessWidget {
  const _MenuIcon(this.icon, {this.danger = false});
  final IconData icon;
  final bool danger;

  @override
  Widget build(BuildContext context) => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: danger ? const Color(0xFFFFEFEA) : Brand.c50, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, size: 20, color: danger ? Brand.danger : Brand.c600),
      );
}

class _MenuTile extends StatelessWidget {
  const _MenuTile(this.icon, this.title, this.subtitle, this.onTap);
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: _MenuIcon(icon),
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      );
}

class _SignedOut extends StatelessWidget {
  const _SignedOut();

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 120), children: [
        Panel(
          padding: const EdgeInsets.all(22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Center(child: Illustration('community', height: 110)),
            const SizedBox(height: 16),
            Text('Join Sashroy', textAlign: TextAlign.center, style: Txt.display(28, weight: FontWeight.w600)),
            const SizedBox(height: 6),
            const Muted('See your savings, track orders and save addresses. Guest checkout works too.',
                size: 14, align: TextAlign.center),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen())),
              child: const Text('Sign in'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
              child: const Text('Create an account'),
            ),
          ]),
        ),
        const SizedBox(height: 18),
        const _Shortcuts(),
      ]);
}

class _SignedIn extends StatefulWidget {
  const _SignedIn({super.key, required this.user});
  final User user;

  @override
  State<_SignedIn> createState() => _SignedInState();
}

class _SignedInState extends State<_SignedIn> {
  late Future<List<Address>> _addresses = context.read<Api>().addresses();

  Future<void> _reload() async {
    final f = context.read<Api>().addresses();
    setState(() => _addresses = f);
    await Future.wait([f.catchError((_) => <Address>[]), context.read<SavingsModel>().refresh()]);
  }

  Future<void> _delete(Address a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete address?'),
        content: Text(a.oneLine),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<Api>().deleteAddress(a.id);
      _reload();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _add() async {
    final saved = await Navigator.of(context, rootNavigator: true).push<bool>(MaterialPageRoute(builder: (_) => const AddressFormScreen()));
    if (saved == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    final savings = context.watch<SavingsModel>().savings;
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 120), children: [
        NightCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: const BoxDecoration(gradient: Brand.goldGradient, shape: BoxShape.circle),
                child: Text(u.name.isEmpty ? '?' : u.name[0].toUpperCase(), style: Txt.display(26, color: Brand.night, weight: FontWeight.w600)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(u.name, style: Txt.display(22, color: Colors.white, weight: FontWeight.w600)),
                  Text(u.email, style: Txt.ui(13, color: Colors.white.withValues(alpha: 0.7))),
                  if (u.phone != null) Text(u.phone!, style: Txt.ui(13, color: Colors.white.withValues(alpha: 0.7))),
                ]),
              ),
            ]),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(children: [
                const Icon(Icons.savings_outlined, color: Brand.gold2),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('SAVED WITH SASHROY', style: Txt.eyebrow(color: Brand.gold2)),
                    PriceText(savings.total, size: 22, color: Colors.white),
                  ]),
                ),
                if (savings.total >= 1)
                  TextButton(
                    onPressed: () => shareSavings(context, savings.total),
                    style: TextButton.styleFrom(foregroundColor: Brand.gold2),
                    child: const Text('Share'),
                  ),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 18),
        Panel(
          onTap: () => context.read<TabsModel>().go(TabsModel.orders),
          child: Row(children: [
            const _MenuIcon(Icons.receipt_long_rounded),
            const SizedBox(width: 14),
            Expanded(child: Text('My orders', style: Txt.ui(15, weight: FontWeight.w800))),
            const Icon(Icons.chevron_right_rounded),
          ]),
        ),
        const SizedBox(height: 24),
        FutureBuilder<List<Address>>(
          future: _addresses,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()));
            }
            if (snap.hasError) return ErrorView(snap.error!, onRetry: _reload);
            final addresses = snap.data!;
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              SectionHeader('Saved addresses', trailing: addresses.isEmpty ? null : '${addresses.length}'),
              ListPanel(children: [
                for (final a in addresses)
                  ListTile(
                    leading: const _MenuIcon(Icons.place_outlined),
                    title: Row(children: [
                      Flexible(child: Text(a.name)),
                      if (a.isDefault) const Padding(padding: EdgeInsets.only(left: 6), child: Tag('Default')),
                    ]),
                    subtitle: Text('${a.oneLine}\n${a.phone}'),
                    isThreeLine: true,
                    trailing: IconButton(tooltip: 'Delete address', icon: const Icon(Icons.delete_outline_rounded), onPressed: () => _delete(a)),
                  ),
                ListTile(
                  leading: const _MenuIcon(Icons.add_location_alt_outlined),
                  title: Text('Add an address', style: Txt.ui(15, weight: FontWeight.w700, color: Brand.c700)),
                  onTap: _add,
                ),
              ]),
            ]);
          },
        ),
        const SizedBox(height: 24),
        const _Shortcuts(signOut: true),
      ]),
    );
  }
}

class AddressFormScreen extends StatefulWidget {
  const AddressFormScreen({super.key});

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(),
      _phone = TextEditingController(),
      _area = TextEditingController(),
      _line = TextEditingController();
  String? _division, _district, _error;
  bool _isDefault = false, _busy = false;

  @override
  void initState() {
    super.initState();
    final u = context.read<AuthModel>().user;
    _name.text = u?.name ?? '';
    _phone.text = u?.phone ?? '';
    context.read<MetaModel>().get().ignore();
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _area, _line]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<Api>().addAddress({
        'name': _name.text.trim(),
        'phone': normalizePhone(_phone.text),
        'division': _division,
        'district': _district,
        'area': _area.text.trim(),
        'line': _line.text.trim(),
        'isDefault': _isDefault,
      });
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta = context.watch<MetaModel>().meta;
    return Scaffold(
      appBar: AppBar(title: const Text('New address')),
      body: meta == null
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _form,
              child: ListView(padding: const EdgeInsets.all(16), children: [
                _ErrorText(_error),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Recipient name'),
                  validator: (v) => (v ?? '').trim().length < 2 ? "Please enter the recipient's name" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Mobile number', hintText: '01XXXXXXXXX'),
                  validator: (v) => bdPhone.hasMatch(normalizePhone(v ?? '')) ? null : 'Enter a valid mobile number',
                ),
                const SizedBox(height: 12),
                PickerField(
                  label: 'Division',
                  icon: Icons.map_outlined,
                  options: meta.divisions.keys.toList(),
                  value: _division,
                  errorText: 'Choose a division',
                  onChanged: (v) => setState(() {
                    _division = v;
                    _district = null;
                    _area.clear();
                  }),
                ),
                const SizedBox(height: 12),
                PickerField(
                  label: 'District',
                  icon: Icons.location_city_outlined,
                  options: meta.divisions[_division] ?? const <String>[],
                  value: _district,
                  enabled: _division != null,
                  errorText: 'Choose a district',
                  onChanged: (v) => setState(() {
                    _district = v;
                    if (meta.thanas[v]?.isNotEmpty ?? false) _area.clear();
                  }),
                ),
                const SizedBox(height: 12),
                ThanaField(thanas: meta.thanas[_district] ?? const [], controller: _area),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _line,
                  decoration: const InputDecoration(labelText: 'House, road, landmark'),
                  validator: (v) => (v ?? '').trim().length < 4 ? 'Enter house, road and other details' : null,
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _isDefault,
                  onChanged: (v) => setState(() => _isDefault = v ?? false),
                  title: const Text('Make this my default address'),
                ),
                const SizedBox(height: 12),
                FilledButton(onPressed: _busy ? null : _save, child: const Text('Save address')),
              ]),
            ),
    );
  }
}

// ───────────────────────────── Server address ─────────────────────────────

class _ServerTile extends StatelessWidget {
  const _ServerTile();

  @override
  Widget build(BuildContext context) => ListTile(
    leading: const _MenuIcon(Icons.dns_outlined),
    title: const Text('Server address'),
    subtitle: Text(Uri.parse(context.watch<ServerModel>().address).authority),
    trailing: const Icon(Icons.chevron_right),
    onTap: () => openServerSettings(context),
  );
}

void openServerSettings(BuildContext context) =>
    Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (_) => const ServerSettingsScreen()));

/// Lets a tester point the app at their own backend, e.g. http://192.168.1.20:3000 on the same Wi-Fi.
class ServerSettingsScreen extends StatefulWidget {
  const ServerSettingsScreen({super.key});

  @override
  State<ServerSettingsScreen> createState() => _ServerSettingsScreenState();
}

class _ServerSettingsScreenState extends State<ServerSettingsScreen> {
  late final _controller = TextEditingController(text: apiBase);
  String? _error, _ok;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Checks that the address answers like a Sashroy server before saving it. Resetting to the built-in
  /// default skips the check, since that address (emulator/simulator host) is unreachable from a real phone.
  Future<void> _save(String input, {bool test = true}) async {
    final url = normalizeServerAddress(input);
    if (url == null) {
      setState(() => _error = 'Enter an address like http://192.168.1.20:3000');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _ok = null;
    });
    if (test) {
      try {
        final res = await http.get(Uri.parse('$url/api/v1/meta')).timeout(const Duration(seconds: 8));
        if (res.statusCode != 200 || !res.body.contains('divisions')) {
          throw Exception('Reached $url but it did not answer like a Sashroy server (HTTP ${res.statusCode}).');
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _busy = false;
            _error = e is Exception && e.toString().startsWith('Exception: Reached')
                ? e.toString().substring(11)
                : 'Could not connect to $url. Is the server running, and is this phone on the same Wi-Fi?';
          });
        }
        return;
      }
    }
    if (!mounted) return;
    final changed = url != apiBase;
    if (changed) {
      // Sessions belong to one server; sign out locally and reload reference data.
      await context.read<AuthModel>().forget();
      if (!mounted) return;
      context.read<MetaModel>().reset();
    }
    await context.read<ServerModel>().set(url);
    if (!mounted) return;
    _controller.text = apiBase;
    context.read<MetaModel>().get().ignore();
    if (changed) context.read<AuthModel>().load();
    setState(() {
      _busy = false;
      _ok = test ? 'Connected to ${Uri.parse(apiBase).authority}.' : 'Using the default server.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final server = context.watch<ServerModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Server address')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Muted(
            'The Sashroy server this app talks to. To test on a phone, run the website on your computer and enter '
            "its address on your Wi-Fi, e.g. http://192.168.1.20:3000 (find the IP in your computer's network settings).",
            size: 14,
          ),
          const SizedBox(height: 16),
          _ErrorText(_error),
          if (_ok != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Brand.c50, borderRadius: BorderRadius.circular(12)),
              child: Text(_ok!, style: const TextStyle(color: Brand.c700, fontSize: 14)),
            ),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: const InputDecoration(labelText: 'Server address', hintText: 'http://192.168.1.20:3000'),
            onSubmitted: _busy ? null : _save,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : () => _save(_controller.text),
            child: _busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : const Text('Test & save'),
          ),
          if (server.isCustom) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _busy ? null : () => _save(defaultApiBase, test: false),
              child: Text('Reset to default (${Uri.parse(defaultApiBase).authority})'),
            ),
          ],
        ],
      ),
    );
  }
}
