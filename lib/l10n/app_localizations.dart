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
  /// **'Connect to Wi-Fi, then tap Start.'**
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
  /// **'Wi-Fi lost. Sharing resumes when it\'s back.'**
  String get wifiLost;

  /// No description provided for @permissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Sharing needs the Wi-Fi Direct permission.'**
  String get permissionRequired;

  /// No description provided for @settingsAction.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsAction;

  /// No description provided for @errorPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi Direct permission denied. Allow it in the app settings.'**
  String get errorPermissionDenied;

  /// No description provided for @errorLocationDisabled.
  ///
  /// In en, this message translates to:
  /// **'Turn on Location. Android needs it for Wi-Fi Direct.'**
  String get errorLocationDisabled;

  /// No description provided for @errorWifiDisabled.
  ///
  /// In en, this message translates to:
  /// **'Turn on Wi-Fi and connect to a network.'**
  String get errorWifiDisabled;

  /// No description provided for @errorWifiNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Connect this phone to a Wi-Fi network with internet.'**
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
  /// **'Another app uses this port. Choose another one in Settings.'**
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
  /// **'Scan it with Share Link on the other phone to connect in one step.'**
  String get qrCaption;

  /// No description provided for @guideStep1.
  ///
  /// In en, this message translates to:
  /// **'Join \"{ssid}\" in Wi-Fi settings, or scan the QR code.'**
  String guideStep1(String ssid);

  /// No description provided for @guideStep2.
  ///
  /// In en, this message translates to:
  /// **'Password: {password}'**
  String guideStep2(String password);

  /// No description provided for @guideStep3.
  ///
  /// In en, this message translates to:
  /// **'Open the network\'s settings (gear icon or long-press) → Advanced.'**
  String get guideStep3;

  /// No description provided for @guideStep4.
  ///
  /// In en, this message translates to:
  /// **'Proxy: Manual, host {host}, port {port}. Save.'**
  String guideStep4(String host, String port);

  /// No description provided for @guideStep5.
  ///
  /// In en, this message translates to:
  /// **'If it says \"No internet\", stay connected anyway.'**
  String get guideStep5;

  /// No description provided for @guideNote.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp and calls need Share Link on the other phone.'**
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
  /// **'On this Android version the name and password are set automatically. Only the port can change.'**
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
  /// **'Saved. Restart sharing to apply.'**
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

  /// No description provided for @batteryRestricted.
  ///
  /// In en, this message translates to:
  /// **'Battery optimization is on'**
  String get batteryRestricted;

  /// No description provided for @batteryRestrictedBody.
  ///
  /// In en, this message translates to:
  /// **'Android may stop sharing when the screen is off.'**
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
  /// **'Sharing keeps running in the background.'**
  String get batteryUnrestrictedBody;

  /// No description provided for @errorInvalidName.
  ///
  /// In en, this message translates to:
  /// **'Enter a network name.'**
  String get errorInvalidName;

  /// No description provided for @errorNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'The name is too long.'**
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
  /// **'Sharing phone'**
  String get clientPhoneA;

  /// No description provided for @clientPortHelper.
  ///
  /// In en, this message translates to:
  /// **'As shown on the sharing phone (default 8282)'**
  String get clientPortHelper;

  /// No description provided for @clientStepsTitle.
  ///
  /// In en, this message translates to:
  /// **'Get internet from the sharing phone'**
  String get clientStepsTitle;

  /// No description provided for @clientStep1.
  ///
  /// In en, this message translates to:
  /// **'Join the \"DIRECT-…\" network in Wi-Fi settings.'**
  String get clientStep1;

  /// No description provided for @clientStep2.
  ///
  /// In en, this message translates to:
  /// **'If that network has a manual proxy, set it to None.'**
  String get clientStep2;

  /// No description provided for @clientStep3.
  ///
  /// In en, this message translates to:
  /// **'Tap CONNECT and accept the VPN request.'**
  String get clientStep3;

  /// No description provided for @clientBankNote.
  ///
  /// In en, this message translates to:
  /// **'Some bank apps won\'t open while a VPN is on. That\'s the bank\'s choice.'**
  String get clientBankNote;

  /// No description provided for @errorVpnDenied.
  ///
  /// In en, this message translates to:
  /// **'VPN not allowed. Tap CONNECT and choose OK.'**
  String get errorVpnDenied;

  /// No description provided for @errorNotOnDirect.
  ///
  /// In en, this message translates to:
  /// **'Join the shared \"DIRECT-…\" network first.'**
  String get errorNotOnDirect;

  /// No description provided for @errorHostUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the sharing phone. Make sure sharing is on.'**
  String get errorHostUnreachable;

  /// No description provided for @errorVpnFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start the VPN tunnel.'**
  String get errorVpnFailed;

  /// No description provided for @errorConnectionLost.
  ///
  /// In en, this message translates to:
  /// **'Connection lost. Rejoin the network and connect again.'**
  String get errorConnectionLost;

  /// No description provided for @clientNetworkTitle.
  ///
  /// In en, this message translates to:
  /// **'Shared network'**
  String get clientNetworkTitle;

  /// No description provided for @clientAutoJoin.
  ///
  /// In en, this message translates to:
  /// **'Join automatically'**
  String get clientAutoJoin;

  /// No description provided for @clientAutoJoinHelp.
  ///
  /// In en, this message translates to:
  /// **'Joins the network when you connect and leaves it when you disconnect.'**
  String get clientAutoJoinHelp;

  /// No description provided for @clientSsidHintAny.
  ///
  /// In en, this message translates to:
  /// **'Optional. Leave empty to pick from a list.'**
  String get clientSsidHintAny;

  /// No description provided for @clientSsidHintExact.
  ///
  /// In en, this message translates to:
  /// **'Exactly as shown on the sharing phone.'**
  String get clientSsidHintExact;

  /// No description provided for @clientJoining.
  ///
  /// In en, this message translates to:
  /// **'Joining the network…'**
  String get clientJoining;

  /// No description provided for @clientAutoStep1.
  ///
  /// In en, this message translates to:
  /// **'Enter the password shown on the sharing phone, or scan its QR code.'**
  String get clientAutoStep1;

  /// No description provided for @clientAutoStep2.
  ///
  /// In en, this message translates to:
  /// **'Tap CONNECT and accept the requests.'**
  String get clientAutoStep2;

  /// No description provided for @errorJoinFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t join. Make sure sharing is on and the password is right.'**
  String get errorJoinFailed;

  /// No description provided for @clientReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting… (attempt {attempt})'**
  String clientReconnecting(int attempt);

  /// No description provided for @clientReconnectingHelp.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the sharing phone. Retrying automatically.'**
  String get clientReconnectingHelp;

  /// No description provided for @scanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code'**
  String get scanQr;

  /// No description provided for @scanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code'**
  String get scanTitle;

  /// No description provided for @scanHint.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at the QR code on the sharing phone.'**
  String get scanHint;

  /// No description provided for @scanFromPhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose a photo'**
  String get scanFromPhoto;

  /// No description provided for @scanTorch.
  ///
  /// In en, this message translates to:
  /// **'Flashlight'**
  String get scanTorch;

  /// No description provided for @scanNotShareLink.
  ///
  /// In en, this message translates to:
  /// **'This isn\'t a Share Link QR code.'**
  String get scanNotShareLink;

  /// No description provided for @scanNoCodeInImage.
  ///
  /// In en, this message translates to:
  /// **'No QR code found in this picture.'**
  String get scanNoCodeInImage;

  /// No description provided for @scanCameraDenied.
  ///
  /// In en, this message translates to:
  /// **'Allow the camera in the app settings, or choose a photo.'**
  String get scanCameraDenied;

  /// No description provided for @scanCameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The camera isn\'t available. Choose a photo instead.'**
  String get scanCameraUnavailable;

  /// No description provided for @sectionTile.
  ///
  /// In en, this message translates to:
  /// **'Quick Settings tile'**
  String get sectionTile;

  /// No description provided for @tileAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add Quick Settings tile'**
  String get tileAddButton;

  /// No description provided for @tileAddHint.
  ///
  /// In en, this message translates to:
  /// **'Open Quick Settings, tap the pencil, and drag the Share Link tile in.'**
  String get tileAddHint;

  /// No description provided for @tileAdded.
  ///
  /// In en, this message translates to:
  /// **'Tile added.'**
  String get tileAdded;

  /// No description provided for @tileAlreadyAdded.
  ///
  /// In en, this message translates to:
  /// **'The tile is already added.'**
  String get tileAlreadyAdded;

  /// No description provided for @tileNotAdded.
  ///
  /// In en, this message translates to:
  /// **'The tile wasn\'t added.'**
  String get tileNotAdded;

  /// No description provided for @errorSetupNeeded.
  ///
  /// In en, this message translates to:
  /// **'Enter the password or scan the QR code first.'**
  String get errorSetupNeeded;

  /// No description provided for @guideTelegramTitle.
  ///
  /// In en, this message translates to:
  /// **'Telegram'**
  String get guideTelegramTitle;

  /// No description provided for @guideTelegram.
  ///
  /// In en, this message translates to:
  /// **'Settings → Data and Storage → Proxy Settings → Add Proxy → SOCKS5, with server {host} and port {port}.'**
  String guideTelegram(String host, String port);

  /// No description provided for @guideWhatsAppTitle.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get guideWhatsAppTitle;

  /// No description provided for @guideWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Settings → Storage and data → Proxy → Use proxy. Host {host}, chat port 5222, media port 7777. Calls won\'t work.'**
  String guideWhatsApp(String host);

  /// No description provided for @guideNoteWithWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'For calls, install Share Link on the other phone.'**
  String get guideNoteWithWhatsApp;

  /// No description provided for @guideDnsTitle.
  ///
  /// In en, this message translates to:
  /// **'If an app says it isn\'t connected'**
  String get guideDnsTitle;

  /// No description provided for @guideDnsTip.
  ///
  /// In en, this message translates to:
  /// **'In this network\'s Wi-Fi settings, set DNS to Manual: keep {host} and add 1.1.1.1. On iPhone: Wi-Fi → ⓘ → Configure DNS.'**
  String guideDnsTip(String host);

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect a device'**
  String get navConnect;

  /// No description provided for @receiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Receive internet'**
  String get receiveTitle;

  /// No description provided for @receiveCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Best: Share Link on both phones'**
  String get receiveCardTitle;

  /// No description provided for @receiveCardBody.
  ///
  /// In en, this message translates to:
  /// **'Every app works, including calls.'**
  String get receiveCardBody;

  /// No description provided for @receiveButton.
  ///
  /// In en, this message translates to:
  /// **'Receive internet on this phone'**
  String get receiveButton;

  /// No description provided for @receivingBanner.
  ///
  /// In en, this message translates to:
  /// **'This phone is receiving internet'**
  String get receivingBanner;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @stopReceivingFirst.
  ///
  /// In en, this message translates to:
  /// **'Disconnect Receive mode first.'**
  String get stopReceivingFirst;

  /// No description provided for @stopSharingFirst.
  ///
  /// In en, this message translates to:
  /// **'Stop sharing on this phone first.'**
  String get stopSharingFirst;

  /// No description provided for @showQr.
  ///
  /// In en, this message translates to:
  /// **'QR code'**
  String get showQr;

  /// No description provided for @howToConnect.
  ///
  /// In en, this message translates to:
  /// **'How to connect'**
  String get howToConnect;

  /// No description provided for @withoutAppTitle.
  ///
  /// In en, this message translates to:
  /// **'Without installing the app'**
  String get withoutAppTitle;

  /// No description provided for @withoutAppSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Works on any phone, including iPhone.'**
  String get withoutAppSubtitle;

  /// No description provided for @guideProxyTitle.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi + manual proxy'**
  String get guideProxyTitle;

  /// No description provided for @guideProxySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browsers and most apps'**
  String get guideProxySubtitle;

  /// No description provided for @guideTelegramSubtitle.
  ///
  /// In en, this message translates to:
  /// **'SOCKS5 proxy in Telegram\'s settings'**
  String get guideTelegramSubtitle;

  /// No description provided for @guideWhatsAppSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Messages and media (no calls)'**
  String get guideWhatsAppSubtitle;

  /// No description provided for @guideDnsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Wallets and bank apps'**
  String get guideDnsSubtitle;

  /// No description provided for @chipHost.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get chipHost;

  /// No description provided for @chipPort.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get chipPort;

  /// No description provided for @chipChatPort.
  ///
  /// In en, this message translates to:
  /// **'Chat port'**
  String get chipChatPort;

  /// No description provided for @chipMediaPort.
  ///
  /// In en, this message translates to:
  /// **'Media port'**
  String get chipMediaPort;

  /// No description provided for @chipDns1.
  ///
  /// In en, this message translates to:
  /// **'DNS 1'**
  String get chipDns1;

  /// No description provided for @chipDns2.
  ///
  /// In en, this message translates to:
  /// **'DNS 2'**
  String get chipDns2;

  /// No description provided for @qrPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Start sharing to show the QR code.'**
  String get qrPlaceholder;

  /// No description provided for @goToHome.
  ///
  /// In en, this message translates to:
  /// **'Go to Home'**
  String get goToHome;

  /// No description provided for @sectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get sectionAppearance;

  /// No description provided for @themeTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeTitle;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @sectionDevice.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get sectionDevice;

  /// No description provided for @sectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get sectionAbout;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @licenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licences'**
  String get licenses;

  /// No description provided for @sessionTime.
  ///
  /// In en, this message translates to:
  /// **'Session time'**
  String get sessionTime;

  /// No description provided for @totalAmount.
  ///
  /// In en, this message translates to:
  /// **'{size} total'**
  String totalAmount(String size);
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
