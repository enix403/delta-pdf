import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import './directory_item.dart';

class AppDataStore {
  static Future<Isar>? _isarInstance = null;

  static Future<void> init() async {
    final dir = await getApplicationSupportDirectory();
    final isar = Isar.open(
      [
        DirectoryItemSchema,
      ],
      directory: dir.path,
      inspector: true,
    );
    _isarInstance = isar;
  }

  static Future<Isar> getIsar() {
    if (_isarInstance == null) {
      // Throw error;
    }

    return _isarInstance!;
  }
}
