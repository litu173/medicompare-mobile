import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'api.dart';
import 'format.dart';
import 'models.dart';
import 'screens/catalog.dart';
import 'state.dart';
import 'theme.dart';

/// White rounded card, the web's `rounded-xl bg-white shadow-sm ring-1 ring-black/5`.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.color = Colors.white});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;

  @override
  // A Material (not a decorated Container) so ListTiles and InkWells inside paint their ink.
  Widget build(BuildContext context) => Material(
        color: color,
        shadowColor: const Color(0x14000000),
        elevation: 0.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0x0D000000)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(padding: padding, child: child),
      );
}

/// Panel whose children are separated by hairlines.
class ListPanel extends StatelessWidget {
  const ListPanel({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Panel(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[if (i > 0) const Divider(), children[i]],
          ],
        ),
      );
}

class Tag extends StatelessWidget {
  const Tag(this.text, {super.key, this.bg = Brand.c100, this.fg = Brand.c700});
  final String text;
  final Color bg, fg;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
        child: Text(text.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
      );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});
  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
            if (trailing != null) Text(trailing!, style: const TextStyle(fontSize: 12, color: Brand.muted)),
          ],
        ),
      );
}

class Muted extends StatelessWidget {
  const Muted(this.text, {super.key, this.size = 12, this.align});
  final String text;
  final double size;
  final TextAlign? align;

  @override
  Widget build(BuildContext context) =>
      Text(text, textAlign: align, style: TextStyle(fontSize: size, color: Brand.muted, height: 1.4));
}

class Pill extends StatelessWidget {
  const Pill(this.label, {super.key, required this.onTap, this.selected = false});
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? Brand.ink : Colors.white,
        shape: StadiumBorder(side: BorderSide(color: selected ? Brand.ink : const Color(0xFFE5E7EB))),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Text(label, style: TextStyle(fontSize: 14, color: selected ? Colors.white : const Color(0xFF374151))),
          ),
        ),
      );
}

/// Horizontally scrolling row; place it outside the page's horizontal padding so it bleeds to the edges.
class HScroll extends StatelessWidget {
  const HScroll({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [for (final c in children) Padding(padding: const EdgeInsets.only(right: 8), child: c)],
        ),
      );
}

class ErrorView extends StatelessWidget {
  const ErrorView(this.error, {super.key, this.onRetry});
  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 40, color: Brand.muted),
              const SizedBox(height: 12),
              Text(error is ApiException ? error.toString() : 'Something went wrong.', textAlign: TextAlign.center),
              if (onRetry != null) ...[
                const SizedBox(height: 12),
                TextButton(onPressed: onRetry, child: const Text('Try again')),
              ],
            ],
          ),
        ),
      );
}

/// Loads data once, shows a spinner / error with retry, and supports pull-to-refresh.
class Loader<T> extends StatefulWidget {
  const Loader({super.key, required this.load, required this.builder});
  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data, Future<void> Function() reload) builder;

  @override
  State<Loader<T>> createState() => _LoaderState<T>();
}

class _LoaderState<T> extends State<Loader<T>> {
  T? _data;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _error = null;
      if (_data == null) _loading = true;
    });
    try {
      final d = await widget.load();
      if (mounted) setState(() => _data = d);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _data == null) return const Center(child: CircularProgressIndicator());
    if (_data == null) return ErrorView(_error ?? 'Not found', onRetry: _reload);
    return widget.builder(context, _data as T, _reload);
  }
}

/// Product photo, or a neutral pill placeholder when there is none (or it fails to load).
class ProductThumb extends StatelessWidget {
  const ProductThumb(this.image, {super.key, this.size = 44});
  final String? image;
  final double size;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: Brand.c50,
      alignment: Alignment.center,
      child: Icon(Icons.medication_outlined, size: size * 0.5, color: Brand.c500),
    );
    final url = mediaUrl(image);
    return ClipRRect(
      borderRadius: BorderRadius.circular(size > 60 ? 12 : 8),
      child: SizedBox(
        width: size,
        height: size,
        child: url == null
            ? placeholder
            : Image.network(
                url,
                fit: BoxFit.cover,
                cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
                errorBuilder: (_, _, _) => placeholder,
                loadingBuilder: (_, child, progress) => progress == null ? child : placeholder,
              ),
      ),
    );
  }
}

