import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:komfortik/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountSecur extends StatefulWidget {
  final bool showDrawer;

  const AccountSecur({Key? key, this.showDrawer = false}) : super(key: key);

  @override
  _AccountSecurState createState() => _AccountSecurState();
}

class Adress {
  final String firstname;
  final String lastname;
  final String address_1;
  final String? country_id;
  final String? zone_id;
  final String city;
  final String email;
  final String telephone;

  Adress({
    required this.firstname,
    required this.lastname,
    required this.address_1,
    required this.country_id,
    required this.zone_id,
    required this.city,
    required this.email,
    required this.telephone,
  });

  factory Adress.fromJson(Map<String, dynamic> json) {
    return Adress(
      firstname: json['firstname'] as String,
      lastname: json['lastname'] as String,
      address_1: json['address_1'] as String,
      country_id: json['country_id'] as String?,
      zone_id: json['zone_id'] as String?,
      city: json['city'] as String,
      email: json['email'] as String,
      telephone: json['telephone'] as String,
    );
  }
}

void signUserOut(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  prefs.clear();
  await FirebaseAuth.instance.signOut();
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (context) => AuthCheck()),
    (route) => false,
  );
}

class _AccountSecurState extends State<AccountSecur> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController firstnameController = TextEditingController();
  final TextEditingController lastnameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController telephoneController = TextEditingController();

  String country_id = '176';
  String zone_id = 'RUS';

  bool _isDataLoaded = false;
  bool _isDataChanged = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        emailController.text = user.email ?? '';
      });
    }
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('userData');
    if (userData != null) {
      final json = jsonDecode(userData);
      print('Loaded data: $json');
      setState(() {
        firstnameController.text = json['firstname'] ?? '';
        lastnameController.text = json['lastname'] ?? '';
        addressController.text = json['address_1'] ?? '';
        country_id = json['country_id'] ?? '';
        zone_id = json['zone_id'] ?? '';
        cityController.text = json['city'] ?? '';
        telephoneController.text = json['telephone'] ?? '';
        _isDataLoaded = true;
      });
    } else {
      setState(() {
        _isDataLoaded = true;
      });
    }
  }

  void _onFieldChanged() {
    setState(() {
      _isDataChanged = true;
    });
  }

  Future<void> _saveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataMap = {
      'email': emailController.text,
      'firstname': firstnameController.text,
      'lastname': lastnameController.text,
      'address_1': addressController.text,
      'country_id': country_id,
      'zone_id': zone_id,
      'city': cityController.text,
      'telephone': telephoneController.text,
    };
    prefs.setString('userData', jsonEncode(userDataMap));
    final savedData = prefs.getString('userData');
    if (savedData != null) {
      print('Saved data: $savedData');
    } else {
      print('Error: Data not saved');
    }

    setState(() {
      _isDataChanged = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Данные успешно сохранены'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Подтверждение'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Вы уверены, что хотите выйти из аккаунта?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Отмена'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Выйти'),
              onPressed: () {
                signUserOut(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 7, 199, 180),
        actions: [
          IconButton(
            onPressed: () => _confirmSignOut(context),
            icon: const Icon(Icons.logout),
          )
        ],
        title: const Text('Персональные данные'),
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(
                context, true); // Возвращаем значение true при возврате
          },
          child: const Icon(Icons.arrow_back),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                enabled: false,
              ),
              TextFormField(
                controller: firstnameController,
                decoration: const InputDecoration(labelText: 'Имя'),
                onChanged: (value) {
                  _onFieldChanged();
                },
              ),
              TextFormField(
                controller: lastnameController,
                decoration: const InputDecoration(labelText: 'Фамилия'),
                onChanged: (value) {
                  _onFieldChanged();
                },
              ),
              TextFormField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Адрес'),
                onChanged: (value) {
                  _onFieldChanged();
                },
              ),
              TextFormField(
                controller: cityController,
                decoration: const InputDecoration(labelText: 'Город'),
                onChanged: (value) {
                  _onFieldChanged();
                },
              ),
              TextFormField(
                controller: telephoneController,
                decoration: const InputDecoration(labelText: 'Телефон'),
                onChanged: (value) {
                  _onFieldChanged();
                },
              ),
              _isDataLoaded && _isDataChanged
                  ? Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(200, 50),
                        ),
                        onPressed: () async {
                          await _saveUserData();
                        },
                        child: const Text('Сохранить изменения'),
                      ),
                    )
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }
}
