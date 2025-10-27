import 'package:flutter/material.dart';
import '../api_service.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  final ApiService api;
  const RegisterPage({super.key, required this.api});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String message = '';

  void _register() async {
    setState(() {
      message = 'Loading...';
    });

    try {
      await widget.api.register(
        usernameController.text,
        emailController.text,
        passwordController.text,
      );

      setState(() {
        message = 'Registration successful!';
      });

      // После успешной регистрации можно редиректить на LoginPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginPage(api: widget.api)),
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
      appBar: AppBar(title: Text('Register')),
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
                controller: emailController,
                decoration: InputDecoration(labelText: 'Email'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              SizedBox(height: 20),
              ElevatedButton(onPressed: _register, child: Text('Register')),
              SizedBox(height: 20),
              Text(message),
            ],
          ),
        ),
      ),
    );
  }
}
