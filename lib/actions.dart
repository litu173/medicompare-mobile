import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'format.dart';

/// Public landing page with the app download and the web store link.
const landingUrl = 'https://litu173.github.io/medicompare/';

/// Invites family and friends: the whole point is that more people find the cheaper equivalent.
Future<void> shareApp(BuildContext context) => SharePlus.instance.share(ShareParams(
      text: 'সাশ্রয় (Sashroy) shows every brand of the same medicine side by side, cheapest first. '
          'Same medicine, honest price. Try it: $landingUrl',
      subject: 'Save on medicines with Sashroy',
    ));

Future<void> shareSavings(BuildContext context, num amount) => SharePlus.instance.share(ShareParams(
      text: 'I saved ${taka(amount)} on my medicines with সাশ্রয় (Sashroy). Same medicine, cheaper brand. '
          'Check yours before you buy: $landingUrl',
      subject: 'I saved on medicines with Sashroy',
    ));

/// Opens the phone dialer.
Future<void> callNumber(BuildContext context, String phone) async {
  final ok = await launchUrl(Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^\d+]'), '')));
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Call $phone from your phone app.')));
  }
}
