import 'package:deltapdf/dto/item_type.dart';
import 'package:flutter/material.dart';

class GridCatalogueItem extends StatelessWidget {
  final ItemType itemType;

  const GridCatalogueItem({super.key, required this.itemType});

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
            //Icons.folder,
            //Icons.article,
            itemType == ItemType.Folder ? Icons.folder : Icons.article,
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
