import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api.dart';
import '../format.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'shop.dart';

// Navigation helpers: push within the current tab's navigator so the bottom bar stays.
void openMedicine(BuildContext context, int id) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductScreen(id: id)));
void openGeneric(BuildContext context, String slug, {String? focus}) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => GenericScreen(slug: slug, focusKey: focus)));
void openCompany(BuildContext context, String slug, String name) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => CompanyScreen(slug: slug, name: name)));
void openSearch(BuildContext context, String q) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => SearchScreen(initialQuery: q)));

// ───────────────────────────── Home ─────────────────────────────

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final api = context.read<Api>();
    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [
          Icon(Icons.medication_rounded, color: Brand.c600),
          SizedBox(width: 6),
          Text('সাশ্রয়', style: TextStyle(fontWeight: FontWeight.w700)),
          Text('  Sashroy', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Brand.c600)),
        ]),
      ),
      body: Loader<HomeData>(
        load: api.home,
        builder: (context, d, reload) => RefreshIndicator(
          onRefresh: reload,
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            children: [
              gutter(const Text.rich(
                TextSpan(children: [
                  TextSpan(text: 'Same medicine. '),
                  TextSpan(text: 'Lower price.', style: TextStyle(color: Brand.c600)),
                ]),
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, height: 1.15),
              )),
              const SizedBox(height: 8),
              gutter(const Text(
                'Search by brand or chemical (generic) name and see every equivalent brand sold in Bangladesh — cheapest first.',
                style: TextStyle(fontSize: 15, color: Color(0xFF4B5563), height: 1.4),
              )),
              const SizedBox(height: 16),
              gutter(SearchField(onSubmitted: (q) => q.trim().isEmpty ? null : openSearch(context, q.trim()))),
              const SizedBox(height: 12),
              HScroll(children: [for (final s in d.popular) Pill(s, onTap: () => openSearch(context, s))]),
              const SizedBox(height: 24),
              gutter(Row(children: [
                for (final (n, l) in [(d.medicines, 'medicines'), (d.generics, 'generics'), (d.companies, 'companies')])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Panel(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(children: [
                          Text(formatNumber(n), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                          Muted(l),
                        ]),
                      ),
                    ),
                  ),
              ])),
              const SizedBox(height: 28),
              gutter(const SectionHeader('Biggest price gaps', trailing: 'same generic, strength & form')),
              for (final g in d.gaps)
                gutter(Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _GapCard(g),
                )),
              const SizedBox(height: 12),
              gutter(GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.25,
                children: const [
                  _Feature(Icons.percent_rounded, 'Always a cheaper option', 'Every equivalent brand ranked by price per unit.'),
                  _Feature(Icons.inventory_2_outlined, 'Out of stock? Switch', 'Alternatives in stock are shown instantly.'),
                  _Feature(Icons.verified_user_outlined, 'Same active ingredient', 'Matched by generic, strength and dosage form.'),
                  _Feature(Icons.local_shipping_outlined, 'Home delivery', 'Cash on delivery across Bangladesh.'),
                ],
              )),
              const SizedBox(height: 20),
              gutter(Material(
                color: Brand.c900,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => context.read<TabsModel>().go(TabsModel.companies),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Browse by company', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          Text('See which products have cheaper equivalents',
                              style: TextStyle(color: Colors.white70, fontSize: 14)),
                        ]),
                      ),
                      Icon(Icons.arrow_forward, color: Colors.white),
                    ]),
                  ),
                ),
              )),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TrackScreen())),
                  child: const Text('Track an order', style: TextStyle(color: Brand.c700)),
                ),
              ),
              gutter(const Muted(disclaimer, size: 11, align: TextAlign.center)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GapCard extends StatelessWidget {
  const _GapCard(this.g);
  final PriceGap g;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => openMedicine(context, g.topId),
        borderRadius: BorderRadius.circular(14),
        child: Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(g.genericName, style: const TextStyle(fontWeight: FontWeight.w600)),
            Muted('${g.strength ?? ''} · ${g.formGroup} · ${g.brands} brands', size: 14),
            const SizedBox(height: 12),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(
                child: Text.rich(TextSpan(style: const TextStyle(fontSize: 14), children: [
                  TextSpan(text: taka(g.minPrice), style: const TextStyle(fontWeight: FontWeight.w600, color: Brand.c700)),
                  const TextSpan(text: ' – ', style: TextStyle(color: Color(0xFF9CA3AF))),
                  TextSpan(
                    text: taka(g.maxPrice),
                    style: const TextStyle(
                        color: Brand.muted, decoration: TextDecoration.lineThrough, decorationColor: Color(0xFFF87171)),
                  ),
                  TextSpan(text: ' ${perUnit(g.unit)}', style: const TextStyle(fontSize: 12, color: Brand.muted)),
                ])),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Brand.c100, borderRadius: BorderRadius.circular(99)),
                child: Text('up to ${savingsPct(g.minPrice, g.maxPrice)}% less',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Brand.c700)),
              ),
            ]),
          ]),
        ),
      );
}

