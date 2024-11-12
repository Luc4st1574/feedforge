// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatMessage {
  final String message;
  final bool isGemini;

  ChatMessage({required this.message, required this.isGemini});
}

class CommentScreen extends StatefulWidget {
  final String initialComment;
  final String commentId;

  const CommentScreen({super.key, required this.initialComment, required this.commentId});

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final TextEditingController _messageController = TextEditingController();
  GenerativeModel? model;
  ChatSession? session;
  bool _isInitialized = false;
  bool _isLoadingResponse = false;
  
  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _initializeGemini();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _initializeGemini() async {
    final geminikey = dotenv.env['GEMINI_KEY'];
    if (geminikey == null) {
      throw Exception('GEMINI_KEY is not set in the environment variables');
    }
    try {
      model = GenerativeModel(
        model: "gemini-pro",
        apiKey: geminikey, // Replace with your actual API key
      );
      session = model?.startChat();

      setState(() => _isInitialized = true);

      if (widget.initialComment.isNotEmpty) {
        await _sendToGemini(widget.initialComment, initialMessage: true);
      }
    } catch (e) {
      debugPrint('Error initializing Gemini: $e');
      if (mounted) {
        _showErrorSnackbar('Failed to initialize AI. Some features may be limited.');
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty || _isLoadingResponse) return;

    final messageText = _messageController.text;
    _messageController.clear();

    setState(() {
      _isLoadingResponse = true;
      _messages.add(ChatMessage(message: messageText, isGemini: false));
    });

    try {
      final geminiResponse = await _sendToGemini(messageText);
      setState(() => _messages.add(ChatMessage(message: geminiResponse, isGemini: true)));
    } catch (e) {
      debugPrint('Error sending message: $e');
      if (mounted) {
        _showErrorSnackbar('Failed to send message. Please try again.');
      }
    } finally {
      setState(() => _isLoadingResponse = false);
    }
  }

  Future<String> _sendToGemini(String message, {bool initialMessage = false}) async {
    if (session == null) {
      return "AI service is not yet initialized.";
    }

    try {
      final prompt = initialMessage 
          ? "Initial comment: $message" 
          : "Initial comment: ${widget.initialComment}\nUser message: $message";
      final response = await session!.sendMessage(Content.text(prompt));
      return response.text ?? "Error: No response text.";
    } catch (e) {
      debugPrint('Error sending message to Gemini: $e');
      return "Error: Could not generate a response.";
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF708291),
        appBar: AppBar(
          backgroundColor: const Color(0xFF708291),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('AI Powered Chat', style: TextStyle(color: Colors.white)),
        ),
        body: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              _buildInitialComment(),
              const Divider(),
              _buildMessageList(),
              if (_isLoadingResponse) _buildLoadingIndicator(),
              _buildMessageInput(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInitialComment() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          widget.initialComment,
          style: const TextStyle(fontSize: 16, color: Colors.black),
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return Expanded(
      child: _messages.isEmpty
          ? const Center(child: Text('No messages yet. Start the conversation!'))
          : ListView.builder(
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[_messages.length - 1 - index];
                return ListTile(
                  title: Text(
                    message.isGemini ? 'Gemini' : 'You',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: message.isGemini ? Colors.blue : Colors.black,
                    ),
                  ),
                  subtitle: Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: message.isGemini 
                          ? Colors.blue.withOpacity(0.2) 
                          : Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      message.message,
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(8.0),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildMessageInput() {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: _messageController,
            enabled: _isInitialized && !_isLoadingResponse,
            style: const TextStyle(color: Colors.black), // Set text color to black
            decoration: InputDecoration(
              hintText: _isInitialized 
                  ? 'Type your message...'
                  : 'Initializing AI...',
              hintStyle: const TextStyle(color: Colors.black),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Colors.blue),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: _isLoadingResponse
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send, color: Colors.blue),
          onPressed: _isInitialized && !_isLoadingResponse 
              ? _sendMessage 
              : null,
        ),
      ],
    ),
  );
  }
}
