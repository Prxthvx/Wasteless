import 'package:flutter/material.dart';
import '../../../../models/donation.dart';

class NgoAvailableDonationsTab extends StatelessWidget {
  final bool isLoading;
  final List<Donation> donations;
  final Future<void> Function() onRefresh;
  final void Function(Donation donation) onClaim;

  const NgoAvailableDonationsTab({
    super.key,
    required this.isLoading,
    required this.donations,
    required this.onRefresh,
    required this.onClaim,
  });

    @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        _HeaderSection(
          donationCount: donations.length,
          isLoading: isLoading,
          onRefresh: onRefresh,
        ),
        Expanded(
          child: _DonationList(
            donations: donations,
            onClaim: onClaim,
          ),
        ),
      ],
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final int donationCount;
  final bool isLoading;
  final Future<void> Function() onRefresh;

  const _HeaderSection({
    required this.donationCount,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.favorite, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$donationCount donations available',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Tap on any donation to claim it',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            onPressed: isLoading ? null : onRefresh,
          ),
        ],
      ),
    );
  }
}

class _DonationList extends StatelessWidget {
  final List<Donation> donations;
  final void Function(Donation donation) onClaim;

  const _DonationList({
    required this.donations,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    if (donations.isEmpty) {
      return const Center(
        child: Text('No available donations at the moment.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: donations.length,
      itemBuilder: (context, index) {
        final donation = donations[index];
        return _DonationCard(
          donation: donation,
          onClaim: onClaim,
        );
      },
    );
  }
}


class _DonationCard extends StatelessWidget {
  final Donation donation;
  final void Function(Donation donation) onClaim;

  const _DonationCard({
    required this.donation,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final daysUntilExpiry =
        donation.expiryDate.difference(DateTime.now()).inDays;
    final isExpired = donation.expiryDate.isBefore(DateTime.now());

    final isUrgent = daysUntilExpiry <= 2;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isUrgent ? Colors.orange : Colors.green,
          child: Icon(
            isUrgent ? Icons.warning : Icons.favorite,
            color: Colors.white,
          ),
        ),
        title: Text(donation.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quantity: ${donation.quantity}'),
            Text(
              'Expires: ${donation.expiryDate.toString().split(' ')[0]} ($daysUntilExpiry days)',
              style: TextStyle(
                color: isUrgent ? Colors.orange : Colors.grey[600],
                fontWeight:
                    isUrgent ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (donation.description != null)
              Text(
                donation.description!,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: isExpired ? null :() => onClaim(donation),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: Text(isExpired ? 'Expired' : 'Claim'),
        ),
      ),
    );
  }
}

