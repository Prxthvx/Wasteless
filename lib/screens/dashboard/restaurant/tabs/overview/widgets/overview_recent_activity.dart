import 'package:flutter/material.dart';

class OverviewRecentActivity extends StatelessWidget {
  const OverviewRecentActivity({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),

        // TEMPORARY placeholder
        // Replace this later with real recent activity widget
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Recent activity will appear here.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ],
    );
  }
}
