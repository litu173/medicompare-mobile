import 'dart:async';

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

// Navigation helpers: push within the current tab's navigator so the bottom bar stays.
void openMedicine(BuildContext context, int id) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductScreen(id: id)));
void openGeneric(BuildContext context, String slug, {String? focus}) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => GenericScreen(slug: slug, focusKey: focus)));
void openCompany(BuildContext context, String slug, String name) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => CompanyScreen(slug: slug, name: name)));
void openSearch(BuildContext context, String q) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => SearchScreen(initialQuery: q)));
void openCompanies(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CompaniesScreen()));

/// Bottom space so content clears the floating tab bar.
const navClearance = SizedBox(height: 110);

String _greeting(String? name) {
  final h = DateTime.now().hour;
  final part = h < 12 ? 'Good morning' : (h < 17 ? 'Good afternoon' : 'Good evening');
  final first = name?.trim().split(' ').first;
  return first == null || first.isEmpty ? part : '$part, $first';
}

// ───────────────────────────── Home ─────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scroll = ScrollController();

  /// True once the dark hero has scrolled away: show an ivory status-bar backdrop with dark icons.
  final _pastHero = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() => _pastHero.value = _scroll.offset > 380);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _pastHero.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final api = context.read<Api>();
    final top = MediaQuery.paddingOf(context).top;
    return ValueListenableBuilder<bool>(
      valueListenable: _pastHero,
      builder: (context, past, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        // Only while Home is the visible tab; other tabs have light backgrounds.
        value: past || context.watch<TabsModel>().index != TabsModel.home ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
        child: Scaffold(
          body: Stack(children: [
            child!,
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: top,
              child: IgnorePointer(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: past ? 1 : 0,
                  child: const ColoredBox(color: Brand.bg),
                ),
              ),
            ),
          ]),
        ),
      ),
      child: Loader<HomeData>(
        load: api.home,
        builder: (context, d, reload) => RefreshIndicator(
          onRefresh: () async {
            await Future.wait([reload(), context.read<SavingsModel>().refresh()]);
          },
          child: ListView(controller: _scroll, padding: EdgeInsets.zero, children: [
            _HomeHero(d),
            const SizedBox(height: 20),
            gutter(const _SavingsCard()),
            const SizedBox(height: 22),
            gutter(const _QuickActions()),
            const SizedBox(height: 28),
            gutter(const SectionHeader('Popular searches', eyebrow: 'Start here')),
            HScroll(children: [
              for (final s in d.popular) Pill(s, icon: Icons.search_rounded, onTap: () => openSearch(context, s)),
            ]),
            const SizedBox(height: 30),
            gutter(SectionHeader('Biggest price gaps',
                eyebrow: 'Same medicine, different price', action: 'Companies', onAction: () => openCompanies(context))),
            SizedBox(
              height: 172,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                clipBehavior: Clip.none,
                itemCount: d.gaps.length,
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (context, i) => SizedBox(width: 270, child: _GapCard(d.gaps[i])),
              ),
            ),
            const SizedBox(height: 30),
            gutter(const _CommunityCard()),
            const SizedBox(height: 30),
            gutter(const SectionHeader('How Sashroy works', eyebrow: 'Four calm steps')),
            gutter(const _HowItWorks()),
            const SizedBox(height: 24),
            gutter(const Muted(disclaimer, size: 11, align: TextAlign.center)),
            navClearance,
          ]),
        ),
      ),
    );
  }
}

class _HomeHero extends StatelessWidget {
  const _HomeHero(this.d);
  final HomeData d;

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthModel, User?>((a) => a.user);
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 14, 20, 26),
      decoration: const BoxDecoration(
        gradient: Brand.heroGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned(
          right: -60,
          top: -40,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [Brand.c500.withValues(alpha: 0.35), Colors.transparent]),
            ),
          ),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Wordmark(light: true, size: 26),
            const Spacer(),
            InkWell(
              customBorder: const CircleBorder(),
              onTap: () => context.read<TabsModel>().go(TabsModel.account),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Brand.gold.withValues(alpha: 0.18),
                child: user == null
                    ? const Icon(Icons.person_outline_rounded, color: Brand.gold2)
                    : Text(user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
                        style: Txt.display(18, color: Brand.gold2, weight: FontWeight.w600)),
              ),
            ),
          ]),
          const SizedBox(height: 26),
          Text(_greeting(user?.name), style: Txt.ui(14, color: Colors.white.withValues(alpha: 0.75))),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(children: [
              const TextSpan(text: 'Same medicine.\n'),
              TextSpan(text: 'Honest', style: Txt.display(36, color: Brand.gold2, weight: FontWeight.w400, style: FontStyle.italic)),
              const TextSpan(text: ' price.'),
            ]),
            style: Txt.display(36, color: Colors.white, weight: FontWeight.w400, height: 1.05),
          ),
          const SizedBox(height: 8),
          Text('একই ওষুধ, সাশ্রয়ী দামে', style: Txt.bn(16, color: Brand.mint, weight: FontWeight.w500)),
          const SizedBox(height: 22),
          SearchField(readOnly: true, onTap: () => context.read<TabsModel>().focusSearch()),
          const SizedBox(height: 18),
          Row(children: [
            for (final (n, l) in [(d.medicines, 'medicines'), (d.generics, 'generics'), (d.companies, 'companies')])
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Column(children: [
                    Text(formatNumber(n), style: Txt.display(20, color: Colors.white, weight: FontWeight.w500)),
                    Text(l, style: Txt.ui(11, color: Colors.white.withValues(alpha: 0.65))),
                  ]),
                ),
              ),
          ]),
        ]),
      ]),
    );
  }
}

