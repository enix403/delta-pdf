import 'package:flutter/material.dart';

import 'misc.dart';
import 'render_controller.dart';

import 'doc_loaded_view.dart';

class PdfDocView extends StatefulWidget {
  const PdfDocView({super.key});

  @override
  State<PdfDocView> createState() => _PdfDocViewState();
}

enum LoadState { OPENING, PARSING, LOADED }

class _PdfDocViewState extends State<PdfDocView> {
  LoadState _loadState = LoadState.OPENING;
  late final RenderController _renderController;

  bool _disposed = false;

  @override
  void initState() {
    super.initState();

    _loadState = LoadState.OPENING;

    loadDummyDocument().then(
      (document) {
        setState(() {
          _loadState = LoadState.PARSING;
        });
        return RenderController.create(document);
      },
    ).then(
      (controller) {
        if (_disposed)
          return;
        setState(() {
          _renderController = controller;
          _loadState = LoadState.LOADED;
        });
      },
    );
  }

  @override
  void dispose() {
    _disposed = false;
    if (_loadState == LoadState.LOADED)
      //
      _renderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (_loadState == LoadState.LOADED) {
      child = PdfDocLoadedView(
        renderCtrl: _renderController,
      );
    } else {
      final debugInfo = (_loadState == LoadState.OPENING ? "OPEN" : "PARSE");
      child = LabelledSpinner("Opening Document (" + debugInfo + ")");
    }

    return Scaffold(
      body: SafeArea(
        child: child,
      ),
    );
  }
}
