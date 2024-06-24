import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:komfortik/pages/services/contacts_page.dart';
import 'package:komfortik/pages/services/privacy_policy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'account_secur.dart';
import 'acc_orders_page.dart';

class sec_acc_page extends StatefulWidget {
  const sec_acc_page({Key? key}) : super(key: key);

  @override
  _sec_acc_pageState createState() => _sec_acc_pageState();
}

class _sec_acc_pageState extends State<sec_acc_page> {
  String token = '';
  String email = '';
  String firstname = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('tokenKey') ??
          ''; // Replace 'tokenKey' with your actual token key
      email = prefs.getString('email') ??
          ''; // Replace 'email' with your actual email key
      final userData = prefs.getString('userData');
      if (userData != null) {
        final Map<String, dynamic> userMap = jsonDecode(userData);
        firstname = userMap['firstname'] ?? '';
      } else {
        firstname = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Аккаунт'),
        automaticallyImplyLeading: false,
        backgroundColor: const Color.fromARGB(255, 7, 199, 180),
        /*actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              onPressed: () {},
              icon: Icon(Icons.notifications),
            ),
          ),
        ],*/
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: <Widget>[
                  /*GestureDetector(
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: ShapeDecoration(
                        image: DecorationImage(
                          image:
                              NetworkImage("https://via.placeholder.com/96x96"),
                          fit: BoxFit.fill,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ),
                  ),*/
                  SizedBox(width: 8.0),
                  GestureDetector(
                    onTap: () async {
                      if (firstname.isNotEmpty) {
                        bool? result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AccountSecur()),
                        );
                        if (result == true) {
                          _loadUserData();
                        }
                      }
                    },
                    child: Text(
                      'Привет, ${firstname.isEmpty ? 'незнакомец' : firstname}!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.0),
              _buildClickableCard('Настройки аккаунта', () async {
                bool? result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AccountSecur()),
                );
                if (result == true) {
                  _loadUserData();
                }
              }),
              SizedBox(height: 16.0),
              _buildClickableCard('Доставки', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          OrdersPage(token: token, email: email)),
                );
              }),
              SizedBox(height: 16.0),
              _buildClickableCard('Контакты', () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => ContactsPage()));
              }),
              SizedBox(height: 16.0),
              _buildClickableCard('Политика конфиденциальности', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PrivacyPolicyPage()),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClickableCard(String title, VoidCallback onTap) {
    return Card(
      child: ListTile(
        title: Text(title),
        onTap: onTap,
      ),
    );
  }
}
