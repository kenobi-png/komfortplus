import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer';
import 'package:komfortik/cart_page.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Импортируйте файл с корзиной

class OrderPageAuth extends StatefulWidget {
  const OrderPageAuth({Key? key}) : super(key: key);

  @override
  _OrderPageAuthState createState() => _OrderPageAuthState();
}

class Adress {
  final String firstname;
  final String lastname;
  final String address_1;
  final String? city;
  final String? country_id;
  final String? zone_id;
  final String email;
  final String telephone;
  final String? shipping_methods;
  final String? payment_methods;

  Adress({
    required this.firstname,
    required this.lastname,
    required this.address_1,
    required this.city,
    required this.country_id,
    required this.zone_id,
    required this.email,
    required this.telephone,
    required this.shipping_methods,
    required this.payment_methods,
  });

  factory Adress.fromJson(Map<String, dynamic> json) {
    return Adress(
      firstname: json['firstname'] as String,
      lastname: json['lastname'] as String,
      address_1: json['address_1'] as String,
      city: json['city'] as String?,
      country_id: json['country_id'] as String?,
      zone_id: json['zone_id'] as String?,
      email: json['email'] as String,
      telephone: json['telephone'] as String,
      shipping_methods: json['shipping_methods'] as String?,
      payment_methods: json['payment_methods'] as String?,
    );
  }
}

class _OrderPageAuthState extends State<OrderPageAuth> {
  String firstname = '';
  String lastname = '';
  String email = '';
  String telephone = '';
  String address_1 = '';
  String shipping_method = '';
  String payment_method = '';
  String zone_id = 'RUS';
  String country_id = '176';
  String city = '';

  final _firstnameController = TextEditingController();
  final _lastnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _address1Controller = TextEditingController();
  final _cityController = TextEditingController();

  bool showAddressField = false;
  bool showCityField = false;
  String? token;

