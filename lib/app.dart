import 'package:deltapdf/core/filesystem.dart';
import 'package:deltapdf/ui/pdf_render/doc_view.dart';
import 'package:flutter/material.dart';

import 'ui/files_view/files_view.dart';
import 'ui/recents_view/recents_view.dart';
import 'ui/favourites_view/favourites_view.dart';

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  int currentViewIndex = 0;

  @override
  Widget build(BuildContext context) {

    return PdfDocView();

    // ignore: dead_code
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () async {
            final hasPermission =
                await PermissionUtils.externalStoragePermission(context);
            if (!hasPermission) return;

            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => PdfDocView()));
          },
          child: Text("Open"),
        ),
      ),
    );

    // ignore: dead_code
    return Scaffold(
      body: [
        FilesView(),
        RecentsView(),
        FavouritesView(),
      ][currentViewIndex],
      bottomNavigationBar: _buildNavigationBar(),
    );
  }

  NavigationBar _buildNavigationBar() {
    const selectedNavButtonColor = Colors.black;

    return NavigationBar(
      selectedIndex: currentViewIndex,
      onDestinationSelected: (int index) {
        setState(() {
          currentViewIndex = index;
        });
      },
      destinations: [
        NavigationDestination(
          icon: Icon(Icons.folder_open),
          selectedIcon: Icon(Icons.folder, color: selectedNavButtonColor),
          label: "Files",
        ),
        NavigationDestination(
          icon: Icon(Icons.hourglass_empty),
          selectedIcon:
              Icon(Icons.hourglass_full, color: selectedNavButtonColor),
          label: "Recents",
        ),
        NavigationDestination(
          icon: Icon(Icons.favorite_border),
          selectedIcon: Icon(Icons.favorite, color: selectedNavButtonColor),
          label: "Favourites",
        ),
      ],
    );
  }
}
