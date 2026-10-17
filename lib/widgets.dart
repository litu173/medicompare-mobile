import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import 'api.dart';
import 'format.dart';
import 'models.dart';
import 'screens/account.dart';
import 'screens/catalog.dart';
import 'state.dart';
import 'theme.dart';

// ───────────────────────────── Surfaces ─────────────────────────────

/// White rounded card with a soft shadow.
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color = Colors.white,
    this.radius = 22,
    this.onTap,
    this.border,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final double radius;
  final VoidCallback? onTap;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: color == Colors.white ? Brand.shadow : null,
          border: border,
        ),
        // A Material so InkWells and ListTiles inside paint their ripples.
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(radius),
          clipBehavior: Clip.antiAlias,
          child: onTap == null
              ? Padding(padding: padding, child: child)
              : InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
        ),
      );
}

/// Card whose children are separated by hairlines.
class ListPanel extends StatelessWidget {
  const ListPanel({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Panel(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const Divider(indent: 16, endIndent: 16),
              children[i],
            ],
          ],
        ),
      );
}

/// Dark emerald card for highlights (savings, banners).
class NightCard extends StatelessWidget {
  const NightCard({super.key, required this.child, this.padding = const EdgeInsets.all(20), this.onTap});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          gradient: Brand.heroGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: Brand.shadowStrong,
          border: Border.all(color: Brand.gold.withValues(alpha: 0.28)),
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
        ),
      );
}

class Tag extends StatelessWidget {
  const Tag(this.text, {super.key, this.bg = Brand.c100, this.fg = Brand.c700, this.icon});
  final String text;
  final Color bg, fg;
  final IconData? icon;

  const Tag.gold(this.text, {super.key, this.icon})
      : bg = Brand.goldBg,
        fg = Brand.goldDeep;

  const Tag.warn(this.text, {super.key, this.icon})
      : bg = const Color(0xFFFFE9E3),
        fg = Brand.danger;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 11, color: fg), const SizedBox(width: 3)],
          Text(text, style: Txt.ui(11, color: fg, weight: FontWeight.w700, spacing: 0.2)),
        ]),
      );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing, this.eyebrow, this.action, this.onAction});
  final String title;
  final String? trailing, eyebrow, action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (eyebrow != null) ...[Text(eyebrow!.toUpperCase(), style: Txt.eyebrow()), const SizedBox(height: 4)],
                Text(title, style: Txt.display(22, weight: FontWeight.w600)),
              ]),
            ),
            if (trailing != null) Text(trailing!, style: Txt.ui(12, color: Brand.muted)),
            if (action != null)
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: const Size(0, 32)),
                child: Text(action!),
              ),
          ],
        ),
      );
}

class Muted extends StatelessWidget {
  const Muted(this.text, {super.key, this.size = 12, this.align, this.maxLines});
  final String text;
  final double size;
  final TextAlign? align;
  final int? maxLines;

  @override
  Widget build(BuildContext context) => Text(
        text,
        textAlign: align,
        maxLines: maxLines,
        overflow: maxLines == null ? null : TextOverflow.ellipsis,
        style: Txt.ui(size, color: Brand.muted, height: 1.45),
      );
}

/// Filter / suggestion chip.
class Pill extends StatelessWidget {
  const Pill(this.label, {super.key, required this.onTap, this.selected = false, this.icon});
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? Brand.night : Colors.white,
        shape: StadiumBorder(side: BorderSide(color: selected ? Brand.night : Brand.line)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: selected ? Brand.gold2 : Brand.c600),
                const SizedBox(width: 6),
              ],
              Text(label, style: Txt.ui(14, weight: FontWeight.w600, color: selected ? Colors.white : Brand.ink)),
            ]),
          ),
        ),
      );
}

/// Horizontally scrolling row that bleeds to the screen edges.
class HScroll extends StatelessWidget {
  const HScroll({super.key, required this.children, this.spacing = 10});
  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        clipBehavior: Clip.none,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [for (final c in children) Padding(padding: EdgeInsets.only(right: spacing), child: c)],
        ),
      );
}

