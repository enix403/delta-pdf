import 'package:flutter/material.dart';

class SortControls extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
}
