import 'package:flutter/material.dart';
import '../../../../models/inventory_item.dart';
import '../../../../models/user_profile.dart';

class EditInventoryDialog extends StatefulWidget {
  final UserProfile profile;
  final InventoryItem item;
  final Future<void> Function(InventoryItem) onItemUpdated;

  const EditInventoryDialog({
    super.key,
    required this.profile,
    required this.item,
    required this.onItemUpdated,
  });

  @override
  State<EditInventoryDialog> createState() => _EditInventoryDialogState();
}

class _EditInventoryDialogState extends State<EditInventoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _quantityCtrl;
  late String _category;
  late DateTime _expiryDate;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item.name);
    _quantityCtrl = TextEditingController(text: widget.item.quantity);
    _category = widget.item.category;
    _expiryDate = widget.item.expiryDate;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _quantityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Inventory Item'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Item Name',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityCtrl,
              decoration: const InputDecoration(
                labelText: 'Quantity (e.g., 5 kg, 10 units)',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Fruits', child: Text('Fruits')),
                DropdownMenuItem(value: 'Vegetables', child: Text('Vegetables')),
                DropdownMenuItem(value: 'Dairy', child: Text('Dairy')),
                DropdownMenuItem(value: 'Bread & Pastries', child: Text('Bread & Pastries')),
                DropdownMenuItem(value: 'Canned Goods', child: Text('Canned Goods')),
                DropdownMenuItem(value: 'Frozen Foods', child: Text('Frozen Foods')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (value) => setState(() => _category = value ?? 'Fruits'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text('Expiry Date: ${_expiryDate.toString().split(' ')[0]}'),
                ),
                TextButton(
                  onPressed: () async {
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
                  child: const Text('Pick Date'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final updatedItem = InventoryItem(
                id: widget.item.id,
                restaurantId: widget.item.restaurantId,
                name: _nameCtrl.text.trim(),
                quantity: _quantityCtrl.text.trim(),
                category: _category,
                expiryDate: _expiryDate,
                status: widget.item.status,
                createdAt: widget.item.createdAt,
                updatedAt: DateTime.now(),
              );
              
              await widget.onItemUpdated(updatedItem);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('Update Item'),
        ),
      ],
    );
  }
}