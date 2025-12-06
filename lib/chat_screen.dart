import 'package:flutter/material.dart';
import 'constants.dart'; // You'll need this for your app's colors

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();

  void _handleSendPressed() {
    if (_textController.text.isNotEmpty) {
      // TODO: Add logic to send message to your AI
      print("User message: ${_textController.text}");
      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Care Giver"),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Constants.darkblue), // Back button color
        titleTextStyle: TextStyle(
          color: Constants.darkGrey,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Column(
        children: [
          // 1. CHAT MESSAGE LIST
          Expanded(
            child: ListView.builder(
              itemCount: 0, // We will add messages here later
              itemBuilder: (context, index) {
                // This will be your chat bubble widget
                return Text("Chat message");
              },
            ),
          ),

          // 2. TEXT INPUT FIELD
          _buildChatInputField(),
        ],
      ),
    );
  }

  // This widget builds the text input bar at the bottom
  Widget _buildChatInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: "Type your message...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 10.0,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            IconButton(
              icon: Icon(Icons.send, color: Constants.darkblue),
              onPressed: _handleSendPressed,
            ),
          ],
        ),
      ),
    );
  }
}