/// Lifetime savings, or an invitation to start.
class _SavingsCard extends StatelessWidget {
  const _SavingsCard();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SavingsModel>().savings;
    if (s.total < 1) {
      return Panel(
        padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('YOUR SAVINGS', style: Txt.eyebrow()),
              const SizedBox(height: 6),
              Text('Every order shows how much you saved.', style: Txt.display(19, weight: FontWeight.w600, height: 1.2)),
              const SizedBox(height: 6),
              const Muted('Compared with the typical price of the same medicine.', size: 12),
              const SizedBox(height: 12),
              SizedBox(
                height: 42,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 42), padding: const EdgeInsets.symmetric(horizontal: 16)),
                  onPressed: () => context.read<TabsModel>().focusSearch(),
                  icon: const Icon(Icons.search_rounded, size: 18),
                  label: Text('Start comparing', style: Txt.ui(14, weight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ]),
          ),
          const Illustration('welcome_save', height: 110),
        ]),
      );
    }
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(gradient: Brand.goldGradient, borderRadius: BorderRadius.circular(26), boxShadow: Brand.shadow),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('YOU HAVE SAVED', style: Txt.eyebrow()),
              const SizedBox(height: 4),
              PriceText(s.total, size: 38, color: Brand.c700),
              Muted('vs the typical price, across ${s.orders} order${s.orders == 1 ? '' : 's'}', size: 12),
            ]),
          ),
          Column(children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(gradient: Brand.goldGradient, shape: BoxShape.circle),
              child: const Icon(Icons.savings_outlined, color: Brand.night, size: 26),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => shareSavings(context, s.total),
              icon: const Icon(Icons.ios_share_rounded, size: 16),
              label: const Text('Share'),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final tabs = context.read<TabsModel>();
    final items = [
      (Icons.compare_arrows_rounded, 'Compare', tabs.focusSearch),
      (Icons.local_shipping_outlined, 'Track order', () => tabs.go(TabsModel.orders)),
      (Icons.apartment_rounded, 'Companies', () => openCompanies(context)),
      (Icons.favorite_border_rounded, 'Invite family', () => shareApp(context)),
    ];
    return Row(children: [
      for (final (icon, label, onTap) in items)
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: Brand.shadow),
                  child: Icon(icon, color: Brand.c600, size: 26),
                ),
                const SizedBox(height: 8),
                Text(label, textAlign: TextAlign.center, style: Txt.ui(12, weight: FontWeight.w700)),
              ]),
            ),
          ),
        ),
    ]);
  }
}

class _GapCard extends StatelessWidget {
  const _GapCard(this.g);
  final PriceGap g;

  @override
  Widget build(BuildContext context) => NightCard(
        onTap: () => openMedicine(context, g.topId),
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(g.genericName,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: Txt.display(20, color: Colors.white, weight: FontWeight.w500)),
            ),
            const Icon(Icons.arrow_outward_rounded, color: Brand.gold2, size: 20),
          ]),
          const SizedBox(height: 2),
          Text('${g.strength ?? ''} · ${g.formGroup} · ${g.brands} brands',
              maxLines: 1, overflow: TextOverflow.ellipsis, style: Txt.ui(12, color: Colors.white.withValues(alpha: 0.65))),
          const Spacer(),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            PriceText(g.minPrice, size: 26, color: Brand.mint),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: PriceText(g.maxPrice, unit: g.unit, size: 15, color: Colors.white.withValues(alpha: 0.55), strike: true),
            ),
          ]),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(gradient: Brand.goldGradient, borderRadius: BorderRadius.circular(99)),
            child: Text('up to ${savingsPct(g.minPrice, g.maxPrice)}% less',
                style: Txt.ui(12, weight: FontWeight.w800, color: Brand.night)),
          ),
        ]),
      );
}

class _CommunityCard extends StatelessWidget {
  const _CommunityCard();

  @override
  Widget build(BuildContext context) => Panel(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        color: Brand.goldBg,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Center(child: Illustration('community', height: 120, semanticLabel: 'Families using Sashroy')),
          const SizedBox(height: 16),
          Text('সবার জন্য সাশ্রয়', style: Txt.bn(16, color: Brand.goldDeep)),
          const SizedBox(height: 4),
          Text('Saving is better together.', style: Txt.display(24, weight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            'Most people never learn a cheaper equal brand exists. Share Sashroy with your parents, neighbours and '
            'family group so everyone pays a fair price for the same medicine.',
            style: Txt.ui(14, color: const Color(0xFF4A4232), height: 1.55),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Brand.night),
            onPressed: () => shareApp(context),
            icon: const Icon(Icons.ios_share_rounded, size: 20),
            label: const Text('Share with family'),
          ),
        ]),
      );
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    const steps = [
      (Icons.search_rounded, 'Search', 'Type the brand on your prescription or the chemical name.'),
      (Icons.compare_arrows_rounded, 'Compare', 'Every equivalent, cheapest first, with stock and savings.'),
      (Icons.shopping_bag_outlined, 'Order', 'Choose your thana and pay cash on delivery.'),
      (Icons.verified_outlined, 'Receive', 'Checked item by item, packed, and tracked to your door.'),
    ];
    return ListPanel(children: [
      for (final (i, (icon, title, body)) in steps.indexed)
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: Brand.c50, borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: Brand.c600),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('0${i + 1} · $title', style: Txt.ui(15, weight: FontWeight.w800)),
                const SizedBox(height: 2),
                Muted(body, size: 13),
              ]),
            ),
          ]),
        ),
    ]);
  }
}

