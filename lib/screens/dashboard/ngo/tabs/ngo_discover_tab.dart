import 'package:flutter/material.dart';
import '../../../../models/donation.dart';
import '../view_model/ngo_dashboard_view_model.dart';
import '../../components/nd_view_map.dart';

class NgoDiscoverTab extends StatelessWidget {

  final NGODashboardViewModel viewModel;
  final Future<void> Function() onRefresh;

  const NgoDiscoverTab({
    super.key,
    required this.viewModel,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final availableDonations = viewModel.availableDonations;

        return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MapSection(donations: availableDonations),
          const SizedBox(height: 16),

          _RefreshButton(onRefresh: onRefresh),
          const SizedBox(height: 12),

          const _SearchAndFilterSection(),
          const SizedBox(height: 16),

          _NearbyRestaurantsSection(donations: availableDonations),
        ],
      ),
    );
  }
}

class _MapSection extends StatelessWidget {
  final List<Donation> donations;

  const _MapSection({required this.donations});

  @override
  Widget build(BuildContext context) {
    return NDViewMap(donations: donations);
  }
}

class _RefreshButton extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _RefreshButton({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.refresh),
        label: const Text('Refresh'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        onPressed: () async {
          await onRefresh();
        },
      ),
    );
  }
}

class _SearchAndFilterSection extends StatelessWidget {
  const _SearchAndFilterSection();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Search & Filters',
              style: Theme.of(context).textTheme.titleLarge,
            ),
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
                      onChanged: (_) {},
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
                      onChanged: (_) {},
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NearbyRestaurantsSection extends StatelessWidget {
  final List<Donation> donations;

  const _NearbyRestaurantsSection({required this.donations});

  @override
  Widget build(BuildContext context) {
    final restaurants = donations.where((d) => d.restaurantProfile != null).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nearby Restaurants',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (restaurants.isEmpty)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'No nearby restaurants found.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              )
            else
              ...restaurants.map((donation) {
                final profile = donation.restaurantProfile!;
                final donationCount = donations
                    .where((d) => d.restaurantProfile?.id == profile.id)
                    .length;

                return _RestaurantCard(
                  name: profile.name,
                  distance: profile.location,
                  subtitle: '$donationCount donation${donationCount > 1 ? 's' : ''} available',
                );
              }),
          ],
        ),
      ),
    );
  }
}


class _RestaurantCard extends StatelessWidget {
  final String name;
  final String distance;
  final String subtitle;

  const _RestaurantCard({
    required this.name,
    required this.distance,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.restaurant),
      title: Text(name),
      subtitle: Text('$subtitle • $distance'),
    );
  }
}
