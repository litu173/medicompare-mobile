import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import '../i18n.dart';

/// Three-slide welcome shown on first launch.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pages = PageController();
  int _index = 0;

  static final _slides = [
    (
      art: 'welcome_compare',
      bn: 'একই ওষুধ, সাশ্রয়ী দামে',
      bnEn: 'একই ওষুধ, সাশ্রয়ী দামে',
      title: 'Same medicine,\nhonest price.',
      body: 'Search the brand on your prescription and see every equivalent from all companies, cheapest first.',
    ),
    (
      art: 'welcome_save',
      bn: 'পরিবারের জন্য সাশ্রয়',
      bnEn: 'পরিবারের জন্য সাশ্রয়',
      title: 'Save for the\nwhole family.',
      body: 'For medicines you take every day, a cheaper equal brand can save thousands of taka a year.',
    ),
    (
      art: 'welcome_delivery',
      bn: 'ঘরে বসে ওষুধ',
      bnEn: 'ঘরে বসে ওষুধ',
      title: 'Delivered with\ncare.',
      body: 'Every order is checked item by item, packed, and brought to your door. Track it live and pay on delivery.',
    ),
  ];

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _next() {
    if (_index == _slides.length - 1) {
      context.read<OnboardingModel>().finish();
    } else {
      _pages.nextPage(duration: Duration(milliseconds: 450), curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = _index == _slides.length - 1;
    return Scaffold(
      backgroundColor: Brand.bg,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: EdgeInsets.fromLTRB(24, 12, 12, 0),
            child: Row(children: [
              Wordmark(size: 24),
              Spacer(),
              if (!last) TextButton(onPressed: () => context.read<OnboardingModel>().finish(), child: Text(tr('Skip'))),
            ]),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pages,
              itemCount: _slides.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                final s = _slides[i];
                return ListView(padding: EdgeInsets.fromLTRB(28, 16, 28, 0), children: [
                  Illustration(s.art, height: 280, semanticLabel: 'Illustration: happy customers'),
                  SizedBox(height: 24),
                  Text(isBangla ? s.bn : s.bnEn, style: Txt.bn(18, color: Brand.goldDeep)),
                  SizedBox(height: 8),
                  Text(tr(s.title), style: Txt.display(38, weight: FontWeight.w500, height: 1.05)),
                  SizedBox(height: 14),
                  Text(tr(s.body), style: Txt.ui(16, color: Brand.muted, height: 1.55)),
                ]);
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(28, 8, 28, 20),
            child: Row(children: [
              for (var i = 0; i < _slides.length; i++)
                AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  margin: EdgeInsets.only(right: 6),
                  width: i == _index ? 26 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _index ? Brand.c600 : Brand.line,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              Spacer(),
              SizedBox(
                width: last ? 190 : 140,
                child: FilledButton(
                  onPressed: _next,
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(last ? tr('Start saving') : tr('Next')),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 20),
                  ]),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