// ───────────────────────────── Search ─────────────────────────────

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.initialQuery = '', this.isTabRoot = false});
  final String initialQuery;
  final bool isTabRoot;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final _controller = TextEditingController(text: widget.initialQuery);
  final _focus = FocusNode();
  late String _query = widget.initialQuery;
  String? _form;
  Future<SearchResult>? _results;
  Suggestions? _suggestions;
  bool _typing = false;
  Timer? _debounce;
  HomeData? _home;
  TabsModel? _tabs;
  int _lastFocusRequest = 0;

  Api get _api => context.read<Api>();

  @override
  void initState() {
    super.initState();
    if (_query.isNotEmpty) _results = _api.search(_query);
    _api.home().then((h) => mounted ? setState(() => _home = h) : null, onError: (_) {});
    if (widget.isTabRoot) {
      _tabs = context.read<TabsModel>();
      _lastFocusRequest = _tabs!.searchFocusRequest;
      _tabs!.addListener(_onTabs);
    }
  }

  /// Home's search bar jumps here and focuses the field.
  void _onTabs() {
    final t = _tabs!;
    if (t.searchFocusRequest != _lastFocusRequest && t.index == TabsModel.search) {
      _lastFocusRequest = t.searchFocusRequest;
      Future.delayed(const Duration(milliseconds: 120), () {
        if (mounted) _focus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _tabs?.removeListener(_onTabs);
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit(String q) {
    q = q.trim();
    FocusScope.of(context).unfocus();
    _controller.text = q;
    setState(() {
      _typing = false;
      _query = q;
      _form = null;
      _results = q.isEmpty ? null : _api.search(q);
    });
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    if (q.trim().length < 2) {
      setState(() {
        _typing = q.isNotEmpty;
        _suggestions = null;
      });
      return;
    }
    setState(() => _typing = true);
    _debounce = Timer(const Duration(milliseconds: 220), () async {
      try {
        final s = await _api.suggest(q.trim());
        if (mounted && _controller.text == q) setState(() => _suggestions = s);
      } catch (_) {}
    });
  }

  void _setForm(String? f) => setState(() {
        _form = f;
        _results = _api.search(_query, form: f);
      });

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Row(children: [
              if (canPop)
                IconButton(onPressed: () => Navigator.of(context).maybePop(), icon: const Icon(Icons.arrow_back_rounded)),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('FIND A CHEAPER EQUAL', style: Txt.eyebrow()),
                  Text('Search', style: Txt.display(32, weight: FontWeight.w600)),
                ]),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: SearchField(
              controller: _controller,
              focusNode: _focus,
              autofocus: !widget.isTabRoot && _query.isEmpty,
              onChanged: _onChanged,
              onSubmitted: _submit,
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _typing ? _suggestionList() : _body(),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _suggestionList() {
    final s = _suggestions;
    final q = _controller.text.trim();
    return ListView(key: const ValueKey('suggest'), padding: const EdgeInsets.fromLTRB(20, 0, 20, 120), children: [
      ListPanel(children: [
        ListTile(
          leading: const _CircleIcon(Icons.search_rounded),
          title: Text('Search “$q”'),
          subtitle: const Text('See every equivalent, cheapest first'),
          onTap: () => _submit(q),
        ),
        if (s != null) ...[
          for (final b in s.brands)
            ListTile(
              leading: const _CircleIcon(Icons.medication_outlined),
              title: Text(b.name),
              subtitle: Text(b.detail, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => openMedicine(context, b.id),
            ),
          for (final g in s.generics)
            ListTile(
              leading: const _CircleIcon(Icons.science_outlined, gold: true),
              title: Text(g.name),
              subtitle: Text('Generic · ${g.brandCount} brands'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => openGeneric(context, g.slug),
            ),
        ],
      ]),
    ]);
  }

  Widget _body() {
    if (_results == null) {
      return ListView(key: const ValueKey('idle'), padding: const EdgeInsets.fromLTRB(20, 8, 20, 120), children: [
        Text('Popular searches', style: Txt.ui(14, weight: FontWeight.w800)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final s in _home?.popular ?? const <String>[]) Pill(s, onTap: () => _submit(s)),
        ]),
        const SizedBox(height: 28),
        Panel(
          color: Brand.goldBg,
          child: Row(children: [
            const Illustration('welcome_compare', height: 100),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Tip', style: Txt.eyebrow()),
                const SizedBox(height: 4),
                Text('Search the chemical name printed on the strip to see every brand of it.',
                    style: Txt.ui(14, weight: FontWeight.w600, height: 1.45)),
              ]),
            ),
          ]),
        ),
      ]);
    }
    return FutureBuilder<SearchResult>(
      key: ValueKey('results-$_query-$_form'),
      future: _results,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const SkeletonList();
        if (snap.hasError) return ErrorView(snap.error!, onRetry: () => _setForm(_form));
        final r = snap.data!;
        return ListView(padding: const EdgeInsets.only(top: 4, bottom: 120), children: [
          if (r.generics.isNotEmpty) ...[
            HScroll(children: [
              for (final g in r.generics)
                Material(
                  color: Brand.c50,
                  shape: const StadiumBorder(side: BorderSide(color: Brand.c100)),
                  child: InkWell(
                    onTap: () => openGeneric(context, g.slug),
                    customBorder: const StadiumBorder(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.science_outlined, size: 16, color: Brand.c700),
                        const SizedBox(width: 6),
                        Text(g.name, style: Txt.ui(14, weight: FontWeight.w700, color: Brand.c700)),
                        const SizedBox(width: 6),
                        Text('${g.brandCount}', style: Txt.ui(12, color: Brand.c700)),
                      ]),
                    ),
                  ),
                ),
            ]),
            const SizedBox(height: 10),
          ],
          if (r.forms.length > 1) ...[
            HScroll(spacing: 8, children: [
              Pill('All forms', selected: _form == null, onTap: () => _setForm(null)),
              for (final f in r.forms) Pill(f.form, selected: _form == f.form, onTap: () => _setForm(f.form)),
            ]),
            const SizedBox(height: 14),
          ],
          if (r.groups.isEmpty)
            gutter(Panel(
              padding: const EdgeInsets.all(28),
              child: Column(children: [
                const Illustration('empty_cart', height: 120),
                const SizedBox(height: 12),
                Text('No medicines found for “$_query”', textAlign: TextAlign.center, style: Txt.display(20, weight: FontWeight.w600)),
                const SizedBox(height: 6),
                const Muted('Check the spelling, or try the generic name (e.g. Paracetamol).', align: TextAlign.center, size: 14),
              ]),
            ))
          else ...[
            gutter(Muted('Results for “$_query” · equivalents sorted cheapest first', size: 13)),
            const SizedBox(height: 12),
            for (final g in r.groups) gutter(Padding(padding: const EdgeInsets.only(bottom: 18), child: _GroupCard(g, _query))),
          ],
        ]);
      },
    );
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon(this.icon, {this.gold = false});
  final IconData icon;
  final bool gold;

  @override
  Widget build(BuildContext context) => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: gold ? Brand.goldBg : Brand.c50, shape: BoxShape.circle),
        child: Icon(icon, size: 20, color: gold ? Brand.goldDeep : Brand.c600),
      );
}

