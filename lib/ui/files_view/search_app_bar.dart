import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SearchAppBarSiver extends StatelessWidget {
  final bool isRoot;

  SearchAppBarSiver({
    super.key,
    required this.isRoot,
  });

  final TextEditingController _searchQueryController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return isRoot ? buildRoot(context) : buildNonRoot(context);
  }

  Widget buildNonRoot(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.only(top: 8.0),
      sliver: SliverAppBar(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.white,
          statusBarIconBrightness: Brightness.dark,
        ),
        automaticallyImplyLeading: false,
        scrolledUnderElevation: 0.0,
        backgroundColor:
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.36),
        floating: true,
      ),
    );
  }

  Widget buildRoot(BuildContext context) {
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
          ),
        ),
        floating: true,
      ),
    );
  }
}
