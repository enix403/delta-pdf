import 'package:flutter/material.dart';

import 'misc.dart';
import 'pipeline.dart';

class PdfDocView extends StatefulWidget {
  const PdfDocView({super.key});

  @override
  State<PdfDocView> createState() => _PdfDocViewState();
}

class _PdfDocViewState extends State<PdfDocView> {
  bool _loaded = false;
  late final RenderPipeline _renderPipeline;

  @override
  void initState() {
    super.initState();
    loadDummyDocument()
      .then((document) => RenderPipeline.create(document))
      .then((pipeline) {
        setState(() {
          _loaded = true;
          _renderPipeline = pipeline;
        });
      });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (_loaded) {
      //child = PdfDocLoadedView(loadCtrl: loadCtrl);
      child = Center(child: Text("loaded"));
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
