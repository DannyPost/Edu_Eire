// lib/studentdeals/studentdeals/product_data.dart
import 'product_model.dart';

class ProductData {
  static final List<Product> _products = <Product>[];

  static List<Product> getAll() => List.unmodifiable(_products);

  /// Flexible lookup: will match against `adminId`, `adminIdLower`, or `admin`.
  /// - Exact match on `adminId` or `admin`
  /// - Case-insensitive match on `adminIdLower`
  static List<Product> getByAdmin(String email) {
    final wantLower = email.toLowerCase();
    return _products.where((p) {
      // We avoid changing your model by reading via `dynamic` and falling back.
      final d = p as dynamic;
      try {
        final adminId       = (d.adminId       as String?);
        final adminIdLower  = (d.adminIdLower  as String?);
        final admin         = (d.admin         as String?);

        if (adminId != null && adminId == email) return true;
        if (admin != null && admin == email) return true;
        if (adminIdLower != null && adminIdLower == wantLower) return true;

      } catch (_) {
        // If a field doesn't exist on the current model, just ignore it.
      }
      return false;
    }).toList();
  }

  static void add(Product product) => _products.add(product);

  static void remove(Product product) =>
      _products.removeWhere((p) => p.id == product.id);

  static void delete(String id) =>
      _products.removeWhere((p) => p.id == id);
}