/// One of the bundled vector illustrations (`assets/illustrations/NAME.svg`).
class Illustration extends StatelessWidget {
  const Illustration(this.name, {super.key, this.height = 180, this.semanticLabel});
  final String name;
  final double height;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
        'assets/illustrations/$name.svg',
        height: height,
        semanticsLabel: semanticLabel,
        excludeFromSemantics: semanticLabel == null,
      );
}

/// সাশ্রয় wordmark with the Latin name.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.light = false, this.size = 26});
  final bool light;
  final double size;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('সাশ্রয়', style: Txt.bn(size, color: light ? Brand.bg : Brand.night, weight: FontWeight.w700, height: 1)),
          const SizedBox(width: 8),
          Text('SASHROY', style: Txt.eyebrow(color: light ? Brand.gold2 : Brand.goldDeep)),
        ],
      );
}

/// A taka amount in the display serif.
class PriceText extends StatelessWidget {
  const PriceText(this.value, {super.key, this.unit, this.size = 18, this.color = Brand.ink, this.strike = false});
  final num? value;
  final String? unit;
  final double size;
  final Color color;
  final bool strike;

  @override
  Widget build(BuildContext context) => Text.rich(TextSpan(children: [
        TextSpan(
          text: taka(value),
          style: Txt.display(size, color: color, weight: FontWeight.w600).copyWith(
            decoration: strike ? TextDecoration.lineThrough : null,
            decorationColor: Brand.rose,
            decorationThickness: 2,
          ),
        ),
        if (unit != null && unit!.isNotEmpty)
          TextSpan(text: perUnit(unit), style: Txt.ui(size * 0.62, color: Brand.muted, weight: FontWeight.w600)),
      ]));
}

// ───────────────────────────── States ─────────────────────────────

class ErrorView extends StatelessWidget {
  const ErrorView(this.error, {super.key, this.onRetry});
  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final offline = error is ApiException && (error as ApiException).status == 0;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(color: Brand.goldBg, shape: BoxShape.circle),
            child: Icon(offline ? Icons.wifi_off_rounded : Icons.error_outline_rounded, size: 32, color: Brand.goldDeep),
          ),
          const SizedBox(height: 16),
          Text(offline ? "Can't reach Sashroy" : 'Something went wrong',
              style: Txt.display(22, weight: FontWeight.w600), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Muted(error is ApiException ? error.toString() : 'Please try again.', size: 14, align: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 20),
            SizedBox(width: 200, child: FilledButton(onPressed: onRetry, child: const Text('Try again'))),
          ],
          // Can't reach the server at all: offer to change its address (e.g. a tunnel link on a real phone).
          if (offline) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => openServerSettings(context),
              icon: const Icon(Icons.dns_outlined, size: 18),
              label: Text('Server: ${Uri.parse(apiBase).authority}'),
            ),
          ],
        ]),
      ),
    );
  }
}

/// Elegant loading state: pulsing skeleton cards.
class SkeletonList extends StatefulWidget {
  const SkeletonList({super.key, this.count = 4});
  final int count;

  @override
  State<SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<SkeletonList> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween(begin: 0.45, end: 1.0).animate(_c),
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            for (var i = 0; i < widget.count; i++)
              Container(
                height: i == 0 ? 150 : 86,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
              ),
          ],
        ),
      );
}

/// Loads data once, shows skeleton / error with retry, and supports pull-to-refresh.
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
    if (_loading && _data == null) return const SkeletonList();
    if (_data == null) return ErrorView(_error ?? 'Not found', onRetry: _reload);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: KeyedSubtree(key: const ValueKey('loaded'), child: widget.builder(context, _data as T, _reload)),
    );
  }
}

// ───────────────────────────── Products ─────────────────────────────

