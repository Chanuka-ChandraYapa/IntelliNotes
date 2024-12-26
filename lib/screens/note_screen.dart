import 'package:flutter/material.dart';
import 'dart:io';
import '../models/note.dart';
import '../helpers/database_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class NoteScreen extends StatefulWidget {
  final Note? note;

  const NoteScreen({Key? key, this.note}) : super(key: key);

  @override
  _NoteScreenState createState() => _NoteScreenState();
}

class _NoteScreenState extends State<NoteScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isExtending = false;
  File? _selectedImage;

  final String _huggingFaceAPI =
      'https://api-inference.huggingface.co/models/mistralai/Mistral-7B-Instruct-v0.3/v1/chat/completions';

  // Replace with your Hugging Face API token
  final String _apiToken = '**';

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
      if (widget.note!.imagePath != null) {
        _selectedImage = File(widget.note!.imagePath!);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // Future<void> _pickImage() async {
  //   final ImagePicker picker = ImagePicker();
  //   final XFile? image = await picker.pickImage(source: ImageSource.gallery);

  //   if (image != null) {
  //     setState(() {
  //       _selectedImage = File(image.path);
  //     });
  //   }
  // }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedImage = File(result.files.single.path!);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to pick an image.')),
      );
    }
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
      imagePath: _selectedImage?.path,
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

  Future<String> _sendSingleMessage(String message) async {
    try {
      print(message);
      final response = await http.post(
        Uri.parse(_huggingFaceAPI),
        headers: {
          'Authorization': 'Bearer $_apiToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'model': 'mistralai/Mistral-7B-Instruct-v0.3',
          'messages': [
            {
              'role': 'user',
              'content':
                  'Extend the following content according to the context, structure, and style. Content: $message. Do not repeat what is written in the content. Just add new content. Do not write any other thing except for the content. Shorter the better. If the last sentence in the content is not completed, Complete it'
            }
          ],
          'max_tokens': 500,
          'stream': false,
        }),
      );

      print(response.body);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Extract the bot's response
        final botResponse =
            data['choices'][0]['message']['content'] ?? 'No response received.';

        return botResponse;
      } else {
        throw Exception('Failed to extend note');
      }
    } catch (e) {
      throw Exception('Something went wrong $e');
    }
  }

  Future<void> _extendNoteContent() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Content cannot be empty for extension')),
      );
      return;
    }

    setState(() {
      _isExtending = true;
    });

    try {
      final extendedContent = await _sendSingleMessage(content);
      setState(() {
        _contentController.text = "$content $extendedContent";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note content extended successfully')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${error.toString()}')),
      );
    } finally {
      setState(() {
        _isExtending = false;
      });
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
            if (_selectedImage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Image.file(
                  _selectedImage!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(labelText: 'Content'),
              maxLines: 5,
              keyboardType: TextInputType.multiline,
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'extend',
            onPressed: _isExtending ? null : _extendNoteContent,
            child: _isExtending
                ? const CircularProgressIndicator(
                    color: Colors.white,
                  )
                : const Icon(Icons.auto_fix_high),
            tooltip: 'Extend Content',
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'addImage',
            onPressed: _pickImage,
            child: const Icon(Icons.add_photo_alternate),
            tooltip: 'Add Image',
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'save',
            onPressed: _saveNote,
            child: const Icon(Icons.save),
          ),
        ],
      ),
    );
  }
}
