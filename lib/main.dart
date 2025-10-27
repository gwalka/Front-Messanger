import 'package:flutter/material.dart';
import '../screens/login_page.dart';
import 'api_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final ApiService api = ApiService();

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Web Auth Test',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginPage(api: api), // стартовый экран — login
    );
  }
}
