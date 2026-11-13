// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'شير لينك';

  @override
  String get start => 'تشغيل';

  @override
  String get stop => 'إيقاف';

  @override
  String get statusStopped => 'متوقف';

  @override
  String get statusStarting => 'جارٍ التشغيل…';

  @override
  String get statusRunning => 'يعمل';

  @override
  String get statusError => 'خطأ';

  @override
  String get hintStopped => 'اتصل بالواي فاي، ثم اضغط تشغيل.';

  @override
  String get networkName => 'اسم الشبكة';

  @override
  String get password => 'كلمة المرور';

  @override
  String get proxyIp => 'عنوان البروكسي';

  @override
  String get proxyPort => 'منفذ البروكسي';

  @override
  String get copy => 'نسخ';

  @override
  String copied(String label) {
    return 'تم نسخ $label';
  }

  @override
  String get connections => 'الاتصالات';

  @override
  String get upload => 'الرفع';

  @override
  String get download => 'التنزيل';

  @override
  String get wifiLost => 'انقطع الواي فاي. ستُستأنف المشاركة عند عودته.';

  @override
  String get permissionRequired => 'المشاركة تحتاج إذن Wi-Fi Direct.';

  @override
  String get settingsAction => 'الإعدادات';

  @override
  String get errorPermissionDenied =>
      'رُفض إذن Wi-Fi Direct. اسمح به من إعدادات التطبيق.';

  @override
  String get errorLocationDisabled =>
      'شغّل الموقع، فأندرويد يحتاجه لـ Wi-Fi Direct.';

  @override
  String get errorWifiDisabled => 'شغّل الواي فاي واتصل بشبكة.';

  @override
  String get errorWifiNotConnected => 'اتصل بشبكة واي فاي فيها إنترنت.';

  @override
  String get errorP2pUnsupported => 'هذا الهاتف لا يدعم Wi-Fi Direct.';

  @override
  String get errorP2pBusy =>
      'Wi-Fi Direct مشغول. أطفئ الواي فاي وشغّله، ثم حاول مجددًا.';

  @override
  String get errorInvalidSettings => 'اسم الشبكة أو كلمة المرور غير صالحة.';

  @override
  String get errorServiceFailed => 'تعذّر تشغيل الخدمة في الخلفية.';

  @override
  String get errorPortInUse =>
      'تطبيق آخر يستخدم هذا المنفذ. اختر غيره من الإعدادات.';

  @override
  String get errorProxyFailed => 'تعذّر تشغيل خادم البروكسي.';

  @override
  String get errorGeneric => 'تعذّر إنشاء مجموعة Wi-Fi Direct.';

  @override
  String get openAppSettings => 'إعدادات التطبيق';

  @override
  String get openLocationSettings => 'إعدادات الموقع';

  @override
  String get openWifiSettings => 'إعدادات الواي فاي';

  @override
  String get qrTitle => 'امسح للانضمام';

  @override
  String get qrCaption =>
      'امسحه بشير لينك على الهاتف الآخر للاتصال بخطوة واحدة.';

  @override
  String guideStep1(String ssid) {
    return 'انضم إلى \"$ssid\" من إعدادات الواي فاي، أو امسح رمز QR.';
  }

  @override
  String guideStep2(String password) {
    return 'كلمة المرور: $password';
  }

  @override
  String get guideStep3 =>
      'افتح إعدادات الشبكة (الترس أو الضغط المطوّل) ← الخيارات المتقدمة.';

  @override
  String guideStep4(String host, String port) {
    return 'البروكسي: يدوي، المضيف $host، المنفذ $port. ثم احفظ.';
  }

  @override
  String get guideStep5 => 'إذا ظهر \"لا يوجد إنترنت\"، ابقَ متصلًا.';

  @override
  String get guideNote => 'واتساب والمكالمات تحتاج شير لينك على الهاتف الآخر.';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get sectionNetwork => 'شبكة Wi-Fi Direct';

  @override
  String networkNameHelper(String fullName) {
    return 'الاسم الكامل: $fullName';
  }

  @override
  String get customNetworkUnsupported =>
      'في هذا الإصدار من أندرويد يُختار الاسم وكلمة المرور تلقائيًا. يمكن تغيير المنفذ فقط.';

  @override
  String get passwordHelper => 'من 8 إلى 63 حرفًا';

  @override
  String get showPassword => 'إظهار كلمة المرور';

  @override
  String get hidePassword => 'إخفاء كلمة المرور';

  @override
  String get generatePassword => 'توليد كلمة مرور';

  @override
  String get portHelper => 'من 1024 إلى 65535 (الافتراضي 8282)';

  @override
  String get save => 'حفظ';

  @override
  String get saved => 'تم حفظ الإعدادات';

  @override
  String get restartToApply => 'تم الحفظ. أعد تشغيل المشاركة لتطبيق التغييرات.';

  @override
  String get restart => 'إعادة التشغيل';

  @override
  String get sectionLanguage => 'اللغة';

  @override
  String get languageSystem => 'لغة النظام';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get batteryRestricted => 'تحسين البطارية مفعّل';

  @override
  String get batteryRestrictedBody =>
      'قد يوقف أندرويد المشاركة عند إطفاء الشاشة.';

  @override
  String get batteryAllow => 'السماح';

  @override
  String get batteryUnrestricted => 'تحسين البطارية متوقف';

  @override
  String get batteryUnrestrictedBody => 'تستمر المشاركة في الخلفية.';

  @override
  String get errorInvalidName => 'أدخل اسمًا للشبكة.';

  @override
  String get errorNameTooLong => 'الاسم طويل جدًا.';

  @override
  String get errorInvalidPassword =>
      'استخدم من 8 إلى 63 حرفًا إنجليزيًا أو رقمًا أو رمزًا.';

  @override
  String get errorInvalidPort => 'استخدم منفذًا بين 1024 و65535.';

  @override
  String get modeShare => 'مشاركة الواي فاي';

  @override
  String get modeConnect => 'اتصال';

  @override
  String get connect => 'اتصال';

  @override
  String get disconnect => 'قطع الاتصال';

  @override
  String get clientDisconnected => 'غير متصل';

  @override
  String get clientConnecting => 'جارٍ الاتصال…';

  @override
  String get clientConnected => 'متصل';

  @override
  String get clientPhoneA => 'الهاتف المُشارِك';

  @override
  String get clientPortHelper =>
      'كما يظهر على الهاتف المُشارِك (الافتراضي 8282)';

  @override
  String get clientStepsTitle => 'استقبال الإنترنت من الهاتف المُشارِك';

  @override
  String get clientStep1 => 'انضم إلى شبكة \"DIRECT-…\" من إعدادات الواي فاي.';

  @override
  String get clientStep2 => 'إذا كان على الشبكة بروكسي يدوي، فاجعله \"بلا\".';

  @override
  String get clientStep3 => 'اضغط اتصال ووافق على طلب VPN.';

  @override
  String get clientBankNote =>
      'بعض تطبيقات البنوك لا تعمل مع أي VPN، وهذا قرار البنك.';

  @override
  String get errorVpnDenied => 'لم يُمنح إذن VPN. اضغط اتصال واختر موافق.';

  @override
  String get errorNotOnDirect => 'انضم أولًا إلى شبكة \"DIRECT-…\" المُشارَكة.';

  @override
  String get errorHostUnreachable =>
      'تعذّر الوصول إلى الهاتف المُشارِك. تأكد أن المشاركة تعمل.';

  @override
  String get errorVpnFailed => 'تعذّر تشغيل نفق VPN.';

  @override
  String get errorConnectionLost =>
      'انقطع الاتصال. انضم إلى الشبكة مجددًا ثم اتصل.';

  @override
  String get clientNetworkTitle => 'الشبكة المُشارَكة';

  @override
  String get clientAutoJoin => 'الانضمام تلقائيًا';

  @override
  String get clientAutoJoinHelp =>
      'ينضم إلى الشبكة عند الاتصال ويغادرها عند قطعه.';

  @override
  String get clientSsidHintAny => 'اختياري. اتركه فارغًا لتختار من قائمة.';

  @override
  String get clientSsidHintExact => 'كما يظهر على الهاتف المُشارِك تمامًا.';

  @override
  String get clientJoining => 'جارٍ الانضمام إلى الشبكة…';

  @override
  String get clientAutoStep1 =>
      'أدخل كلمة المرور الظاهرة على الهاتف المُشارِك، أو امسح رمز QR.';

  @override
  String get clientAutoStep2 => 'اضغط اتصال ووافق على الطلبات.';

  @override
  String get errorJoinFailed =>
      'تعذّر الانضمام. تأكد أن المشاركة تعمل وأن كلمة المرور صحيحة.';

  @override
  String clientReconnecting(int attempt) {
    return 'جارٍ إعادة الاتصال… (المحاولة $attempt)';
  }

  @override
  String get clientReconnectingHelp =>
      'تعذّر الوصول إلى الهاتف المُشارِك. تتم إعادة المحاولة تلقائيًا.';

  @override
  String get scanQr => 'امسح رمز QR';

  @override
  String get scanTitle => 'امسح رمز QR';

  @override
  String get scanHint => 'وجّه الكاميرا نحو رمز QR على الهاتف المُشارِك.';

  @override
  String get scanFromPhoto => 'اختر صورة';

  @override
  String get scanTorch => 'الفلاش';

  @override
  String get scanNotShareLink => 'هذا ليس رمز QR من شير لينك.';

  @override
  String get scanNoCodeInImage => 'لم يُعثر على رمز QR في هذه الصورة.';

  @override
  String get scanCameraDenied =>
      'اسمح بالكاميرا من إعدادات التطبيق، أو اختر صورة.';

  @override
  String get scanCameraUnavailable =>
      'الكاميرا غير متاحة. اختر صورة بدلًا منها.';

  @override
  String get sectionTile => 'مربع الإعدادات السريعة';

  @override
  String get tileAddButton => 'إضافة مربع إلى الإعدادات السريعة';

  @override
  String get tileAddHint =>
      'افتح الإعدادات السريعة، واضغط القلم، ثم اسحب مربع شير لينك إلى مربعاتك.';

  @override
  String get tileAdded => 'تمت إضافة المربع.';

  @override
  String get tileAlreadyAdded => 'المربع مضاف بالفعل.';

  @override
  String get tileNotAdded => 'لم تتم إضافة المربع.';

  @override
  String get errorSetupNeeded => 'أدخل كلمة المرور أو امسح رمز QR أولًا.';

  @override
  String get guideTelegramTitle => 'تيليجرام';

  @override
  String guideTelegram(String host, String port) {
    return 'الإعدادات ← البيانات والتخزين ← إعدادات البروكسي ← إضافة بروكسي ← SOCKS5، بالخادم $host والمنفذ $port.';
  }

  @override
  String get guideWhatsAppTitle => 'واتساب';

  @override
  String guideWhatsApp(String host) {
    return 'الإعدادات ← التخزين والبيانات ← البروكسي ← استخدام البروكسي. المضيف $host، منفذ الدردشة 5222، منفذ الوسائط 7777. المكالمات لا تعمل.';
  }

  @override
  String get guideNoteWithWhatsApp =>
      'للمكالمات، ثبّت شير لينك على الهاتف الآخر.';

  @override
  String get guideDnsTitle => 'إذا قال تطبيق إنه غير متصل';

  @override
  String guideDnsTip(String host) {
    return 'في إعدادات هذه الشبكة اجعل DNS يدويًا: أبقِ $host وأضف 1.1.1.1. على الآيفون: Wi-Fi ← ⓘ ← تكوين DNS.';
  }

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navConnect => 'توصيل جهاز';

  @override
  String get receiveTitle => 'استقبال الإنترنت';

  @override
  String get receiveCardTitle => 'الأفضل: شير لينك على الهاتفين';

  @override
  String get receiveCardBody => 'تعمل كل التطبيقات، ومنها المكالمات.';

  @override
  String get receiveButton => 'استقبال الإنترنت على هذا الهاتف';

  @override
  String get receivingBanner => 'هذا الهاتف يستقبل الإنترنت';

  @override
  String get open => 'فتح';

  @override
  String get stopReceivingFirst => 'اقطع اتصال وضع الاستقبال أولًا.';

  @override
  String get stopSharingFirst => 'أوقف المشاركة على هذا الهاتف أولًا.';

  @override
  String get showQr => 'رمز QR';

  @override
  String get howToConnect => 'طريقة الاتصال';

  @override
  String get withoutAppTitle => 'بدون تثبيت التطبيق';

  @override
  String get withoutAppSubtitle => 'تعمل على أي هاتف، ومنه الآيفون.';

  @override
  String get guideProxyTitle => 'الواي فاي + بروكسي يدوي';

  @override
  String get guideProxySubtitle => 'المتصفحات ومعظم التطبيقات';

  @override
  String get guideTelegramSubtitle => 'بروكسي SOCKS5 من إعدادات تيليجرام';

  @override
  String get guideWhatsAppSubtitle => 'الرسائل والوسائط (بدون مكالمات)';

  @override
  String get guideDnsSubtitle => 'المحافظ وتطبيقات البنوك';

  @override
  String get chipHost => 'العنوان';

  @override
  String get chipPort => 'المنفذ';

  @override
  String get chipChatPort => 'منفذ الدردشة';

  @override
  String get chipMediaPort => 'منفذ الوسائط';

  @override
  String get chipDns1 => 'DNS 1';

  @override
  String get chipDns2 => 'DNS 2';

  @override
  String get qrPlaceholder => 'شغّل المشاركة ليظهر رمز QR.';

  @override
  String get goToHome => 'الذهاب إلى الرئيسية';

  @override
  String get sectionAppearance => 'المظهر';

  @override
  String get themeTitle => 'السمة';

  @override
  String get themeSystem => 'حسب النظام';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get sectionDevice => 'الجهاز';

  @override
  String get sectionAbout => 'حول التطبيق';

  @override
  String get version => 'الإصدار';

  @override
  String get licenses => 'تراخيص المصادر المفتوحة';

  @override
  String get sessionTime => 'مدة الجلسة';

  @override
  String totalAmount(String size) {
    return 'الإجمالي $size';
  }
}
