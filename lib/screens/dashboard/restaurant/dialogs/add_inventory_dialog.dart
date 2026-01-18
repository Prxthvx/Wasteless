import 'package:flutter/material.dart';
import '../../../../models/inventory_item.dart';
import '../../../../models/user_profile.dart';
import '../../../../services/barcode_lookup_service.dart';
import '../../../scanner_screen.dart';

class AddInventoryDialog extends StatefulWidget {
  final UserProfile profile;
  final void Function(InventoryItem item) onItemAdded;

  const AddInventoryDialog({
    super.key,
    required this.profile,
    required this.onItemAdded,
  });

  @override
  State<AddInventoryDialog> createState() => _AddInventoryDialogState();
}

class _AddInventoryDialogState extends State<AddInventoryDialog> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  DateTime _expiryDate = DateTime.now().add(const Duration(days: 1));
  String _category = 'Other';

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final item = InventoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      restaurantId: widget.profile.id,
      name: _nameController.text.trim(),
      quantity: _quantityController.text.trim(),
      category: _category,
      expiryDate: _expiryDate,
      status: 'available',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    widget.onItemAdded(item);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Inventory Item'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Item Name'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Quantity'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: const [
                  DropdownMenuItem(value: 'Vegetables', child: Text('Vegetables')),
                  DropdownMenuItem(value: 'Fruits', child: Text('Fruits')),
                  DropdownMenuItem(value: 'Dairy', child: Text('Dairy')),
                  DropdownMenuItem(value: 'Bread & Pastries', child: Text('Bread & Pastries')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (value) => setState(() => _category = value!),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Expiry Date'),
                subtitle: Text(
                  _expiryDate.toString().split(' ').first,
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _expiryDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() => _expiryDate = picked);
                  }
                },
              ),
              const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Scan Barcode'),
                      onPressed: () async {
                          final result = await Navigator.push<String>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ScannerScreen(),
                            ),
                          );

                          if (result == null || result.isEmpty) return;

                          final product =
                              await BarcodeLookupService.fetchProductFromBarcode(result);

                          if (!mounted) return;

                          setState(() {
                            _nameController.text =
                                product['name']?.trim().isNotEmpty == true
                                    ? product['name']!
                                    : 'Unknown Product';

                            _quantityController.text =
                                product['quantity']?.trim().isNotEmpty == true
                                    ? product['quantity']!
                                    : '1';

                            const allowedCategories = [
                              'Vegetables',
                              'Fruits',
                              'Dairy',
                              'Bread & Pastries',
                              'Canned Goods',
                              'Frozen Foods',
                              'Other',
                            ];

                            final apiCategory = product['category'] ?? 'Other';
                            _category =
                                allowedCategories.contains(apiCategory) ? apiCategory : 'Other';
                          });
                        },
                    ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Add Item'),
        ),
      ],
    );
  }

}