class _Feature extends StatelessWidget {
  const _Feature(this.icon, this.title, this.body);
  final IconData icon;
  final String title, body;

  @override
  Widget build(BuildContext context) => Panel(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: Brand.c600, size: 20),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Muted(body),
        ]),
      );
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
  late String _query = widget.initialQuery;
  String? _form;
  Future<SearchResult>? _results;
  Suggestions? _suggestions;
  bool _typing = false;
  Timer? _debounce;
  HomeData? _home;

  Api get _api => context.read<Api>();

  @override
  void initState() {
    super.initState();
    if (_query.isNotEmpty) _results = _api.search(_query);
    _api.home().then((h) => mounted ? setState(() => _home = h) : null, onError: (_) {});
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
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
    return Scaffold(
      appBar: AppBar(title: Text(_query.isEmpty || widget.isTabRoot ? 'Search' : _query)),
      body: Column(children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: SearchField(
            controller: _controller,
            autofocus: widget.isTabRoot && _query.isEmpty,
            onChanged: _onChanged,
            onSubmitted: _submit,
          ),
        ),
        Expanded(child: _typing ? _suggestionList() : _body()),
      ]),
    );
  }

  Widget _suggestionList() {
    final s = _suggestions;
    final q = _controller.text.trim();
    return ListView(children: [
      ListTile(
        leading: const Icon(Icons.search, color: Brand.muted),
        title: Text('Search “$q”'),
        onTap: () => _submit(q),
      ),
      if (s != null) ...[
        for (final b in s.brands)
          ListTile(
            leading: const Icon(Icons.medication_outlined, color: Brand.c600),
            title: Text(b.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(b.detail, maxLines: 1, overflow: TextOverflow.ellipsis),
            onTap: () => openMedicine(context, b.id),
          ),
        for (final g in s.generics)
          ListTile(
            leading: const Icon(Icons.science_outlined, color: Brand.c600),
            title: Text(g.name),
            subtitle: Text('Generic · ${g.brandCount} brands'),
            onTap: () => openGeneric(context, g.slug),
          ),
      ],
    ]);
  }

  Widget _body() {
    if (_results == null) {
      return ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Popular searches', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final s in _home?.popular ?? const <String>[]) Pill(s, onTap: () => _submit(s)),
        ]),
      ]);
    }
    return FutureBuilder<SearchResult>(
      future: _results,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (snap.hasError) return ErrorView(snap.error!, onRetry: () => _setForm(_form));
        final r = snap.data!;
        return ListView(padding: const EdgeInsets.symmetric(vertical: 16), children: [
          if (r.generics.isNotEmpty) ...[
            HScroll(children: [
              for (final g in r.generics)
                Material(
                  color: Brand.c50,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Brand.c100)),
                  child: InkWell(
                    onTap: () => openGeneric(context, g.slug),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.science_outlined, size: 16, color: Brand.c700),
                        const SizedBox(width: 6),
                        Text(g.name, style: const TextStyle(fontWeight: FontWeight.w500, color: Brand.c700)),
                        const SizedBox(width: 6),
                        Text('${g.brandCount}', style: const TextStyle(fontSize: 12, color: Brand.c700)),
                      ]),
                    ),
                  ),
                ),
            ]),
            const SizedBox(height: 12),
          ],
          if (r.forms.length > 1) ...[
            HScroll(children: [
              Pill('All forms', selected: _form == null, onTap: () => _setForm(null)),
              for (final f in r.forms) Pill(f.form, selected: _form == f.form, onTap: () => _setForm(f.form)),
            ]),
            const SizedBox(height: 12),
          ],
          if (r.groups.isEmpty)
            gutter(Panel(
              padding: const EdgeInsets.all(32),
              child: Column(children: [
                const Icon(Icons.search_off_rounded, size: 40, color: Brand.muted),
                const SizedBox(height: 8),
                Text('No medicines found for “$_query”', style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Muted('Check the spelling, or try the generic name (e.g. Paracetamol).', align: TextAlign.center),
              ]),
            ))
          else ...[
            gutter(Muted(
              '${r.groups.length} medicine group${r.groups.length > 1 ? 's' : ''} for “$_query” · cheapest first',
              size: 14,
            )),
            const SizedBox(height: 12),
            for (final g in r.groups)
              gutter(Padding(padding: const EdgeInsets.only(bottom: 16), child: _GroupCard(g, _query))),
          ],
        ]);
      },
    );
  }
}

