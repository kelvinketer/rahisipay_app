import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Added for network calls
import 'dart:convert'; // Added for JSON encoding/decoding

class FarmAdvisorScreen extends StatefulWidget {
  final String farmerPhone;

  const FarmAdvisorScreen({super.key, required this.farmerPhone});

  @override
  State<FarmAdvisorScreen> createState() => _FarmAdvisorScreenState();
}

class _FarmAdvisorScreenState extends State<FarmAdvisorScreen> {
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // The initial greeting from the AI when the farmer opens the screen
    _messages.add({
      "isUser": false,
      "text": "Hello! I am your Oletai Farm Advisor. I see you are farming in Kiambu County. The weather in Juja is expected to be dry this week. How can I help you maximize your yield today?"
    });
  }

  void _sendMessage() async {
    if (_chatController.text.trim().isEmpty) return;

    String userText = _chatController.text.trim();
    
    setState(() {
      _messages.add({"isUser": true, "text": userText});
      _chatController.clear();
      _isTyping = true;
    });

    try {
      // THE LIVE CONNECTION TO YOUR GEMINI-POWERED BACKEND
      final response = await http.post(
        Uri.parse('https://rahisipay-api.onrender.com/api/v1/advisor/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "farmer_phone": widget.farmerPhone,
          "message": userText
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String aiReply = data['reply'];
        
        if (mounted) {
          setState(() {
            _isTyping = false;
            _messages.add({"isUser": false, "text": aiReply});
          });
        }
      } else {
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add({"isUser": false, "text": "Network error. The Oletai AI servers are currently syncing. Please try again."});
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF144D2F),
        title: const Row(
          children: [
            Icon(Icons.psychology, color: Colors.lightGreenAccent),
            SizedBox(width: 10),
            Text("Oletai AI Agronomist", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 1,
      ),
      body: Column(
        children: [
          // Chat Messages Area
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['isUser'];
                return _buildChatBubble(msg['text'], isUser);
              },
            ),
          ),
          
          // Typing Indicator
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.only(left: 24, bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Oletai AI is analyzing...", style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontStyle: FontStyle.italic)),
              ),
            ),

          // Input Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _chatController,
                        decoration: const InputDecoration(
                          hintText: "Ask about crops, weather, or soil...",
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                        maxLines: null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _isTyping ? null : _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        color: Color(0xFF144D2F),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF144D2F) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 20),
          ),
          boxShadow: [
            if (!isUser) BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
          ]
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}