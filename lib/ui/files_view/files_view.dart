import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import './grid_catalogue_view.dart';

class FilesView extends StatefulWidget {
  const FilesView({super.key});

  @override
  _FilesViewState createState() => _FilesViewState();
}

class _FilesViewState extends State<FilesView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SearchBarSiver(),
          _buildSortControls(),
          _buildGridView(),
          // bottom padding
          SliverToBoxAdapter(
            child: const SizedBox(
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

  Widget _buildSortControls() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(
            left: 16.0, right: 16.0, top: 24.0, bottom: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Date Modified",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(
                  height: 0,
                  width: 8,
                ),
                Icon(Icons.north, size: 16),
              ],
            ),
            Icon(Icons.list),
          ],
        ),
        //),
      ),
    );
  }

  Widget _buildGridView() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0),
      sliver: GridCatalogueView(),
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

class CreateItemModal extends StatelessWidget {
  const CreateItemModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton.outlined(
                icon: const Icon(Icons.folder_open),
                onPressed: () {
                  _onCreaterFolderPressed(context);
                },
              ),
              const Text("Folder")
            ],
          ),
          SizedBox(width: 56.0),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton.outlined(
                icon: const Icon(Icons.article),
                onPressed: () {},
              ),
              const Text("File")
            ],
          ),
        ],
      ),
    );
  }

  void _onCreaterFolderPressed(BuildContext context) {
    Navigator.pop(context);
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Create Folder"),
          content: TextField(
            maxLines: 1,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Folder Name',
              isDense: true,
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            FilledButton(
              child: const Text("Create"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}

class SearchBarSiver extends StatelessWidget {
  SearchBarSiver({super.key});

  final TextEditingController _searchQueryController = TextEditingController();

  Widget _buildSearchField() {
    return TextField(
      controller: _searchQueryController,
      autofocus: false,
      decoration: InputDecoration(
        hintText: "Search",
        hintStyle: TextStyle(color: const Color(0xFF8A8A8A)),
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(64),
        ),
        filled: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return SliverPadding(
      padding: const EdgeInsets.only(top: 8.0),
      sliver: SliverAppBar(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.white,
          statusBarIconBrightness: Brightness.dark,
        ),
        automaticallyImplyLeading: false,
        scrolledUnderElevation: 0.0,
        backgroundColor: Colors.transparent,
        title: _buildSearchField(),
        floating: true,
      ),
    );
  }
}