IconData formIcon(String? form) {
  final f = (form ?? '').toLowerCase();
  if (f.contains('capsule')) return Icons.medication_rounded;
  if (f.contains('tablet')) return Icons.medication_outlined;
  if (RegExp('injection|infusion|syringe').hasMatch(f)) return Icons.vaccines_outlined;
  if (RegExp('drop|ophthalmic').hasMatch(f)) return Icons.water_drop_outlined;
  if (RegExp('inhal|nebul').hasMatch(f)) return Icons.air_rounded;
  if (RegExp('syrup|suspension|solution|liquid').hasMatch(f)) return Icons.local_drink_outlined;
  if (RegExp('cream|ointment|gel|lotion').hasMatch(f)) return Icons.spa_outlined;
  return Icons.medical_services_outlined;
}

/// The product's own photo, or a soft dosage-form icon when it has none (never a different product's photo).
class ProductThumb extends StatelessWidget {
  const ProductThumb(this.image, {super.key, this.size = 52, this.form});
  final String? image;
  final double size;
  final String? form;

  @override
  Widget build(BuildContext context) {
    final placeholder = DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Brand.c50, Color(0xFFF4EFE3)]),
      ),
      child: Center(child: Icon(formIcon(form), size: size * 0.46, color: Brand.c600)),
    );
    final url = mediaUrl(image);
    return ClipRRect(
      borderRadius: BorderRadius.circular(size > 70 ? 26 : 16),
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

/// Adds to the cart with a light haptic and a shortcut to the cart.
void addToCart(BuildContext context, CartLine line) {
  HapticFeedback.lightImpact();
  context.read<CartModel>().add(line);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_rounded, color: Brand.mint, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text('${line.brandName} added to cart')),
      ]),
      duration: const Duration(seconds: 3),
      persist: false,
      action: context.read<TabsModel>().index == TabsModel.cart
          ? null
          : SnackBarAction(label: 'View cart', onPressed: () => context.read<TabsModel>().go(TabsModel.cart)),
    ));
}

/// Round "+" button that becomes a − qty + stepper once the item is in the cart.
class AddControl extends StatelessWidget {
  const AddControl({super.key, required this.m});
  final Medicine m;

  @override
  Widget build(BuildContext context) {
    final canAdd = m.packId != null && m.listPrice != null && m.listLabel != null;
    if (!canAdd) return const SizedBox.shrink();
    final step = isPerPiece(m.listLabel) ? 10 : 1;
    final line = context.select<CartModel, CartLine?>((c) => c.lines.where((l) => l.packId == m.packId).firstOrNull);
    final qty = line?.qty ?? 0;
    final out = m.outOfStock;

    if (qty > 0) {
      final cart = context.read<CartModel>();
      return Container(
        height: 40,
        decoration: BoxDecoration(color: Brand.c50, borderRadius: BorderRadius.circular(99), border: Border.all(color: Brand.c100)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _RoundIcon(Icons.remove_rounded, 'Fewer ${m.brandName}', () {
            HapticFeedback.selectionClick();
            cart.setQty(m.packId!, qty - step);
          }),
          SizedBox(width: 30, child: Text('$qty', textAlign: TextAlign.center, style: Txt.ui(14, weight: FontWeight.w800, color: Brand.c700))),
          _RoundIcon(Icons.add_rounded, 'More ${m.brandName}', () {
            HapticFeedback.selectionClick();
            cart.setQty(m.packId!, qty + step);
          }),
        ]),
      );
    }

    return Semantics(
      button: true,
      label: out ? '${m.brandName} sold out' : 'Add ${m.brandName} to cart',
      child: Material(
        color: out ? const Color(0xFFE9ECEA) : Brand.c600,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: out
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
                      qty: step,
                    ),
                  ),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(out ? Icons.block_rounded : Icons.add_rounded, color: out ? Brand.muted : Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon(this.icon, this.tooltip, this.onTap);
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 38, height: 38),
        icon: Icon(icon, size: 18, color: Brand.c700),
      );
}

