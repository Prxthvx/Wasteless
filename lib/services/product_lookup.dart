// lib/services/product_lookup.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

/// small local fallback DB (replace with persistent DB later)
final Map<String, Map<String, String>> localProducts = {
  // "barcode": {"name":"Product Name", "quantity":"400g", "category":"Bread & Pastries"},
  "8901234567890": {"name":"Sample Milk 1L", "quantity":"1 L", "category":"Dairy"},
};

String mapCategoryTagToLocal(String? tag) {
  if (tag == null) return 'Other';
  final t = tag.toLowerCase();
  if (t.contains('milk') || t.contains('dairy')) return 'Dairy';
  if (t.contains('bread') || t.contains('bakery')) return 'Bread & Pastries';
  if (t.contains('fruit') || t.contains('fruits')) return 'Fruits';
  if (t.contains('vegetable') || t.contains('vegetables')) return 'Vegetables';
  if (t.contains('frozen')) return 'Frozen Foods';
  if (t.contains('canned') || t.contains('can') || t.contains('tinned')) return 'Canned Goods';
  return 'Other';
}

/// Returns a map { "name": ..., "quantity": ..., "category": ... } or null if not found.
Future<Map<String, String>?> fetchProductDetails(String barcode) async {
  // 1) check local DB first
  if (localProducts.containsKey(barcode)) {
    return localProducts[barcode];
  }

  // 2) call OpenFoodFacts
  try {
    final url = Uri.parse("https://world.openfoodfacts.org/api/v2/product/$barcode.json");
    final resp = await http.get(url).timeout(const Duration(seconds: 8));
    if (resp.statusCode != 200) return null;

    final data = jsonDecode(resp.body);
    if (data == null) return null;

    // OpenFoodFacts returns status==1 when found
    if (data["status"] == 1) {
      final product = data["product"] ?? {};
      // try multiple fields for product name
      final name = (product["product_name"] ??
                    product["product_name_en"] ??
                    product["generic_name"] ??
                    product["brands"] ??
                    "").toString().trim();
      final quantity = (product["quantity"] ?? "").toString().trim();

      // categories_tags e.g. ["en:milk", "en:milk-products"]
      String category = 'Other';
      if (product["categories_tags"] != null && (product["categories_tags"] as List).isNotEmpty) {
        final firstTag = (product["categories_tags"] as List).first.toString();
        category = mapCategoryTagToLocal(firstTag);
      }

      return {
        "name": name.isEmpty ? "Unknown product" : name,
        "quantity": quantity,
        "category": category,
      };
    } else {
      return null;
    }
  } catch (e) {
    // network error or parse error
    return null;
  }
}
