import 'dart:async';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:pdfx/pdfx.dart';

export 'render_dto.dart';
import 'render_dto.dart';
import 'cmd_executor.dart';

/* ===================================== */

abstract class _RenderCommand {}

class _UpdateConfigCommand extends _RenderCommand {
  final ViewportInfo viewportInfo;
  final int version;

  _UpdateConfigCommand({
    required this.viewportInfo,
    required this.version,
  });
}

class _AddChunkCommand extends _RenderCommand {
  final PageChunk chunk;
  final int version;

  _AddChunkCommand(this.chunk, {required this.version});
}

class _CloseCommand extends _RenderCommand {}

class _CloseCommandPong {}

/* ===================================== */

class _WorkerArgs {
  final SendPort sendToMain;
  final PdfDocument document;
  final RootIsolateToken token;

  _WorkerArgs({
    required this.sendToMain,
    required this.document,
    required this.token,
  });
}

class RenderController {
  final PdfDocument document;

  int _latestVersion = 0;
  int get latestVersion => _latestVersion;
  final List<PageChunk> _visitedChunks = [];
  List<PageChunk> get visitedChunks => _visitedChunks;

  RenderController(this.document);

  final StreamController<RenderResult> _renderStreamController =
      new StreamController();
  Stream<RenderResult> get outputStream => _renderStreamController.stream;

  late final SendPort _sendToWorker;

  static Future<RenderController> create(PdfDocument document) async {
    final ctrl = RenderController(document);
    await ctrl.init();
    return ctrl;
  }

  Future<void> init() async {
    _sendToWorker = await _initWorker();
  }

  Future<SendPort> _initWorker() {
    Completer<SendPort> completer = Completer();

    final listenFromWorker = ReceivePort();
    listenFromWorker.listen((data) {
      if (data is SendPort) {
        final sendToWorker = data;
        completer.complete(sendToWorker);
      } else if (data is RenderResult) {
        final result = data;
        if (result.version == _latestVersion)
          _renderStreamController.add(result);
      } else if (data is _CloseCommandPong) {
        listenFromWorker.close();
      }
    }, onDone: () {
      document.close();
    });

    final token = RootIsolateToken.instance!;

    Isolate.spawn(
      _workerIsolate,
      _WorkerArgs(
        sendToMain: listenFromWorker.sendPort,
        document: document,
        token: token,
      ),
    );

    return completer.future;
  }

  static void _workerIsolate(_WorkerArgs args) {
    BackgroundIsolateBinaryMessenger.ensureInitialized(args.token);

    final listenFromMain = ReceivePort();
    args.sendToMain.send(listenFromMain.sendPort);

    final cmdExecutor = RenderCommandExecutor(
      document: args.document,
      afterClosed: () {
        args.sendToMain.send(_CloseCommandPong());
        listenFromMain.close();
      },
    );

    cmdExecutor.stream.listen((result) {
      args.sendToMain.send(result);
    });

    listenFromMain.listen((data) {
      if (data is _AddChunkCommand) {
        cmdExecutor.enqueue(data.version, data.chunk);
      } else if (data is _UpdateConfigCommand) {
        cmdExecutor.updateConfig(data.version, data.viewportInfo);
      } else if (data is _CloseCommand) {
        cmdExecutor.close();
      }
    });
  }

  void _tickVersion() {
    _visitedChunks.clear();
    _latestVersion++;
  }

  void enqueueChunk(PageChunk chunk) {
    _visitedChunks.add(chunk);
    _sendToWorker.send(
      _AddChunkCommand(
        chunk,
        version: _latestVersion,
      ),
    );
  }

  void updateViewport(ViewportInfo viewportInfo) {
    _tickVersion();
    _sendToWorker.send(
      _UpdateConfigCommand(
        viewportInfo: viewportInfo,
        version: _latestVersion,
      ),
    );
  }

  // [NOTE]: RenderController must not be used after a call to this method
  void dispose() {
    _tickVersion();
    _sendToWorker.send(_CloseCommand());
  }
}
