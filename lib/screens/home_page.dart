import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'chat_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  List<UserSearchDto> _users = [];
  bool _isLoading = false;

  Future<void> _searchUsers() async {
    if (_searchController.text.isEmpty) {
      setState(() {
        _users = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:8080/home/search?query=${_searchController.text}'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final users = data.map((json) => UserSearchDto.fromJson(json)).toList();
        setState(() {
          _users = users;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ✅ Метод для получения токена
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // ✅ Метод для создания чата
  Future<int?> _createChat(int targetUserId) async {
    String? token = await _getToken(); // ✅ Получаем токен

    if (token == null) {
      print('Токен не найден');
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8080/home/chat?secondUserId=$targetUserId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // ✅ Используем токен
        },
      );

      if (response.statusCode == 200) {
        final chat = json.decode(response.body);
        return chat['id']; // возвращаем chatId
      } else {
        print('Ошибка создания чата: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Ошибка: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Поиск юзера',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _searchUsers,
                ),
              ),
              onSubmitted: (_) => _searchUsers(),
            ),
            SizedBox(height: 16),
            if (_isLoading)
              CircularProgressIndicator()
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return ListTile(
                      title: Text(user.username),
                      subtitle: Text('ID: ${user.id}'),
                      trailing: IconButton(
                        icon: Icon(Icons.message),
                        onPressed: () async { // ✅ async
                          // 1. Создаём чат
                          int? chatId = await _createChat(user.id);

                          if (chatId != null) {
                            // 2. Переходим на ChatPage с chatId
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatPage(
                                  chatId: chatId,
                                  targetUserId: user.id,
                                  targetUsername: user.username,
                                ),
                              ),
                            );
                          } else {
                            // 3. Показываем ошибку
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Не удалось создать чат')),
                            );
                          }
                        },
                      ),
                      onTap: () {
                        print('Выбран юзер: ${user.username}, ID: ${user.id}');
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class UserSearchDto {
  final int id;
  final String username;

  UserSearchDto({required this.id, required this.username});

  factory UserSearchDto.fromJson(Map<String, dynamic> json) {
    return UserSearchDto(
      id: json['id'],
      username: json['username'],
    );
  }
}
