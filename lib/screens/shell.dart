import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state.dart';
import 'account.dart';
import 'catalog.dart';
import 'shop.dart';

/// Bottom-tab shell. Each tab keeps its own navigation stack, like the web's persistent bottom nav.
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
    CompaniesScreen(),
    CartScreen(),
    AccountScreen(),
  ];

  void _select(TabsModel tabs, int i) {
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
        bottomNavigationBar: NavigationBar(
          selectedIndex: tabs.index,
          onDestinationSelected: (i) => _select(tabs, i),
          destinations: [
            const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
            const NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
            const NavigationDestination(
                icon: Icon(Icons.business_outlined), selectedIcon: Icon(Icons.business), label: 'Companies'),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: cartCount > 0,
                label: Text('$cartCount'),
                child: const Icon(Icons.shopping_cart_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: cartCount > 0,
                label: Text('$cartCount'),
                child: const Icon(Icons.shopping_cart),
              ),
              label: 'Cart',
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person),
              label: signedIn ? 'Account' : 'Sign in',
            ),
          ],
        ),
      ),
    );
  }
}
