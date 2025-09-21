import 'dart:convert';
import 'package:http/http.dart' as http;

class BarcodeLookupService {
  static Future<Map<String, String>> fetchProductFromBarcode(String code) async {
    final url = Uri.parse("https://world.openfoodfacts.org/api/v0/product/$code.json");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 1) {
          final product = data['product'];
          return {
            'name': product['product_name'] ?? "Unknown Product",
            'quantity': product['quantity'] ?? "1",
            'category': (product['categories_tags'] != null && product['categories_tags'].isNotEmpty)
                ? product['categories_tags'][0].toString().replaceAll('en:', '')
                : "Other",
          };
        }
      }
      return {'name': "Unknown item ($code)", 'quantity': "", 'category': "Other"};
    } catch (e) {
      return {'name': "Error fetching product", 'quantity': "", 'category': "Other"};
    }
  }
}