/// One equivalence group (same generic, strength, form): cheapest few brands plus the searched one.
class _GroupCard extends StatelessWidget {
  const _GroupCard(this.g, this.q);
  final SearchGroup g;
  final String q;
  static const preview = 6;

  @override
  Widget build(BuildContext context) {
    final searchedBrand = g.items.where((i) => g.matchedIds.contains(i.id)).firstOrNull;
    final visible = g.items.take(preview).toList();
    final hidden = [
      for (final (idx, i) in g.items.indexed)
        if (idx >= preview && g.matchedIds.contains(i.id) && g.total > 1) i,
    ].take(2).toList();
    final brandSearch = searchedBrand != null && !g.genericName.toLowerCase().contains(q.toLowerCase());
    final reference = brandSearch ? searchedBrand.comparePrice : g.maxPrice;
    final shown = [...visible, ...hidden];
    final save = g.minPrice != null && g.maxPrice != null ? savingsPct(g.minPrice!, g.maxPrice!) : 0;

    return ListPanel(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text.rich(TextSpan(children: [
                TextSpan(text: g.genericName, style: const TextStyle(fontWeight: FontWeight.w600)),
                if (g.strength != null)
                  TextSpan(text: ' ${g.strength}', style: const TextStyle(color: Brand.muted)),
              ])),
              Muted('${g.form} · ${g.total} brand${g.total > 1 ? 's' : ''}'),
            ]),
          ),
          if (g.minPrice != null && g.maxPrice != null && g.total > 1)
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Muted('${taka(g.minPrice)} – ${taka(g.maxPrice)}${perUnit(g.unit)}'),
              if (save > 0)
                Text('save up to $save%',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Brand.c700)),
            ]),
        ]),
      ),
      for (final (idx, m) in shown.indexed)
        MedicineTile(
          m: m,
          cheapest: idx == 0 && g.total > 1,
          reference: reference,
          highlight: brandSearch && g.matchedIds.contains(m.id) ? 'Searched' : null,
        ),
      if (g.total > shown.length)
        InkWell(
          onTap: () => g.genericSlug != null
              ? openGeneric(context, g.genericSlug!, focus: g.equivKey)
              : openMedicine(context, g.items.first.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('See all ${g.total} brands', style: const TextStyle(fontWeight: FontWeight.w500, color: Brand.c700)),
              const Icon(Icons.chevron_right, size: 18, color: Brand.c700),
            ]),
          ),
        ),
    ]);
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
    if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 350), alignment: 0.02);
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
            child: ListView(padding: const EdgeInsets.symmetric(vertical: 16), children: [
              gutter(Panel(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ProductThumb(m.image, size: 76),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(m.dosageForm.toUpperCase(),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5, color: Brand.muted)),
                        Text.rich(TextSpan(children: [
                          TextSpan(text: m.brandName),
                          if (m.strength != null)
                            TextSpan(text: ' ${m.strength}', style: const TextStyle(fontWeight: FontWeight.w500, color: Brand.muted)),
                        ]), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.2)),
                      ]),
                    ),
                    if (m.type == 'herbal') const Tag('Herbal', bg: Color(0xFFECFCCB), fg: Color(0xFF3F6212)),
                  ]),
                  const SizedBox(height: 12),
                  _LinkRow(
                    icon: Icons.science_outlined,
                    text: m.genericName,
                    color: m.genericSlug != null ? Brand.c700 : const Color(0xFF374151),
                    onTap: m.genericSlug == null ? null : () => openGeneric(context, m.genericSlug!),
                  ),
                  _LinkRow(
                    icon: Icons.business_outlined,
                    text: m.manufacturerName,
                    onTap: () => openCompany(context, m.manufacturerSlug, m.manufacturerName),
                  ),
                  const Divider(height: 28),
                  Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Text(taka(m.comparePrice), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 6),
                    Muted(perUnit(m.compareUnit), size: 14),
                    const Spacer(),
                    if (eq.length > 1 && m.comparePrice != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: rank == 1 ? Brand.c100 : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          rank == 1 ? 'Lowest price' : '#$rank of ${eq.length} by price',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600, color: rank == 1 ? Brand.c700 : const Color(0xFF374151)),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 4),
                  Text(
                    out ? 'Currently out of stock' : m.stock < 20 ? 'Only ${m.stock} left' : 'In stock',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: out ? Brand.danger : Brand.c700),
                  ),
                  const SizedBox(height: 16),
                  PackPicker(medicine: m, packs: d.packs, onSeeAlternatives: _toAlternatives),
                ]),
              )),
              if (cheaper.isNotEmpty && cheapest != null && maxSave > 0) ...[
                const SizedBox(height: 16),
                gutter(Material(
                  color: Brand.c600,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _toAlternatives,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(children: [
                        const Icon(Icons.trending_down_rounded, color: Colors.white, size: 26),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(
                              '${cheaper.length} cheaper equivalent${cheaper.length > 1 ? 's' : ''} — save up to $maxSave%',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            Text(
                              '${cheapest.brandName} by ${cheapest.manufacturerName} costs ${taka(cheapest.comparePrice)}${perUnit(cheapest.compareUnit)}',
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ]),
                        ),
                      ]),
                    ),
                  ),
                )),
              ],
              if (out && d.alternatives.any((a) => a.stock > 0)) ...[
                const SizedBox(height: 16),
                gutter(Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Brand.amberBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFF78350F)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This brand is out of stock. The alternatives below contain the same active ingredient, strength and form.',
                        style: TextStyle(fontSize: 14, color: Color(0xFF78350F)),
                      ),
                    ),
                  ]),
                )),
              ],
              const SizedBox(height: 20),
              gutter(SectionHeader('Equivalent brands', trailing: '${eq.length} total · cheapest first', key: _altKey)),
              if (d.alternatives.isEmpty)
                gutter(const Panel(
                  child: Muted('No other brand with exactly the same generic, strength and form is listed.', size: 14),
                ))
              else
                gutter(ListPanel(children: [
                  for (final (i, e) in eq.indexed)
                    MedicineTile(
                      m: e,
                      cheapest: i == 0,
                      reference: m.comparePrice,
                      highlight: e.id == m.id ? 'This brand' : null,
                    ),
                ])),
              const SizedBox(height: 8),
              gutter(const Muted(
                'Equivalents share the same generic, strength and dosage form. Ask your doctor or pharmacist before switching.',
                size: 11,
              )),
              if (d.variants.isNotEmpty) ...[
                const SizedBox(height: 20),
                gutter(const SectionHeader('Other strengths & forms')),
                HScroll(children: [
                  for (final v in d.variants)
                    InkWell(
                      onTap: () => openMedicine(context, v.anyId),
                      borderRadius: BorderRadius.circular(14),
                      child: Panel(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(v.strength ?? '—', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                          Muted('${v.formGroup} · ${v.brands} brands'),
                          if (v.minPrice != null)
                            Text('from ${taka(v.minPrice)}${perUnit(v.unit)}',
                                style: const TextStyle(fontSize: 12, color: Brand.c700)),
                        ]),
                      ),
                    ),
                ]),
              ],
              if (d.generic != null && d.generic!.monograph.isNotEmpty) ...[
                const SizedBox(height: 20),
                gutter(SectionHeader('About ${d.generic!.name}')),
                gutter(Monograph(d.generic!)),
              ],
              const SizedBox(height: 16),
              gutter(const Muted(disclaimer, size: 11, align: TextAlign.center)),
            ]),
          );
        },
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.icon, required this.text, this.onTap, this.color = const Color(0xFF374151)});
  final IconData icon;
  final String text;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            Icon(icon, size: 16, color: color == Brand.c700 ? Brand.c700 : const Color(0xFF9CA3AF)),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color))),
            if (onTap != null) const Icon(Icons.chevron_right, size: 16, color: Color(0xFF9CA3AF)),
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
        LayoutBuilder(
          builder: (context, c) => Wrap(spacing: 8, runSpacing: 8, children: [
            for (final p in widget.packs)
              SizedBox(
                width: (c.maxWidth - 8) / 2,
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
        const SizedBox(height: 16),
      ],
      Row(children: [
        QtyStepper(value: soldOut ? 0 : q, min: 1, max: soldOut ? 0 : maxQty, onChanged: (v) => setState(() => _qty = v)),
        const Spacer(),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          const Muted('Total'),
          Text(taka(soldOut ? 0 : pack.price * q), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        ]),
      ]),
      const SizedBox(height: 16),
      if (soldOut)
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Brand.ink),
          onPressed: widget.onSeeAlternatives,
          child: const Text('Out of stock — see alternatives'),
        )
      else
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: add,
              icon: const Icon(Icons.shopping_cart_outlined, size: 18),
              label: const Text('Add to cart'),
            ),
          ),
          const SizedBox(width: 8),
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
        child: Material(
          color: selected ? Brand.c50 : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: selected ? Brand.c600 : const Color(0xFFE5E7EB), width: selected ? 1.5 : 1),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: enoughStock ? onTap : null,
            child: Opacity(
              opacity: enoughStock ? 1 : 0.5,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(pack.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  Text(taka(pack.price), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  if (!enoughStock)
                    const Text('Not enough stock', style: TextStyle(fontSize: 11, color: Brand.danger)),
                ]),
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
            child: ListView(padding: const EdgeInsets.symmetric(vertical: 16), children: [
              gutter(Panel(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('GENERIC', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5, color: Brand.muted)),
                  Text(g.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.2)),
                  if (g.drugClass != null) ...[const SizedBox(height: 4), Muted(g.drugClass!, size: 14)],
                  const SizedBox(height: 8),
                  Text('${g.brandCount} brands in ${d.groups.length} strength${d.groups.length == 1 ? '' : 's'} / forms',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Brand.c700)),
                ]),
              )),
              const SizedBox(height: 20),
              gutter(const SectionHeader('All brands', trailing: 'cheapest first in each group')),
              for (final grp in groups)
                gutter(Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _GenericGroup(items: grp, expanded: grp.first.equivKey == focusKey),
                )),
              if (g.monograph.isNotEmpty) ...[
                const SizedBox(height: 4),
                gutter(const SectionHeader('Drug information')),
                gutter(Monograph(g)),
              ],
              const SizedBox(height: 16),
              gutter(const Muted(disclaimer, size: 11, align: TextAlign.center)),
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
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${first.strength ?? '—'} · ${first.formGroup}', style: const TextStyle(fontWeight: FontWeight.w600)),
              Muted('${items.length} brand${items.length == 1 ? '' : 's'}'),
            ]),
          ),
          if (min != null && max != null && items.length > 1)
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Muted('${taka(min)} – ${taka(max)}${perUnit(priced.first.compareUnit)}'),
              if (savingsPct(min, max) > 0)
                Text('save up to ${savingsPct(min, max)}%',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Brand.c700)),
            ]),
        ]),
      ),
      for (final (i, m) in shown.indexed) MedicineTile(m: m, cheapest: i == 0 && items.length > 1, reference: max),
      if (items.length > preview)
        InkWell(
          onTap: () => setState(() => _all = !_all),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text(_all ? 'Show fewer' : 'Show all ${items.length} brands',
                  style: const TextStyle(fontWeight: FontWeight.w500, color: Brand.c700)),
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
            child: ListView(padding: const EdgeInsets.symmetric(vertical: 16), children: [
              gutter(const Muted('Pick a company to see its products and which have cheaper equivalents from others.', size: 14)),
              const SizedBox(height: 12),
              gutter(TextField(
                decoration: const InputDecoration(hintText: 'Filter companies', prefixIcon: Icon(Icons.filter_list)),
                onChanged: (v) => setState(() => _filter = v.trim()),
              )),
              const SizedBox(height: 12),
              gutter(ListPanel(children: [
                for (final c in list)
                  ListTile(
                    title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    subtitle: Text('${c.brandCount} products · ${c.genericCount} generics'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => openCompany(context, c.slug, c.name),
                  ),
                if (list.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Muted('No companies match.')),
              ])),
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
              ? const Center(child: CircularProgressIndicator())
              : NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n.metrics.extentAfter < 600) _more();
                    return false;
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: _items.length + 2,
                    itemBuilder: (context, i) {
                      if (i == 0) {
                        return gutter(Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(c!.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
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
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(first ? 14 : 0),
                          bottom: Radius.circular(last ? 14 : 0),
                        ),
                        child: ColoredBox(
                          color: Colors.white,
                          child: Column(children: [
                            if (!first) const Divider(),
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
