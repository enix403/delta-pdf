import 'dart:io';
//import 'package:path_provider/path_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:external_path/external_path.dart';

class RootStorageNotFound implements Exception {}

class DocumentTree {
  static String? treeRoot;

  static String getRoot() {
    if (treeRoot == null) throw new Exception("Tree Root not initialized");
    return treeRoot!;
  }

  static String resolveFromRoot(List<String> segments) {
    final relPath = segments.join('/');
    final absPath = getRoot() + "/" + relPath;
    return absPath;
  }

  static Future<String> identifyInternalStorage() async {
    List<String> storagePaths =
        await ExternalPath.getExternalStorageDirectories();

    if (storagePaths.isEmpty) throw RootStorageNotFound();

    int maxIndex = -1;
    double maxScore = double.negativeInfinity;
    for (int i = 0; i < storagePaths.length; ++i) {
      double score = 0;
      String path = storagePaths[i];
      if (path.contains("emulated")) ++score;

      if (path.contains("sdcard")) --score;

      if (score > maxScore) {
        maxScore = score;
        maxIndex = i;
      }
    }

    return storagePaths[maxIndex];
  }

  static Future<void> ensureTreeRoot() async {
    String internalRoot = await identifyInternalStorage();
    const TREE_ROOT_NAME = "DeltaPDFDocs";

    if (internalRoot.endsWith('/')) {
      internalRoot = internalRoot.substring(0, internalRoot.length - 1);
    }

    final treeTootPath = "$internalRoot/$TREE_ROOT_NAME";
    print("treeTootPath: $treeTootPath");
    treeRoot = treeTootPath;
    Directory(treeTootPath).create(recursive: true);
  }
}

class PermissionUtils {
  // This func is added to access scope storage to export csv files
  static Future<bool> externalStoragePermission(BuildContext context) async {
    final androidVersion = await DeviceInfoPlugin().androidInfo;

    if ((androidVersion.version.sdkInt ?? 0) >= 30) {
      return await checkManageStoragePermission(context);
    } else {
      return await checkStoragePermission(context);
    }
  }

  static Future<bool> checkManageStoragePermission(BuildContext context) async {
    return (await Permission.manageExternalStorage.isGranted ||
        await Permission.manageExternalStorage.request().isGranted);
  }

  static Future<bool> checkStoragePermission(
    BuildContext context, {
    String? storageTitle,
    String? storageSubMessage,
  }) async {
    if (await Permission.storage.isGranted ||
        await Permission.storage.request().isGranted) {
      return true;
    } else {
      return false;
    }
  }
}
