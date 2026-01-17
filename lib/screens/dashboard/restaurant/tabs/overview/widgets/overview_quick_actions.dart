import 'package:flutter/material.dart';

class OverviewQuickActions extends StatelessWidget {
  const OverviewQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),

        // TEMPORARY placeholder
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Quick action buttons will appear here.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ],
    );
  }
}
