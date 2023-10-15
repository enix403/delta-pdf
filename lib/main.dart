import 'package:deltapdf/datastore/datastore.dart';
import 'package:flutter/material.dart';

import './app.dart';

void main() async  {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDataStore.init();
  runApp(const Root());
}

class Root extends StatelessWidget {
  const Root({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Delta PDF',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: App(),
    );
  }
}
