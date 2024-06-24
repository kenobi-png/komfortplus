import 'dart:convert';

// Класс Product для представления продукта в заказе
class Product {
  final String order_product_id;
  final String order_id;
  final String product_id;
  final String thumb;
  final String name;
  final String model;
  final String description;
  final String quantity;
  final String price;
  final String total;
  final String tax;
  final String reward;
  final String image;

  Product({
    required this.order_product_id,
    required this.order_id,
    required this.product_id,
    required this.thumb,
    required this.name,
    required this.model,
    required this.description,
    required this.quantity,
    required this.price,
    required this.total,
    required this.tax,
    required this.reward,
    required this.image,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      order_product_id: json['order_product_id'] ?? '',
      order_id: json['order_id'] ?? '',
      product_id: json['product_id'] ?? '',
      thumb: json['thumb'] ?? '',
      name: json['name'] ?? '',
      model: json['model'] ?? '',
      description: json['description'] ?? '',
      quantity: json['quantity'] ?? '',
      price: json['price'] ?? '',
      total: json['total'] ?? '',
      tax: json['tax'] ?? '',
      reward: json['reward'] ?? '',
      image: json['image'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_product_id': order_product_id,
      'order_id': order_id,
      'product_id': product_id,
      'thumb': thumb,
      'name': name,
      'model': model,
      'description': description,
      'quantity': quantity,
      'price': price,
      'total': total,
      'tax': tax,
      'reward': reward,
      'image': image,
    };
  }
}

// Класс Order для представления заказа
class Order {
  final String? product_id;
  final String? name;
  final String? thumb;
  final String? price;
  final String? description;
  final String date_added;
  final String total;
  final String shipping_method;
  final String? order_id;
  final String? invoice_no;
  final String? invoice_prefix;
  final String? store_id;
  final String? store_name;
  final String? store_url;
  final String? customer_id;
  final String? customer_group_id;
  final String? firstname;
  final String? lastname;
  final String? email;
  final String? telephone;
  final String? fax;
  final String? custom_field;
  final String? payment_firstname;
  final String? payment_lastname;
  final String? payment_company;
  final String? payment_address_1;
  final String? payment_address_2;
  final String? payment_city;
  final String? payment_postcode;
  final String? payment_country;
  final String? payment_country_id;
  final String? payment_zone;
  final String? payment_zone_id;
  final String? payment_address_format;
  final String? payment_custom_field;
  final String? payment_method;
  final String? payment_code;
  final String? shipping_firstname;
  final String? shipping_lastname;
  final String? shipping_company;
  final String? shipping_address_1;
  final String? shipping_address_2;
  final String? shipping_city;
  final String? shipping_postcode;
  final String? shipping_country;
  final String? shipping_country_id;
  final String? shipping_zone;
  final String? shipping_zone_id;
  final String? shipping_address_format;
  final String? shipping_custom_field;
  final String? shipping_code;
  final String? comment;
  final String? order_status_id;
  final String? affiliate_id;
  final String? commission;
  final String? marketing_id;
  final String? tracking;
  final String? language_id;
  final String? currency_id;
  final String? currency_code;
  final String? currency_value;
  final String? ip;
  final String? forwarded_ip;
  final String? user_agent;
  final String? accept_language;
  final String? date_modified;
  final List<Product> products; // Список продуктов в заказе

