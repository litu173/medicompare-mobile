import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../actions.dart';
import '../api.dart';
import '../format.dart';
import '../i18n.dart';
import '../legal.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'account.dart';

void openSettings(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));

/// App settings: account, appearance, language, store connection, about & updates, legal.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthModel>();
    final settings = context.watch<SettingsModel>();
    final update = context.watch<UpdateModel>();
    final support = context.watch<MetaModel>().meta?.supportPhone;
    void push(Widget w) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));

    return Scaffold(
      appBar: AppBar(title: Text(tr('Settings'))),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 120), children: [
        if (update.available) ...[
          _UpdateBanner(update: update),
          const SizedBox(height: 18),
        ],
        if (auth.signedIn) ...[
          _Group(tr('Account'), [
            _Tile(Icons.person_outline_rounded, tr('Edit profile'), auth.user!.name, () => push(const EditProfileScreen())),
            _Tile(Icons.lock_outline_rounded, tr('Change password'), null, () => push(const ChangePasswordScreen())),
            _Tile(Icons.logout_rounded, tr('Sign out'), auth.user!.email, () async {
              await context.read<AuthModel>().logout();
              if (context.mounted) Navigator.of(context).pop();
            }),
            _Tile(Icons.delete_forever_outlined, tr('Delete account'), tr('Permanently remove your account'),
                () => _confirmDelete(context),
                danger: true),
          ]),
          const SizedBox(height: 18),
        ],
        _Group(tr('Appearance'), [
          Padding(
            padding: const EdgeInsets.all(14),
            child: _Segmented(
              value: settings.theme,
              options: [
                ('system', tr('System'), Icons.brightness_auto_rounded),
                ('light', tr('Light'), Icons.light_mode_rounded),
                ('dark', tr('Dark'), Icons.dark_mode_rounded),
              ],
              onChanged: context.read<SettingsModel>().setTheme,
            ),
          ),
        ]),
        const SizedBox(height: 18),
        _Group(tr('Language'), [
          Padding(
            padding: const EdgeInsets.all(14),
            child: _Segmented(
              value: settings.language,
              options: [('en', 'English', Icons.translate_rounded), ('bn', 'বাংলা', Icons.translate_rounded)],
              onChanged: context.read<SettingsModel>().setLanguage,
            ),
          ),
        ]),
        const SizedBox(height: 18),
        _Group(tr('Help & sharing'), [
          if (support != null)
            _Tile(Icons.support_agent_rounded, tr('Talk to a pharmacist'), support, () => callNumber(context, support)),
          _Tile(Icons.favorite_border_rounded, tr('Invite your family'), tr('Help them pay a fair price too'), () => shareApp(context)),
          _Tile(Icons.dns_outlined, tr('Server address'), Uri.parse(context.watch<ServerModel>().address).authority,
              () => openServerSettings(context)),
        ]),
        const SizedBox(height: 18),
        _Group(tr('About'), [
          _Tile(Icons.info_outline_rounded, tr('About Sashroy'), '${tr('Version')} ${update.currentVersion}', () => push(const AboutScreen())),
          _Tile(Icons.privacy_tip_outlined, tr('Privacy policy'), null,
              () => push(LegalScreen(title: tr('Privacy policy'), bnTitle: 'গোপনীয়তা নীতি', sections: privacyPolicy))),
          _Tile(Icons.gavel_rounded, tr('Terms & conditions'), null,
              () => push(LegalScreen(title: tr('Terms & conditions'), bnTitle: 'শর্তাবলী', sections: termsAndConditions))),
        ]),
      ]),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(tr('Delete your account?')),
        content: Text(tr('Your profile, saved addresses and sign-in are deleted for good. Past orders stay with the pharmacy as anonymous sales records.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(tr('Cancel'))),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Brand.danger),
            onPressed: () => Navigator.pop(c, true),
            child: Text(tr('Delete')),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await context.read<AuthModel>().deleteAccount();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Your account was deleted.'))));
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

class _Group extends StatelessWidget {
  const _Group(this.title, this.children);
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title.toUpperCase(), style: Txt.eyebrow(color: Brand.muted)),
        ),
        ListPanel(children: children),
      ]);
}

