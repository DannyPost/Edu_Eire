class Product {
  final String id;
  final String adminId;
  final String title;
  final String description;
  final double price;
  final String sector;
  final String location;
  final String mode;
  final String? imageUrl;
  final String? stripeUrl;
  final int supply;

  Product({
    required this.id,
    required this.adminId,
    required this.title,
    required this.description,
    required this.price,
    required this.sector,
    required this.location,
    required this.mode,
    this.imageUrl,
    this.stripeUrl,
    required this.supply,
  });

  factory Product.fromMap(Map<String, dynamic> data, [String? id]) {
    return Product(
      id: id ?? data['id'] ?? '',
      adminId: data['adminId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      sector: data['sector'] ?? '',
      location: data['location'] ?? '',
      mode: data['mode'] ?? '',
      imageUrl: data['imageUrl'],
      stripeUrl: data['stripeUrl'],
      supply: (data['supply'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'adminId': adminId,
      'title': title,
      'description': description,
      'price': price,
      'sector': sector,
      'location': location,
      'mode': mode,
      'imageUrl': imageUrl,
      'stripeUrl': stripeUrl,
      'supply': supply,
    };
  }

  // So Product can be used as Map key (e.g. in cart)
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
