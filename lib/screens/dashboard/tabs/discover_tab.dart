import 'package:flutter/material.dart';
import '../../../models/donation.dart';
import '../components/nd_view_map.dart';

class DiscoverTab extends StatelessWidget {
  final List<Donation> availableDonations;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final void Function(String restaurantName) onShowRestaurantDetails;

  const DiscoverTab({
    Key? key,
    required this.availableDonations,
    required this.isLoading,
    required this.onRefresh,
    required this.onShowRestaurantDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NDViewMap(donations: availableDonations),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              onPressed: isLoading ? null : onRefresh,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Search & Filters', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search donations...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 180,
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('All Categories')),
                              DropdownMenuItem(value: 'vegetables', child: Text('Vegetables')),
                              DropdownMenuItem(value: 'fruits', child: Text('Fruits')),
                              DropdownMenuItem(value: 'dairy', child: Text('Dairy')),
                              DropdownMenuItem(value: 'bread', child: Text('Bread & Pastries')),
                            ],
                            onChanged: (value) {},
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 140,
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Distance',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: '5', child: Text('5 km')),
                              DropdownMenuItem(value: '10', child: Text('10 km')),
                              DropdownMenuItem(value: '20', child: Text('20 km')),
                            ],
                            onChanged: (value) {},
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nearby Restaurants', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  ...availableDonations
                    .where((d) => d.restaurantProfile != null)
                    .map((donation) {
                      final profile = donation.restaurantProfile;
                      if (profile == null) return const SizedBox.shrink();
                      final donationCount = availableDonations.where((d) => d.restaurantProfile?.id == profile.id).length;
                      String distance = profile.location;
                      return _buildRestaurantCard(
                        context,
                        profile.name,
                        distance,
                        '$donationCount donation${donationCount > 1 ? 's' : ''} available',
                      );
                    })
                    .toList(),
                  if (availableDonations.where((d) => d.restaurantProfile != null).isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text('No nearby restaurants found.', style: TextStyle(color: Colors.grey[600])),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantCard(BuildContext context, String name, String distance, String donations) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(Icons.restaurant, color: Colors.white),
        ),
        title: Text(name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(distance),
            Text(donations, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => onShowRestaurantDetails(name),
      ),
    );
  }
}
