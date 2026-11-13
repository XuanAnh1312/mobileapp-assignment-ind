class Product {
  final String id;
  final String name;
  final double price;
  final String image;
  final String description;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    required this.description,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final price = json['price'];
    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Sản phẩm',
      price: price is num ? price.toDouble() : double.tryParse('$price') ?? 0,
      image:
          (json['imgURL'] ?? json['image'] ?? json['imageUrl'])?.toString() ??
          '',
      description: (json['des'] ?? json['description'])?.toString() ?? '',
    );
  }

  String get formattedPrice {
    final parts = price
        .toStringAsFixed(price == price.roundToDouble() ? 0 : 2)
        .split('.');
    final integer = parts.first.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    return '$integer${parts.length > 1 ? ',${parts[1]}' : ''}đ';
  }
}
