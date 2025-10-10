// lib/models/chat_message.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum ChatSender { user, assistant }

class ChatMessage {
  final ChatSender sender;
  final String text;
  final DateTime at;

  const ChatMessage({
    required this.sender,
    required this.text,
    required this.at,
  });

  String get role => sender == ChatSender.user ? 'user' : 'assistant';

  Map<String, dynamic> toFirestore() => {
    'role': role,
    'text': text,
    'at': Timestamp.fromDate(at),
  };

  factory ChatMessage.fromFirestore(Map<String, dynamic> data) {
    final role = (data['role'] as String? ?? 'assistant').toLowerCase();
    final ts = data['at'];
    DateTime at;
    if (ts is Timestamp) {
      at = ts.toDate();
    } else if (ts is DateTime) {
      at = ts;
    } else {
      at = DateTime.now();
    }
    return ChatMessage(
      sender: role == 'user' ? ChatSender.user : ChatSender.assistant,
      text: (data['text'] as String? ?? '').trim(),
      at: at,
    );
  }
}
