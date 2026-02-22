import 'package:flutter/material.dart';
import '../../../../models/inventory_item.dart';
import '../../../../models/user_profile.dart';
import '../../../../models/donation.dart';

class PostDonationDialog extends StatefulWidget {
  final UserProfile profile;
  final InventoryItem item;
  final Future<void> Function(Donation) onDonationPosted;

  const PostDonationDialog({
    super.key,
    required this.profile,
    required this.item,
    required this.onDonationPosted,
  });

  @override
  State<PostDonationDialog> createState() => _PostDonationDialogState();
}

class _PostDonationDialogState extends State<PostDonationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleCtrl.text = widget.item.name;
    _descriptionCtrl.text = 'Fresh ${widget.item.name} available for donation';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Post as Donation'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Donation Title',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionCtrl,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Item Details:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800])),
                  Text('Quantity: ${widget.item.quantity}'),
                  Text('Category: ${widget.item.category}'),
                  Text('Expires: ${widget.item.expiryDate.toString().split(' ')[0]}'),
                ],
              ),
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
              final donation = Donation(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                inventoryItemId: widget.item.id,
                restaurantId: widget.profile.id,
                title: _titleCtrl.text.trim(),
                description: _descriptionCtrl.text.trim(),
                quantity: widget.item.quantity,
                expiryDate: widget.item.expiryDate,
                status: 'available',
                postedAt: DateTime.now(),
              );
              await widget.onDonationPosted(donation);
              // Navigation and snackbar are handled in the callback
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Post Donation'),
        ),
      ],
    );
  }
}
