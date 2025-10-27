import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String baseUrl = 'http://localhost:8080';

  Future<Map<String, dynamic>> login(String username, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'login': username, 'password': password}),
    );

    if (res.statusCode == 200) {
      final responseBody = jsonDecode(res.body);

      // ✅ Захватываем токен (предполагается, что он в поле 'token')
      String? token = responseBody['accessToken'];

      if (token != null) {
        // ✅ Сохраняем токен
        await _saveToken(token);
      }

      return responseBody; // ✅ Возвращаем как и раньше
    } else {
      throw Exception('Failed to login: ${res.body}');
    }
  }

  Future<void> register(String userName, String email, String password) async {
    final uri = Uri.parse('$baseUrl/auth/register');
    final body = jsonEncode({
      'userName': userName,
      'email': email,
      'password': password,
    });

    print('📤 Sending registration body: $body');

    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: body,
    );

    print('📥 Response status: ${res.statusCode}');
    print('📨 Response body: ${res.body}');

    if (res.statusCode != 200) {
      throw Exception('Failed to register: ${res.body}');
    }
  }

  // ✅ Приватный метод для сохранения токена
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  // ✅ Публичный метод для получения токена (может понадобиться позже)
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
}