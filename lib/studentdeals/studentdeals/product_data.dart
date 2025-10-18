import 'product_model.dart';

class ProductData {
  static final List<Product> _products = [];

  static List<Product> getAll() => _products;

  static List<Product> getByAdmin(String adminId) =>
      _products.where((p) => p.adminId == adminId).toList();

  static void add(Product product) {
    _products.add(product);
  }

  static void remove(Product product) {
    _products.removeWhere((p) => p.id == product.id);
  }

  static void delete(String id) {
    _products.removeWhere((p) => p.id == id);
  }
}