/// One equivalence group. When the user typed a brand, that brand heads the group.
class _GroupCard extends StatelessWidget {
  const _GroupCard(this.g, this.q);
  final SearchGroup g;
  final String q;
  static const preview = 6;

  @override
  Widget build(BuildContext context) {
    final ql = q.toLowerCase();
    final matched = g.items.where((i) => g.matchedIds.contains(i.id)).toList();
    final brandSearch = matched.isNotEmpty && !g.genericName.toLowerCase().contains(ql);
    final hero = brandSearch
        ? (matched.where((i) => i.brandName.toLowerCase() == ql).firstOrNull ??
            matched.where((i) => i.brandName.toLowerCase().startsWith(ql)).firstOrNull ??
            matched.first)
        : null;
    final rest = g.items.where((i) => i.id != hero?.id).toList();
    final shown = rest.take(preview).toList();
    final reference = hero?.comparePrice ?? g.maxPrice;
    final save = g.minPrice != null && g.maxPrice != null ? savingsPct(g.minPrice!, g.maxPrice!) : 0;

    return Panel(
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (hero != null)
          _SearchedHero(m: hero, items: g.items)
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(text: g.genericName),
                      if (g.strength != null)
                        TextSpan(text: '  ${g.strength}', style: Txt.ui(15, color: Brand.muted, weight: FontWeight.w700)),
                    ]),
                    style: Txt.display(21, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Muted('${g.form} · ${g.total} brand${g.total > 1 ? 's' : ''}', size: 13),
                ]),
              ),
              if (save > 0 && g.total > 1) Tag.gold('Save up to $save%'),
            ]),
          ),
        if (shown.isNotEmpty) ...[
          if (hero != null)
            Container(
              color: Brand.bg,
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
              child: Text('SAME MEDICINE FROM OTHER COMPANIES · CHEAPEST FIRST', style: Txt.eyebrow(color: Brand.muted)),
            ),
          for (final (i, m) in shown.indexed) ...[
            if (i > 0) const Divider(indent: 16, endIndent: 16),
            MedicineTile(m: m, cheapest: i == 0 && g.total > 1, reference: reference),
          ],
        ],
        if (rest.length > shown.length)
          InkWell(
            onTap: () => g.genericSlug != null
                ? openGeneric(context, g.genericSlug!, focus: g.equivKey)
                : openMedicine(context, g.items.first.id),
            child: Container(
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: Brand.line))),
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('See all ${g.total} brands', style: Txt.ui(14, weight: FontWeight.w800, color: Brand.c700)),
                const Icon(Icons.chevron_right_rounded, size: 20, color: Brand.c700),
              ]),
            ),
          ),
      ]),
    );
  }
}

class _SearchedHero extends StatelessWidget {
  const _SearchedHero({required this.m, required this.items});
  final Medicine m;
  final List<Medicine> items;

