import 'dart:ui';

//import 'package:deltapdf/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    final appBar = SliverAppBar(
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
      ),
      automaticallyImplyLeading: false,
      scrolledUnderElevation: 0.0,
      backgroundColor: Colors.transparent,
      title: _buildSearchField(context),
      floating: true,
    );

    final sortRow = SliverToBoxAdapter(
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

    final grid = SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        //mainAxisExtent: 164,
        childAspectRatio: 1,
        crossAxisCount: 2,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return CatalogueItem();
        },
        childCount: 30,
      ),
    );

    final bottomPadding = SliverToBoxAdapter(
      child: const SizedBox(
        height: 128,
      ),
    );

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.only(top: 8.0),
          sliver: appBar,
        ),
        sortRow,
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0),
          sliver: grid,
        ),
        bottomPadding
      ],
    );
  }
}

class CatalogueItem extends StatelessWidget {
  const CatalogueItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      //color: getRandomColor(),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.folder,
            size: 132,
            //color: Color(0xAA6F2219),
            color: Color(0xAA6A371C),
            //color: Color(0xAA86452E),
            //color: Color(0xAAB4634E),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Opacity(opacity: 0, child: Icon(Icons.more_vert)),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: const Text(
                    "Distance between line and plane",
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ),
              Icon(Icons.more_vert)
            ],
          ),
        ],
      ),
    );
  }
}
