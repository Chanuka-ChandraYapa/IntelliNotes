import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../helpers/database_helper.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final String _huggingFaceAPI =
      'https://api-inference.huggingface.co/models/mistralai/Mistral-7B-Instruct-v0.3/v1/chat/completions';

  // Replace with your Hugging Face API token
  final String _apiToken = '**';

  // Store the conversation history for context
  List<Map<String, String>> _conversationHistory = [];

  void load() async {
    final allNotesContent = await DatabaseHelper.instance.getNoteContents();
    print(allNotesContent);
    _sendMessage(
        "You are a restricted assistant bot to help users with their daily note entries. They will ask you anything about their notes, or ask you to summarize, organize, or analyze them. List of notes will be sent. Respond back with an interesting question about the notes. If the list of notes is empty, respond with 'Hmm. No notes yet. How about I give you an idea?'. Notes: $allNotesContent");
    _messages.removeAt(0);
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> _sendMessage(String message) async {
    setState(() {
      _messages.add({'sender': 'user', 'message': message});
      _conversationHistory.add({'role': 'user', 'content': message});
    });

    try {
      final response = await http.post(
        Uri.parse(_huggingFaceAPI),
        headers: {
          'Authorization': 'Bearer $_apiToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'model': 'mistralai/Mistral-7B-Instruct-v0.3',
          'messages': _conversationHistory,
          'max_tokens': 500,
          'stream': false,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Extract the bot's response
        final botResponse =
            data['choices'][0]['message']['content'] ?? 'No response received.';

        setState(() {
          _messages.add({'sender': 'bot', 'message': botResponse});
          _conversationHistory
              .add({'role': 'assistant', 'content': botResponse});
        });
      } else {
        setState(() {
          _messages.add({
            'sender': 'bot',
            'message': 'Error: Unable to get response from the AI.'
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages
            .add({'sender': 'bot', 'message': 'Error: Something went wrong.'});
      });
    }
  }

  Future<void> _sendSingleMessage(String message) async {
    try {
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
                  'Extend the following content according to the context, structure, and style. Content: $message'
            }
          ],
          'max_tokens': 500,
          'stream': false,
        }),
      );

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
      throw Exception('Error: Something went wrong');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat with AI'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUserMessage = message['sender'] == 'user';

                // Access current theme's colors
                final backgroundColor = isUserMessage
                    ? Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[700]
                        : Color.fromARGB(255, 215, 212, 212)
                    : Theme.of(context).brightness == Brightness.dark
                        ? Colors.blueGrey[700]
                        : Colors.blue[100];

                final textColor =
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black;

                return Align(
                  alignment: isUserMessage
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      message['message']!,
                      style: TextStyle(color: textColor),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      hintStyle: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white54
                            : Colors.black54,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.send,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                  onPressed: () {
                    final message = _controller.text.trim();
                    if (message.isNotEmpty) {
                      _sendMessage(message);
                      _controller.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
