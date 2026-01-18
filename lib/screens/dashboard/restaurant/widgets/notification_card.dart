import 'package:flutter/material.dart';

class NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onTap;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color typeColor = _getColor(notification['type']);
    final IconData typeIcon = _getIcon(notification['type']);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: notification['read'] ? 1 : 3,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          color: notification['read']
              ? Colors.white
              : Colors.blue.shade50,
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: typeColor.withOpacity(0.1),
                child: Icon(typeIcon, color: typeColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification['title'],
                      style: TextStyle(
                        fontWeight: notification['read']
                            ? FontWeight.w500
                            : FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(notification['message']),
                    const SizedBox(height: 4),
                    Text(
                      notification['time'],
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColor(String type) {
    switch (type) {
      case 'warning':
        return Colors.orange;
      case 'recipe':
        return Colors.green;
      case 'donation':
        return Colors.red;
      case 'analytics':
        return Colors.purple;
      case 'feature':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'warning':
        return Icons.warning;
      case 'recipe':
        return Icons.restaurant_menu;
      case 'donation':
        return Icons.favorite;
      case 'analytics':
        return Icons.analytics;
      case 'feature':
        return Icons.new_releases;
      default:
        return Icons.notifications;
    }
  }
}
