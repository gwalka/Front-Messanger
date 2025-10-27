import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

class ChatPage extends StatefulWidget {
  final int chatId;
  final int targetUserId;
  final String targetUsername;

  const ChatPage({
    super.key,
    required this.chatId,
    required this.targetUserId,
    required this.targetUsername,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late StompClient _stompClient;
  String? _authToken;
  int? _myUserId;
  final List<Message> _messages = [];
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _connectStomp();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  int? _extractUserIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final normalized = payload.replaceAll('-', '+').replaceAll('_', '/');
      final pad = (4 - normalized.length % 4) % 4;
      final padded = normalized + '=' * pad;

      final json = utf8.decode(base64.decode(padded));
      final map = jsonDecode(json) as Map<String, dynamic>;
      return map['userId'] as int?;
    } catch (e) {
      print('Ошибка парсинга токена: $e');
      return null;
    }
  }

  void _connectStomp() async {
    String? token = await _getToken();
    if (token == null) {
      print('Токен не найден');
      return;
    }
    _authToken = token;
    _myUserId = _extractUserIdFromToken(token);

    if (_myUserId == null) {
      print('Не удалось извлечь userId из токена');
      return;
    }

    _stompClient = StompClient(
      config: StompConfig(
        url: 'ws://localhost:8080/ws',
        webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        onConnect: (StompFrame frame) {
          print('STOMP подключён успешно');
          _stompClient.subscribe(
            destination: '/topic/chat/${widget.chatId}',
            callback: (StompFrame frame) {
              try {
                final data = json.decode(frame.body!);
                setState(() {
                  _messages.add(
                    Message(
                      content: data['content'],
                      senderId: data['senderId'],
                      timestamp: DateTime.now(),
                    ),
                  );
                });
              } catch (e) {
                print('Ошибка разбора входящего сообщения: $e');
                print('Получено тело: ${frame.body}');
              }
            },
          );
        },
        onWebSocketError: (error) => print('WebSocket ошибка: $error'),
        onStompError: (StompFrame frame) => print('STOMP ошибка: ${frame.body}'),
        onDisconnect: (StompFrame? frame) => print('STOMP отключён'),
      ),
    );

    _stompClient.activate();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty || _authToken == null) return;

    final payload = json.encode({
      'content': text,
      'token': _authToken,
    });

    _stompClient.send(
      destination: '/app/chat/${widget.chatId}/sendMessage',
      body: payload,
    );

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with ${widget.targetUsername}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMine = msg.senderId == _myUserId;

                return Align(
                  alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isMine ? Colors.blue : Colors.grey[300],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg.content,
                          style: TextStyle(
                            color: isMine ? Colors.white : Colors.black,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('HH:mm:ss').format(msg.timestamp),
                          style: TextStyle(
                            fontSize: 11,
                            color: isMine ? Colors.blueAccent[100] : Colors.grey[600],
                          ),
                        ),
                      ],
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
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _stompClient.deactivate();
    _messageController.dispose();
    super.dispose();
  }
}

class Message {
  final String content;
  final int senderId;
  final DateTime timestamp;

  Message({
    required this.content,
    required this.senderId,
    required this.timestamp,
  });
}