  @override
  Widget build(BuildContext context) {
    final cheaper = items
        .where((i) => i.id != m.id && !i.priceSuspect && i.comparePrice != null && m.comparePrice != null && i.comparePrice! < m.comparePrice!)
        .toList();
    final best = cheaper.where((i) => i.stock > 0).firstOrNull ?? cheaper.firstOrNull;
    return InkWell(
      onTap: () => openMedicine(context, m.id),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('YOU SEARCHED', style: Txt.eyebrow()),
          const SizedBox(height: 10),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ProductThumb(m.image, size: 68, form: m.dosageForm),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text.rich(
                  TextSpan(children: [
                    TextSpan(text: m.brandName),
                    if (m.strength != null) TextSpan(text: '  ${m.strength}', style: Txt.ui(15, color: Brand.muted, weight: FontWeight.w700)),
                  ]),
                  style: Txt.display(26, weight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text('${m.dosageForm} · ${m.genericName}', style: Txt.ui(13, color: Brand.muted, weight: FontWeight.w600)),
                Text(m.manufacturerName, style: Txt.ui(13, color: Brand.muted)),
                const SizedBox(height: 8),
                Row(children: [
                  PriceText(m.comparePrice, unit: m.compareUnit, size: 22),
                  if (m.outOfStock) ...[const SizedBox(width: 8), const Tag.warn('Out of stock')],
                ]),
              ]),
            ),
            AddControl(m: m),
          ]),
          if (best != null && m.comparePrice != null && best.comparePrice != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(gradient: Brand.heroGradient, borderRadius: BorderRadius.circular(18)),
              child: Row(children: [
                const Icon(Icons.trending_down_rounded, color: Brand.mint, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Text.rich(TextSpan(style: Txt.ui(14, color: Colors.white, height: 1.4), children: [
                    TextSpan(text: '${cheaper.length} cheaper equal${cheaper.length > 1 ? 's' : ''} below. '),
                    TextSpan(
                      text: 'Save up to ${savingsPct(best.comparePrice!, m.comparePrice!)}%',
                      style: Txt.ui(14, color: Brand.gold2, weight: FontWeight.w800),
                    ),
                  ])),
                ),
              ]),
            ),
          ] else if (items.length > 1) ...[
            const SizedBox(height: 12),
            const Tag('This is already the lowest price', icon: Icons.verified_rounded),
          ],
        ]),
      ),
    );
  }
}