/// One brand in an equivalence list: photo, name, maker, price per unit, savings and a quick add.
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

    return Material(
      color: highlight != null ? Brand.goldBg.withValues(alpha: 0.6) : Colors.transparent,
      child: InkWell(
        onTap: () => openMedicine(context, m.id),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          child: Row(
            children: [
              ProductThumb(m.image, form: m.dosageForm),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(m.brandName, style: Txt.ui(16, weight: FontWeight.w700)),
                        if (m.strength != null) Text(m.strength!, style: Txt.ui(13, color: Brand.muted, weight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${showGeneric ? '${m.dosageForm} · ${m.genericName} · ' : ''}${m.manufacturerName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Txt.ui(12, color: Brand.muted),
                    ),
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                      PriceText(m.comparePrice, unit: m.compareUnit, size: 17),
                      if (cheapest && !out && !m.priceSuspect) const Tag.gold('Cheapest', icon: Icons.workspace_premium_rounded),
                      if (highlight != null) Tag(highlight!, bg: Brand.night, fg: Brand.gold2),
                      if (out)
                        Tag.warn(m.comparePrice == null ? 'No price' : 'Out of stock')
                      else if (m.priceSuspect)
                        const Tag('Price unverified', bg: Brand.amberBg, fg: Brand.amber)
                      else if (save > 0)
                        Tag('Save $save%', icon: Icons.south_east_rounded),
                    ]),
                    if (cheaperCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text('$cheaperCount cheaper equivalent${cheaperCount > 1 ? 's' : ''} elsewhere',
                            style: Txt.ui(12, weight: FontWeight.w700, color: Brand.amber)),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              AddControl(m: m),
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
    final size = compact ? 36.0 : 48.0;
    Widget btn(IconData icon, String label, bool enabled, int next) => SizedBox(
          width: size,
          height: size,
          child: IconButton(
            tooltip: label,
            padding: EdgeInsets.zero,
            iconSize: 18,
            color: Brand.c700,
            onPressed: enabled
                ? () {
                    HapticFeedback.selectionClick();
                    onChanged(next);
                  }
                : null,
            icon: Icon(icon),
          ),
        );
    return Container(
      decoration: BoxDecoration(color: Brand.c50, borderRadius: BorderRadius.circular(99), border: Border.all(color: Brand.c100)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        btn(Icons.remove_rounded, 'Decrease quantity', value > min, value - 1),
        SizedBox(
          width: 30,
          child: Text('$value', textAlign: TextAlign.center, style: Txt.ui(compact ? 14 : 16, weight: FontWeight.w800, color: Brand.c700)),
        ),
        btn(Icons.add_rounded, 'Increase quantity', value < max, value + 1),
      ]),
    );
  }
}

/// Rounded search bar.
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    this.controller,
    this.focusNode,
    this.onSubmitted,
    this.onChanged,
    this.autofocus = false,
    this.onTap,
    this.readOnly = false,
  });
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted, onChanged;
  final VoidCallback? onTap;
  final bool autofocus, readOnly;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), boxShadow: Brand.shadow),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          autofocus: autofocus,
          readOnly: readOnly,
          onTap: onTap,
          textInputAction: TextInputAction.search,
          onSubmitted: onSubmitted,
          onChanged: onChanged,
          autocorrect: false,
          style: Txt.ui(16, weight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: 'Search brand or generic · e.g. Napa',
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Icon(Icons.search_rounded, color: Brand.c600, size: 24),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
            focusedBorder:
                OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Brand.c600, width: 1.6)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            suffixIcon: controller == null
                ? null
                : ListenableBuilder(
                    listenable: controller!,
                    builder: (context, _) => controller!.text.isEmpty
                        ? const SizedBox.shrink()
                        : IconButton(
                            tooltip: 'Clear',
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () {
                              controller!.clear();
                              onChanged?.call('');
                            },
                          ),
                  ),
          ),
        ),
      );
}

/// Page-gutter padding for list children (horizontal scrollers stay unpadded so they bleed to the edges).
Widget gutter(Widget child) => Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: child);

