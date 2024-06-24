class Product {
  final String name;
  final String thumb;
  final String price;
  final String description;

  Product({
    required this.name,
    required this.thumb,
    required this.price,
    required this.description,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      name: json['name'] ?? '',
      thumb: json['thumb'] ?? '',
      price: json['price'] ?? '',
      description: json['description'] ?? '',
    );
  }
}