// ───────────────────────────── Product ─────────────────────────────

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key, required this.id});
  final int id;

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final _altKey = GlobalKey();

  void _toAlternatives() {
    final ctx = _altKey.currentContext;
    if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final api = context.read<Api>();
    return Scaffold(
      appBar: AppBar(title: const Text('Medicine')),
      body: Loader<MedicineDetail>(
        load: () => api.medicine(widget.id),
        builder: (context, d, reload) {
          final m = d.medicine;
          final eq = d.equivalents;
          final cheaper = d.alternatives
              .where((a) => a.comparePrice != null && !a.priceSuspect && m.comparePrice != null && a.comparePrice! < m.comparePrice!)
              .toList();
          final cheapest = eq.where((e) => e.comparePrice != null && !e.priceSuspect && e.stock > 0).firstOrNull;
          final rank = eq.indexWhere((e) => e.id == m.id) + 1;
          final maxSave = cheapest != null && m.comparePrice != null ? savingsPct(cheapest.comparePrice!, m.comparePrice!) : 0;
          final out = m.stock <= 0;

          return RefreshIndicator(
            onRefresh: reload,
            child: ListView(padding: const EdgeInsets.only(top: 4), children: [
              gutter(Panel(
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ProductThumb(m.image, size: 96, form: m.dosageForm),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Wrap(spacing: 6, runSpacing: 6, children: [
                          Tag(m.dosageForm, bg: Brand.bg, fg: Brand.muted),
                          if (m.type == 'herbal') const Tag('Herbal', bg: Color(0xFFECFCCB), fg: Color(0xFF3F6212)),
                        ]),
                        const SizedBox(height: 8),
                        Text(m.brandName, style: Txt.display(30, weight: FontWeight.w600)),
                        if (m.strength != null) Text(m.strength!, style: Txt.ui(16, color: Brand.muted, weight: FontWeight.w700)),
                        if (m.image == null) ...[const SizedBox(height: 4), const Muted('Product photo coming soon', size: 11)],
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _LinkRow(
                    icon: Icons.science_outlined,
                    label: 'Generic',
                    text: m.genericName,
                    onTap: m.genericSlug == null ? null : () => openGeneric(context, m.genericSlug!),
                  ),
                  _LinkRow(
                    icon: Icons.apartment_rounded,
                    label: 'Made by',
                    text: m.manufacturerName,
                    onTap: () => openCompany(context, m.manufacturerSlug, m.manufacturerName),
                  ),
                  const Divider(height: 28),
                  Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    PriceText(m.comparePrice, unit: m.compareUnit, size: 32),
                    const Spacer(),
                    if (eq.length > 1 && m.comparePrice != null)
                      rank == 1
                          ? const Tag.gold('Lowest price', icon: Icons.workspace_premium_rounded)
                          : Tag('#$rank of ${eq.length} by price', bg: Brand.bg, fg: Brand.ink),
                  ]),
                  const SizedBox(height: 6),
                  Row(children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: out ? Brand.danger : Brand.c500),
                    ),
                    const SizedBox(width: 6),
                    Text(out ? 'Currently out of stock' : m.stock < 20 ? 'Only ${m.stock} left' : 'In stock',
                        style: Txt.ui(14, weight: FontWeight.w700, color: out ? Brand.danger : Brand.c700)),
                  ]),
                  const SizedBox(height: 18),
                  PackPicker(medicine: m, packs: d.packs, onSeeAlternatives: _toAlternatives),
                ]),
              )),
              if (cheaper.isNotEmpty && cheapest != null && maxSave > 0) ...[
                const SizedBox(height: 16),
                gutter(NightCard(
                  onTap: _toAlternatives,
                  child: Row(children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(gradient: Brand.goldGradient, shape: BoxShape.circle),
                      child: const Icon(Icons.trending_down_rounded, color: Brand.night),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Save up to $maxSave%', style: Txt.display(22, color: Brand.gold2, weight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(
                          '${cheaper.length} cheaper equal${cheaper.length > 1 ? 's' : ''}. ${cheapest.brandName} by ${cheapest.manufacturerName} costs ${taka(cheapest.comparePrice)}${perUnit(cheapest.compareUnit)}.',
                          style: Txt.ui(13, color: Colors.white.withValues(alpha: 0.8), height: 1.4),
                        ),
                      ]),
                    ),
                    const Icon(Icons.arrow_downward_rounded, color: Colors.white),
                  ]),
                )),
              ],
              if (out && d.alternatives.any((a) => a.stock > 0)) ...[
                const SizedBox(height: 16),
                gutter(Panel(
                  color: Brand.amberBg,
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.info_outline_rounded, size: 20, color: Brand.amber),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This brand is out of stock. The alternatives below have the same active ingredient, strength and form.',
                        style: Txt.ui(14, color: Brand.amber, weight: FontWeight.w600, height: 1.45),
                      ),
                    ),
                  ]),
                )),
              ],
              const SizedBox(height: 26),
              gutter(SectionHeader('Equivalent brands',
                  key: _altKey, eyebrow: 'Same generic · strength · form', trailing: '${eq.length} · cheapest first')),
              if (d.alternatives.isEmpty)
                gutter(const Panel(child: Muted('No other brand with exactly the same generic, strength and form is listed.', size: 14)))
              else
                gutter(ListPanel(children: [
                  for (final (i, e) in eq.indexed)
                    MedicineTile(m: e, cheapest: i == 0, reference: m.comparePrice, highlight: e.id == m.id ? 'This brand' : null),
                ])),
              const SizedBox(height: 8),
              gutter(const Muted('Ask your doctor or pharmacist before switching brands.', size: 11)),
              if (d.variants.isNotEmpty) ...[
                const SizedBox(height: 26),
                gutter(const SectionHeader('Other strengths & forms')),
                HScroll(children: [
                  for (final v in d.variants)
                    SizedBox(
                      width: 150,
                      child: Panel(
                        padding: const EdgeInsets.all(14),
                        onTap: () => openMedicine(context, v.anyId),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(v.strength ?? '—', style: Txt.display(18, weight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Muted('${v.formGroup} · ${v.brands} brands', maxLines: 2),
                          if (v.minPrice != null) ...[
                            const SizedBox(height: 6),
                            Text('from ${taka(v.minPrice)}${perUnit(v.unit)}', style: Txt.ui(12, weight: FontWeight.w800, color: Brand.c700)),
                          ],
                        ]),
                      ),
                    ),
                ]),
              ],
              if (d.generic != null && d.generic!.monograph.isNotEmpty) ...[
                const SizedBox(height: 26),
                gutter(SectionHeader('About ${d.generic!.name}', eyebrow: 'Drug information')),
                gutter(Monograph(d.generic!)),
              ],
              const SizedBox(height: 18),
              gutter(const Muted(disclaimer, size: 11, align: TextAlign.center)),
              navClearance,
            ]),
          );
        },
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.icon, required this.label, required this.text, this.onTap});
  final IconData icon;
  final String label, text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: Brand.c50, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 18, color: Brand.c600),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label.toUpperCase(), style: Txt.eyebrow(color: Brand.muted)),
                Text(text, style: Txt.ui(15, weight: FontWeight.w700, color: onTap != null ? Brand.c700 : Brand.ink)),
              ]),
            ),
            if (onTap != null) const Icon(Icons.chevron_right_rounded, color: Brand.muted),
          ]),
        ),
      );
}

/// Pack size, quantity and add-to-cart for one product.
class PackPicker extends StatefulWidget {
  const PackPicker({super.key, required this.medicine, required this.packs, required this.onSeeAlternatives});
  final Medicine medicine;
  final List<Pack> packs;
  final VoidCallback onSeeAlternatives;

  @override
  State<PackPicker> createState() => _PackPickerState();
}

class _PackPickerState extends State<PackPicker> {
  late Pack? _pack = widget.packs.firstOrNull;
  late int _qty = isPerPiece(_pack?.label) ? 10 : 1;

