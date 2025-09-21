import 'package:flutter/material.dart';
import '../../../models/donation.dart';

class RecentActivityCard extends StatelessWidget {
  final List<Donation> recentClaims;
  final List<Donation> recentAvailable;
  final void Function(int tabIndex) onNavigate;
  const RecentActivityCard({super.key, required this.recentClaims, required this.recentAvailable, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => onNavigate(3),
                  child: Text(
                    'View All',
                    style: TextStyle(
                      color: Colors.blue[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (recentClaims.isEmpty && recentAvailable.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No recent activity. Start by claiming donations!',
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              )
            else ...[
              if (recentClaims.isNotEmpty) ...[
                Text(
                  'Recent Claims',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                ...recentClaims.map((claim) => InkWell(
                  onTap: () => onNavigate(3),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.green.shade100,
                          child: Icon(Icons.check_circle, size: 16, color: Colors.green),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                claim.title ?? 'No Title',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                '${claim.quantity ?? ''} • ${claim.status ?? ''}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey[400]),
                      ],
                    ),
                  ),
                )).toList(),
              ],
              if (recentAvailable.isNotEmpty) ...[
                if (recentClaims.isNotEmpty) const SizedBox(height: 16),
                Text(
                  'New Donations Available',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                ...recentAvailable.map((donation) => InkWell(
                  onTap: () => onNavigate(2),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.red.shade100,
                          child: Icon(Icons.favorite, size: 16, color: Colors.red),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                donation.title,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                '${donation.quantity ?? ''} • ${donation.status ?? ''}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey[400]),
                      ],
                    ),
                  ),
                )).toList(),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
