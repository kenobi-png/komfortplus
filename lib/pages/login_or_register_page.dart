import 'package:flutter/material.dart';
import 'package:komfortik/pages/noauth/login_page.dart';
import 'package:komfortik/pages/noauth/register_page.dart';

class LoginOrRegisterPage extends StatefulWidget {
  const LoginOrRegisterPage({super.key});

  @override
  State<LoginOrRegisterPage> createState() => _LoginOrRegisterPageState();
}

class _LoginOrRegisterPageState extends State<LoginOrRegisterPage> {
  bool showLoginPage = true;

  void togglePage() {
    setState(() {
      showLoginPage = !showLoginPage;
      print("showLoginPage: $showLoginPage"); // Отладочный вывод
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLoginPage) {
      return LoginPage(
          //  onTap: togglePage,
          );
    } else {
      return RegisterPage(
          //  onTap: togglePage,
          );
    }
  }
}
