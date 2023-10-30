import 'package:flutter/material.dart';

class LabelledSpinner extends StatelessWidget {
  final String label;

  const LabelledSpinner(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Center(child: CircularProgressIndicator()),
          SizedBox(
            height: 16,
          ),
          Text(label),
        ],
      ),
    );
  }
}