class _Tile extends StatelessWidget {
  const _Tile(this.icon, this.title, this.subtitle, this.onTap, {this.danger = false});
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: danger ? Brand.danger.withValues(alpha: 0.12) : Brand.c50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: danger ? Brand.danger : Brand.c700),
        ),
        title: Text(title, style: Txt.ui(15, weight: FontWeight.w700, color: danger ? Brand.danger : null)),
        subtitle: subtitle == null ? null : Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Icon(Icons.chevron_right_rounded, color: Brand.muted),
        onTap: onTap,
      );
}

/// Pill-style segmented control.
class _Segmented extends StatelessWidget {
  const _Segmented({required this.value, required this.options, required this.onChanged});
  final String value;
  final List<(String, String, IconData)> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: Brand.bg, borderRadius: BorderRadius.circular(18)),
        child: Row(children: [
          for (final (v, label, icon) in options)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(v),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: v == value ? Brand.night : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(icon, size: 16, color: v == value ? Brand.gold2 : Brand.muted),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(label,
                          overflow: TextOverflow.ellipsis,
                          style: Txt.ui(13.5, weight: FontWeight.w700, color: v == value ? Colors.white : Brand.ink)),
                    ),
                  ]),
                ),
              ),
            ),
        ]),
      );
}

class _UpdateBanner extends StatelessWidget {
  const _UpdateBanner({required this.update});
  final UpdateModel update;

  @override
  Widget build(BuildContext context) => NightCard(
        onTap: () => downloadUpdate(context, update),
        child: Row(children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(gradient: Brand.goldGradient, shape: BoxShape.circle),
            child: const Icon(Icons.system_update_rounded, color: Brand.night),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr('Update available'), style: Txt.display(20, color: Brand.gold2, weight: FontWeight.w600)),
              Text('${tr('Version')} ${update.latestVersion} · ${tr('Tap to download')}',
                  style: Txt.ui(13, color: Colors.white.withValues(alpha: 0.8))),
            ]),
          ),
          const Icon(Icons.download_rounded, color: Colors.white),
        ]),
      );
}

/// Opens the latest APK in the browser; Android then offers to install it.
Future<void> downloadUpdate(BuildContext context, UpdateModel update) async {
  final ok = await launchUrl(Uri.parse(update.downloadUrl), mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Open {url} in your browser.', {'url': landingUrl}))));
  }
}

// ───────────────────────────── About & updates ─────────────────────────────

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final u = context.watch<UpdateModel>();
    return Scaffold(
      appBar: AppBar(title: Text(tr('About Sashroy'))),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 40), children: [
        Panel(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const Illustration('community', height: 110),
            const SizedBox(height: 16),
            const Wordmark(size: 30),
            const SizedBox(height: 6),
            Text(tr('Same medicine. Honest price.'), style: Txt.display(20, weight: FontWeight.w500)),
            const SizedBox(height: 14),
            Text('${tr('Version')} ${u.currentVersion}', style: Txt.ui(14, weight: FontWeight.w700, color: Brand.muted)),
          ]),
        ),
        const SizedBox(height: 18),
        if (u.available)
          _UpdateBanner(update: u)
        else
          Panel(
            child: Row(children: [
              Icon(u.latestVersion == null ? Icons.update_rounded : Icons.verified_rounded, color: Brand.c600),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  u.error != null
                      ? tr(u.error!)
                      : u.latestVersion == null
                          ? tr('Check whether a newer version is available.')
                          : tr('You have the latest version.'),
                  style: Txt.ui(14, weight: FontWeight.w600),
                ),
              ),
            ]),
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: u.checking ? null : () => context.read<UpdateModel>().check(),
          icon: u.checking
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.refresh_rounded),
          label: Text(tr('Check for updates')),
        ),
        if (u.available && u.notes != null) ...[
          const SizedBox(height: 18),
          Text(tr("What's new"), style: Txt.display(18, weight: FontWeight.w600)),
          const SizedBox(height: 6),
          Muted(u.notes!, size: 14),
        ],
        const SizedBox(height: 24),
        Muted(tr('Prices come from an open, MedEx-derived dataset and are confirmed when we call about your order.'),
            size: 12, align: TextAlign.center),
        const SizedBox(height: 6),
        Muted(tr(disclaimer), size: 11, align: TextAlign.center),
      ]),
    );
  }
}

