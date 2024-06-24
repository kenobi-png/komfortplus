import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:komfortik/components/my_button.dart';
import 'package:komfortik/components/my_textfield.dart';
import 'package:komfortik/components/square_tile.dart';
import 'package:komfortik/main.dart';
import 'package:komfortik/pages/noauth/login_page.dart';
import 'package:komfortik/pages/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _auth = AuthService();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmpassword = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    _email.dispose();
    _password.dispose();
    _confirmpassword.dispose();
  }

  // ошибка входа уведомление пользователя
  void showErrorMessage(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Color.fromARGB(255, 7, 199, 180),
          title: Center(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 7, 199, 180),
        title: const Text('Регистрация'),
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(Icons.arrow_back),
        ),
      ),
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 0),
                const Icon(
                  Icons.lock,
                  size: 100,
                ),
                const SizedBox(height: 10),
                Text(
                  'Добро пожаловать на страницу регистрации!',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),
                MyTextField(
                  controller: _email,
                  hintText: 'Почта',
                  obscureText: false,
                ),
                const SizedBox(height: 10),
                MyTextField(
                  controller: _password,
                  hintText: 'Пароль',
                  obscureText: true,
                ),
                const SizedBox(height: 10),
                MyTextField(
                  controller: _confirmpassword,
                  hintText: 'Подтвердите пароль',
                  obscureText: true,
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Не помните пароль?',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                MyButton(
                  text: "Зарегистрироваться",
                  onTap: _register,
                ),
                const SizedBox(height: 50),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Divider(
                          thickness: 0.5,
                          color: Colors.grey[400],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Text(
                          'Или авторизуйтесь с помощью',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          thickness: 0.5,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SquareTile(
                      onTap: () async {
                        User? user = await _auth.signInWithGoogle();
                        if (user != null) {
                          goToHome(context);
                        } else {
                          showErrorMessage('Не удалось войти через Google');
                        }
                      },
                      imagePath: 'lib/images/google.png',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  goToLogin(BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );

  goToHome(BuildContext context) => Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => AuthCheck()),
        (route) => false,
      );

  _register() async {
    if (_password.text == _confirmpassword.text) {
      try {
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _email.text,
          password: _password.text,
        );
        User? user = userCredential.user;
        await user?.sendEmailVerification();
        UserModel userData = UserModel(
          uid: user?.uid,
          email: _email.text,
          password: _password.text,
        );

        final prefs = await SharedPreferences.getInstance();
        prefs.setString('userData', jsonEncode(userData.toJson()));

        showErrorMessage(
            "Пожалуйста, подтвердите свою почту, перейдя по ссылке, отправленной на ваш email.");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const EmailVerificationPage()),
        );
      } on FirebaseAuthException catch (e) {
        showErrorMessage(e.message!);
      }
    } else {
      showErrorMessage("Пароли не совпадают.");
    }
  }
}

class EmailVerificationPage extends StatelessWidget {
  const EmailVerificationPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 7, 199, 180),
        title: const Text('Подтверждение почты'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Пожалуйста, подтвердите свою почту. Проверьте вашу почту и перейдите по ссылке для подтверждения.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                User? user = FirebaseAuth.instance.currentUser;
                await user?.reload();
                if (user != null && user.emailVerified) {
                  UserModel userData = UserModel(
                    uid: user.uid,
                    email: user.email,
                    password: '', // пароль не сохраняется в целях безопасности
                  );
                  final prefs = await SharedPreferences.getInstance();
                  prefs.setString('userData', jsonEncode(userData.toJson()));
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyApp(isLoggedIn: true),
                    ),
                  );
                } else {
                  showErrorMessage(context,
                      "Почта еще не подтверждена. Пожалуйста, проверьте вашу почту.");
                }
              },
              child: const Text('Я подтвердил почту'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                User? user = FirebaseAuth.instance.currentUser;
                await user?.sendEmailVerification();
                showErrorMessage(
                    context, "Письмо с подтверждением отправлено повторно.");
              },
              child: const Text('Отправить письмо еще раз'),
            ),
          ],
        ),
      ),
    );
  }

  void showErrorMessage(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Color.fromARGB(255, 7, 199, 180),
          title: Center(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      },
    );
  }
}