  @override
  Widget build(BuildContext context) {
    final pack = _pack;
    final m = widget.medicine;
    if (pack == null) return const Muted('This product is not available for online purchase.', size: 14);
    final maxQty = (m.stock ~/ pack.qty).clamp(0, 99);
    final soldOut = maxQty == 0;
    final q = _qty.clamp(1, maxQty < 1 ? 1 : maxQty);

    void add() => addToCart(
          context,
          CartLine(
            packId: pack.id,
            medicineId: m.id,
            brandName: m.brandName,
            description: m.cartDescription,
            packLabel: pack.label,
            price: pack.price,
            qty: q,
          ),
        );

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (widget.packs.length > 1) ...[
        Text('CHOOSE A PACK', style: Txt.eyebrow(color: Brand.muted)),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, c) => Wrap(spacing: 10, runSpacing: 10, children: [
            for (final p in widget.packs)
              SizedBox(
                width: (c.maxWidth - 10) / 2,
                child: _PackOption(
                  pack: p,
                  selected: p.id == pack.id,
                  enoughStock: p.qty <= m.stock,
                  onTap: () => setState(() {
                    _pack = p;
                    _qty = isPerPiece(p.label) ? 10 : 1;
                  }),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 18),
      ],
      Row(children: [
        QtyStepper(value: soldOut ? 0 : q, min: 1, max: soldOut ? 0 : maxQty, onChanged: (v) => setState(() => _qty = v)),
        const Spacer(),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('TOTAL', style: Txt.eyebrow(color: Brand.muted)),
          PriceText(soldOut ? 0 : pack.price * q, size: 26),
        ]),
      ]),
      const SizedBox(height: 18),
      if (soldOut)
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Brand.night),
          onPressed: widget.onSeeAlternatives,
          child: const Text('Out of stock · see alternatives'),
        )
      else
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: add,
              icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
              label: const Text('Add'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton(
              onPressed: () {
                add();
                context.read<TabsModel>().go(TabsModel.cart);
              },
              child: const Text('Buy now'),
            ),
          ),
        ]),
    ]);
  }
}

class _PackOption extends StatelessWidget {
  const _PackOption({required this.pack, required this.selected, required this.enoughStock, required this.onTap});
  final Pack pack;
  final bool selected, enoughStock;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        selected: selected,
        button: true,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
            color: selected ? Brand.c50 : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: selected ? Brand.c600 : Brand.line, width: selected ? 1.8 : 1.2),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: enoughStock ? onTap : null,
              child: Opacity(
                opacity: enoughStock ? 1 : 0.5,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(pack.label, style: Txt.ui(13, weight: FontWeight.w700, color: Brand.muted)),
                    const SizedBox(height: 2),
                    PriceText(pack.price, size: 20),
                    if (!enoughStock) Text('Not enough stock', style: Txt.ui(11, color: Brand.danger, weight: FontWeight.w700)),
                  ]),
                ),
              ),
            ),
          ),
        ),
      );
}

// ───────────────────────────── Generic ─────────────────────────────

class GenericScreen extends StatelessWidget {
  const GenericScreen({super.key, required this.slug, this.focusKey});
  final String slug;

  /// Equivalence group to show first and expanded (from "See all N brands").
  final String? focusKey;

  @override
  Widget build(BuildContext context) {
    final api = context.read<Api>();
    return Scaffold(
      appBar: AppBar(title: const Text('Generic')),
      body: Loader<GenericDetail>(
        load: () => api.generic(slug),
        builder: (context, d, reload) {
          final g = d.generic;
          final groups = [...d.groups.where((x) => x.first.equivKey == focusKey), ...d.groups.where((x) => x.first.equivKey != focusKey)];
          return RefreshIndicator(
            onRefresh: reload,
            child: ListView(padding: const EdgeInsets.only(top: 4), children: [
              gutter(NightCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('GENERIC · CHEMICAL NAME', style: Txt.eyebrow(color: Brand.gold2)),
                  const SizedBox(height: 8),
                  Text(g.name, style: Txt.display(30, color: Colors.white, weight: FontWeight.w500)),
                  if (g.drugClass != null) ...[
                    const SizedBox(height: 4),
                    Text(g.drugClass!, style: Txt.ui(14, color: Colors.white.withValues(alpha: 0.7))),
                  ],
                  const SizedBox(height: 14),
                  Text('${g.brandCount} brands in ${d.groups.length} strength${d.groups.length == 1 ? '' : 's'} / forms',
                      style: Txt.ui(14, weight: FontWeight.w700, color: Brand.mint)),
                ]),
              )),
              const SizedBox(height: 26),
              gutter(const SectionHeader('All brands', eyebrow: 'Cheapest first in each group')),
              for (final grp in groups)
                gutter(Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: _GenericGroup(items: grp, expanded: grp.first.equivKey == focusKey),
                )),
              if (g.monograph.isNotEmpty) ...[
                const SizedBox(height: 8),
                gutter(const SectionHeader('Drug information')),
                gutter(Monograph(g)),
              ],
              const SizedBox(height: 18),
              gutter(const Muted(disclaimer, size: 11, align: TextAlign.center)),
              navClearance,
            ]),
          );
        },
      ),
    );
  }
}

class _GenericGroup extends StatefulWidget {
  const _GenericGroup({required this.items, required this.expanded});
  final List<Medicine> items;
  final bool expanded;

  @override
  State<_GenericGroup> createState() => _GenericGroupState();
}

