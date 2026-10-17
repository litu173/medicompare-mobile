import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'api.dart';
import 'screens/shell.dart';
import 'state.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load the saved server address before anything talks to the API.
  final server = ServerModel();
  await server.load();
  final api = Api();
  final auth = AuthModel(api)..load();
  final cart = CartModel()..load();
  final device = DeviceOrders()..load();
  final meta = MetaModel(api)..get().ignore();

  runApp(MultiProvider(
    providers: [
      Provider.value(value: api),
      ChangeNotifierProvider.value(value: server),
      ChangeNotifierProvider.value(value: auth),
      ChangeNotifierProvider.value(value: cart),
      ChangeNotifierProvider.value(value: device),
      ChangeNotifierProvider.value(value: meta),
      ChangeNotifierProvider(create: (_) => TabsModel()),
    ],
    child: const MediCompareApp(),
  ));
}

class MediCompareApp extends StatelessWidget {
  const MediCompareApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'সাশ্রয় Sashroy',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        // A new server address rebuilds the shell so every tab reloads from the new backend.
        home: Shell(key: ValueKey(context.watch<ServerModel>().address)),
      );
}
