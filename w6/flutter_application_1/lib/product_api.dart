import 'dart:convert';

import 'package:http/http.dart' as http;

import 'product_models.dart';

class ProductApi {
  static final endpoint = Uri.parse(
    'https://mock.apidog.com/m1/890655-872447-default/v2/product',
  );

  static Future<List<Product>> fetchProducts() async {
    final response = await http
        .get(endpoint)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception('Không thể tải sản phẩm (HTTP ${response.statusCode}).');
    }
    final dynamic body = jsonDecode(utf8.decode(response.bodyBytes));
    final dynamic data =
        body is Map<String, dynamic> && body.containsKey('data')
        ? body['data']
        : body;
    if (data is List) {
      return data
          .map((item) => Product.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    if (data is Map<String, dynamic>) return [Product.fromJson(data)];
    throw const FormatException('Dữ liệu sản phẩm không hợp lệ.');
  }
}