// ───────────────────────────── Legal ─────────────────────────────

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.title, required this.bnTitle, required this.sections});
  final String title, bnTitle;
  final List<LegalSection> sections;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 40), children: [
          Text(bnTitle, style: Txt.bn(16, color: Brand.goldDeep)),
          Text(tr('Last updated {date}', {'date': legalUpdated}), style: Txt.ui(13, color: Brand.muted)),
          if (isBangla) ...[
            const SizedBox(height: 8),
            Muted('এই নীতিমালার বাংলা সংস্করণ শীঘ্রই আসছে। নিচে ইংরেজি সংস্করণ দেওয়া হলো।', size: 13),
          ],
          const SizedBox(height: 14),
          for (final (i, s) in sections.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Panel(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text.rich(TextSpan(children: [
                    TextSpan(text: '${(i + 1).toString().padLeft(2, '0')}  ', style: Txt.display(18, color: Brand.goldDeep)),
                    TextSpan(text: s.title, style: Txt.display(18, weight: FontWeight.w600)),
                  ])),
                  const SizedBox(height: 8),
                  for (final p in s.body)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(p, style: Txt.ui(14, color: Brand.ink, weight: FontWeight.w500, height: 1.55)),
                    ),
                ]),
              ),
            ),
        ]),
      );
}

// ───────────────────────────── Account settings ─────────────────────────────

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: context.read<AuthModel>().user?.name ?? '');
  late final _phone = TextEditingController(text: context.read<AuthModel>().user?.phone ?? '');
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<AuthModel>().updateProfile(_name.text.trim(), normalizePhone(_phone.text));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Profile saved'))));
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = context.watch<AuthModel>().user?.email ?? '';
    return Scaffold(
      appBar: AppBar(title: Text(tr('Edit profile'))),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 40), children: [
          if (_error != null) _ErrorBox(_error!),
          Panel(
            child: Column(children: [
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: tr('Full name'), prefixIcon: const Icon(Icons.person_outline_rounded)),
                validator: (v) => (v ?? '').trim().length < 2 ? tr('Please enter your name') : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                    labelText: tr('Mobile number (optional)'), hintText: '01XXXXXXXXX', prefixIcon: const Icon(Icons.phone_outlined)),
                validator: (v) {
                  final p = normalizePhone(v ?? '');
                  return p.isEmpty || bdPhone.hasMatch(p) ? null : tr('Enter a valid mobile number');
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: email,
                readOnly: true,
                decoration: InputDecoration(
                    labelText: tr('Email'), helperText: tr('Email cannot be changed'), prefixIcon: const Icon(Icons.mail_outline_rounded)),
              ),
            ]),
          ),
          const SizedBox(height: 18),
          FilledButton(onPressed: _busy ? null : _save, child: Text(tr('Save changes'))),
        ]),
      ),
    );
  }
}

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController(), _next = TextEditingController(), _again = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_current, _next, _again]) {
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
      await context.read<Api>().changePassword(_current.text, _next.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Password changed'))));
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(tr('Change password'))),
        body: Form(
          key: _form,
          child: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 40), children: [
            if (_error != null) _ErrorBox(_error!),
            Panel(
              child: Column(children: [
                TextFormField(
                  controller: _current,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: tr('Current password'),
                    helperText: tr('Leave empty if you signed up with Google'),
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _next,
                  obscureText: true,
                  decoration: InputDecoration(labelText: tr('New password (8+ characters)'), prefixIcon: const Icon(Icons.lock_reset_rounded)),
                  validator: (v) => (v ?? '').length < 8 ? tr('Password must be at least 8 characters') : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _again,
                  obscureText: true,
                  decoration: InputDecoration(labelText: tr('Repeat new password'), prefixIcon: const Icon(Icons.lock_reset_rounded)),
                  validator: (v) => v != _next.text ? tr('Passwords do not match') : null,
                ),
              ]),
            ),
            const SizedBox(height: 18),
            FilledButton(onPressed: _busy ? null : _save, child: Text(tr('Change password'))),
          ]),
        ),
      );
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Brand.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
        child: Text(text, style: Txt.ui(14, color: Brand.danger, weight: FontWeight.w600)),
      );
}
