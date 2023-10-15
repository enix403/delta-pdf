import 'package:isar/isar.dart';
import 'package:deltapdf/dto/item_kind.dart';

part 'directory_item.g.dart';

@collection
class DirectoryItem {
  Id id = Isar.autoIncrement;

  @Enumerated(EnumType.ordinal)
  late DirectoryItemKind kind;

  late String name;

  //final children = IsarLinks<DirectoryItem>();
  @Index()
  int? parentId;
}
