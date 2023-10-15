import 'package:deltapdf/datastore/datastore.dart';
import 'package:flutter/material.dart';

class CreateItemModal extends StatelessWidget {
  //final BuildContext parentContext;
  final void Function(String name)? createFolder;

  const CreateItemModal({
    super.key,
    //required this.parentContext,
    this.createFolder,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton.outlined(
                icon: const Icon(Icons.folder_open),
                onPressed: () {
                  _onCreaterFolderPressed(context);
                },
              ),
              const Text("Folder")
            ],
          ),
          SizedBox(width: 56.0),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton.outlined(
                icon: const Icon(Icons.article),
                onPressed: () {},
              ),
              const Text("File")
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _onCreaterFolderPressed(BuildContext context) async {
    Navigator.pop(context);

    // ignore: unused_local_variable
    final value = await _showFolderNameDialog(context);
    if (value == null) return;

    createFolder?.call(value);
  }

  Future<String?> _showFolderNameDialog(BuildContext context) {
    final textController = TextEditingController();

    return showDialog<String?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Create Folder"),
          content: TextField(
            controller: textController,
            maxLines: 1,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Folder Name',
              isDense: true,
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.pop(context, null);
              },
            ),
            FilledButton(
              child: const Text("Create"),
              onPressed: () {
                Navigator.pop(context, textController.text);
              },
            ),
          ],
        );
      },
    );
  }
}
