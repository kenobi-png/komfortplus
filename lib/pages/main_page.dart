import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:komfortik/pages/product_page.dart';
import 'dart:developer';
import 'dart:io';

class ProductSorter {
  static List<Product> sort(List<Product> products, SortBy sortBy,
      {bool enableSorting = true, bool defaultSort = false}) {
    if (!enableSorting || defaultSort) {
      return products;
    }

    switch (sortBy) {
      case SortBy.priceAsc:
        products.sort((a, b) {
          if (!_isValidPrice(a.price)) return 1;
          if (!_isValidPrice(b.price)) return -1;
          return _parsePrice(a.price).compareTo(_parsePrice(b.price));
        });
        break;
      case SortBy.priceDesc:
        products.sort((a, b) {
          if (!_isValidPrice(a.price)) return -1;
          if (!_isValidPrice(b.price)) return 1;
          return _parsePrice(b.price).compareTo(_parsePrice(a.price));
        });
        break;
      case SortBy.nameAsc:
        products.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortBy.nameDesc:
        products.sort((a, b) => b.name.compareTo(a.name));
        break;
      default:
        break;
    }
    return products;
  }

  static bool _isValidPrice(String price) {
    return !_parsePrice(price).isNaN;
  }

  static double _parsePrice(String priceString) {
    final priceCleaned = priceString
        .replaceAll(RegExp(r'[^0-9.]'), '')
        .replaceAll('.', '')
        .replaceAll(',', '');
    return double.tryParse(priceCleaned) ?? double.nan;
  }
}

class ProductApi {
  static final Map<String, List<Product>> _productCache = {};
  static const int maxProducts = 50;
  static const String tokenKey = 'api_token';
  static const int maxAttempts =
      3; //кол-во ошибок до того как появится сообщение об ошибке
  static const Duration retryDelay = Duration(
      seconds:
          2); //время перед отправкой следующего запроса(хз какое поставить)
  static Future<String> fetchToken() async {
    int attempts = 0;
    while (attempts < maxAttempts) {
      try {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        String? token = prefs.getString(tokenKey);

        if (token != null) {
          log('Using cached token: $token');
          return token;
        } else {
          token = await _requestNewToken();
          log('New token fetched: $token');
          return token;
        }
      } catch (error) {
        attempts++;
        log('Error fetching token: $error');
        await Future.delayed(
            retryDelay); //задержка до следующего повтора отправки запроса
      }
    }
    throw Exception('Failed to fetch token after $maxAttempts attempts');
  }

  static Future<String> _requestNewToken() async {
    String url = 'https://klimatkomfort161.ru/index.php?route=api/login';
    String username = 'gus';
    String key =
        'YdfKNNWkEEEccoHG5fLmWi8O1ORBJynmEGDEARc5gE4KOoJmN5zRwm7XDAQJNkUcXhwj4twQGnrxv0BfBbwW5r1mMWVeP3zBYXYqoQydU2a5xmQ43Gt3gh0lE3yeDiDjXzYpS4O4FlT5DlxzDk27hzjRM1Lh5DNJGJ0gXjIKXxXDaQ4nrOhfhyDu4i0iDErFtlsIRwU3nEmvW32mXfT34RxQ1gLuwrXmTugYXmoSyrgO0MVnu6jp8lRvMShaDUGJ';

    try {
      // Получение и вывод локального IP-адреса
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          log('Local IP address: ${addr.address}');
        }
      }

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
          prefs.setString(tokenKey, token);
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

  static Future<List<Product>> fetchProducts() async {
    if (_productCache.containsKey('products')) {
      return _productCache['products']!;
    }
    try {
      String token = await fetchToken();

      var response = await http.get(Uri.parse(
          'https://klimatkomfort161.ru/index.php?route=api/product&token=$token'));
      log('Request URL: https://klimatkomfort161.ru/index.php?route=api/product&token=$token');
      //log('Response body: ${response.body}');
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse.containsKey('products')) {
          final List<dynamic> jsonDataList = jsonResponse['products'];

          List<Product> products = jsonDataList
              .map((json) => Product.fromJson(json))
              .take(maxProducts)
              .toList();

          _productCache['products'] = products;

          return products;
        } else {
          throw Exception('Invalid data format');
        }
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (error) {
      log('Error fetching products: $error');
      if (error.toString().contains('Invalid data format')) {
        log('Attempting to fetch a new token due to invalid data format');
        await clearToken();
        return await fetchProducts();
      } else {
        throw Exception('Failed to load products');
      }
    }
  }

