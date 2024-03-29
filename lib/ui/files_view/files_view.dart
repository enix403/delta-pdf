import 'dart:io';
import 'package:deltapdf/core/filesystem.dart';
import 'package:deltapdf/dto/item_kind.dart';
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
  final navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    isarFuture = AppDataStore.getIsar();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: isarFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        return WillPopScope(
          onWillPop: () async {
            // If the inner navigator can be popped, then
            // pop that one instead
            if (navigatorKey.currentState != null &&
                navigatorKey.currentState!.canPop()) {
              navigatorKey.currentState!.pop();
              return false;
            }
            return true;
          },
          child: Navigator(
            key: navigatorKey,
            onGenerateInitialRoutes: (_, _0) => [
              MaterialPageRoute(
                builder: (_) => ExploreFolderView(
                  parentId: null,
                  folderTitle: "",
                  isar: snapshot.data!,
                  path: [],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ExploreFolderView extends StatefulWidget {
  final int? parentId;
  final List<String> path;
  final String folderTitle;
  final Isar isar;

  const ExploreFolderView({
    super.key,
    required this.parentId,
    required this.folderTitle,
    required this.isar,
    required this.path,
  });

  @override
  State<ExploreFolderView> createState() => _ExploreFolderViewState();
}

class _ExploreFolderViewState extends State<ExploreFolderView> {
  late Future<List<DirectoryItem>> items;

  @override
  void initState() {
    super.initState();
    refreshItems();
  }

  void refreshItems() {
    final col = widget.isar.collection<DirectoryItem>();
    setState(() {
      items = col.where().parentIdEqualTo(widget.parentId).findAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SearchAppBarSiver(
            isRoot: widget.parentId == null,
            folderTitle: widget.folderTitle,
          ),
          FutureBuilder(
            future: items,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return SortControls();
              }
              return SliverToBoxAdapter(child: SizedBox.shrink());
            },
          ),
          SliverToBoxAdapter(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton(
                  onPressed: () {
                    refreshItems();
                  },
                  child: const Text("Refresh"),
                ),
              ],
            ),
          ),
          FutureBuilder(
            future: items,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return _buildItems(context, snapshot.data!);
              }

              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 64.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [CircularProgressIndicator()],
                  ),
                ),
              );
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

  Widget _buildItems(BuildContext context, List<DirectoryItem> items) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0),
      sliver: GridDirectoryView(
        items: items,
        onItemTapped: (item) {
          if (item.kind == DirectoryItemKind.File) return;

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) {
                return ExploreFolderView(
                  parentId: item.id,
                  folderTitle: item.name,
                  isar: widget.isar,
                  path: [...widget.path, item.name],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<bool> isNameInvalid(String name) async {
    final itemsList = await items;
    return itemsList.any((item) => item.name == name);
  }

  void onNameConflict(BuildContext context, String name) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Item \"$name\" already exists. Please choose another name."),
      showCloseIcon: true,
    ));
  }

  void _onCreateItemPressed(BuildContext context) async {
    final hasPermission =
        await PermissionUtils.externalStoragePermission(context);
    if (!hasPermission) return;

    await DocumentTree.ensureTreeRoot();

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      builder: (_) {
        return CreateItemModal(
          createFolder: (name) async {
            if ((await isNameInvalid(name)))
              return onNameConflict(context, name);
            // Add entry to the database
            final newItem = DirectoryItem()
              ..kind = DirectoryItemKind.Folder
              ..name = name
              ..parentId = widget.parentId;
            final isar = widget.isar;
            await isar.writeTxn(() async {
              await isar.collection<DirectoryItem>().put(newItem);
            });

            // Create the actual directory
            final dirPath = DocumentTree.resolveFromRoot(widget.path + [name]);
            Directory(dirPath).create(recursive: true);

            refreshItems();

            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Folder \"$name\" created."),
              showCloseIcon: true,
            ));
          },
          createFile: (pltfile) async {
            final name = pltfile.name;
            if ((await isNameInvalid(name)))
              return onNameConflict(context, name);

            // copy to tree root
            print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
            print("createFile: " + (pltfile.path ?? ""));
            print("createFile: " + (pltfile.name ?? ""));
            print("createFile: " + (pltfile.extension ?? ""));

            final newPath = DocumentTree.resolveFromRoot(widget.path + [name]);
            final nativeFile = File(pltfile.path!);
            nativeFile.copySync(newPath);
            print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");

            // add entry
            final newItem = DirectoryItem()
              ..kind = DirectoryItemKind.File
              ..name = name
              ..parentId = widget.parentId;
            final isar = widget.isar;
            await isar.writeTxn(() async {
              await isar.collection<DirectoryItem>().put(newItem);
            });

            refreshItems();

            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("File \"$name\" added."),
              showCloseIcon: true,
            ));
          },
        );
      },
    );
  }
}
