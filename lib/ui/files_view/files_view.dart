import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

import 'package:deltapdf/datastore/datastore.dart';
import 'package:deltapdf/datastore/directory_item.dart';

import 'grid_directory_view.dart';
import 'search_app_bar.dart';
import 'sort_controls.dart';
import 'create_item_modal.dart';

class FilesView extends StatefulWidget {
  const FilesView({super.key});

  @override
  FilesViewState createState() => FilesViewState();
}

class FilesViewState extends State<FilesView> {
  late final Future<Isar> isar;

  @override
  void initState() {
    super.initState();
    isar = AppDataStore.getIsar();
  }

  @override
  Widget build(BuildContext context) {
    return ExploreFolderView(parentId: null, folderTitle: "");
  }
}

class ExploreFolderView extends StatefulWidget {
  final int? parentId;
  final String folderTitle;
  late final Isar isar;

  ExploreFolderView({
    super.key,
    required this.parentId,
    required this.folderTitle,
    //required this.isar,
  });

  @override
  State<ExploreFolderView> createState() => _ExploreFolderViewState();
}

class _ExploreFolderViewState extends State<ExploreFolderView> {
  late final Future<List<DirectoryItem>> items;

  @override
  void initState() {
    super.initState();
    final col = widget.isar.collection<DirectoryItem>();
    items = col.where().parentIdEqualTo(widget.parentId).findAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SearchAppBarSiver(isRoot: widget.parentId == null),
          SortControls(),
          _buildGridView(),
          // bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(
              height: 128,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _onCreateItemPressed(context);
          //_settingModalBottomSheet(context);
        },
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }

  Widget _buildGridView() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0),
      sliver: GridDirectoryView(),
    );
  }

  void _onCreateItemPressed(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return CreateItemModal();
      },
    );
  }
}