  static void clearProductCache() {
    _productCache.remove('products');
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late Future<List<Product>> futureProducts;
  SortBy _sortBy = SortBy.none;
  List<Product> allProducts = [];

  @override
  void initState() {
    super.initState();
    futureProducts = ProductApi.fetchProducts().then((products) {
      setState(() {
        allProducts = products;
      });
      return products;
    });
  }

  Future<void> _refreshProducts() async {
    setState(() {
      futureProducts = ProductApi.fetchProducts().then((products) {
        setState(() {
          allProducts = products;
        });
        return products;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color.fromARGB(255, 7, 199, 180),
          title: const Text('Каталог'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: IconButton(
                icon: const Icon(Icons.sort),
                onPressed: () {
                  _showSortOptions(context);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  showSearch(
                    context: context,
                    delegate: ProductSearchDelegate(products: allProducts),
                  );
                },
              ),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _refreshProducts,
          child: FutureBuilder<List<Product>>(
            future: futureProducts,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return const Center(child: Text('Ошибка загрузки данных.'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                    child: Text('Нет продуктов для отображения.'));
              } else {
                List<Product> sortedProducts =
                    ProductSorter.sort(snapshot.data!, _sortBy);
                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        MediaQuery.of(context).size.width > 600 ? 4 : 2,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: sortedProducts.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ProductPage(product: sortedProducts[index]),
                          ),
                        );
                      },
                      child: ProductCard(product: sortedProducts[index]),
                    );
                  },
                );
              }
            },
          ),
        ));
  }

  void _showSortOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Сортировка'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                _buildSortOption(
                    context, 'Цена (возрастание)', SortBy.priceAsc),
                _buildSortOption(context, 'Цена (убывание)', SortBy.priceDesc),
                _buildSortOption(context, 'Название (А-Я)', SortBy.nameAsc),
                _buildSortOption(context, 'Название (Я-А)', SortBy.nameDesc),
                _buildSortOption(context, 'По умолчанию', SortBy.none)
                //опции сортировки
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortOption(BuildContext context, String label, SortBy sortBy) {
    return ListTile(
      title: Text(label),
      onTap: () {
        setState(() {
          _sortBy = sortBy;
        });
        Navigator.of(context).pop();
      },
    );
  }
}

class ProductSearchDelegate extends SearchDelegate {
  final List<Product> products;

  ProductSearchDelegate({required this.products});

  @override
  String get searchFieldLabel => 'Поиск товаров';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: AnimatedIcon(
        icon: AnimatedIcons.menu_arrow,
        progress: transitionAnimation,
      ),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final results = query.isEmpty
        ? []
        : products
            .where((product) =>
                product.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final product = results[index];
        return ListTile(
          title: Text(product.name),
          onTap: () {
            query = product.name;
            showResults(context);
          },
        );
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = query.isEmpty
        ? products
        : products
            .where((product) =>
                product.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
        childAspectRatio: 0.7,
      ),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final product = results[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductPage(product: product),
              ),
            );
          },
          child: ProductCard(product: product),
        );
      },
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
              _truncateProductName(product.name),
              style: const TextStyle(fontSize: 18),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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

  String _truncateProductName(String name) {
    const maxLength = 40; // максимальная длина названия
    return name.length <= maxLength
        ? name
        : '${name.substring(0, maxLength)}...';
  }
}

class Product {
  final String? product_id;
  final String name;
  final String thumb;
  final String price;
  final String description;

  Product({
    this.product_id,
    required this.name,
    required this.thumb,
    required this.price,
    required this.description,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      product_id: json['product_id'] as String?,
      name: json['name'] as String,
      thumb: json['thumb'] as String,
      price: json['price'] as String,
      description: json['description'] as String,
    );
  }
}

enum SortBy { priceAsc, priceDesc, nameAsc, nameDesc, none }
