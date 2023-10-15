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
  late final Future<Isar> isarFuture;

  @override
  void initState() {
    super.initState();
    isarFuture = AppDataStore.getIsar();
  }

  @override
  Widget build(BuildContext context) {
    //return ExploreFolderView(parentId: null, folderTitle: "");
    return FutureBuilder(
      future: isarFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        return ExploreFolderView(
          parentId: null,
          folderTitle: "",
          isar: snapshot.data!,
        );
      },
    );
  }
}

class ExploreFolderView extends StatefulWidget {
  final int? parentId;
  final String folderTitle;
  final Isar isar;

  ExploreFolderView({
    super.key,
    required this.parentId,
    required this.folderTitle,
    required this.isar,
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
          FutureBuilder(
            future: items,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData) return SortControls();
              return SliverToBoxAdapter(child: SizedBox.shrink());
            },
          ),
          FutureBuilder(
            future: items,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 64.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [CircularProgressIndicator()],
                    ),
                  ),
                );
              }

              return _buildItems();
            },
          ),
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

  Widget _buildItems() {
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
