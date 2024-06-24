import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_html/flutter_html.dart';
import 'package:komfortik/cart_page.dart';
import 'package:komfortik/connectivity_checker.dart';
import 'package:komfortik/cart_page.dart' as cart;
import 'package:komfortik/pages/main_page.dart' as main;
import 'package:connectivity/connectivity.dart';

class ProductPage extends StatefulWidget {
  final main.Product product;

  const ProductPage({Key? key, required this.product}) : super(key: key);

  @override
  _ProductPageState createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  bool _isConnected = false;
  bool _isDescriptionExpanded = false;
  int _quantity = 0;
  bool _isInCart = false;
  int _cartItemCount = 0;

  Timer? _timer;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _checkConnectivity();
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      setState(() {
        _isConnected = result != ConnectivityResult.none;
      });
    });

    _checkIfInCart();
    cart.Cart.onCartChanged = () {
      _checkIfInCart();
    };
  }

  void _checkIfInCart() {
    _isInCart = false;
    _cartItemCount = 0;

    for (var item in cart.Cart.items) {
      if (item.product_id == widget.product.product_id) {
        _isInCart = true;
        _cartItemCount = item.quantity;
        break;
      }
    }
  }

  void _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isConnected = connectivityResult != ConnectivityResult.none;
    });
  }

  void _startTimer() {
    _timer = Timer(const Duration(seconds: 8), () {
      if (!_isConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка: Проверьте подключение к интернету.'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  bool _snackBarVisible = false;

  void _addToCart() {
    final item = cart.Product(
      name: widget.product.name,
      thumb: widget.product.thumb,
      price: widget.product.price,
      description: widget.product.description,
      product_id: widget.product.product_id,
      quantity: _quantity,
    );
    cart.Cart.addItem(item);
    setState(() {
      _isInCart = true;
      _cartItemCount += _quantity;
    });

    if (!_snackBarVisible && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Товар добавлен в корзину'),
          duration: Duration(seconds: 2),
        ),
      );

      setState(() {
        _snackBarVisible = true;
      });

      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _snackBarVisible = false;
          });
        }
      });
    }
  }

  void _incrementQuantity() {
    setState(() {
      _quantity++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ConnectivityChecker(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: _isConnected
            ? ProductContent(
                product: widget.product,
                isDescriptionExpanded: _isDescriptionExpanded,
                onDescriptionToggle: () {
                  setState(() {
                    _isDescriptionExpanded = !_isDescriptionExpanded;
                  });
                },
                updateQuantity: (newQuantity) {
                  setState(() {
                    _quantity = newQuantity;
                  });
                },
              )
            : const Center(
                child: CircularProgressIndicator(),
              ),
        bottomNavigationBar: BottomAppBar(
          child: Center(
            child: ElevatedButton(
              onPressed: () {
                if (mounted) {
                  setState(() {
                    _addToCart();
                  });
                }
              },
              child: Text(_isInCart
                  ? 'В корзине - $_cartItemCount шт'
                  : 'Добавить в корзину'),
            ),
          ),
        ),
      ),
    );
  }
}

class ProductContent extends StatelessWidget {
  final main.Product product;
  final bool isDescriptionExpanded;
  final VoidCallback onDescriptionToggle;
  final ValueChanged<int> updateQuantity;

  const ProductContent({
    Key? key,
    required this.product,
    required this.isDescriptionExpanded,
    required this.onDescriptionToggle,
    required this.updateQuantity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Image.network(
                product.thumb,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Цена: ${product.price}',
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: onDescriptionToggle,
                  child: Row(
                    children: [
                      Text(
                        'Характеристики и описание',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      Icon(
                        isDescriptionExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: Theme.of(context).primaryColor,
                      ),
                    ],
                  ),
                ),
                if (isDescriptionExpanded) ...[
                  const SizedBox(height: 10),
                  Html(
                    data: json.decode(product.description),
                    style: {
                      'body': Style(fontSize: FontSize(18)),
                    },
                  ),
                ],
                const SizedBox(height: 10),
                const Text(
                  'Похожие товары:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                FutureBuilder<List<main.Product>>(
                  future: _fetchRandomProducts(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else {
                      List<main.Product>? randomProducts = snapshot.data;
                      if (randomProducts != null && randomProducts.isNotEmpty) {
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets
                              .zero, // Убираем внешний отступ GridView
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.7,
                            mainAxisSpacing:
                                10, // Уменьшаем вертикальный отступ между товарами
                            crossAxisSpacing:
                                10, // Уменьшаем горизонтальный отступ между товарами
                          ),
                          itemCount: randomProducts.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductPage(
                                      product: randomProducts[index],
                                    ),
                                  ),
                                );
                              },
                              child:
                                  ProductCard(product: randomProducts[index]),
                            );
                          },
                        );
                      } else {
                        return const Text('Нет похожих товаров');
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<List<main.Product>> _fetchRandomProducts() async {
    List<main.Product> products = await main.ProductApi.fetchProducts();
    products.shuffle();
    return products;
  }
}

class ProductCard extends StatelessWidget {
  final main.Product product;

  const ProductCard({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Image.network(
              product.thumb,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              product.name,
              style: const TextStyle(fontSize: 18),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              product.price,
              style: const TextStyle(
                fontSize: 16,
                color: Color.fromARGB(220, 18, 87, 216),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
