import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:komfortik/cart_page.dart';
import 'package:komfortik/connectivity_checker.dart';
import 'package:komfortik/pages/auth/account_page.dart';
import 'package:komfortik/pages/noauth/account_page_noauth.dart';
import 'package:komfortik/pages/services/splashscreen.dart';
import 'firebase_options.dart';
import 'package:komfortik/pages/main_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyAppStarter());
}

class MyAppStarter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Климат Комфорт',
      theme: ThemeData(
        primaryColor: const Color.fromARGB(255, 7, 199, 180),
        hintColor: const Color.fromARGB(255, 7, 199, 180),
        scaffoldBackgroundColor: const Color.fromARGB(255, 235, 235, 235),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 7, 199, 180),
        ),
      ),
      home: SplashScreen(),
    );
  }
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Климат Комфорт',
      theme: ThemeData(
        primaryColor: const Color.fromARGB(255, 7, 199, 180),
        hintColor: const Color.fromARGB(255, 7, 199, 180),
        scaffoldBackgroundColor: const Color.fromARGB(255, 235, 235, 235),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 7, 199, 180),
        ),
      ),
      home: ConnectivityChecker(
        child: MainScreen(isLoggedIn: isLoggedIn),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final bool isLoggedIn;

  const MainScreen({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late PageController _pageController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: widget.isLoggedIn
            ? [
                const MainPage(),
                const CartPage(),
                const sec_acc_page(),
              ]
            : [
                const MainPage(),
                const CartPage(),
                const AuthPageNonAuth(),
              ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Главная',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Корзина',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Аккаунт',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color.fromARGB(255, 7, 199, 180),
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.ease,
            );
          });
        },
      ),
    );
  }
}

class UserModel {
  String? uid;
  String? email;
  String? password;

  UserModel({this.uid, this.email, this.password});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'],
      email: json['email'],
      password: json['password'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'password': password,
    };
  }
}

class AuthCheck extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          return MyApp(isLoggedIn: true);
        } else {
          return MyApp(isLoggedIn: false);
        }
      },
    );
  }
}
