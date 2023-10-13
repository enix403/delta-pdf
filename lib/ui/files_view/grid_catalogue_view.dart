import 'package:deltapdf/dto/item_type.dart';
import 'package:flutter/material.dart';

import './grid_catalogue_item.dart';

class GridCatalogueView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        childAspectRatio: 1,
        crossAxisCount: 2,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return GridCatalogueItem(
            itemType: ItemType.Folder,
          );
        },
        childCount: 30,
      ),
    );
  }
}
