import 'package:deltapdf/dto/item_kind.dart';
import 'package:deltapdf/datastore/directory_item.dart';
import 'package:flutter/material.dart';

class GridDirectoryView extends StatelessWidget {
  final List<DirectoryItem> items;

  final void Function(DirectoryItem item) onItemTapped;

  const GridDirectoryView({
    super.key,
    required this.items,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return SliverGrid.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        childAspectRatio: 1,
        crossAxisCount: 2,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: () {
            //print("Tapped ${item.id}");
            onItemTapped(item);
          },
          child: GridDirectoryItem(
            item: item,
          ),
        );
      },
      itemCount: items.length,
    );
  }
}

class GridDirectoryItem extends StatelessWidget {
  final DirectoryItem item;

  const GridDirectoryItem({super.key, required this.item});

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
            item.kind == DirectoryItemKind.Folder
                ? Icons.folder
                : Icons.article,
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
                  child: Text(
                    item.name,
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


/*
return SliverGrid(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    childAspectRatio: 1,
    crossAxisCount: 2,
  ),
  delegate: SliverChildBuilderDelegate(
    (context, index) {
      return GridDirectoryItem(
        itemType: DirectoryItemKind.Folder,
      );
    },
    childCount: items.length,
  ),
);
*/