/// Input-style field that opens a searchable bottom-sheet list (friendlier than a long dropdown).
class PickerField extends StatelessWidget {
  const PickerField({
    super.key,
    required this.label,
    required this.icon,
    required this.options,
    required this.value,
    required this.onChanged,
    this.errorText = 'Please choose one',
    this.enabled = true,
  });
  final String label, errorText;
  final IconData icon;
  final List<String> options;
  final String? value;
  final ValueChanged<String> onChanged;
  final bool enabled;

  Future<void> _open(BuildContext context, FormFieldState<String> field) async {
    FocusScope.of(context).unfocus();
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Brand.bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _PickerSheet(title: label, options: options, selected: value),
    );
    if (picked != null) {
      field.didChange(picked);
      onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) => FormField<String>(
        key: ValueKey('$label-$value-${options.length}'),
        initialValue: value,
        validator: (v) => v == null || v.isEmpty ? errorText : null,
        builder: (field) => InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: enabled && options.isNotEmpty ? () => _open(context, field) : null,
          child: InputDecorator(
            isEmpty: field.value == null,
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(icon),
              suffixIcon: const Icon(Icons.unfold_more_rounded),
              errorText: field.errorText,
              enabled: enabled && options.isNotEmpty,
            ),
            child: Text(field.value ?? '', style: Txt.ui(16, weight: FontWeight.w600)),
          ),
        ),
      );
}

class _PickerSheet extends StatefulWidget {
  const _PickerSheet({required this.title, required this.options, this.selected});
  final String title;
  final List<String> options;
  final String? selected;

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final list = _q.isEmpty ? widget.options : widget.options.where((o) => o.toLowerCase().contains(_q.toLowerCase())).toList();
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: Column(children: [
          const SizedBox(height: 10),
          Container(width: 44, height: 5, decoration: BoxDecoration(color: Brand.line, borderRadius: BorderRadius.circular(99))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
            child: Row(children: [
              Expanded(child: Text(widget.title, style: Txt.display(24, weight: FontWeight.w600))),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
            ]),
          ),
          if (widget.options.length > 8)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: TextField(
                autofocus: false,
                decoration: InputDecoration(hintText: 'Search ${widget.title.toLowerCase()}', prefixIcon: const Icon(Icons.search_rounded)),
                onChanged: (v) => setState(() => _q = v.trim()),
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final o = list[i];
                final sel = o == widget.selected;
                return ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  tileColor: sel ? Brand.c50 : null,
                  title: Text(o, style: Txt.ui(16, weight: sel ? FontWeight.w800 : FontWeight.w600, color: sel ? Brand.c700 : Brand.ink)),
                  trailing: sel ? const Icon(Icons.check_circle_rounded, color: Brand.c600) : null,
                  onTap: () => Navigator.pop(context, o),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

/// Thana / area: a searchable picker of the district's thanas when known, otherwise free text.
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
        decoration: const InputDecoration(labelText: 'Area / thana', hintText: 'e.g. Mirpur', prefixIcon: Icon(Icons.place_outlined)),
        validator: (v) => (v ?? '').trim().length < 2 ? 'Enter your area / thana' : null,
        onChanged: (_) => onChanged?.call(),
      );
    }
    return PickerField(
      label: 'Thana / upazila',
      icon: Icons.place_outlined,
      options: thanas,
      value: thanas.contains(controller.text) ? controller.text : null,
      errorText: 'Choose your thana',
      onChanged: (v) {
        controller.text = v;
        onChanged?.call();
      },
    );
  }
}

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
            iconColor: Brand.c700,
            collapsedIconColor: Brand.muted,
            title: Text(title, style: Txt.ui(15, weight: FontWeight.w700)),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            expandedAlignment: Alignment.topLeft,
            children: [Text(body, style: Txt.ui(14, color: const Color(0xFF34443D), weight: FontWeight.w500, height: 1.6))],
          ),
        ),
      Container(
        color: Brand.bg,
        padding: const EdgeInsets.all(14),
        child: const Muted("Source: open MedEx-derived dataset. For reference only — follow your doctor's prescription.", size: 11),
      ),
    ]);
  }
}

const disclaimer =
    'Information is for price comparison only and is not medical advice. Always consult a doctor or pharmacist before switching medicines.';