/// Area / thana: a dropdown of the district's thanas when the server provides them, otherwise free text.
class ThanaField extends StatelessWidget {
  const ThanaField({super.key, required this.thanas, required this.controller, this.onChanged});
  final List<String> thanas;
  final TextEditingController controller;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    if (thanas.isEmpty) {
      return TextFormField(
        controller: controller,
        decoration: const InputDecoration(labelText: 'Area / thana', hintText: 'e.g. Mirpur'),
        validator: (v) => (v ?? '').trim().length < 2 ? 'Enter your area / thana' : null,
        onChanged: (_) => onChanged?.call(),
      );
    }
    final current = thanas.contains(controller.text) ? controller.text : null;
    return DropdownButtonFormField<String>(
      key: ValueKey('thana-${thanas.first}-$current'),
      initialValue: current,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Thana / area'),
      items: [for (final t in thanas) DropdownMenuItem(value: t, child: Text(t))],
      validator: (v) => v == null ? 'Choose your thana / area' : null,
      onChanged: (v) {
        controller.text = v ?? '';
        onChanged?.call();
      },
    );
  }
}

/// Adds to the cart and offers a shortcut to it.
void addToCart(BuildContext context, CartLine line) {
  context.read<CartModel>().add(line);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text('${line.brandName} added to cart'),
      duration: const Duration(seconds: 3),
      persist: false,
      action: context.read<TabsModel>().index == TabsModel.cart
          ? null
          : SnackBarAction(label: 'View cart', onPressed: () => context.read<TabsModel>().go(TabsModel.cart)),
    ));
}

/// One brand in an equivalence list: name, company, price per unit and a quick-add button.
class MedicineTile extends StatelessWidget {
  const MedicineTile({
    super.key,
    required this.m,
    this.cheapest = false,
    this.reference,
    this.highlight,
    this.showGeneric = false,
    this.cheaperCount = 0,
  });

  final Medicine m;
  final bool cheapest, showGeneric;

  /// Price compared against for the "Save N%" label.
  final double? reference;
  final String? highlight;
  final int cheaperCount;

