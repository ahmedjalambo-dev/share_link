import 'package:flutter/material.dart';

import 'wifi_qr_view.dart';

/// Shows the Wi-Fi QR code in a bottom sheet.
Future<void> showQrSheet(
  BuildContext context, {
  required String ssid,
  required String password,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: WifiQrView(ssid: ssid, password: password),
      ),
    ),
  );
}