  Order({
    this.product_id,
    this.name,
    this.thumb,
    this.price,
    this.description,
    required this.date_added,
    required this.total,
    required this.shipping_method,
    this.order_id,
    this.invoice_no,
    this.invoice_prefix,
    this.store_id,
    this.store_name,
    this.store_url,
    this.customer_id,
    this.customer_group_id,
    this.firstname,
    this.lastname,
    this.email,
    this.telephone,
    this.fax,
    this.custom_field,
    this.payment_firstname,
    this.payment_lastname,
    this.payment_company,
    this.payment_address_1,
    this.payment_address_2,
    this.payment_city,
    this.payment_postcode,
    this.payment_country,
    this.payment_country_id,
    this.payment_zone,
    this.payment_zone_id,
    this.payment_address_format,
    this.payment_custom_field,
    this.payment_method,
    this.payment_code,
    this.shipping_firstname,
    this.shipping_lastname,
    this.shipping_company,
    this.shipping_address_1,
    this.shipping_address_2,
    this.shipping_city,
    this.shipping_postcode,
    this.shipping_country,
    this.shipping_country_id,
    this.shipping_zone,
    this.shipping_zone_id,
    this.shipping_address_format,
    this.shipping_custom_field,
    this.shipping_code,
    this.comment,
    this.order_status_id,
    this.affiliate_id,
    this.commission,
    this.marketing_id,
    this.tracking,
    this.language_id,
    this.currency_id,
    this.currency_code,
    this.currency_value,
    this.ip,
    this.forwarded_ip,
    this.user_agent,
    this.accept_language,
    this.date_modified,
    required this.products,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    var productsJson = json['products'] as List<dynamic>;
    List<Product> productsList =
        productsJson.map((i) => Product.fromJson(i)).toList();

    return Order(
      product_id: json['product_id'] as String?,
      name: json['name'] as String?,
      thumb: json['thumb'] as String?,
      price: json['price'] as String?,
      description: json['description'] as String?,
      date_added: json['date_added'] as String,
      total: json['total'] as String,
      shipping_method: json['shipping_method'] as String,
      order_id: json['order_id'] as String?,
      invoice_no: json['invoice_no'] as String?,
      invoice_prefix: json['invoice_prefix'] as String?,
      store_id: json['store_id'] as String?,
      store_name: json['store_name'] as String?,
      store_url: json['store_url'] as String?,
      customer_id: json['customer_id'] as String?,
      customer_group_id: json['customer_group_id'] as String?,
      firstname: json['firstname'] as String?,
      lastname: json['lastname'] as String?,
      email: json['email'] as String?,
      telephone: json['telephone'] as String?,
      fax: json['fax'] as String?,
      custom_field: json['custom_field'] as String?,
      payment_firstname: json['payment_firstname'] as String?,
      payment_lastname: json['payment_lastname'] as String?,
      payment_company: json['payment_company'] as String?,
      payment_address_1: json['payment_address_1'] as String?,
      payment_address_2: json['payment_address_2'] as String?,
      payment_city: json['payment_city'] as String?,
      payment_postcode: json['payment_postcode'] as String?,
      payment_country: json['payment_country'] as String?,
      payment_country_id: json['payment_country_id'] as String?,
      payment_zone: json['payment_zone'] as String?,
      payment_zone_id: json['payment_zone_id'] as String?,
      payment_address_format: json['payment_address_format'] as String?,
      payment_custom_field: json['payment_custom_field'] as String?,
      payment_method: json['payment_method'] as String?,
      payment_code: json['payment_code'] as String?,
      shipping_firstname: json['shipping_firstname'] as String?,
      shipping_lastname: json['shipping_lastname'] as String?,
      shipping_company: json['shipping_company'] as String?,
      shipping_address_1: json['shipping_address_1'] as String?,
      shipping_address_2: json['shipping_address_2'] as String?,
      shipping_city: json['shipping_city'] as String?,
      shipping_postcode: json['shipping_postcode'] as String?,
      shipping_country: json['shipping_country'] as String?,
      shipping_country_id: json['shipping_country_id'] as String?,
      shipping_zone: json['shipping_zone'] as String?,
      shipping_zone_id: json['shipping_zone_id'] as String?,
      shipping_address_format: json['shipping_address_format'] as String?,
      shipping_custom_field: json['shipping_custom_field'] as String?,
      shipping_code: json['shipping_code'] as String?,
      comment: json['comment'] as String?,
      order_status_id: json['order_status_id'] as String?,
      affiliate_id: json['affiliate_id'] as String?,
      commission: json['commission'] as String?,
      marketing_id: json['marketing_id'] as String?,
      tracking: json['tracking'] as String?,
      language_id: json['language_id'] as String?,
      currency_id: json['currency_id'] as String?,
      currency_code: json['currency_code'] as String?,
      currency_value: json['currency_value'] as String?,
      ip: json['ip'] as String?,
      forwarded_ip: json['forwarded_ip'] as String?,
      user_agent: json['user_agent'] as String?,
      accept_language: json['accept_language'] as String?,
      date_modified: json['date_modified'] as String?,
      products: productsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': product_id,
      'name': name,
      'thumb': thumb,
      'price': price,
      'description': description,
      'date_added': date_added,
      'total': total,
      'shipping_method': shipping_method,
      'order_id': order_id,
      'invoice_no': invoice_no,
      'invoice_prefix': invoice_prefix,
      'store_id': store_id,
      'store_name': store_name,
      'store_url': store_url,
      'customer_id': customer_id,
      'customer_group_id': customer_group_id,
      'firstname': firstname,
      'lastname': lastname,
      'email': email,
      'telephone': telephone,
      'fax': fax,
      'custom_field': custom_field,
      'payment_firstname': payment_firstname,
      'payment_lastname': payment_lastname,
      'payment_company': payment_company,
      'payment_address_1': payment_address_1,
      'payment_address_2': payment_address_2,
      'payment_city': payment_city,
      'payment_postcode': payment_postcode,
      'payment_country': payment_country,
      'payment_country_id': payment_country_id,
      'payment_zone': payment_zone,
      'payment_zone_id': payment_zone_id,
      'payment_address_format': payment_address_format,
      'payment_custom_field': payment_custom_field,
      'payment_method': payment_method,
      'payment_code': payment_code,
      'shipping_firstname': shipping_firstname,
      'shipping_lastname': shipping_lastname,
      'shipping_company': shipping_company,
      'shipping_address_1': shipping_address_1,
      'shipping_address_2': shipping_address_2,
      'shipping_city': shipping_city,
      'shipping_postcode': shipping_postcode,
      'shipping_country': shipping_country,
      'shipping_country_id': shipping_country_id,
      'shipping_zone': shipping_zone,
      'shipping_zone_id': shipping_zone_id,
      'shipping_address_format': shipping_address_format,
      'shipping_custom_field': shipping_custom_field,
      'shipping_code': shipping_code,
      'comment': comment,
      'order_status_id': order_status_id,
      'affiliate_id': affiliate_id,
      'commission': commission,
      'marketing_id': marketing_id,
      'tracking': tracking,
      'language_id': language_id,
      'currency_id': currency_id,
      'currency_code': currency_code,
      'currency_value': currency_value,
      'ip': ip,
      'forwarded_ip': forwarded_ip,
      'user_agent': user_agent,
      'accept_language': accept_language,
      'date_modified': date_modified,
      'products': products.map((product) => product.toJson()).toList(),
    };
  }
}
