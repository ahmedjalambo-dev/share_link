import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Share Link'**
  String get appTitle;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'START'**
  String get start;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'STOP'**
  String get stop;

  /// No description provided for @statusStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get statusStopped;

  /// No description provided for @statusStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting…'**
  String get statusStarting;

  /// No description provided for @statusRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get statusRunning;

  /// No description provided for @statusError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get statusError;

  /// No description provided for @hintStopped.
  ///
  /// In en, this message translates to:
  /// **'Connect this phone to Wi-Fi, then tap Start to share it.'**
  String get hintStopped;

  /// No description provided for @networkName.
  ///
  /// In en, this message translates to:
  /// **'Network name'**
  String get networkName;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @proxyIp.
  ///
  /// In en, this message translates to:
  /// **'Proxy IP'**
  String get proxyIp;

  /// No description provided for @proxyPort.
  ///
  /// In en, this message translates to:
  /// **'Proxy port'**
  String get proxyPort;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'{label} copied'**
  String copied(String label);

  /// No description provided for @connections.
  ///
  /// In en, this message translates to:
  /// **'Connections'**
  String get connections;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @wifiLost.
  ///
  /// In en, this message translates to:
  /// **'This phone lost its Wi-Fi connection. Sharing resumes when it reconnects.'**
  String get wifiLost;

  /// No description provided for @permissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi Direct permission is required to share the connection.'**
  String get permissionRequired;

  /// No description provided for @settingsAction.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsAction;

  /// No description provided for @errorPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi Direct permission was denied. Allow it in the app settings.'**
  String get errorPermissionDenied;

  /// No description provided for @errorLocationDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location is turned off. Android needs it on for Wi-Fi Direct.'**
  String get errorLocationDisabled;

  /// No description provided for @errorWifiDisabled.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi is turned off. Turn it on and connect to a network.'**
  String get errorWifiDisabled;

  /// No description provided for @errorWifiNotConnected.
  ///
  /// In en, this message translates to:
  /// **'This phone is not connected to a Wi-Fi network with internet.'**
  String get errorWifiNotConnected;

  /// No description provided for @errorP2pUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This phone does not support Wi-Fi Direct.'**
  String get errorP2pUnsupported;

  /// No description provided for @errorP2pBusy.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi Direct is busy. Turn Wi-Fi off and on, then try again.'**
  String get errorP2pBusy;

  /// No description provided for @errorInvalidSettings.
  ///
  /// In en, this message translates to:
  /// **'The network name or password is invalid.'**
  String get errorInvalidSettings;

  /// No description provided for @errorServiceFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start the background service.'**
  String get errorServiceFailed;

  /// No description provided for @errorPortInUse.
  ///
  /// In en, this message translates to:
  /// **'The proxy port is already used by another app. Choose a different port in Settings.'**
  String get errorPortInUse;

  /// No description provided for @errorProxyFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start the proxy server.'**
  String get errorProxyFailed;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Could not create the Wi-Fi Direct group.'**
  String get errorGeneric;

  /// No description provided for @openAppSettings.
  ///
  /// In en, this message translates to:
  /// **'App settings'**
  String get openAppSettings;

  /// No description provided for @openLocationSettings.
  ///
  /// In en, this message translates to:
  /// **'Location settings'**
  String get openLocationSettings;

  /// No description provided for @openWifiSettings.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi settings'**
  String get openWifiSettings;

  /// No description provided for @qrTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan to join'**
  String get qrTitle;

  /// No description provided for @qrCaption.
  ///
  /// In en, this message translates to:
  /// **'Scan with the other phone\'s camera to join the network. You still need to set the proxy (see the guide below).'**
  String get qrCaption;

  /// No description provided for @guideTitle.
  ///
  /// In en, this message translates to:
  /// **'How to connect the other phone'**
  String get guideTitle;

  /// No description provided for @guideStep1.
  ///
  /// In en, this message translates to:
  /// **'Open Wi-Fi settings and join \"{ssid}\", or scan the QR code.'**
  String guideStep1(String ssid);

  /// No description provided for @guideStep2.
  ///
  /// In en, this message translates to:
  /// **'Enter the password: {password}'**
  String guideStep2(String password);

  /// No description provided for @guideStep3.
  ///
  /// In en, this message translates to:
  /// **'Tap the gear icon (or long-press the network), then Modify / Advanced options.'**
  String get guideStep3;

  /// No description provided for @guideStep4.
  ///
  /// In en, this message translates to:
  /// **'Set Proxy to Manual: host {host}, port {port}. Leave the bypass list empty and save.'**
  String guideStep4(String host, String port);

  /// No description provided for @guideStep5.
  ///
  /// In en, this message translates to:
  /// **'If the phone says \"No internet\", choose to stay connected. Browsing still works.'**
  String get guideStep5;

  /// No description provided for @guideNote.
  ///
  /// In en, this message translates to:
  /// **'Browsers and most apps use the proxy. Some games, calls and VPN apps ignore it and won\'t work.'**
  String get guideNote;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @sectionNetwork.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi Direct network'**
  String get sectionNetwork;

  /// No description provided for @networkNameHelper.
  ///
  /// In en, this message translates to:
  /// **'Full name: {fullName}'**
  String networkNameHelper(String fullName);

  /// No description provided for @customNetworkUnsupported.
  ///
  /// In en, this message translates to:
  /// **'On this Android version the system picks the network name and password automatically. Only the port can be changed.'**
  String get customNetworkUnsupported;

  /// No description provided for @passwordHelper.
  ///
  /// In en, this message translates to:
  /// **'8–63 characters'**
  String get passwordHelper;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @generatePassword.
  ///
  /// In en, this message translates to:
  /// **'Generate password'**
  String get generatePassword;

  /// No description provided for @portHelper.
  ///
  /// In en, this message translates to:
  /// **'1024–65535 (default 8282)'**
  String get portHelper;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get saved;

  /// No description provided for @restartToApply.
  ///
  /// In en, this message translates to:
  /// **'Settings saved. Restart sharing to apply them.'**
  String get restartToApply;

  /// No description provided for @restart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get restart;

  /// No description provided for @sectionLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get sectionLanguage;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @sectionBattery.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get sectionBattery;

  /// No description provided for @batteryRestricted.
  ///
  /// In en, this message translates to:
  /// **'Battery optimization is on'**
  String get batteryRestricted;

  /// No description provided for @batteryRestrictedBody.
  ///
  /// In en, this message translates to:
  /// **'Android may stop sharing while the screen is off. Allow the app to run in the background.'**
  String get batteryRestrictedBody;

  /// No description provided for @batteryAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get batteryAllow;

  /// No description provided for @batteryUnrestricted.
  ///
  /// In en, this message translates to:
  /// **'Battery optimization is off'**
  String get batteryUnrestricted;

  /// No description provided for @batteryUnrestrictedBody.
  ///
  /// In en, this message translates to:
  /// **'Sharing can keep running in the background.'**
  String get batteryUnrestrictedBody;

  /// No description provided for @errorInvalidName.
  ///
  /// In en, this message translates to:
  /// **'Enter a network name.'**
  String get errorInvalidName;

  /// No description provided for @errorNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'The name is too long (the full name must fit in 32 bytes).'**
  String get errorNameTooLong;

  /// No description provided for @errorInvalidPassword.
  ///
  /// In en, this message translates to:
  /// **'Use 8–63 English letters, numbers or symbols.'**
  String get errorInvalidPassword;

  /// No description provided for @errorInvalidPort.
  ///
  /// In en, this message translates to:
  /// **'Use a port between 1024 and 65535.'**
  String get errorInvalidPort;

  /// No description provided for @modeShare.
  ///
  /// In en, this message translates to:
  /// **'Share Wi-Fi'**
  String get modeShare;

  /// No description provided for @modeConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get modeConnect;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'CONNECT'**
  String get connect;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'DISCONNECT'**
  String get disconnect;

  /// No description provided for @clientDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get clientDisconnected;

  /// No description provided for @clientConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get clientConnecting;

  /// No description provided for @clientConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get clientConnected;

  /// No description provided for @clientPhoneA.
  ///
  /// In en, this message translates to:
  /// **'Connected to Phone A'**
  String get clientPhoneA;

  /// No description provided for @clientPortHelper.
  ///
  /// In en, this message translates to:
  /// **'The port shown on Phone A (default 8282)'**
  String get clientPortHelper;

  /// No description provided for @clientStepsTitle.
  ///
  /// In en, this message translates to:
  /// **'Use this phone with Phone A\'s internet'**
  String get clientStepsTitle;

  /// No description provided for @clientStep1.
  ///
  /// In en, this message translates to:
  /// **'In Wi-Fi settings, join the \"DIRECT-…\" network shown on Phone A (password or QR code).'**
  String get clientStep1;

  /// No description provided for @clientStep2.
  ///
  /// In en, this message translates to:
  /// **'If you set a manual proxy on that network before, set Proxy back to None.'**
  String get clientStep2;

  /// No description provided for @clientStep3.
  ///
  /// In en, this message translates to:
  /// **'Tap CONNECT and accept the VPN request. All apps (WhatsApp, Telegram, banking) then use Phone A\'s internet.'**
  String get clientStep3;

  /// No description provided for @clientBankNote.
  ///
  /// In en, this message translates to:
  /// **'A few banking apps refuse to open while any VPN is on. That is the bank\'s security policy and can\'t be changed by this app.'**
  String get clientBankNote;

  /// No description provided for @errorVpnDenied.
  ///
  /// In en, this message translates to:
  /// **'VPN permission was not given. Tap CONNECT again and choose OK.'**
  String get errorVpnDenied;

  /// No description provided for @errorNotOnDirect.
  ///
  /// In en, this message translates to:
  /// **'This phone isn\'t connected to Phone A\'s \"DIRECT-…\" network. Join it in Wi-Fi settings first.'**
  String get errorNotOnDirect;

  /// No description provided for @errorHostUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach Phone A. Make sure sharing is running on Phone A and the port matches.'**
  String get errorHostUnreachable;

  /// No description provided for @errorVpnFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start the VPN tunnel.'**
  String get errorVpnFailed;

  /// No description provided for @errorConnectionLost.
  ///
  /// In en, this message translates to:
  /// **'The connection to Phone A was lost. Rejoin its Wi-Fi network and connect again.'**
  String get errorConnectionLost;

  /// No description provided for @guideRecommended.
  ///
  /// In en, this message translates to:
  /// **'Best option: install Share Link on the other phone too. Join this network, choose \"Connect\" at the top and tap CONNECT. Every app works, including WhatsApp, Telegram and banking apps.'**
  String get guideRecommended;

  /// No description provided for @guideManualTitle.
  ///
  /// In en, this message translates to:
  /// **'Without the app (browsers and some apps only):'**
  String get guideManualTitle;

  /// No description provided for @clientNetworkTitle.
  ///
  /// In en, this message translates to:
  /// **'Phone A\'s network'**
  String get clientNetworkTitle;

  /// No description provided for @clientAutoJoin.
  ///
  /// In en, this message translates to:
  /// **'Join automatically'**
  String get clientAutoJoin;

  /// No description provided for @clientAutoJoinHelp.
  ///
  /// In en, this message translates to:
  /// **'The app joins Phone A\'s Wi-Fi when you tap CONNECT and leaves it when you disconnect.'**
  String get clientAutoJoinHelp;

  /// No description provided for @clientSsidHintAny.
  ///
  /// In en, this message translates to:
  /// **'Optional. Leave empty to choose Phone A\'s network from a list.'**
  String get clientSsidHintAny;

  /// No description provided for @clientSsidHintExact.
  ///
  /// In en, this message translates to:
  /// **'Exactly as shown on Phone A.'**
  String get clientSsidHintExact;

  /// No description provided for @clientJoining.
  ///
  /// In en, this message translates to:
  /// **'Joining Phone A\'s Wi-Fi…'**
  String get clientJoining;

  /// No description provided for @clientAutoStep1.
  ///
  /// In en, this message translates to:
  /// **'Enter the password shown on Phone A (it\'s saved for next time).'**
  String get clientAutoStep1;

  /// No description provided for @clientAutoStep2.
  ///
  /// In en, this message translates to:
  /// **'Tap CONNECT. If Android asks, choose Phone A\'s network and allow the connection, then accept the VPN request.'**
  String get clientAutoStep2;

  /// No description provided for @errorJoinFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t join Phone A\'s Wi-Fi. Make sure sharing is running on Phone A and the password is correct.'**
  String get errorJoinFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
