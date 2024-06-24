import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:komfortik/pages/main_page.dart' as main;
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/product_page.dart';
import 'pages/auth/order_page.dart';
import 'pages/noauth/account_page_noauth.dart';

class Cart {
  static final List<Product> _items = [];
  static List<Product> get items => _items;

  static Function()? onCartChanged;

  static Future<void> saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartItems = _items.map((item) => jsonEncode(item.toMap())).toList();
      await prefs.setStringList('cart_items', cartItems);
    } catch (e, stackTrace) {
      print('Ошибка при сохранении корзины: $e');
      print(stackTrace);
    }
  }

  static Future<void> loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartItems = prefs.getStringList('cart_items');
    if (cartItems != null) {
      _items.clear();
      for (final item in cartItems) {
        final productMap = jsonDecode(item);
        final product = Product.fromMap(productMap);
        _items.add(product);
      }
    }
    onCartChanged?.call();
  }

  static void addItem(Product product) {
    bool isExisting = false;

    for (var item in _items) {
      if (item.name == product.name) {
        item.quantity++;
        isExisting = true;
        break;
      }
    }

    if (!isExisting) {
      bool isNumeric(String str) {
        return double.tryParse(str.replaceAll(RegExp(r'[^\d.]'), '')) != null;
      }

      if (isNumeric(product.price)) {
        String formattedPrice = product.price.replaceAll(RegExp(r'[^\d.]'), '');
        double price = double.parse(formattedPrice);
        Product newItem = Product(
          name: product.name,
          thumb: product.thumb,
          price: price.toString(),
          description: product.description,
          product_id: product.product_id,
        );
        _items.add(newItem);
      } else {
        _items.add(product);
      }
    }

    saveCart();
    onCartChanged?.call();
  }

  static void removeItem(Product product, BuildContext context) {
    _items.remove(product);
    saveCart();
    onCartChanged?.call();

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text('${product.name} удален из корзины'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  static Future<void> clearCart(BuildContext context) async {
    _items.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cart_items');
    onCartChanged?.call();
  }

  static double getTotalPrice() {
    double totalPrice = 0;
    for (var item in _items) {
      totalPrice += double.parse(item.price) * item.quantity;
    }
    saveCart();
    return totalPrice;
  }
}

class Product {
  final String name;
  final String thumb;
  final String price;
  final String description;
  final String? product_id;
  int quantity;

  Product({
    required this.name,
    required this.thumb,
    required this.price,
    this.description = '',
    this.quantity = 1,
    required this.product_id,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'thumb': thumb,
      'price': price,
      'description': description,
      'product_id': product_id,
      'quantity': quantity,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      name: map['name'],
      thumb: map['thumb'],
      price: map['price'],
      description: map['description'],
      product_id: map['product_id'],
      quantity: map['quantity'],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          thumb == other.thumb &&
          price == other.price &&
          description == other.description &&
          product_id == other.product_id;

  @override
  int get hashCode =>
      name.hashCode ^
      thumb.hashCode ^
      price.hashCode ^
      description.hashCode ^
      product_id.hashCode;
}

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  @override
  void initState() {
    super.initState();
    Cart.onCartChanged = updateCart;
    Cart.loadCart().then((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    Cart.onCartChanged = null;
    super.dispose();
  }

  void updateCart() {
    setState(() {});
    Cart.saveCart();
  }

  void confirmClearCartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Очистить корзину?'),
          content: Text('Вы уверены, что хотите очистить корзину?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                Cart.clearCart(context);
                Navigator.of(context).pop();
              },
              child: Text('Очистить'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 7, 199, 180),
        title: const Text('Корзина'),
        automaticallyImplyLeading: false,
      ),
      body: Cart.items.isEmpty
          ? const Center(
              child: Text('Ваша корзина пуста'),
            )
          : RefreshIndicator(
              onRefresh: () async {
                Cart.loadCart().then((_) {
                  setState(() {});
                });
              },
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Общая сумма: ${Cart.getTotalPrice().toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () => confirmClearCartDialog(context),
                          child: const Text('Очистить корзину'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: Cart.items.length,
                      itemBuilder: (context, index) {
                        final cartProduct = Cart.items[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 16.0),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProductPage(
                                    product: main.Product(
                                      name: cartProduct.name,
                                      thumb: cartProduct.thumb,
                                      price: cartProduct.price,
                                      description: cartProduct.description,
                                      product_id: cartProduct.product_id,
                                    ),
                                  ),
                                ),
                              ).then((_) {
                                updateCart();
                              });
                            },
                            child: Card(
                              elevation: 4,
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height: 100,
                                      width: 100,
                                      child: Image.network(
                                        cartProduct.thumb,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            cartProduct.name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Цена: ${cartProduct.price}',
                                            style:
                                                const TextStyle(fontSize: 14),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.remove),
                                                onPressed: () {
                                                  setState(() {
                                                    if (cartProduct.quantity >
                                                        1) {
                                                      cartProduct.quantity--;
                                                      Cart.saveCart();
                                                    }
                                                  });
                                                },
                                              ),
                                              Text('${cartProduct.quantity}'),
                                              IconButton(
                                                icon: const Icon(Icons.add),
                                                onPressed: () {
                                                  setState(() {
                                                    cartProduct.quantity++;
                                                    Cart.saveCart();
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text(
                                                'Удалить из корзины?'),
                                            content: const Text(
                                              'Вы уверены, что хотите удалить этот товар из корзины?',
                                            ),
                                            actionsAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                                child: const Text('Отмена'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  setState(() {
                                                    Cart.removeItem(
                                                        cartProduct, context);
                                                    Navigator.pop(context);
                                                  });
                                                },
                                                child: const Text('Удалить'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: Cart.items.isNotEmpty
          ? user != null
              ? FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OrderPageAuth(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.shopping_cart),
                  label: const Text('Оформить заказ'),
                )
              : FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AuthPageNonAuth(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.shopping_cart),
                  label: const Text('Войти для заказа'),
                )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
