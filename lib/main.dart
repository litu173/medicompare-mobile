import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import 'api.dart';
import 'i18n.dart';
import 'screens/onboarding.dart';
import 'screens/shell.dart';
import 'state.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load the saved server address before anything talks to the API.
  final server = ServerModel();
  await server.load();
  // Pick up the live store link before the first request (falls back to the saved one if offline).
  await server.discover();
  final settings = SettingsModel();
  await settings.load();
  final api = Api();
  final auth = AuthModel(api)..load();
  final cart = CartModel()..load();
  final device = DeviceOrders();
  final meta = MetaModel(api)..get().ignore();
  final onboarding = OnboardingModel();
  await onboarding.load();
  await device.load();
  final savings = SavingsModel(api, device);
  // Recount savings whenever the signed-in user changes (including the initial session restore).
  auth.addListener(() => savings.refresh());
  savings.refresh().ignore();
  final update = UpdateModel();
  try {
    final info = await PackageInfo.fromPlatform();
    await update.loadCurrent(info.version, info.buildNumber);
  } catch (_) {}
  update.check().ignore();

  runApp(MultiProvider(
    providers: [
      Provider.value(value: api),
      ChangeNotifierProvider.value(value: server),
      ChangeNotifierProvider.value(value: settings),
      ChangeNotifierProvider.value(value: auth),
      ChangeNotifierProvider.value(value: cart),
      ChangeNotifierProvider.value(value: device),
      ChangeNotifierProvider.value(value: meta),
      ChangeNotifierProvider.value(value: onboarding),
      ChangeNotifierProvider.value(value: savings),
      ChangeNotifierProvider.value(value: update),
      ChangeNotifierProvider(create: (_) => TabsModel()),
    ],
    child: const SashroyApp(),
  ));
}

class SashroyApp extends StatefulWidget {
  const SashroyApp({super.key});

  @override
  State<SashroyApp> createState() => _SashroyAppState();
}

class _SashroyAppState extends State<SashroyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Follow the phone's dark mode when the theme is set to "System".
  @override
  void didChangePlatformBrightness() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsModel>();
    final systemDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    // Colors and strings are read from these globals while widgets build, so set them first.
    Brand.dark = settings.theme == 'dark' || (settings.theme == 'system' && systemDark);
    appLanguage = settings.language;
    final address = context.watch<ServerModel>().address;

    return MaterialApp(
      key: ValueKey('${Brand.dark}-$appLanguage'),
      title: 'সাশ্রয় Sashroy',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      // A new server address, theme or language rebuilds the shell so everything picks it up.
      home: context.watch<OnboardingModel>().done
          ? Shell(key: ValueKey('$address-${Brand.dark}-$appLanguage'))
          : const OnboardingScreen(),
    );
  }
}