  @override
  void initState() {
    super.initState();
    _fetchToken();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _emailController.text = user.email ?? '';
      });
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('userData');

      if (userDataString != null) {
        final userData = jsonDecode(userDataString);
        print('Loaded user data: $userData');

        setState(() {
          firstname = userData['firstname'] ?? '';
          lastname = userData['lastname'] ?? '';
          email = userData['email'] ?? '';
          telephone = userData['telephone'] ?? '';
          address_1 = userData['address_1'] ?? '';
          city = userData['city'] ?? '';
        });

        _firstnameController.text = firstname;
        _lastnameController.text = lastname;
        _telephoneController.text = telephone;
        _address1Controller.text = address_1;
        _cityController.text = city;
      } else {
        print('No user data found in SharedPreferences');
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _fetchToken() async {
    String url = 'https://klimatkomfort161.ru/index.php?route=api/login';
    String username = 'gus';
    String key =
        'YdfKNNWkEEEccoHG5fLmWi8O1ORBJynmEGDEARc5gE4KOoJmN5zRwm7XDAQJNkUcXhwj4twQGnrxv0BfBbwW5r1mMWVeP3zBYXYqoQydU2a5xmQ43Gt3gh0lE3yeDiDjXzYpS4O4FlT5DlxzDk27hzjRM1Lh5DNJGJ0gXjIKXxXDaQ4nrOhfhyDu4i0iDErFtlsIRwU3nEmvW32mXfT34RxQ1gLuwrXmTugYXmoSyrgO0MVnu6jp8lRvMShaDUGJ';

    try {
      var response = await http.post(Uri.parse(url), body: {
        'username': username,
        'key': key,
      });
      log('Response: ${response.body}');
      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          token = data['token'];
        });
      } else {
        throw Exception('Failed to fetch token: ${response.statusCode}');
      }
    } catch (error) {
      log('Error fetching token: $error');
      throw Exception('Failed to fetch token');
    }
  }

  void submitOrder() async {
    if (token == null) {
      await _fetchToken();
    }
    await setCustomer();

    // Получение продуктов из корзины
    List<Map<String, dynamic>> cartItems = Cart.items.map((product) {
      return {
        'product_id': product.product_id,
        'quantity': product.quantity.toString(),
      };
    }).toList();

    for (var item in cartItems) {
      await addProductToCart(item['product_id'], item['quantity']);
    }
    await setShippingAddress();
    await setShippingMethods();
    await setShippingMethod();
    await setPaymentAddress();
    await setPaymentMethods();
    await setPaymentMethod();
    await setOrderAdd();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Заказ подтвержден'),
          content: const Text(
              'Ваш заказ успешно оформлен. Ожидайте звонок от менеджера!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('ОК'),
            ),
          ],
        );
      },
    );
  }

  Future<void> setCustomer() async {
    String url =
        'https://klimatkomfort161.ru/index.php?route=api/customer&token=$token'; // 1
    try {
      var response = await http.post(Uri.parse(url), body: {
        'firstname': firstname,
        'lastname': lastname,
        'email': email,
        'telephone': telephone
      });

      log('Set shipping address request body: $firstname, $lastname, $email, $telephone');
      log('Set shipping address response: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to set shipping address: ${response.statusCode}');
      }
    } catch (error) {
      log('Error setting shipping address: $error');
      throw Exception('Failed to set shipping address');
    }
  }

  Future<void> addProductToCart(String product_id, String quantity) async {
    String url =
        'https://klimatkomfort161.ru/index.php?route=api/cart/add&token=$token'; // 2
    try {
      var response = await http.post(Uri.parse(url), body: {
        'product_id': product_id,
        'quantity': quantity,
      });

      log('Add product response: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to add product to cart: ${response.statusCode}');
      }
    } catch (error) {
      log('Error adding product to cart: $error');
      throw Exception('Failed to add product to cart');
    }
  }

  Future<void> setShippingAddress() async {
    String url =
        'https://klimatkomfort161.ru/index.php?route=api/shipping/address&token=$token'; // 3
    try {
      var response = await http.post(Uri.parse(url), body: {
        'firstname': firstname,
        'lastname': lastname,
        'address_1': address_1,
        'city': city,
        'country_id': country_id,
        'zone_id': zone_id,
      });

      log('Set shipping address request body: $address_1, $city, $country_id, $zone_id');
      log('Set shipping address response: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to set shipping address: ${response.statusCode}');
      }
    } catch (error) {
      log('Error setting shipping address: $error');
      throw Exception('Failed to set shipping address');
    }
  }

  Future<void> setShippingMethods() async {
    String url =
        'https://klimatkomfort161.ru/index.php?route=api/shipping/methods&token=$token'; // 4
    try {
      var response = await http.post(Uri.parse(url));

      log('Set order add response: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to add order: ${response.statusCode}');
      }
    } catch (error) {
      log('Error adding order: $error');
      throw Exception('Failed to add order');
    }
  }

  Future<void> setShippingMethod() async {
    String url =
        'https://klimatkomfort161.ru/index.php?route=api/shipping/method&token=$token'; // 5
    try {
      var response = await http.post(Uri.parse(url), body: {
        'shipping_method': shipping_method,
      });

      log('Set shipping method request body: $shipping_method');
      log('Set shipping method response: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to set shipping method: ${response.statusCode}');
      }
    } catch (error) {
      log('Error setting shipping method: $error');
      throw Exception('Failed to set shipping method');
    }
  }

  Future<void> setPaymentAddress() async {
    String url =
        'https://klimatkomfort161.ru/index.php?route=api/payment/address&token=$token'; // 6
    try {
      var response = await http.post(Uri.parse(url), body: {
        'firstname': firstname,
        'lastname': lastname,
        'address_1': address_1,
        'city': city,
        'country_id': country_id,
        'zone_id': zone_id,
      });

      log('Set payment address request body: $address_1, $city, $country_id, $zone_id');
      log('Set payment address response: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to set payment address: ${response.statusCode}');
      }
    } catch (error) {
      log('Error setting payment address: $error');
      throw Exception('Failed to set payment address');
    }
  }

  Future<void> setPaymentMethods() async {
    String url =
        'https://klimatkomfort161.ru/index.php?route=api/payment/methods&token=$token'; // 7
    try {
      var response = await http.post(Uri.parse(url), body: {
        'payment_method': payment_method,
      });

      log('Set payment method request body: $payment_method');
      log('Set payment method response: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to set payment method: ${response.statusCode}');
      }
    } catch (error) {
      log('Error setting payment method: $error');
      throw Exception('Failed to set payment method');
    }
  }

  Future<void> setPaymentMethod() async {
    String url =
        'https://klimatkomfort161.ru/index.php?route=api/payment/method&token=$token'; // 8
    try {
      var response = await http.post(Uri.parse(url), body: {
        'payment_method': payment_method,
      });

      log('Set payment method request body: $payment_method');
      log('Set payment method response: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to set payment method: ${response.statusCode}');
      }
    } catch (error) {
      log('Error setting payment method: $error');
      throw Exception('Failed to set payment method');
    }
  }

  Future<void> setOrderAdd() async {
    String url =
        'https://klimatkomfort161.ru/index.php?route=api/order/add&token=$token'; // 9
    try {
      var response = await http.post(Uri.parse(url));

      log('Set order add response: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to add order: ${response.statusCode}');
      }
    } catch (error) {
      log('Error adding order: $error');
      throw Exception('Failed to add order');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Оформление заказа'),
        backgroundColor: Color.fromARGB(255, 7, 199, 180),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Контактные данные',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Имя'),
              controller: _firstnameController,
              onChanged: (value) {
                setState(() {
                  firstname = value;
                });
              },
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Фамилия'),
              controller: _lastnameController,
              onChanged: (value) {
                setState(() {
                  lastname = value;
                });
              },
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Телефон'),
              controller: _telephoneController,
              onChanged: (value) {
                setState(() {
                  telephone = value;
                });
              },
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Email'),
              controller: _emailController,
              onChanged: (value) {
                setState(() {
                  email = value;
                });
              },
            ),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Способ доставки'),
              value: shipping_method.isNotEmpty ? shipping_method : null,
              onChanged: (value) {
                setState(() {
                  shipping_method = value!;
                  if (value == 'by_total.by_total_3') {
                    // Show address field for Ростов на Дону
                    showAddressField = true;
                    showCityField = false;
                  } else if (value == 'flat.flat') {
                    // Show city and address fields for Ростовская область
                    showAddressField = true;
                    showCityField = true;
                  } else {
                    // Hide address and city fields
                    showAddressField = false;
                    showCityField = false;
                  }
                });
              },
              items: const [
                DropdownMenuItem(
                  value: 'pickup.pickup',
                  child: Text('Самовывоз'),
                ),
                DropdownMenuItem(
                  value: 'by_total.by_total_3',
                  child: Text('Доставка по г. Ростов на Дону'),
                ),
                DropdownMenuItem(
                  value: 'flat.flat',
                  child: Text('Доставка по Ростовской области'),
                ),
              ],
            ),
            if (showAddressField)
              TextFormField(
                decoration: const InputDecoration(labelText: 'Адрес'),
                controller: _address1Controller,
                onChanged: (value) {
                  setState(() {
                    address_1 = value;
                  });
                },
              ),
            if (showCityField)
              TextFormField(
                decoration: const InputDecoration(labelText: 'Город/Поселок'),
                controller: _cityController,
                onChanged: (value) {
                  setState(() {
                    city = value;
                  });
                },
              ),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Способ оплаты'),
              value: payment_method.isNotEmpty ? payment_method : null,
              onChanged: (value) {
                setState(() {
                  payment_method = value!;
                });
              },
              items: const [
                DropdownMenuItem(
                  value: 'free_checkout',
                  child: Text('Наличный расчет'),
                ),
                DropdownMenuItem(
                  value: 'bank_transfer',
                  child: Text('Безналичный расчет'),
                ),
              ],
            ),
            const SizedBox(height: 50.0),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: isValidForm()
                        ? BorderSide(
                            width: 2, color: Color.fromARGB(255, 7, 199, 180))
                        : BorderSide.none,
                  ),
                  elevation: 5,
                ),
                onPressed: isValidForm()
                    ? () {
                        submitOrder();
                      }
                    : null,
                child: Text(
                  'Подтвердить заказ',
                  style: TextStyle(
                    fontSize: 20,
                    color: isValidForm()
                        ? Color.fromARGB(255, 7, 199, 180)
                        : Colors.grey,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  bool isValidForm() {
    return firstname.isNotEmpty &&
        lastname.isNotEmpty &&
        telephone.isNotEmpty &&
        shipping_method.isNotEmpty &&
        (showAddressField ? address_1.isNotEmpty : true) &&
        (showCityField ? city.isNotEmpty : true) &&
        payment_method.isNotEmpty;
  }
}

void main() {
  runApp(MaterialApp(
    home: OrderPageAuth(),
  ));
}
