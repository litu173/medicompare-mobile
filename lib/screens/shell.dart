import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../state.dart';
import '../theme.dart';
import 'account.dart';
import 'catalog.dart';
import 'settings.dart';
import 'shop.dart';
import '../i18n.dart';

/// Bottom-tab shell. Each tab keeps its own navigation stack; the bar floats above the content.
class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  final _navigators = List.generate(5, (_) => GlobalKey<NavigatorState>());

  /// Last shown tab and which way the user moved (1 = right, -1 = left), for the page transition.
  int _last = TabsModel.home;
  int _direction = 1;

  static const _roots = <Widget>[
    HomeScreen(),
    SearchScreen(isTabRoot: true),
    CartScreen(),
    OrdersScreen(),
    AccountScreen(),
  ];

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsModel>();
    if (settings.reopenSettings) {
      settings.reopenSettings = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigators[context.read<TabsModel>().index].currentState?.push(
          PageRouteBuilder(pageBuilder: (_, _, _) => const SettingsScreen()),
        );
      });
    }
  }

  void _select(TabsModel tabs, int i) {
    HapticFeedback.selectionClick();
    if (i == tabs.index) {
      _navigators[i].currentState?.popUntil((r) => r.isFirst);
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      tabs.go(i);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = context.watch<TabsModel>();
    final cartCount = context.select<CartModel, int>((c) => c.count);
    final signedIn = context.select<AuthModel, bool>((a) => a.signedIn);
    // Tabs can also change from elsewhere (e.g. "Start comparing"), so work out the direction here.
    if (tabs.index != _last) {
      _direction = tabs.index > _last ? 1 : -1;
      _last = tabs.index;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = _navigators[tabs.index].currentState;
        if (nav != null && await nav.maybePop()) return;
        if (tabs.index != TabsModel.home) tabs.go(TabsModel.home);
      },
      // Default status bar for the light (or dark-theme) tabs; Home's own region overrides it while visible.
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: Brand.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: Scaffold(
          extendBody: true,
          body: Stack(
            fit: StackFit.expand,
            children: [
              for (var i = 0; i < _roots.length; i++)
                _TabPage(
                  active: i == tabs.index,
                  direction: _direction,
                  child: HeroControllerScope.none(
                    child: Navigator(
                      key: _navigators[i],
                      onGenerateRoute: (_) =>
                          MaterialPageRoute(builder: (_) => _roots[i]),
                    ),
                  ),
                ),
            ],
          ),
          bottomNavigationBar: _FloatingBar(
            index: tabs.index,
            onSelect: (i) => _select(tabs, i),
            items: [
              _NavItem(Icons.home_outlined, Icons.home_rounded, 'Home'),
              _NavItem(Icons.search_rounded, Icons.search_rounded, 'Search'),
              _NavItem(
                Icons.shopping_bag_outlined,
                Icons.shopping_bag_rounded,
                'Cart',
                badge: cartCount,
              ),
              _NavItem(
                Icons.receipt_long_outlined,
                Icons.receipt_long_rounded,
                'Orders',
              ),
              _NavItem(
                Icons.person_outline_rounded,
                Icons.person_rounded,
                signedIn ? tr('Account') : tr('Sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.activeIcon, this.label, {this.badge = 0});
  final IconData icon, activeIcon;
  final String label;
  final int badge;
}

/// Keeps a tab alive and cross-fades it in or out with a short slide in the direction of travel.
class _TabPage extends StatefulWidget {
  const _TabPage({
    required this.active,
    required this.direction,
    required this.child,
  });
  final bool active;
  final int direction;
  final Widget child;

  @override
  State<_TabPage> createState() => _TabPageState();
}

class _TabPageState extends State<_TabPage>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    reverseDuration: const Duration(milliseconds: 200),
    value: widget.active ? 1 : 0,
  );

  @override
  void didUpdateWidget(_TabPage old) {
    super.didUpdateWidget(old);
    if (widget.active != old.active) {
      widget.active ? _c.forward(from: 0) : _c.reverse();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    child: widget.child,
    builder: (context, child) {
      final hidden = !widget.active && _c.isDismissed;
      final t = widget.active
          ? Curves.easeOutCubic.transform(_c.value)
          : Curves.easeInCubic.transform(_c.value);
      // Incoming page drifts in from the side it came from; the outgoing one drifts the other way.
      final dx =
          (1 - t) *
          0.06 *
          (widget.active ? widget.direction : -widget.direction);
      return Offstage(
        offstage: hidden,
        child: TickerMode(
          enabled: !hidden,
          child: IgnorePointer(
            ignoring: !widget.active,
            child: ExcludeFocus(
              excluding: !widget.active,
              child: Opacity(
                opacity: t,
                child: FractionalTranslation(
                  translation: Offset(dx, 0),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _FloatingBar extends StatelessWidget {
  const _FloatingBar({
    required this.index,
    required this.onSelect,
    required this.items,
  });
  final int index;
  final ValueChanged<int> onSelect;
  final List<_NavItem> items;

  /// Same gap between the selection pill and the bar's edge on every side.
  static const _inset = 6.0, _height = 68.0, _radius = 28.0;
  static const _duration = Duration(milliseconds: 380);
  static const _curve = Curves.easeOutQuart;

  @override
  Widget build(BuildContext context) => SafeArea(
    minimum: EdgeInsets.fromLTRB(14, 0, 14, 10),
    child: Container(
      height: _height,
      padding: EdgeInsets.all(_inset),
      decoration: BoxDecoration(
        color: Brand.night,
        borderRadius: BorderRadius.circular(_radius),
        boxShadow: Brand.shadowStrong,
        border: Border.all(color: Brand.gold.withValues(alpha: 0.22)),
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          // The selected tab is wider to fit its label; the rest share what is left.
          final selected = box.maxWidth * 1.7 / (items.length + 0.7);
          final other = (box.maxWidth - selected) / (items.length - 1);
          return Stack(
            fit: StackFit.expand,
            children: [
              AnimatedPositioned(
                duration: _duration,
                curve: _curve,
                left: index * other,
                top: 0,
                bottom: 0,
                width: selected,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Brand.gold.withValues(alpha: 0.16),
                    border: Border.all(
                      color: Brand.gold.withValues(alpha: 0.18),
                    ),
                    // Concentric with the bar's corners.
                    borderRadius: BorderRadius.circular(_radius - _inset),
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, item) in items.indexed)
                    AnimatedContainer(
                      duration: _duration,
                      curve: _curve,
                      width: i == index ? selected : other,
                      child: _TabButton(
                        item: item,
                        active: i == index,
                        onTap: () => onSelect(i),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    ),
  );
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.item,
    required this.active,
    required this.onTap,
  });
  final _NavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: active,
    button: true,
    label: tr(item.label),
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ClipRect(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Badge(
              isLabelVisible: item.badge > 0,
              backgroundColor: Brand.gold,
              textColor: Brand.night,
              label: Text(
                '${item.badge}',
                style: Txt.ui(10, weight: FontWeight.w800, color: Brand.night),
              ),
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 220),
                transitionBuilder: (child, a) => ScaleTransition(
                  scale: Tween(begin: 0.8, end: 1.0).animate(a),
                  child: FadeTransition(opacity: a, child: child),
                ),
                child: Icon(
                  active ? item.activeIcon : item.icon,
                  key: ValueKey(active),
                  size: 24,
                  color: active
                      ? Brand.gold2
                      : Colors.white.withValues(alpha: 0.72),
                ),
              ),
            ),
            // The label grows in from zero width so the pill and text move together.
            Flexible(
              child: AnimatedSize(
                duration: _FloatingBar._duration,
                curve: _FloatingBar._curve,
                child: active
                    ? Padding(
                        padding: EdgeInsets.only(left: 7),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                          builder: (context, v, child) =>
                              Opacity(opacity: v, child: child),
                          child: Text(
                            tr(item.label),
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            style: Txt.ui(
                              13,
                              weight: FontWeight.w700,
                              color: Brand.gold2,
                            ),
                          ),
                        ),
                      )
                    : SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
