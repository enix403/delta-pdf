import 'dart:ui';

//import 'package:deltapdf/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import './grid_catalogue_item.dart';

class FilesView extends StatefulWidget {
  const FilesView({super.key});

  @override
  _FilesViewState createState() => _FilesViewState();
}

class _FilesViewState extends State<FilesView> {
  TextEditingController _searchQueryController = TextEditingController();

  Widget _buildSearchField(BuildContext context) {
    return TextField(
      controller: _searchQueryController,
      autofocus: false,
      decoration: InputDecoration(
        hintText: "Search",
        hintStyle: TextStyle(color: const Color(0xFF8A8A8A)),
        border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(64)),
        filled: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _buildSearchBar(context),
        _buildSortControls(),
        _buildGridView(),
        // bottom padding
        SliverToBoxAdapter(
          child: const SizedBox(
            height: 128,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
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
        title: _buildSearchField(context),
        floating: true,
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
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          childAspectRatio: 1,
          crossAxisCount: 2,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return GridCatalogueItem();
          },
          childCount: 30,
        ),
      ),
    );
  }
}


