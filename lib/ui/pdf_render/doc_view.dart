import 'package:flutter/material.dart';

import 'misc.dart';
import 'pipeline.dart';

import 'doc_loaded_view.dart';

class PdfDocView extends StatefulWidget {
  const PdfDocView({super.key});

  @override
  State<PdfDocView> createState() => _PdfDocViewState();
}

enum LoadState { OPENING, PARSING, LOADED }

class _PdfDocViewState extends State<PdfDocView> {
  LoadState _loadState = LoadState.OPENING;
  late final RenderPipeline _renderPipeline;

  @override
  void initState() {
    super.initState();

    _loadState = LoadState.OPENING;

    loadDummyDocument().then(
      (document) {
        setState(() {
          _loadState = LoadState.PARSING;
        });
        return RenderPipeline.create(document);
      },
    ).then(
      (pipeline) {
        setState(() {
          _renderPipeline = pipeline;
          _loadState = LoadState.LOADED;
        });
      },
    );
  }

  @override
  void dispose() {
    if (_loadState == LoadState.LOADED) _renderPipeline.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (_loadState == LoadState.LOADED) {
      child = PdfDocLoadedView(
        pipeline: _renderPipeline,
      );
    } else {
      final debugInfo = (_loadState == LoadState.OPENING ? "OPEN" : "PARSE");
      child = LabelledSpinner("Opening Document(" + debugInfo + ")");
    }

    return Scaffold(
      body: SafeArea(
        child: child,
      ),
    );
  }
}
