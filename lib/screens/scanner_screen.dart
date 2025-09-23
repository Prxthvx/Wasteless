import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerScreen extends StatefulWidget {
  final Function(String) onScanned;

  const ScannerScreen({super.key, required this.onScanned});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController cameraController = MobileScannerController();
  bool _scanned = false; //  prevent multiple triggers

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Barcode"),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: MobileScanner(
        controller: cameraController,
        onDetect: (capture) {
          if (_scanned) return;
          for (final barcode in capture.barcodes) {
            final String? code = barcode.rawValue;
            if (code != null) {
              _scanned = true;
              widget.onScanned(code);
              Navigator.pop(context); // ✅ close scanner
              break;
            }
          }
        },
      ),
    );
  }
}
