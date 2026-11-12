// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Share Link';

  @override
  String get start => 'START';

  @override
  String get stop => 'STOP';

  @override
  String get statusStopped => 'Stopped';

  @override
  String get statusStarting => 'Starting…';

  @override
  String get statusRunning => 'Running';

  @override
  String get statusError => 'Error';

  @override
  String get hintStopped => 'Connect to Wi-Fi, then tap Start.';

  @override
  String get networkName => 'Network name';

  @override
  String get password => 'Password';

  @override
  String get proxyIp => 'Proxy IP';

  @override
  String get proxyPort => 'Proxy port';

  @override
  String get copy => 'Copy';

  @override
  String copied(String label) {
    return '$label copied';
  }

  @override
  String get connections => 'Connections';

  @override
  String get upload => 'Upload';

  @override
  String get download => 'Download';

  @override
  String get wifiLost => 'Wi-Fi lost. Sharing resumes when it\'s back.';

  @override
  String get permissionRequired => 'Sharing needs the Wi-Fi Direct permission.';

  @override
  String get settingsAction => 'Settings';

  @override
  String get errorPermissionDenied =>
      'Wi-Fi Direct permission denied. Allow it in the app settings.';

  @override
  String get errorLocationDisabled =>
      'Turn on Location. Android needs it for Wi-Fi Direct.';

  @override
  String get errorWifiDisabled => 'Turn on Wi-Fi and connect to a network.';

  @override
  String get errorWifiNotConnected =>
      'Connect this phone to a Wi-Fi network with internet.';

  @override
  String get errorP2pUnsupported => 'This phone does not support Wi-Fi Direct.';

  @override
  String get errorP2pBusy =>
      'Wi-Fi Direct is busy. Turn Wi-Fi off and on, then try again.';

  @override
  String get errorInvalidSettings => 'The network name or password is invalid.';

  @override
  String get errorServiceFailed => 'Could not start the background service.';

  @override
  String get errorPortInUse =>
      'Another app uses this port. Choose another one in Settings.';

  @override
  String get errorProxyFailed => 'Could not start the proxy server.';

  @override
  String get errorGeneric => 'Could not create the Wi-Fi Direct group.';

  @override
  String get openAppSettings => 'App settings';

  @override
  String get openLocationSettings => 'Location settings';

  @override
  String get openWifiSettings => 'Wi-Fi settings';

  @override
  String get qrTitle => 'Scan to join';

  @override
  String get qrCaption =>
      'Scan it with Share Link on the other phone to connect in one step.';

  @override
  String guideStep1(String ssid) {
    return 'Join \"$ssid\" in Wi-Fi settings, or scan the QR code.';
  }

  @override
  String guideStep2(String password) {
    return 'Password: $password';
  }

  @override
  String get guideStep3 =>
      'Open the network\'s settings (gear icon or long-press) → Advanced.';

  @override
  String guideStep4(String host, String port) {
    return 'Proxy: Manual, host $host, port $port. Save.';
  }

  @override
  String get guideStep5 => 'If it says \"No internet\", stay connected anyway.';

  @override
  String get guideNote =>
      'WhatsApp and calls need Share Link on the other phone.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get sectionNetwork => 'Wi-Fi Direct network';

  @override
  String networkNameHelper(String fullName) {
    return 'Full name: $fullName';
  }

  @override
  String get customNetworkUnsupported =>
      'On this Android version the name and password are set automatically. Only the port can change.';

  @override
  String get passwordHelper => '8–63 characters';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get generatePassword => 'Generate password';

  @override
  String get portHelper => '1024–65535 (default 8282)';

  @override
  String get save => 'Save';

  @override
  String get saved => 'Settings saved';

  @override
  String get restartToApply => 'Saved. Restart sharing to apply.';

  @override
  String get restart => 'Restart';

  @override
  String get sectionLanguage => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get batteryRestricted => 'Battery optimization is on';

  @override
  String get batteryRestrictedBody =>
      'Android may stop sharing when the screen is off.';

  @override
  String get batteryAllow => 'Allow';

  @override
  String get batteryUnrestricted => 'Battery optimization is off';

  @override
  String get batteryUnrestrictedBody =>
      'Sharing keeps running in the background.';

  @override
  String get errorInvalidName => 'Enter a network name.';

  @override
  String get errorNameTooLong => 'The name is too long.';

  @override
  String get errorInvalidPassword =>
      'Use 8–63 English letters, numbers or symbols.';

  @override
  String get errorInvalidPort => 'Use a port between 1024 and 65535.';

  @override
  String get modeShare => 'Share Wi-Fi';

  @override
  String get modeConnect => 'Connect';

  @override
  String get connect => 'CONNECT';

  @override
  String get disconnect => 'DISCONNECT';

  @override
  String get clientDisconnected => 'Disconnected';

  @override
  String get clientConnecting => 'Connecting…';

  @override
  String get clientConnected => 'Connected';

  @override
  String get clientPhoneA => 'Sharing phone';

  @override
  String get clientPortHelper => 'As shown on the sharing phone (default 8282)';

  @override
  String get clientStepsTitle => 'Get internet from the sharing phone';

  @override
  String get clientStep1 => 'Join the \"DIRECT-…\" network in Wi-Fi settings.';

  @override
  String get clientStep2 =>
      'If that network has a manual proxy, set it to None.';

  @override
  String get clientStep3 => 'Tap CONNECT and accept the VPN request.';

  @override
  String get clientBankNote =>
      'Some bank apps won\'t open while a VPN is on. That\'s the bank\'s choice.';

  @override
  String get errorVpnDenied => 'VPN not allowed. Tap CONNECT and choose OK.';

  @override
  String get errorNotOnDirect => 'Join the shared \"DIRECT-…\" network first.';

  @override
  String get errorHostUnreachable =>
      'Can\'t reach the sharing phone. Make sure sharing is on.';

  @override
  String get errorVpnFailed => 'Could not start the VPN tunnel.';

  @override
  String get errorConnectionLost =>
      'Connection lost. Rejoin the network and connect again.';

  @override
  String get clientNetworkTitle => 'Shared network';

  @override
  String get clientAutoJoin => 'Join automatically';

  @override
  String get clientAutoJoinHelp =>
      'Joins the network when you connect and leaves it when you disconnect.';

  @override
  String get clientSsidHintAny => 'Optional. Leave empty to pick from a list.';

  @override
  String get clientSsidHintExact => 'Exactly as shown on the sharing phone.';

  @override
  String get clientJoining => 'Joining the network…';

  @override
  String get clientAutoStep1 =>
      'Enter the password shown on the sharing phone, or scan its QR code.';

  @override
  String get clientAutoStep2 => 'Tap CONNECT and accept the requests.';

  @override
  String get errorJoinFailed =>
      'Couldn\'t join. Make sure sharing is on and the password is right.';

  @override
  String clientReconnecting(int attempt) {
    return 'Reconnecting… (attempt $attempt)';
  }

  @override
  String get clientReconnectingHelp =>
      'Can\'t reach the sharing phone. Retrying automatically.';

  @override
  String get scanQr => 'Scan QR code';

  @override
  String get scanTitle => 'Scan QR code';

  @override
  String get scanHint =>
      'Point the camera at the QR code on the sharing phone.';

  @override
  String get scanFromPhoto => 'Choose a photo';

  @override
  String get scanTorch => 'Flashlight';

  @override
  String get scanNotShareLink => 'This isn\'t a Share Link QR code.';

  @override
  String get scanNoCodeInImage => 'No QR code found in this picture.';

  @override
  String get scanCameraDenied =>
      'Allow the camera in the app settings, or choose a photo.';

  @override
  String get scanCameraUnavailable =>
      'The camera isn\'t available. Choose a photo instead.';

  @override
  String get sectionTile => 'Quick Settings tile';

  @override
  String get tileAddButton => 'Add Quick Settings tile';

  @override
  String get tileAddHint =>
      'Open Quick Settings, tap the pencil, and drag the Share Link tile in.';

  @override
  String get tileAdded => 'Tile added.';

  @override
  String get tileAlreadyAdded => 'The tile is already added.';

  @override
  String get tileNotAdded => 'The tile wasn\'t added.';

  @override
  String get errorSetupNeeded =>
      'Enter the password or scan the QR code first.';

  @override
  String get guideTelegramTitle => 'Telegram';

  @override
  String guideTelegram(String host, String port) {
    return 'Settings → Data and Storage → Proxy Settings → Add Proxy → SOCKS5, with server $host and port $port.';
  }

  @override
  String get guideWhatsAppTitle => 'WhatsApp';

  @override
  String guideWhatsApp(String host) {
    return 'Settings → Storage and data → Proxy → Use proxy. Host $host, chat port 5222, media port 7777. Calls won\'t work.';
  }

  @override
  String get guideNoteWithWhatsApp =>
      'For calls, install Share Link on the other phone.';

  @override
  String get guideDnsTitle => 'If an app says it isn\'t connected';

  @override
  String guideDnsTip(String host) {
    return 'In this network\'s Wi-Fi settings, set DNS to Manual: keep $host and add 1.1.1.1. On iPhone: Wi-Fi → ⓘ → Configure DNS.';
  }

  @override
  String get navHome => 'Home';

  @override
  String get navConnect => 'Connect a device';

  @override
  String get receiveTitle => 'Receive internet';

  @override
  String get receiveCardTitle => 'Best: Share Link on both phones';

  @override
  String get receiveCardBody => 'Every app works, including calls.';

  @override
  String get receiveButton => 'Receive internet on this phone';

  @override
  String get receivingBanner => 'This phone is receiving internet';

  @override
  String get open => 'Open';

  @override
  String get stopReceivingFirst => 'Disconnect Receive mode first.';

  @override
  String get stopSharingFirst => 'Stop sharing on this phone first.';

  @override
  String get showQr => 'QR code';

  @override
  String get howToConnect => 'How to connect';

  @override
  String get withoutAppTitle => 'Without installing the app';

  @override
  String get withoutAppSubtitle => 'Works on any phone, including iPhone.';

  @override
  String get guideProxyTitle => 'Wi-Fi + manual proxy';

  @override
  String get guideProxySubtitle => 'Browsers and most apps';

  @override
  String get guideTelegramSubtitle => 'SOCKS5 proxy in Telegram\'s settings';

  @override
  String get guideWhatsAppSubtitle => 'Messages and media (no calls)';

  @override
  String get guideDnsSubtitle => 'Wallets and bank apps';

  @override
  String get chipHost => 'Host';

  @override
  String get chipPort => 'Port';

  @override
  String get chipChatPort => 'Chat port';

  @override
  String get chipMediaPort => 'Media port';

  @override
  String get chipDns1 => 'DNS 1';

  @override
  String get chipDns2 => 'DNS 2';

  @override
  String get qrPlaceholder => 'Start sharing to show the QR code.';

  @override
  String get goToHome => 'Go to Home';

  @override
  String get sectionAppearance => 'Appearance';

  @override
  String get themeTitle => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get sectionDevice => 'Device';

  @override
  String get sectionAbout => 'About';

  @override
  String get version => 'Version';

  @override
  String get licenses => 'Open-source licences';
}
