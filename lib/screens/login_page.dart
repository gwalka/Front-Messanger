import 'package:flutter/material.dart';
import '../api_service.dart';
import 'register_page.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  final ApiService api;
  const LoginPage({super.key, required this.api});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String message = '';

  void _login() async {
    setState(() {
      message = 'Loading...';
    });

    try {
      final response = await widget.api.login(
        usernameController.text,
        passwordController.text,
      );

      setState(() {
        message = 'Login successful!';
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage()),
      );

    } catch (e) {
      setState(() {
        message = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Center(
        child: Container(
          width: 400,
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: InputDecoration(labelText: 'Username'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              SizedBox(height: 20),
              ElevatedButton(onPressed: _login, child: Text('Login')),
              SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RegisterPage(api: widget.api),
                    ),
                  );
                },
                child: Text('Зарегистрироваться'),
              ),
              SizedBox(height: 20),
              Text(message),
            ],
          ),
        ),
      ),
    );
  }
}
