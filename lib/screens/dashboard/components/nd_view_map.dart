import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../models/donation.dart';

class NDViewMap extends StatefulWidget {
  final List<Donation> donations;

  const NDViewMap({super.key, required this.donations});

  @override
  State<NDViewMap> createState() => _NDViewMapState();
}

class _NDViewMapState extends State<NDViewMap> {
  double _zoom = 12.5;
  bool _fullscreen = false;
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  Widget build(BuildContext context) {
    final validDonations = widget.donations.where((d) =>
      d.restaurantProfile != null &&
      d.restaurantProfile?.latitude != null &&
      d.restaurantProfile?.longitude != null
    ).toList();

    LatLng mapCenter = const LatLng(12.9716, 77.5946);
    if (validDonations.isNotEmpty) {
      final first = validDonations.first.restaurantProfile;
      mapCenter = LatLng(first?.latitude ?? 12.9716, first?.longitude ?? 77.5946);
    }

    Widget mapWidget = Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            center: mapCenter,
            zoom: _zoom,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.wasteless',
            ),
            MarkerLayer(
              markers: validDonations.map((donation) {
                final profile = donation.restaurantProfile;
                return Marker(
                  width: 40,
                  height: 40,
                  point: LatLng(profile?.latitude ?? 12.9716, profile?.longitude ?? 77.5946),
                  child: GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: Text(profile?.name ?? 'Unknown'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Donation: ${donation.title}'),
                              Text('Quantity: ${donation.quantity}'),
                              Text('Expires: ${donation.expiryDate.toString().split(' ')[0]}'),
                              if ((donation.description ?? '').isNotEmpty)
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
        Positioned(
          top: 12,
          right: 12,
          child: Column(
            children: [
              FloatingActionButton(
                heroTag: 'zoom_in',
                mini: true,
                onPressed: () {
                  setState(() {
                    _zoom = (_zoom + 1).clamp(1.0, 18.0);
                    _mapController.move(_mapController.center, _zoom);
                  });
                },
                child: const Icon(Icons.zoom_in),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: 'zoom_out',
                mini: true,
                onPressed: () {
                  setState(() {
                    _zoom = (_zoom - 1).clamp(1.0, 18.0);
                    _mapController.move(_mapController.center, _zoom);
                  });
                },
                child: const Icon(Icons.zoom_out),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: 'fullscreen',
                mini: true,
                onPressed: () => setState(() => _fullscreen = !_fullscreen),
                child: Icon(_fullscreen ? Icons.fullscreen_exit : Icons.fullscreen),
              ),
            ],
          ),
        ),
      ],
    );

    if (_fullscreen) {
      return Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => setState(() => _fullscreen = false),
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            color: Colors.black.withOpacity(0.1),
            child: mapWidget,
          ),
        ),
      );
    }

    return SizedBox(
      height: 300,
      child: mapWidget,
    );
  }
}