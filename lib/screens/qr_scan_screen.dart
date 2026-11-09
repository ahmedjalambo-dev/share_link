import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../l10n/app_localizations.dart';
import '../services/share_channel.dart';
import '../utils/wifi_qr.dart';

/// Full-screen scanner for Phone A's Wi-Fi QR code (camera or a saved photo).
/// Pops with the [WifiQrData] of the first valid Share Link code.
class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );

  /// Set once a valid code was found, so a second detection can't pop twice.
  bool _done = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Returns true if [capture] held a Share Link code (and the screen was closed).
  bool _handle(BarcodeCapture? capture) {
    if (_done || capture == null) return false;
    for (final barcode in capture.barcodes) {
      final data = barcode.rawValue == null
          ? null
          : parseWifiQr(barcode.rawValue!);
      if (data != null && data.isShareLinkNetwork) {
        _done = true;
        Navigator.of(context).pop(data);
        return true;
      }
    }
    if (capture.barcodes.isNotEmpty) {
      _showSnack(AppLocalizations.of(context).scanNotShareLink);
    }
    return false;
  }

  Future<void> _pickPhoto() async {
    final l = AppLocalizations.of(context);
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image == null || !mounted) return;
    final capture = await _controller.analyzeImage(
      image.path,
      formats: const [BarcodeFormat.qrCode],
    );
    if (!mounted) return;
    if (capture == null || capture.barcodes.isEmpty) {
      _showSnack(l.scanNoCodeInImage);
    } else {
      _handle(capture);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(l.scanTitle),
        actions: [
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _controller,
            builder: (context, state, _) {
              if (state.torchState == TorchState.unavailable) {
                return const SizedBox.shrink();
              }
              return IconButton(
                tooltip: l.scanTorch,
                icon: Icon(
                  state.torchState == TorchState.on
                      ? Icons.flash_on
                      : Icons.flash_off,
                ),
                onPressed: _controller.toggleTorch,
              );
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handle,
            errorBuilder: (context, error) => _CameraError(error: error),
          ),
          const _ScanFrame(),
          Positioned(
            left: 16,
            right: 16,
            bottom: 32,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l.scanHint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  onPressed: _pickPhoto,
                  icon: const Icon(Icons.photo_library),
                  label: Text(l.scanFromPhoto),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Square guide in the middle of the camera preview.
class _ScanFrame extends StatelessWidget {
  const _ScanFrame();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 3),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

/// Shown instead of the preview when the camera can't start (e.g. permission
/// denied). Choosing a photo still works.
class _CameraError extends StatelessWidget {
  const _CameraError({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography, color: Colors.white, size: 48),
              const SizedBox(height: 16),
              Text(
                denied ? l.scanCameraDenied : l.scanCameraUnavailable,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
              if (denied) ...[
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => ShareChannel.openSystemSettings('app'),
                  child: Text(l.openAppSettings),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
