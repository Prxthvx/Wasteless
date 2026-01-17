import 'package:flutter/material.dart';
import '../../../../models/donation.dart';

class NgoMyClaimsTab extends StatelessWidget {
  final bool isLoading;
  final List<Donation> claimedDonations;
  final void Function(String action, Donation donation) onAction;

  const NgoMyClaimsTab({
    super.key,
    required this.isLoading,
    required this.claimedDonations,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        _ClaimsSummarySection(claimedDonations: claimedDonations),
        Expanded(
          child: _ClaimsList(
            claimedDonations: claimedDonations,
            onAction: onAction,
          ),
        ),
      ],
    );
  }
}

class _ClaimsSummarySection extends StatelessWidget {
  final List<Donation> claimedDonations;

  const _ClaimsSummarySection({required this.claimedDonations});

  @override
  Widget build(BuildContext context) {
    final totalClaims = claimedDonations.length;
    final activeClaims =
        claimedDonations.where((d) => d.status == 'claimed').length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Claims: $totalClaims',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Active: $activeClaims',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClaimsList extends StatelessWidget {
  final List<Donation> claimedDonations;
  final void Function(String action, Donation donation) onAction;

  const _ClaimsList({
    required this.claimedDonations,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    if (claimedDonations.isEmpty) {
      return const Center(
        child: Text('No claims found.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: claimedDonations.length,
      itemBuilder: (context, index) {
        final donation = claimedDonations[index];
        return _ClaimCard(
          donation: donation,
          onAction: onAction,
        );
      },
    );
  }
}

class _ClaimCard extends StatelessWidget {
  final Donation donation;
  final void Function(String action, Donation donation) onAction;

  const _ClaimCard({
    required this.donation,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _statusColor(donation.status),
          child: Icon(
            _statusIcon(donation.status),
            color: Colors.white,
          ),
        ),
        title: Text(donation.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quantity: ${donation.quantity}'),
            Text('Status: ${donation.status.toUpperCase()}'),
            if (donation.claimedAt != null)
              Text(
                'Claimed: ${donation.claimedAt!.toString().split(' ')[0]}',
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'details',
              child: Text('View Details'),
            ),
            const PopupMenuItem(
              value: 'contact',
              child: Text('Contact Restaurant'),
            ),
            if (donation.status == 'claimed')
              const PopupMenuItem(
                value: 'complete',
                child: Text('Mark Complete'),
              ),
          ],
          onSelected: (value) => onAction(value, donation),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'claimed':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'claimed':
        return Icons.pending;
      case 'completed':
        return Icons.check_circle;
      default:
        return Icons.help_outline;
    }
  }
}
