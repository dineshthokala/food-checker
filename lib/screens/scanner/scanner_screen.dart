import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/logger.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    talker.info('ScannerScreen opened');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Scan Food Barcode', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_rounded),
            onPressed: () {
              try {
                controller.toggleTorch();
              } catch (e, st) {
                logScreenError('ScannerScreen', 'Failed to toggle torch', e, st);
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              try {
                if (!_isScanning) return;
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null) {
                    _isScanning = false;
                    talker.info('Barcode found: ${barcode.rawValue}');
                    // Return the barcode value to the previous screen
                    context.pop(barcode.rawValue);
                    break;
                  }
                }
              } catch (e, st) {
                logScreenError('ScannerScreen', 'Failed to process barcode', e, st);
              }
            },
            errorBuilder: (context, error) {
              logScreenError('ScannerScreen', 'Scanner camera error', error);
              return const Center(
                child: Text(
                  'Camera unavailable. Please check permissions.',
                  style: TextStyle(color: Colors.white),
                ),
              );
            },
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.deepTeal, width: 4),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    try {
      controller.dispose();
    } catch (e, st) {
      logScreenError('ScannerScreen', 'Failed to dispose scanner controller', e, st);
    }
    super.dispose();
  }
}
