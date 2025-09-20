import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../models/donation.dart';

class NDViewMap extends StatelessWidget {
  final List<Donation> donations;

  const NDViewMap({super.key, required this.donations});

  @override
  Widget build(BuildContext context) {
    // Filter donations with valid coordinates
    final validDonations = donations.where((d) =>
      d.restaurantProfile != null &&
      d.restaurantProfile!.latitude != null &&
      d.restaurantProfile!.longitude != null
    ).toList();

    // Center map on first valid donation, else default to Bengaluru
    LatLng mapCenter = const LatLng(12.9716, 77.5946);
    if (validDonations.isNotEmpty) {
      final first = validDonations.first.restaurantProfile!;
      mapCenter = LatLng(first.latitude!, first.longitude!);
    }

    return SizedBox(
      height: 300,
      child: FlutterMap(
        options: MapOptions(
          center: mapCenter,
          zoom: 12.5,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.wasteless',
          ),
          MarkerLayer(
            markers: validDonations.map((donation) {
              final profile = donation.restaurantProfile!;
              return Marker(
                width: 40,
                height: 40,
                point: LatLng(profile.latitude!, profile.longitude!),
                child: GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: Text(profile.name),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Donation: ${donation.title}'),
                            Text('Quantity: ${donation.quantity}'),
                            Text('Expires: ${donation.expiryDate.toString().split(' ')[0]}'),
                            if (donation.description != null && donation.description!.isNotEmpty)
                              Text('Description: ${donation.description}'),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 36,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}