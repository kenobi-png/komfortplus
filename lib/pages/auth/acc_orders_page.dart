import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:komfortik/components/order.dart';

class OrderService {
  static const String tokenKey = 'token';

  static Future<String?> fetchToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString(tokenKey);

    if (token != null) {
      log('Using cached token: $token');
      // Проверяем, действителен ли токен
      bool isValid = await _verifyToken(token);
      if (isValid) {
        return token;
      } else {
        log('Cached token is not valid. Requesting a new token.');
        return await _requestNewToken();
      }
    } else {
      return await _requestNewToken();
    }
  }

  static Future<bool> _verifyToken(String token) async {
    String url =
        'https://klimatkomfort161.ru/index.php?route=api/token/verify&token=$token';
    try {
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        return data['valid'] == true;
      }
      return false;
    } catch (error) {
      log('Error verifying token: $error');
      return false;
    }
  }

  static Future<String?> _requestNewToken() async {
    String url = 'https://klimatkomfort161.ru/index.php?route=api/login';
    String username = 'gus';
    String key =
        'YdfKNNWkEEEccoHG5fLmWi8O1ORBJynmEGDEARc5gE4KOoJmN5zRwm7XDAQJNkUcXhwj4twQGnrxv0BfBbwW5r1mMWVeP3zBYXYqoQydU2a5xmQ43Gt3gh0lE3yeDiDjXzYpS4O4FlT5DlxzDk27hzjRM1Lh5DNJGJ0gXjIKXxXDaQ4nrOhfhyDu4i0iDErFtlsIRwU3nEmvW32mXfT34RxQ1gLuwrXmTugYXmoSyrgO0MVnu6jp8lRvMShaDUGJ';

    try {
      var response = await http.post(Uri.parse(url), body: {
        'username': username,
        'key': key,
      });

      log('Request URL: $url');
      log('Request Body: username=$username, key=$key');
      log('Response: ${response.body}');

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        String? token = data['token'];

        if (token != null) {
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString(tokenKey, token);
          return token;
        } else {
          throw Exception('Token is null');
        }
      } else {
        throw Exception('Failed to fetch token: ${response.statusCode}');
      }
    } catch (error) {
      log('Error fetching token: $error');
      throw Exception('Failed to fetch token');
    }
  }

  static Future<void> clearToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
  }

  Future<List<Order>> fetchOrders(String token, String email) async {
    // Сначала проверим токен
    bool isValid = await _verifyToken(token);
    if (!isValid) {
      log('Token is not valid. Requesting a new token.');
      token = await _requestNewToken() ?? '';
    }

    String url =
        'https://klimatkomfort161.ru/index.php?route=api/customer_orders&token=$token';

    try {
      var response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
        body: {
          'email': email,
        },
      );

      log('Request URL: $url');
      log('Request body: {email: $email}');
      log('Response status: ${response.statusCode}');
      log('Response body: ${response.body}');

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse = json.decode(response.body);
        List<dynamic> ordersJson = jsonResponse['orders'];

        List<Order> orders =
            ordersJson.map((json) => Order.fromJson(json)).toList();
        return orders;
      } else if (response.statusCode == 401) {
        log('Token is invalid. Clearing token.');
        await clearToken();
        throw Exception('Token is invalid. Please log in again.');
      } else {
        throw Exception('Failed to fetch orders: ${response.statusCode}');
      }
    } catch (error) {
      log('Error fetching orders: $error');
      throw Exception('Failed to fetch orders: $error');
    }
  }
}

class OrdersPage extends StatefulWidget {
  final String token;
  final String email;

  const OrdersPage({required this.token, required this.email, Key? key})
      : super(key: key);

  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late Future<List<Order>> _ordersFuture;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _ordersFuture = Future.value([]);
  }

  void _loadUserData() async {
    try {
      String? token = await OrderService.fetchToken();
      User? user = _auth.currentUser;

      if (token != null && user != null) {
        setState(() {
          _ordersFuture = OrderService().fetchOrders(token, user.email!);
        });
      } else {
        throw Exception('Failed to load user or token is null');
      }
    } catch (error) {
      log('Error loading user data: $error');
      // Handle error loading user data
    }
  }

  Widget _buildOrderDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 8.0),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(Product product) {
    String formattedPrice = '${product.price} ₽';

    // Убираем ".0000" из конца строки, если оно там есть
    if (formattedPrice.contains('.')) {
      formattedPrice =
          formattedPrice.replaceAll(RegExp(r"([.]*0000)(?!.*\d)"), "");
    }

    return Card(
      child: GestureDetector(
        child: ListTile(
          leading: Image.network(product.image, width: 50, height: 50),
          title: Text(product.name ?? 'No Name'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Цена: $formattedPrice'),
              Text('Количество: ${product.quantity ?? 'No Quantity'}'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderItem(Order order) {
    String formattedTotal = '${order.total} ₽';
    if (formattedTotal.contains('.')) {
      formattedTotal =
          formattedTotal.replaceAll(RegExp(r"([.]*0000)(?!.*\d)"), "");
    }
    return Card(
      child: ExpansionTile(
        title: Text('Заказ #${order.order_id}'),
        subtitle: Text('Дата: ${order.date_added}\nИтого: ${formattedTotal}'),
        children: order.products
            .map((product) => _buildProductItem(product))
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ваши заказы'),
        backgroundColor: const Color.fromARGB(255, 7, 199, 180),
      ),
      body: SafeArea(
        child: FutureBuilder<List<Order>>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Ошибка: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              // Возвращаем NoOrder, если нет данных
              return NoOrder();
            } else {
              final orders = snapshot.data!;
              return ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return GestureDetector(
                    child: _buildOrderItem(order),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}

class NoOrder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('lib/images/delivery.png', height: 100.0, width: 100.0),
          SizedBox(height: 16.0),
          Text(
            'У вас пока нет заказов.',
            style: TextStyle(fontSize: 18.0),
          ),
          SizedBox(height: 8.0),
          Text(
            'Вы можете сделать заказ и он появится здесь.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
