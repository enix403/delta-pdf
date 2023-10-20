import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SearchAppBarSiver extends StatelessWidget {
  final bool isRoot;
  final String? folderTitle;

  SearchAppBarSiver({super.key, required this.isRoot, this.folderTitle});

  final TextEditingController _searchQueryController = TextEditingController();

  static Color _barFillColor(BuildContext context) =>
      Theme.of(context).colorScheme.primaryContainer.withOpacity(0.36);

  @override
  Widget build(BuildContext context) {
    final inner = isRoot ? buildRoot(context) : buildNonRoot(context);
    return SliverPadding(
      padding: const EdgeInsets.only(top: 8.0),
      sliver: inner,
    );
  }

  Widget buildNonRoot(BuildContext context) {
    return SliverAppBar(
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
      ),
      //automaticallyImplyLeading: false,
      title: Text(folderTitle ?? ""),
      scrolledUnderElevation: 0.0,
      titleSpacing: 0,
      titleTextStyle:
          Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18.0),
      backgroundColor: _barFillColor(context),
      floating: true,
    );
  }

  Widget buildRoot(BuildContext context) {
    return SliverAppBar(
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
      ),
      automaticallyImplyLeading: false,
      scrolledUnderElevation: 0.0,
      backgroundColor: Colors.transparent,
      title: TextField(
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
            fillColor: _barFillColor(context)),
      ),
      floating: true,
    );
  }
}
