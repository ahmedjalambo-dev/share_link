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
  String get hintStopped =>
      'Connect this phone to Wi-Fi, then tap Start to share it.';

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
  String get wifiLost =>
      'This phone lost its Wi-Fi connection. Sharing resumes when it reconnects.';

  @override
  String get permissionRequired =>
      'Wi-Fi Direct permission is required to share the connection.';

  @override
  String get settingsAction => 'Settings';

  @override
  String get errorPermissionDenied =>
      'Wi-Fi Direct permission was denied. Allow it in the app settings.';

  @override
  String get errorLocationDisabled =>
      'Location is turned off. Android needs it on for Wi-Fi Direct.';

  @override
  String get errorWifiDisabled =>
      'Wi-Fi is turned off. Turn it on and connect to a network.';

  @override
  String get errorWifiNotConnected =>
      'This phone is not connected to a Wi-Fi network with internet.';

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
      'The proxy port is already used by another app. Choose a different port in Settings.';

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
      'On the other phone, open Share Link → Connect a device → Receive mode → \"Scan Phone A\'s QR code\" to join and connect in one step. Its camera app can also scan it, but then only joins the Wi-Fi.';

  @override
  String guideStep1(String ssid) {
    return 'Open Wi-Fi settings and join \"$ssid\", or scan the QR code.';
  }

  @override
  String guideStep2(String password) {
    return 'Enter the password: $password';
  }

  @override
  String get guideStep3 =>
      'Tap the gear icon (or long-press the network), then Modify / Advanced options.';

  @override
  String guideStep4(String host, String port) {
    return 'Set Proxy to Manual: host $host, port $port. Leave the bypass list empty and save.';
  }

  @override
  String get guideStep5 =>
      'If the phone says \"No internet\", choose to stay connected. Browsing still works.';

  @override
  String get guideNote =>
      'Browsers and most apps use the manual proxy, and Telegram can use its own SOCKS5 setting. WhatsApp and calls ignore both: for them, install Share Link on the other phone and use Receive mode.';

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
      'On this Android version the system picks the network name and password automatically. Only the port can be changed.';

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
  String get restartToApply => 'Settings saved. Restart sharing to apply them.';

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
      'Android may stop sharing while the screen is off. Allow the app to run in the background.';

  @override
  String get batteryAllow => 'Allow';

  @override
  String get batteryUnrestricted => 'Battery optimization is off';

  @override
  String get batteryUnrestrictedBody =>
      'Sharing can keep running in the background.';

  @override
  String get errorInvalidName => 'Enter a network name.';

  @override
  String get errorNameTooLong =>
      'The name is too long (the full name must fit in 32 bytes).';

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
  String get clientPhoneA => 'Connected to Phone A';

  @override
  String get clientPortHelper => 'The port shown on Phone A (default 8282)';

  @override
  String get clientStepsTitle => 'Use this phone with Phone A\'s internet';

  @override
  String get clientStep1 =>
      'In Wi-Fi settings, join the \"DIRECT-…\" network shown on Phone A (password or QR code).';

  @override
  String get clientStep2 =>
      'If you set a manual proxy on that network before, set Proxy back to None.';

  @override
  String get clientStep3 =>
      'Tap CONNECT and accept the VPN request. All apps (WhatsApp, Telegram, banking) then use Phone A\'s internet.';

  @override
  String get clientBankNote =>
      'A few banking apps refuse to open while any VPN is on. That is the bank\'s security policy and can\'t be changed by this app.';

  @override
  String get errorVpnDenied =>
      'VPN permission was not given. Tap CONNECT again and choose OK.';

  @override
  String get errorNotOnDirect =>
      'This phone isn\'t connected to Phone A\'s \"DIRECT-…\" network. Join it in Wi-Fi settings first.';

  @override
  String get errorHostUnreachable =>
      'Can\'t reach Phone A. Make sure sharing is running on Phone A and the port matches.';

  @override
  String get errorVpnFailed => 'Could not start the VPN tunnel.';

  @override
  String get errorConnectionLost =>
      'The connection to Phone A was lost. Rejoin its Wi-Fi network and connect again.';

  @override
  String get clientNetworkTitle => 'Phone A\'s network';

  @override
  String get clientAutoJoin => 'Join automatically';

  @override
  String get clientAutoJoinHelp =>
      'The app joins Phone A\'s Wi-Fi when you tap CONNECT and leaves it when you disconnect.';

  @override
  String get clientSsidHintAny =>
      'Optional. Leave empty to choose Phone A\'s network from a list.';

  @override
  String get clientSsidHintExact => 'Exactly as shown on Phone A.';

  @override
  String get clientJoining => 'Joining Phone A\'s Wi-Fi…';

  @override
  String get clientAutoStep1 =>
      'Enter the password shown on Phone A (it\'s saved for next time).';

  @override
  String get clientAutoStep2 =>
      'Tap CONNECT. If Android asks, choose Phone A\'s network and allow the connection, then accept the VPN request.';

  @override
  String get errorJoinFailed =>
      'Couldn\'t join Phone A\'s Wi-Fi. Make sure sharing is running on Phone A and the password is correct.';

  @override
  String clientReconnecting(int attempt) {
    return 'Reconnecting… (attempt $attempt)';
  }

  @override
  String get clientReconnectingHelp =>
      'Phone A can\'t be reached. Reconnecting automatically; apps resume by themselves. Tap DISCONNECT to stop.';

  @override
  String get scanQr => 'Scan Phone A\'s QR code';

  @override
  String get scanTitle => 'Scan Phone A\'s QR code';

  @override
  String get scanHint =>
      'Point the camera at the QR code on Phone A\'s screen.';

  @override
  String get scanFromPhoto => 'Choose a photo';

  @override
  String get scanTorch => 'Flashlight';

  @override
  String get scanNotShareLink => 'This isn\'t Phone A\'s Share Link QR code.';

  @override
  String get scanNoCodeInImage => 'No QR code found in this picture.';

  @override
  String get scanCameraDenied =>
      'Camera permission is needed to scan. Allow it in the app settings, or choose a photo of the QR code instead.';

  @override
  String get scanCameraUnavailable =>
      'The camera can\'t be used right now. You can choose a photo of the QR code instead.';

  @override
  String get sectionTile => 'Quick Settings tile';

  @override
  String get tileAddButton => 'Add Quick Settings tile';

  @override
  String get tileAddHint =>
      'Swipe down twice from the top of the screen, tap the edit (pencil) button, and drag the Share Link tile into your tiles.';

  @override
  String get tileAdded =>
      'Tile added. Swipe down to start or stop from anywhere.';

  @override
  String get tileAlreadyAdded => 'The tile is already in your Quick Settings.';

  @override
  String get tileNotAdded => 'The tile wasn\'t added.';

  @override
  String get errorSetupNeeded =>
      'Enter Phone A\'s password or scan its QR code first, then tap CONNECT.';

  @override
  String get guideTelegramTitle => 'Telegram';

  @override
  String guideTelegram(String host, String port) {
    return 'In Telegram: Settings → Data and Storage → Proxy Settings → Add proxy → SOCKS5. Server $host, port $port, leave username and password empty.';
  }

  @override
  String get guideWhatsAppTitle => 'WhatsApp';

  @override
  String guideWhatsApp(String host) {
    return 'In WhatsApp: Settings → Storage and data → Proxy → Use proxy. Proxy host $host, chat port 5222, media port 7777. Messages and media work; calls don\'t go through the proxy.';
  }

  @override
  String get guideNoteWithWhatsApp =>
      'Browsers and most apps use the manual proxy, and Telegram and WhatsApp can use their own proxy settings. For calls, install Share Link on the other phone and use Receive mode.';

  @override
  String get guideDnsTitle => 'If an app says it isn\'t connected';

  @override
  String guideDnsTip(String host) {
    return 'Some apps (e.g. wallets) check the internet themselves. In the other phone\'s Wi-Fi settings for this network, set DNS to Manual, keep $host and add 1.1.1.1. On iPhone: Settings → Wi-Fi → ⓘ → Configure DNS → Manual → Add Server.';
  }

  @override
  String get navHome => 'Home';

  @override
  String get navConnect => 'Connect a device';

  @override
  String get receiveTitle => 'Receive internet';

  @override
  String get receiveCardTitle => 'Best: install Share Link on the other phone';

  @override
  String get receiveCardBody =>
      'With the app on the other phone, every app works there, including calls. On that phone open \"Connect a device\" and tap the button below.';

  @override
  String get receiveButton => 'This phone needs internet? Open Receive mode';

  @override
  String get receivingBanner => 'Receiving internet from Phone A';

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
  String get withoutAppSubtitle =>
      'Works on any phone, including iPhone. Tap a method to see its steps.';

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
  String get qrPlaceholder =>
      'Start sharing to show the QR code for this network.';

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
