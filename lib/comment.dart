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
        apiKey: geminikey,
      );
      session = model?.startChat();

      await _sendToGemini(
          "You are Forge Bot, the AI assistant inside this app that gives users analytics of their clients and feedback. Keep responses focused and clear.");

      setState(() => _isInitialized = true);

      if (widget.initialComment.isNotEmpty) {
        setState(() {
          _messages.add(ChatMessage(message: widget.initialComment, isGemini: false));
        });

        setState(() {
          _isLoadingResponse = true;
        });

        try {
          final geminiResponse = await _sendToGemini(widget.initialComment);
          setState(() => _messages.add(ChatMessage(message: geminiResponse, isGemini: true)));
        } catch (e) {
          debugPrint('Error sending initial comment: $e');
          if (mounted) {
            _showErrorSnackbar('Failed to send initial comment. Please try again.');
          }
        } finally {
          setState(() => _isLoadingResponse = false);
        }
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

  Future<String> _sendToGemini(String message) async {
    if (session == null) {
      return "AI service is not yet initialized.";
    }

    try {
      final response = await session!.sendMessage(Content.text(message));
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
          title: const Text('AI Powered Chat', style: TextStyle(color: Color(0xFFFF8700))),
        ),
        body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Flexible(child: _buildMessageList()),
              if (_isLoadingResponse) _buildLoadingIndicator(),
              _buildMessageInput(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return const Center(child: Text('No messages yet. Start the conversation!'));
    }

    return ListView.builder(
      reverse: true,
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[_messages.length - 1 - index];
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: message.isGemini ? MainAxisAlignment.start : MainAxisAlignment.end,
          children: [
            if (message.isGemini) _buildBotAvatar(),
            _buildMessageBubble(message),
            if (!message.isGemini) _buildUserAvatar(),
          ],
        );
      },
    );
  }

  Widget _buildUserAvatar() {
  return const Padding(
    padding: EdgeInsets.only(right: 8.0, top: 4.0), // Added padding to right and top
    child: CircleAvatar(
      radius: 20,
      backgroundColor: Colors.blueAccent,
      child: Icon(Icons.person, color: Colors.white, size: 20),
    ),
  );
}

  Widget _buildBotAvatar() {
  return Padding(
    padding: const EdgeInsets.only(left: 8.0, top: 10.0),
    child: CircleAvatar(
      radius: 22,
      backgroundColor: const Color(0xFFFF8700).withOpacity(0.2),
      child: const CircleAvatar(
        radius: 20,
        backgroundImage: AssetImage('assets/images/forgebot.png'), // Using the 'forgebot' image
        backgroundColor: Colors.transparent,
      ),
    ),
  );
}


  Widget _buildMessageBubble(ChatMessage message) {
    return Flexible(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: message.isGemini ? const Color(0xFFFF8700).withOpacity(0.2) : Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: message.isGemini ? Radius.zero : const Radius.circular(12),
            bottomRight: message.isGemini ? const Radius.circular(12) : Radius.zero,
          ),
        ),
        child: Column(
          crossAxisAlignment: message.isGemini ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Text(
              message.isGemini ? 'Forge Bot' : 'You',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: message.isGemini ? const Color.fromARGB(255, 196, 88, 0) : Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message.message,
              style: const TextStyle(color: Colors.black),
            ),
          ],
        ),
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
      padding: const EdgeInsets.all(10.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              enabled: _isInitialized && !_isLoadingResponse,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: _isInitialized ? 'Type your message...' : 'Initializing AI...',
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
                : const Icon(Icons.send, color: Color(0xFFFF8700)),
            onPressed: _isInitialized && !_isLoadingResponse ? _sendMessage : null,
          ),
        ],
      ),
    );
  }
}