class _GenericGroupState extends State<_GenericGroup> {
  late bool _all = widget.expanded;
  static const preview = 5;

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final first = items.first;
    final priced = items.where((i) => i.comparePrice != null && !i.priceSuspect).toList();
    final min = priced.firstOrNull?.comparePrice, max = priced.lastOrNull?.comparePrice;
    final shown = _all ? items : items.take(preview).toList();
    return ListPanel(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${first.strength ?? '—'} · ${first.formGroup}', style: Txt.display(19, weight: FontWeight.w600)),
              Muted('${items.length} brand${items.length == 1 ? '' : 's'}', size: 13),
            ]),
          ),
          if (min != null && max != null && items.length > 1 && savingsPct(min, max) > 0) Tag.gold('Save up to ${savingsPct(min, max)}%'),
        ]),
      ),
      for (final (i, m) in shown.indexed) MedicineTile(m: m, cheapest: i == 0 && items.length > 1, reference: max),
      if (items.length > preview)
        InkWell(
          onTap: () => setState(() => _all = !_all),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: Text(_all ? 'Show fewer' : 'Show all ${items.length} brands',
                  style: Txt.ui(14, weight: FontWeight.w800, color: Brand.c700)),
            ),
          ),
        ),
    ]);
  }
}

// ───────────────────────────── Companies ─────────────────────────────

class CompaniesScreen extends StatefulWidget {
  const CompaniesScreen({super.key});

  @override
  State<CompaniesScreen> createState() => _CompaniesScreenState();
}

class _CompaniesScreenState extends State<CompaniesScreen> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final api = context.read<Api>();
    return Scaffold(
      appBar: AppBar(title: const Text('Companies')),
      body: Loader<List<Company>>(
        load: api.companies,
        builder: (context, all, reload) {
          final f = _filter.toLowerCase();
          final list = f.isEmpty ? all : all.where((c) => c.name.toLowerCase().contains(f)).toList();
          return RefreshIndicator(
            onRefresh: reload,
            child: ListView(padding: const EdgeInsets.only(top: 4), children: [
              gutter(const Muted('Pick a company to see its products and which ones have cheaper equivalents elsewhere.', size: 14)),
              const SizedBox(height: 14),
              gutter(TextField(
                decoration: const InputDecoration(hintText: 'Filter companies', prefixIcon: Icon(Icons.filter_list_rounded)),
                onChanged: (v) => setState(() => _filter = v.trim()),
              )),
              const SizedBox(height: 14),
              gutter(ListPanel(children: [
                for (final c in list)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Brand.c50,
                      child: Text(c.name.replaceAll(RegExp('[^A-Za-z]'), '').padRight(2).substring(0, 2).toUpperCase(),
                          style: Txt.ui(13, weight: FontWeight.w800, color: Brand.c700)),
                    ),
                    title: Text(c.name),
                    subtitle: Text('${c.brandCount} products · ${c.genericCount} generics'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => openCompany(context, c.slug, c.name),
                  ),
                if (list.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Muted('No companies match.')),
              ])),
              navClearance,
            ]),
          );
        },
      ),
    );
  }
}

class CompanyScreen extends StatefulWidget {
  const CompanyScreen({super.key, required this.slug, required this.name});
  final String slug, name;

  @override
  State<CompanyScreen> createState() => _CompanyScreenState();
}

class _CompanyScreenState extends State<CompanyScreen> {
  final _items = <Medicine>[];
  Company? _company;
  int _page = 0, _pages = 1;
  bool _loading = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _more();
  }

  Future<void> _more() async {
    if (_loading || _page >= _pages) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final p = await context.read<Api>().company(widget.slug, _page + 1);
      if (!mounted) return;
      setState(() {
        _company = p.company;
        _page = p.page;
        _pages = p.pages;
        _items.addAll(p.items);
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _company;
    return Scaffold(
      appBar: AppBar(title: Text(widget.name, overflow: TextOverflow.ellipsis)),
      body: _items.isEmpty && _error != null
          ? ErrorView(_error!, onRetry: _more)
          : _items.isEmpty
              ? const SkeletonList()
              : NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n.metrics.extentAfter < 600) _more();
                    return false;
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 4, bottom: 120),
                    itemCount: _items.length + 2,
                    itemBuilder: (context, i) {
                      if (i == 0) {
                        return gutter(Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('COMPANY', style: Txt.eyebrow()),
                            Text(c!.name, style: Txt.display(26, weight: FontWeight.w600)),
                            Muted('${c.brandCount} products · ${c.genericCount} generics', size: 14),
                          ]),
                        ));
                      }
                      if (i == _items.length + 1) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: _loading
                                ? const CircularProgressIndicator()
                                : _error != null
                                    ? TextButton(onPressed: _more, child: const Text('Load more'))
                                    : Muted('${_items.length} of ${c!.brandCount}'),
                          ),
                        );
                      }
                      final m = _items[i - 1];
                      final first = i == 1, last = i == _items.length;
                      return gutter(ClipRRect(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(first ? 22 : 0), bottom: Radius.circular(last ? 22 : 0)),
                        child: ColoredBox(
                          color: Colors.white,
                          child: Column(children: [
                            if (!first) const Divider(indent: 16, endIndent: 16),
                            MedicineTile(m: m, showGeneric: true, cheaperCount: m.cheaperCount),
                          ]),
                        ),
                      ));
                    },
                  ),
                ),
    );
  }
}
