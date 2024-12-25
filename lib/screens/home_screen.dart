import 'package:flutter/material.dart';
import '../models/note.dart';
import '../helpers/database_helper.dart';
import '../screens/note_screen.dart';
import '../screens/chat_screen.dart'; // Import Chat Screen
import 'package:intl/intl.dart'; // Add intl package for date formatting.
import 'note_view_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Note>> _notes;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  void _loadNotes() {
    _notes = DatabaseHelper.instance.getNotes();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return DateFormat('hh:mm a').format(date);
    } else {
      return DateFormat('MMM dd').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ChatScreen()), // Navigate to Chat Screen
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Note>>(
        future: _notes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final note = snapshot.data![index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: ListTile(
                    title: Text(
                      note.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        note.content.length > 50
                            ? '${note.content.substring(0, 50)}...'
                            : note.content,
                      ),
                    ),
                    trailing: Text(
                      _formatDate(note.date),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NoteViewScreen(note: note),
                      ),
                    ).then((_) => setState(() => _loadNotes())),
                  ),
                );
              },
            );
          } else {
            return const Center(child: Text('No notes available.'));
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NoteScreen()),
        ).then((_) => setState(() => _loadNotes())),
        child: const Icon(Icons.add),
      ),
    );
  }
}
