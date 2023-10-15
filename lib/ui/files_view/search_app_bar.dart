import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
