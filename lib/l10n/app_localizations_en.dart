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
      'Scan with the other phone\'s camera to join the network. You still need to set the proxy (see the guide below).';

  @override
  String get guideTitle => 'How to connect the other phone';

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
      'Browsers and most apps use the proxy. Some games, calls and VPN apps ignore it and won\'t work.';

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
  String get sectionBattery => 'Battery';

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
  String get guideRecommended =>
      'Best option: install Share Link on the other phone too. Join this network, choose \"Connect\" at the top and tap CONNECT. Every app works, including WhatsApp, Telegram and banking apps.';

  @override
  String get guideManualTitle =>
      'Without the app (browsers and some apps only):';

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
}
