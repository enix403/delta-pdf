import 'package:flutter/material.dart';

import 'misc.dart';
import 'controllers.dart';

import 'doc_loaded_view.dart';

class PdfDocView extends StatefulWidget {
  const PdfDocView({super.key});

  @override
  State<PdfDocView> createState() => _PdfDocViewState();
}

class _PdfDocViewState extends State<PdfDocView> {
  final loadCtrl = new PdfLoadController();

  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    loadCtrl
      ..load("1601")
      ..notifyOnLoaded((_) {
        setState(() {
          _loaded = true;
        });
      });
  }

  @override
  void dispose() {
    loadCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (_loaded) {
      child = PdfDocLoadedView(loadCtrl: loadCtrl);
    } else {
      child = const LabelledSpinner("Opening Document");
    }

    return Scaffold(
      body: SafeArea(
        child: child,
      ),
    );
  }
}
