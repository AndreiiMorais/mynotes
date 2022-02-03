import 'package:flutter/material.dart';

class NewNotesView extends StatefulWidget {
  const NewNotesView({Key? key}) : super(key: key);

  @override
  _NewNotesViewState createState() => _NewNotesViewState();
}

class _NewNotesViewState extends State<NewNotesView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Note'),
      ),
      body: const Text('Write your new note here...'),
    );
  }
}
