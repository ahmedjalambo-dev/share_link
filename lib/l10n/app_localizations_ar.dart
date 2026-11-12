// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'Share Link';

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
  String get hintStopped =>
      'اتصل بشبكة واي فاي من هذا الهاتف، ثم اضغط تشغيل لمشاركتها.';

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
  String get wifiLost =>
      'فقد هذا الهاتف اتصال الواي فاي. ستُستأنف المشاركة عند عودة الاتصال.';

  @override
  String get permissionRequired => 'يلزم منح إذن Wi-Fi Direct لمشاركة الاتصال.';

  @override
  String get settingsAction => 'الإعدادات';

  @override
  String get errorPermissionDenied =>
      'تم رفض إذن Wi-Fi Direct. اسمح به من إعدادات التطبيق.';

  @override
  String get errorLocationDisabled =>
      'خدمة الموقع متوقفة. يحتاجها أندرويد لتشغيل Wi-Fi Direct.';

  @override
  String get errorWifiDisabled => 'الواي فاي متوقف. شغّله واتصل بشبكة.';

  @override
  String get errorWifiNotConnected =>
      'هذا الهاتف غير متصل بشبكة واي فاي فيها إنترنت.';

  @override
  String get errorP2pUnsupported => 'هذا الهاتف لا يدعم Wi-Fi Direct.';

  @override
  String get errorP2pBusy =>
      'Wi-Fi Direct مشغول. أطفئ الواي فاي ثم شغّله وحاول مجددًا.';

  @override
  String get errorInvalidSettings => 'اسم الشبكة أو كلمة المرور غير صالحة.';

  @override
  String get errorServiceFailed => 'تعذّر تشغيل الخدمة في الخلفية.';

  @override
  String get errorPortInUse =>
      'منفذ البروكسي مستخدم من تطبيق آخر. اختر منفذًا مختلفًا من الإعدادات.';

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
      'على الهاتف الآخر افتح Share Link ← توصيل جهاز ← وضع الاستقبال ← \"امسح رمز QR للهاتف (أ)\" للانضمام والاتصال بخطوة واحدة. يمكن لتطبيق الكاميرا أيضًا مسحه، لكنه عندها ينضم إلى الواي فاي فقط.';

  @override
  String guideStep1(String ssid) {
    return 'افتح إعدادات الواي فاي وانضم إلى الشبكة \"$ssid\"، أو امسح رمز QR.';
  }

  @override
  String guideStep2(String password) {
    return 'أدخل كلمة المرور: $password';
  }

  @override
  String get guideStep3 =>
      'اضغط على أيقونة الترس (أو اضغط مطولًا على الشبكة)، ثم تعديل / الخيارات المتقدمة.';

  @override
  String guideStep4(String host, String port) {
    return 'اجعل البروكسي يدويًا: المضيف $host والمنفذ $port. اترك قائمة التجاوز فارغة واحفظ.';
  }

  @override
  String get guideStep5 =>
      'إذا ظهرت رسالة \"لا يوجد اتصال بالإنترنت\"، اختر البقاء متصلًا. التصفح يعمل رغم ذلك.';

  @override
  String get guideNote =>
      'المتصفحات ومعظم التطبيقات تستخدم البروكسي اليدوي، ويمكن لتيليجرام استخدام إعداد SOCKS5 الخاص به. أما واتساب والمكالمات فتتجاهلهما: لها ثبّت Share Link على الهاتف الآخر واستخدم وضع الاستقبال.';

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
      'في هذا الإصدار من أندرويد يختار النظام اسم الشبكة وكلمة المرور تلقائيًا. يمكن تغيير المنفذ فقط.';

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
  String get restartToApply => 'تم الحفظ. أعد تشغيل المشاركة لتطبيق الإعدادات.';

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
  String get sectionBattery => 'البطارية';

  @override
  String get batteryRestricted => 'تحسين البطارية مفعّل';

  @override
  String get batteryRestrictedBody =>
      'قد يوقف أندرويد المشاركة عند إطفاء الشاشة. اسمح للتطبيق بالعمل في الخلفية.';

  @override
  String get batteryAllow => 'السماح';

  @override
  String get batteryUnrestricted => 'تحسين البطارية متوقف';

  @override
  String get batteryUnrestrictedBody =>
      'يمكن أن تستمر المشاركة في العمل في الخلفية.';

  @override
  String get errorInvalidName => 'أدخل اسمًا للشبكة.';

  @override
  String get errorNameTooLong =>
      'الاسم طويل جدًا (يجب ألا يتجاوز الاسم الكامل 32 بايت).';

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
  String get clientPhoneA => 'متصل بالهاتف (أ)';

  @override
  String get clientPortHelper =>
      'المنفذ الظاهر على الهاتف (أ) (الافتراضي 8282)';

  @override
  String get clientStepsTitle => 'استخدم إنترنت الهاتف (أ) على هذا الهاتف';

  @override
  String get clientStep1 =>
      'من إعدادات الواي فاي، انضم إلى الشبكة \"DIRECT-…\" الظاهرة على الهاتف (أ) (بكلمة المرور أو رمز QR).';

  @override
  String get clientStep2 =>
      'إذا كنت قد ضبطت بروكسي يدويًا على تلك الشبكة من قبل، فأعد البروكسي إلى \"بلا\".';

  @override
  String get clientStep3 =>
      'اضغط اتصال ووافق على طلب VPN. بعدها تستخدم كل التطبيقات (واتساب، تيليجرام، البنوك) إنترنت الهاتف (أ).';

  @override
  String get clientBankNote =>
      'بعض تطبيقات البنوك ترفض العمل أثناء تشغيل أي VPN. هذه سياسة أمان البنك ولا يمكن لهذا التطبيق تغييرها.';

  @override
  String get errorVpnDenied =>
      'لم يتم منح إذن VPN. اضغط اتصال مرة أخرى واختر موافق.';

  @override
  String get errorNotOnDirect =>
      'هذا الهاتف غير متصل بشبكة \"DIRECT-…\" الخاصة بالهاتف (أ). انضم إليها من إعدادات الواي فاي أولًا.';

  @override
  String get errorHostUnreachable =>
      'تعذّر الوصول إلى الهاتف (أ). تأكد أن المشاركة تعمل عليه وأن المنفذ مطابق.';

  @override
  String get errorVpnFailed => 'تعذّر تشغيل نفق VPN.';

  @override
  String get errorConnectionLost =>
      'انقطع الاتصال بالهاتف (أ). انضم إلى شبكته مجددًا ثم اتصل.';

  @override
  String get clientNetworkTitle => 'شبكة الهاتف (أ)';

  @override
  String get clientAutoJoin => 'الانضمام تلقائيًا';

  @override
  String get clientAutoJoinHelp =>
      'ينضم التطبيق إلى شبكة الهاتف (أ) عند الضغط على اتصال، ويغادرها عند قطع الاتصال.';

  @override
  String get clientSsidHintAny =>
      'اختياري. اتركه فارغًا لاختيار شبكة الهاتف (أ) من قائمة.';

  @override
  String get clientSsidHintExact => 'كما يظهر تمامًا على الهاتف (أ).';

  @override
  String get clientJoining => 'جارٍ الانضمام إلى شبكة الهاتف (أ)…';

  @override
  String get clientAutoStep1 =>
      'أدخل كلمة المرور الظاهرة على الهاتف (أ) (تُحفظ للمرات القادمة).';

  @override
  String get clientAutoStep2 =>
      'اضغط اتصال. إذا سألك أندرويد فاختر شبكة الهاتف (أ) واسمح بالاتصال، ثم وافق على طلب VPN.';

  @override
  String get errorJoinFailed =>
      'تعذّر الانضمام إلى شبكة الهاتف (أ). تأكد أن المشاركة تعمل عليه وأن كلمة المرور صحيحة.';

  @override
  String clientReconnecting(int attempt) {
    return 'جارٍ إعادة الاتصال… (المحاولة $attempt)';
  }

  @override
  String get clientReconnectingHelp =>
      'تعذّر الوصول إلى الهاتف (أ). تتم إعادة الاتصال تلقائيًا وستعود التطبيقات للعمل وحدها. اضغط قطع الاتصال للإيقاف.';

  @override
  String get scanQr => 'امسح رمز QR للهاتف (أ)';

  @override
  String get scanTitle => 'امسح رمز QR للهاتف (أ)';

  @override
  String get scanHint => 'وجّه الكاميرا نحو رمز QR الظاهر على شاشة الهاتف (أ).';

  @override
  String get scanFromPhoto => 'اختر صورة';

  @override
  String get scanTorch => 'الفلاش';

  @override
  String get scanNotShareLink =>
      'هذا ليس رمز QR الخاص بـ Share Link على الهاتف (أ).';

  @override
  String get scanNoCodeInImage => 'لم يُعثر على رمز QR في هذه الصورة.';

  @override
  String get scanCameraDenied =>
      'يلزم إذن الكاميرا للمسح. اسمح به من إعدادات التطبيق، أو اختر صورة لرمز QR بدلًا من ذلك.';

  @override
  String get scanCameraUnavailable =>
      'لا يمكن استخدام الكاميرا الآن. يمكنك اختيار صورة لرمز QR بدلًا من ذلك.';

  @override
  String get sectionTile => 'مربع الإعدادات السريعة';

  @override
  String get tileAddButton => 'إضافة مربع إلى الإعدادات السريعة';

  @override
  String get tileAddHint =>
      'اسحب من أعلى الشاشة إلى الأسفل مرتين، واضغط زر التعديل (القلم)، ثم اسحب مربع Share Link إلى مربعاتك.';

  @override
  String get tileAdded =>
      'تمت إضافة المربع. اسحب للأسفل للتشغيل أو الإيقاف من أي مكان.';

  @override
  String get tileAlreadyAdded => 'المربع موجود بالفعل في الإعدادات السريعة.';

  @override
  String get tileNotAdded => 'لم تتم إضافة المربع.';

  @override
  String get errorSetupNeeded =>
      'أدخل كلمة مرور الهاتف (أ) أو امسح رمز QR الخاص به أولًا، ثم اضغط اتصال.';

  @override
  String get guideTelegramTitle => 'تيليجرام';

  @override
  String guideTelegram(String host, String port) {
    return 'في تيليجرام: الإعدادات ← البيانات والتخزين ← إعدادات البروكسي ← إضافة بروكسي ← SOCKS5. الخادم $host والمنفذ $port، واترك اسم المستخدم وكلمة المرور فارغين.';
  }

  @override
  String get guideWhatsAppTitle => 'واتساب';

  @override
  String guideWhatsApp(String host) {
    return 'في واتساب: الإعدادات ← التخزين والبيانات ← البروكسي ← استخدام البروكسي. مضيف البروكسي $host، منفذ الدردشة 5222، منفذ الوسائط 7777. الرسائل والوسائط تعمل؛ المكالمات لا تمر عبر البروكسي.';
  }

  @override
  String get guideNoteWithWhatsApp =>
      'المتصفحات ومعظم التطبيقات تستخدم البروكسي اليدوي، ويمكن لتيليجرام وواتساب استخدام إعدادات البروكسي الخاصة بهما. للمكالمات، ثبّت Share Link على الهاتف الآخر واستخدم وضع الاستقبال.';

  @override
  String get guideDnsTitle => 'إذا قال تطبيق إنه غير متصل';

  @override
  String guideDnsTip(String host) {
    return 'بعض التطبيقات (مثل المحافظ) تفحص الإنترنت بنفسها. في إعدادات الواي فاي على الهاتف الآخر لهذه الشبكة، اجعل DNS يدويًا، أبقِ $host وأضف 1.1.1.1. على الآيفون: الإعدادات ← Wi-Fi ← ⓘ ← تكوين DNS ← يدوي ← إضافة خادم.';
  }

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navConnect => 'توصيل جهاز';

  @override
  String get receiveTitle => 'استقبال الإنترنت';

  @override
  String get receiveCardTitle => 'الأفضل: ثبّت Share Link على الهاتف الآخر';

  @override
  String get receiveCardBody =>
      'مع التطبيق على الهاتف الآخر تعمل عليه كل التطبيقات، ومنها المكالمات. على ذلك الهاتف افتح «توصيل جهاز» واضغط الزر بالأسفل.';

  @override
  String get receiveButton => 'هذا الهاتف يحتاج إنترنت؟ افتح وضع الاستقبال';

  @override
  String get receivingBanner => 'يستقبل هذا الهاتف الإنترنت من الهاتف (أ)';

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
  String get withoutAppSubtitle =>
      'تعمل على أي هاتف، ومنه الآيفون. اضغط على طريقة لترى خطواتها.';

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
  String get qrPlaceholder => 'ابدأ المشاركة ليظهر رمز QR لهذه الشبكة.';

  @override
  String get goToHome => 'الذهاب إلى الرئيسية';
}