  @override
  Widget build(BuildContext context) {
    final out = m.outOfStock;
    final save = reference != null && m.comparePrice != null && !m.priceSuspect ? savingsPct(m.comparePrice!, reference!) : 0;
    final canAdd = m.packId != null && m.listPrice != null && m.listLabel != null;
    final perPiece = isPerPiece(m.listLabel);
    Widget? status;
    if (out) {
      status = Text(m.comparePrice == null ? 'Price unavailable' : 'Out of stock',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Brand.danger));
    } else if (m.priceSuspect) {
      status = const Text('Price unverified',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Brand.amber));
    } else if (save > 0) {
      status = Text('Save $save%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Brand.c700));
    }

    return Material(
      color: highlight != null ? Brand.amberBg : Colors.white,
      child: InkWell(
        onTap: () => openMedicine(context, m.id),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              ProductThumb(m.image),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(m.brandName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        if (m.strength != null) Text(m.strength!, style: const TextStyle(fontSize: 14, color: Brand.muted)),
                        if (cheapest && !out && !m.priceSuspect) const Tag('Cheapest'),
                        if (highlight != null) Tag(highlight!, bg: const Color(0xFFFEF3C7), fg: const Color(0xFF92400E)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${showGeneric ? '${m.dosageForm} · ${m.genericName} · ' : ''}${m.manufacturerName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Brand.muted),
                    ),
                    if (status != null) Padding(padding: const EdgeInsets.only(top: 2), child: status),
                    if (cheaperCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '$cheaperCount cheaper equivalent${cheaperCount > 1 ? 's' : ''} from other companies',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Brand.amber),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text.rich(TextSpan(children: [
                    TextSpan(text: taka(m.comparePrice), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    TextSpan(text: perUnit(m.compareUnit), style: const TextStyle(fontSize: 12, color: Brand.muted)),
                  ])),
                  if (m.listLabel != null && m.listLabel != '1 ${m.compareUnit}')
                    Text('${taka(m.listPrice)} · ${m.listLabel}', style: const TextStyle(fontSize: 11, color: Brand.muted)),
                ],
              ),
              if (canAdd) ...[
                const SizedBox(width: 10),
                SizedBox(
                  height: 36,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      side: BorderSide(color: out ? const Color(0xFFE5E7EB) : Brand.c600),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    onPressed: out
                        ? null
                        : () => addToCart(
                              context,
                              CartLine(
                                packId: m.packId!,
                                medicineId: m.id,
                                brandName: m.brandName,
                                description: m.cartDescription,
                                packLabel: m.listLabel!,
                                price: m.listPrice!,
                                qty: perPiece ? 10 : 1,
                              ),
                            ),
                    icon: const Icon(Icons.add, size: 14),
                    label: Text(perPiece ? '10' : 'Add', semanticsLabel: 'Add ${m.brandName} to cart'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class QtyStepper extends StatelessWidget {
  const QtyStepper({super.key, required this.value, required this.onChanged, this.min = 1, this.max = 99, this.compact = false});
  final int value, min, max;
  final ValueChanged<int> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 34.0 : 44.0;
    Widget btn(IconData icon, String label, bool enabled, int next) => SizedBox(
          width: size,
          height: size,
          child: IconButton(
            tooltip: label,
            padding: EdgeInsets.zero,
            iconSize: 16,
            onPressed: enabled ? () => onChanged(next) : null,
            icon: Icon(icon),
          ),
        );
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(compact ? 8 : 12),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        btn(Icons.remove, 'Decrease quantity', value > min, value - 1),
        SizedBox(
          width: 28,
          child: Text('$value', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        btn(Icons.add, 'Increase quantity', value < max, value + 1),
      ]),
    );
  }
}

/// Search input that submits a query (used on Home and Search).
class SearchField extends StatelessWidget {
  const SearchField({super.key, this.controller, this.onSubmitted, this.onChanged, this.autofocus = false, this.onTap, this.readOnly = false});
  final TextEditingController? controller;
  final ValueChanged<String>? onSubmitted, onChanged;
  final VoidCallback? onTap;
  final bool autofocus, readOnly;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        autofocus: autofocus,
        readOnly: readOnly,
        onTap: onTap,
        textInputAction: TextInputAction.search,
        onSubmitted: onSubmitted,
        onChanged: onChanged,
        autocorrect: false,
        decoration: InputDecoration(
          hintText: 'Search brand or generic, e.g. Napa',
          prefixIcon: const Icon(Icons.search, color: Brand.muted),
          suffixIcon: controller == null
              ? null
              : ListenableBuilder(
                  listenable: controller!,
                  builder: (context, _) => controller!.text.isEmpty
                      ? const SizedBox.shrink()
                      : IconButton(
                          tooltip: 'Clear',
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            controller!.clear();
                            onChanged?.call('');
                          },
                        ),
                ),
        ),
      );
}

/// Page-gutter padding for list children (horizontal scrollers stay unpadded so they bleed to the edges).
Widget gutter(Widget child) => Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: child);

/// Collapsible drug information for a generic.
class Monograph extends StatelessWidget {
  const Monograph(this.generic, {super.key});
  final Generic generic;

  @override
  Widget build(BuildContext context) {
    final sections = generic.monograph;
    if (sections.isEmpty) return const SizedBox.shrink();
    return ListPanel(children: [
      for (final (i, (title, body)) in sections.indexed)
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: i == 0,
            title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            expandedAlignment: Alignment.topLeft,
            children: [Text(body, style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF374151)))],
          ),
        ),
      Container(
        color: const Color(0xFFF9FAFB),
        padding: const EdgeInsets.all(12),
        child: const Muted('Source: open MedEx-derived dataset. For reference only — follow your doctor\'s prescription.', size: 11),
      ),
    ]);
  }
}

const disclaimer =
    'Information is for price comparison only and is not medical advice. Always consult a doctor or pharmacist before switching medicines.';
