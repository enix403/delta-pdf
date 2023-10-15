import 'package:deltapdf/dto/item_kind.dart';
import 'package:flutter/material.dart';

class GridDirectoryView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        childAspectRatio: 1,
        crossAxisCount: 2,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          //return GridDirectoryItem(
            //itemType: DirectoryItemKind.Folder,
          //);
          return null;
        },
        //childCount: 30,
      ),
    );
  }
}

/*
class GridDirectoryItem extends StatelessWidget {
  final DirectoryItemKind itemType;

  const GridDirectoryItem({super.key, required this.itemType});

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
            itemType == DirectoryItemKind.Folder ? Icons.folder : Icons.article,
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
*/
