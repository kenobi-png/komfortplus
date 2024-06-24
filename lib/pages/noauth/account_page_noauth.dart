import 'package:flutter/material.dart';
import 'package:komfortik/pages/noauth/login_page.dart';
import 'package:komfortik/pages/noauth/register_page.dart';
import 'package:komfortik/pages/services/privacy_policy.dart';

class AuthPageNonAuth extends StatefulWidget {
  const AuthPageNonAuth({Key? key});

  @override
  _AuthPageNonAuthState createState() => _AuthPageNonAuthState();
}

class _AuthPageNonAuthState extends State<AuthPageNonAuth> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 7, 199, 180),
        title: const Text('Авторизация'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset('lib/images/register.png', height: 90.0, width: 90.0),
            SizedBox(height: 20.0),
            Text(
              'Войдите в свой профиль',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20.0),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'После входа вам будет доступно',
                  style: TextStyle(
                    fontSize: 18.0,
                  ),
                ),
                Text(
                  'оформление заказа',
                  style: TextStyle(
                    fontSize: 18.0,
                  ),
                ),
              ],
            ),
            SizedBox(height: 40.0),
            ElevatedButton(
              onPressed: () {
                goToLogin(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 7, 199, 180),
                padding: EdgeInsets.symmetric(horizontal: 90.0, vertical: 15.0),
              ),
              child: DefaultTextStyle(
                style: TextStyle(color: Colors.white),
                child: Text(
                  'Войти в профиль',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22.0,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20.0),
            GestureDetector(
              onTap: () {
                goToPrivacyPolicy(context);
              },
              child: Text(
                'Политика конфиденциальности',
                style: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                  fontSize: 16.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void goToLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  void goToRegister(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterPage()),
    );
  }

  void goToPrivacyPolicy(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              PrivacyPolicyPage()), // Используем страницу политики конфиденциальности
    );
  }
}
