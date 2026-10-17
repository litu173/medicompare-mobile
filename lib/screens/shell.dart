import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../state.dart';
import '../theme.dart';
import 'account.dart';
import 'catalog.dart';
import 'shop.dart';

/// Bottom-tab shell. Each tab keeps its own navigation stack; the bar floats above the content.
class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  final _navigators = List.generate(5, (_) => GlobalKey<NavigatorState>());

  static const _roots = <Widget>[
    HomeScreen(),
    SearchScreen(isTabRoot: true),
    CartScreen(),
    OrdersScreen(),
    AccountScreen(),
  ];

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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = _navigators[tabs.index].currentState;
        if (nav != null && await nav.maybePop()) return;
        if (tabs.index != TabsModel.home) tabs.go(TabsModel.home);
      },
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: tabs.index,
          children: [
            for (var i = 0; i < _roots.length; i++)
              HeroControllerScope.none(
                child: Navigator(
                  key: _navigators[i],
                  onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => _roots[i]),
                ),
              ),
          ],
        ),
        bottomNavigationBar: _FloatingBar(
          index: tabs.index,
          onSelect: (i) => _select(tabs, i),
          items: [
            const _NavItem(Icons.home_outlined, Icons.home_rounded, 'Home'),
            const _NavItem(Icons.search_rounded, Icons.search_rounded, 'Search'),
            _NavItem(Icons.shopping_bag_outlined, Icons.shopping_bag_rounded, 'Cart', badge: cartCount),
            const _NavItem(Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Orders'),
            _NavItem(Icons.person_outline_rounded, Icons.person_rounded, signedIn ? 'Account' : 'Sign in'),
          ],
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

class _FloatingBar extends StatelessWidget {
  const _FloatingBar({required this.index, required this.onSelect, required this.items});
  final int index;
  final ValueChanged<int> onSelect;
  final List<_NavItem> items;

  @override
  Widget build(BuildContext context) => SafeArea(
        minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        child: Container(
          height: 66,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: Brand.night,
            borderRadius: BorderRadius.circular(26),
            boxShadow: Brand.shadowStrong,
            border: Border.all(color: Brand.gold.withValues(alpha: 0.22)),
          ),
          child: Row(children: [
            for (final (i, item) in items.indexed)
              Expanded(
                flex: i == index ? 15 : 10,
                child: Semantics(
                  selected: i == index,
                  button: true,
                  label: item.label,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onSelect(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                      decoration: BoxDecoration(
                        color: i == index ? Brand.gold.withValues(alpha: 0.16) : Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Badge(
                          isLabelVisible: item.badge > 0,
                          backgroundColor: Brand.gold,
                          textColor: Brand.night,
                          label: Text('${item.badge}', style: Txt.ui(10, weight: FontWeight.w800, color: Brand.night)),
                          child: Icon(i == index ? item.activeIcon : item.icon,
                              size: 23, color: i == index ? Brand.gold2 : Colors.white.withValues(alpha: 0.72)),
                        ),
                        if (i == index) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(item.label,
                                maxLines: 1,
                                overflow: TextOverflow.fade,
                                softWrap: false,
                                style: Txt.ui(12.5, weight: FontWeight.w700, color: Brand.gold2)),
                          ),
                        ],
                      ]),
                    ),
                  ),
                ),
              ),
          ]),
        ),
      );
}
