import 'package:flutter/material.dart';
import '../models/note.dart';
import '../helpers/database_helper.dart';

class NoteScreen extends StatefulWidget {
  final Note? note;

  const NoteScreen({Key? key, this.note}) : super(key: key);

  @override
  _NoteScreenState createState() => _NoteScreenState();
}

class _NoteScreenState extends State<NoteScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and Content cannot be empty')),
      );
      return;
    }

    final note = Note(
      id: widget.note?.id,
      title: title,
      content: content,
      date: DateTime.now(),
    );

    if (widget.note == null) {
      await DatabaseHelper.instance.insert(note);
    } else {
      await DatabaseHelper.instance.update(note);
      Navigator.pop(context);
    }

    Navigator.pop(context);
  }

  Future<void> _deleteNote() async {
    if (widget.note != null) {
      await DatabaseHelper.instance.delete(widget.note!.id!);
      Navigator.pop(context);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'New Note' : 'Edit Note'),
        actions: [
          if (widget.note != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteNote,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(labelText: 'Content'),
              maxLines: 10,
              keyboardType: TextInputType.multiline,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveNote,
        child: const Icon(Icons.save),
      ),
    );
  }
}
