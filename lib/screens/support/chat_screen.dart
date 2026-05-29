import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/ai_service.dart';
import '../../theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [
    {"role": "assistant", "content": "Hello! I'm AuraBot. 🤖\nHow can I help you navigate Auracity today?"}
  ];
  bool _isTyping = false;

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "content": text});
      _controller.clear();
      _isTyping = true;
    });
    _scrollToBottom();

    final response = await AiService.getChatSupportResponse(_messages);

    if (mounted) {
      setState(() {
        _messages.add({"role": "assistant", "content": response});
        _isTyping = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              AppTheme.primaryBlue.withOpacity(0.05),
              AppTheme.accentCyan.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isBot = msg['role'] == 'assistant';
                  return _buildMessageBubble(msg['content']!, isBot);
                },
              ),
            ),
            if (_isTyping) _buildTypingIndicator(),
            _buildQuickActions(),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, bottom: 20, left: 20, right: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppTheme.primaryBlue, AppTheme.accentCyan]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AuraBot', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.priorityGreen, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('Online Concierge', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textLight, fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isBot) {
    return Align(
      alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isBot ? Colors.white : AppTheme.primaryBlue,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isBot ? 4 : 20),
            bottomRight: Radius.circular(isBot ? 20 : 4),
          ),
          boxShadow: [
            BoxShadow(
              color: (isBot ? Colors.black : AppTheme.primaryBlue).withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            color: isBot ? AppTheme.textDark : Colors.white,
            fontSize: 14,
            height: 1.5,
            fontWeight: isBot ? FontWeight.w500 : FontWeight.w600,
          ),
        ),
      ).animate().fadeIn(duration: 400.ms).slideX(begin: isBot ? -0.1 : 0.1, end: 0, curve: Curves.easeOutCubic),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 24, bottom: 16),
      child: Row(
        children: [
          Text('AuraBot is thinking', style: TextStyle(fontSize: 12, color: AppTheme.textLight.withOpacity(0.7))),
          const SizedBox(width: 8),
          const SizedBox(
            width: 12, height: 12,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryBlue),
          ),
        ],
      ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms),
    );
  }

  Widget _buildQuickActions() {
    final actions = ["💰 How to earn?", "📏 What is Credibility?", "🏙️ Treasury info", "📝 How to report?"];
    return SizedBox(
      height: 50,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ActionChip(
              label: Text(actions[index]),
              backgroundColor: Colors.white,
              side: BorderSide(color: AppTheme.primaryBlue.withOpacity(0.1)),
              labelStyle: GoogleFonts.inter(color: AppTheme.primaryBlue, fontSize: 12, fontWeight: FontWeight.bold),
              onPressed: () {
                _controller.text = actions[index];
                _sendMessage();
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _controller,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Ask AuraBot something...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: AppTheme.textLight),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: AppTheme.primaryBlue, shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
