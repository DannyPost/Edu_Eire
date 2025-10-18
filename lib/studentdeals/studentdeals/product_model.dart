// lib/product_model.dart
class Product {
  final String id;
  final String title;
  final String description;
  final double price;
  final int supply;
  final String sector;
  final String location;
  final String mode;
  final String imageUrl;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.supply,
    required this.sector,
    required this.location,
    required this.mode,
    required this.imageUrl,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    // SAFELY parse all fields, fallback if missing
    return Product(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      price: _parseDouble(map['price']),
      supply: _parseInt(map['supply']),
      sector: map['sector']?.toString() ?? '',
      location: map['location']?.toString() ?? '',
      mode: map['mode']?.toString() ?? '',
      imageUrl: map['imageUrl']?.toString() ?? '',
    );
  }

  static double _parseDouble(dynamic v) {
    if (v is int) return v.toDouble();
    if (v is double) return v;
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}
