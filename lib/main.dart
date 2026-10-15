import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'api.dart';
import 'screens/shell.dart';
import 'state.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final api = Api();
  final auth = AuthModel(api)..load();
  final cart = CartModel()..load();
  final device = DeviceOrders()..load();
  final meta = MetaModel(api)..get().ignore();

  runApp(MultiProvider(
    providers: [
      Provider.value(value: api),
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
        title: 'MediCompare BD',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const Shell(),
      );
}
