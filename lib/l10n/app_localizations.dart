import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AppLocalizations {
  AppLocalizations(this.locale) {
    current = this;
  }

  final Locale locale;
  static AppLocalizations current = AppLocalizations._fallback();

  AppLocalizations._fallback() : locale = const Locale('zh', 'CN');

  static const supportedLocales = <Locale>[
    Locale('zh', 'CN'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('de'),
  ];

  static const delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  static Locale resolveLocale(List<Locale>? preferred, Iterable<Locale> _) {
    for (final locale in preferred ?? const <Locale>[]) {
      if (locale.languageCode == 'zh') {
        final traditional =
            locale.scriptCode == 'Hant' ||
            const {'TW', 'HK', 'MO'}.contains(locale.countryCode);
        return traditional
            ? const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')
            : const Locale('zh', 'CN');
      }
      if (const {'en', 'es', 'fr', 'de'}.contains(locale.languageCode)) {
        return Locale(locale.languageCode);
      }
    }
    return const Locale('zh', 'CN');
  }

  String get _code {
    if (locale.languageCode == 'zh') {
      return locale.scriptCode == 'Hant' ||
              const {'TW', 'HK', 'MO'}.contains(locale.countryCode)
          ? 'zh_Hant'
          : 'zh';
    }
    return locale.languageCode;
  }

  String t(String key) =>
      (_values[_code] ?? _values['zh']!)[key] ?? _values['zh']![key] ?? key;

  String get appName => 'Pictools';

  String toolName(String id) => t('tool.$id.name');
  String toolDescription(String id) => t('tool.$id.description');

  static final _values = <String, Map<String, String>>{
    'zh': {
      ..._commonZh,
      'tagline': '图片工具集合',
      'settings': '设置',
      'settingsSubtitle': '语言、隐私与应用信息',
      'language': '语言',
      'languageHint': '选择界面语言',
      'systemLanguage': '跟随系统',
      'privacy': '隐私政策',
      'privacyHint': '了解数据如何在设备上处理',
      'about': '关于',
      'version': '版本',
      'localProcessing': '本地图片处理',
      'back': '返回',
      'close': '关闭',
      'tool.image_compare.name': '图片对比',
      'tool.image_compare.description': '对比两张图片，清晰查看差异并切换多种对比模式',
      'tool.image_adjust.name': '图片调整',
      'tool.image_adjust.description': '调整尺寸或按比例裁剪，快速得到所需画面',
      'tool.image_enhance.name': '亮度增强',
      'tool.image_enhance.description': '提升亮度和暗部细节，让画面更清晰通透',
      'tool.background_removal.name': '主体抠图',
      'tool.background_removal.description': '本地识别主体并移除背景，支持透明或纯色导出',
      'tool.image_converter.name': '格式转换',
      'tool.image_converter.description': '批量转换 PNG、JPG、WebP、BMP、ICO 和 TIFF',
      'openCurrent': '在当前窗口打开',
      'openNew': '在新窗口打开',
      'privacyTitle': '隐私政策',
      'privacyUpdated': '更新日期：2026年7月27日',
      'privacyIntroTitle': '我们的原则',
      'privacyIntro': 'Pictools 没有自有服务器，不要求注册账号，也不使用广告、分析或追踪 SDK。',
      'privacyLocalTitle': '图片处理',
      'privacyLocal':
          '图片对比、调整、亮度增强和格式转换均在您的设备上完成。应用不会将图片上传给我们。Android 版不申请网络权限。',
      'privacyFilesTitle': '文件访问',
      'privacyFiles': '您通过系统文件选择器主动选择图片，并决定导出位置。应用不会扫描您的相册，也不会在未经操作的情况下访问其他文件。',
      'privacyPrefsTitle': '本地设置',
      'privacyPrefs': '您选择的界面语言仅保存在设备本地，可随时改为跟随系统。',
      'privacyDesktopTitle': '桌面版抠图模型',
      'privacyDesktop':
          '桌面版仅在您主动下载抠图模型时连接 Hugging Face。模型下载后，推理完全在本地完成；图片不会发送给 Hugging Face。',
      'privacySharingTitle': '数据共享',
      'privacySharing': '我们不收集、出售或共享您的个人数据。卸载应用会由操作系统清除应用保存的本地偏好。',
      'privacyContactTitle': '联系我们',
      'privacyContact': '如对本政策有疑问，请通过应用商店页面提供的开发者联系方式联系我们。',
    },
    'zh_Hant': {
      ..._commonZhHant,
      'tagline': '圖片工具集合',
      'settings': '設定',
      'settingsSubtitle': '語言、隱私與應用程式資訊',
      'language': '語言',
      'languageHint': '選擇介面語言',
      'systemLanguage': '跟隨系統',
      'privacy': '隱私權政策',
      'privacyHint': '瞭解資料如何在裝置上處理',
      'about': '關於',
      'version': '版本',
      'localProcessing': '本機圖片處理',
      'back': '返回',
      'close': '關閉',
      'tool.image_compare.name': '圖片比較',
      'tool.image_compare.description': '比較兩張圖片，清楚查看差異並切換多種比較模式',
      'tool.image_adjust.name': '圖片調整',
      'tool.image_adjust.description': '調整尺寸或依比例裁切，快速取得所需畫面',
      'tool.image_enhance.name': '亮度增強',
      'tool.image_enhance.description': '提升亮度與暗部細節，讓畫面更清晰透亮',
      'tool.background_removal.name': '主體去背',
      'tool.background_removal.description': '在本機辨識主體並移除背景，支援透明或純色匯出',
      'tool.image_converter.name': '格式轉換',
      'tool.image_converter.description': '批次轉換 PNG、JPG、WebP、BMP、ICO 與 TIFF',
      'openCurrent': '在目前視窗開啟',
      'openNew': '在新視窗開啟',
      'privacyTitle': '隱私權政策',
      'privacyUpdated': '更新日期：2026年7月27日',
      'privacyIntroTitle': '我們的原則',
      'privacyIntro': 'Pictools 沒有自有伺服器，不要求註冊帳號，也不使用廣告、分析或追蹤 SDK。',
      'privacyLocalTitle': '圖片處理',
      'privacyLocal':
          '圖片比較、調整、亮度增強與格式轉換都在您的裝置上完成。應用程式不會將圖片上傳給我們。Android 版不要求網路權限。',
      'privacyFilesTitle': '檔案存取',
      'privacyFiles': '您透過系統檔案選擇器主動選取圖片，並決定匯出位置。應用程式不會掃描相簿，也不會在未經操作時存取其他檔案。',
      'privacyPrefsTitle': '本機設定',
      'privacyPrefs': '您選擇的介面語言只會儲存在裝置本機，並可隨時改為跟隨系統。',
      'privacyDesktopTitle': '桌面版去背模型',
      'privacyDesktop':
          '桌面版只會在您主動下載去背模型時連線至 Hugging Face。模型下載後，推論完全在本機完成；圖片不會傳送給 Hugging Face。',
      'privacySharingTitle': '資料分享',
      'privacySharing': '我們不收集、出售或分享您的個人資料。解除安裝時，作業系統會清除應用程式儲存的本機偏好。',
      'privacyContactTitle': '聯絡我們',
      'privacyContact': '若對本政策有疑問，請使用應用程式商店頁面所列的開發者聯絡方式。',
    },
    'en': {
      ..._commonEn,
      'tagline': 'Everyday image tools',
      'settings': 'Settings',
      'settingsSubtitle': 'Language, privacy, and app information',
      'language': 'Language',
      'languageHint': 'Choose the display language',
      'systemLanguage': 'Use system language',
      'privacy': 'Privacy policy',
      'privacyHint': 'See how your data is handled on this device',
      'about': 'About',
      'version': 'Version',
      'localProcessing': 'On-device image processing',
      'back': 'Back',
      'close': 'Close',
      'tool.image_compare.name': 'Compare images',
      'tool.image_compare.description':
          'Compare two images and inspect differences in several viewing modes',
      'tool.image_adjust.name': 'Resize and crop',
      'tool.image_adjust.description':
          'Resize or crop to an aspect ratio for the exact framing you need',
      'tool.image_enhance.name': 'Enhance brightness',
      'tool.image_enhance.description':
          'Lift brightness and shadow detail for a clearer image',
      'tool.background_removal.name': 'Remove background',
      'tool.background_removal.description':
          'Detect the subject locally and export it on a transparent or solid background',
      'tool.image_converter.name': 'Convert format',
      'tool.image_converter.description':
          'Batch convert PNG, JPG, WebP, BMP, ICO, and TIFF images',
      'openCurrent': 'Open in this window',
      'openNew': 'Open in a new window',
      'privacyTitle': 'Privacy Policy',
      'privacyUpdated': 'Last updated: July 27, 2026',
      'privacyIntroTitle': 'Our approach',
      'privacyIntro':
          'Pictools has no proprietary servers, requires no account, and includes no advertising, analytics, or tracking SDKs.',
      'privacyLocalTitle': 'Image processing',
      'privacyLocal':
          'Image comparison, adjustment, brightness enhancement, and format conversion take place on your device. The app does not upload your images to us. The Android app requests no network permission.',
      'privacyFilesTitle': 'File access',
      'privacyFiles':
          'You choose images and export locations through the system file picker. The app does not scan your library or access other files without an action from you.',
      'privacyPrefsTitle': 'Local settings',
      'privacyPrefs':
          'Your display-language preference is stored only on this device and can be changed back to the system setting at any time.',
      'privacyDesktopTitle': 'Desktop background-removal model',
      'privacyDesktop':
          'The desktop app connects to Hugging Face only when you choose to download the background-removal model. Once downloaded, inference runs entirely on your device; images are not sent to Hugging Face.',
      'privacySharingTitle': 'Data sharing',
      'privacySharing':
          'We do not collect, sell, or share your personal data. Your operating system removes locally stored app preferences when you uninstall the app.',
      'privacyContactTitle': 'Contact',
      'privacyContact':
          'Questions about this policy can be sent using the developer contact details on the app store listing.',
    },
    'es': {
      ..._commonEs,
      'tagline': 'Herramientas para imágenes',
      'settings': 'Ajustes',
      'settingsSubtitle': 'Idioma, privacidad e información de la aplicación',
      'language': 'Idioma',
      'languageHint': 'Elige el idioma de la interfaz',
      'systemLanguage': 'Usar el idioma del sistema',
      'privacy': 'Política de privacidad',
      'privacyHint': 'Consulta cómo se tratan los datos en este dispositivo',
      'about': 'Acerca de',
      'version': 'Versión',
      'localProcessing': 'Procesamiento de imágenes en el dispositivo',
      'back': 'Volver',
      'close': 'Cerrar',
      'tool.image_compare.name': 'Comparar imágenes',
      'tool.image_compare.description':
          'Compara dos imágenes y examina las diferencias con varios modos de vista',
      'tool.image_adjust.name': 'Redimensionar y recortar',
      'tool.image_adjust.description':
          'Cambia el tamaño o recorta con una proporción para obtener el encuadre que buscas',
      'tool.image_enhance.name': 'Mejorar brillo',
      'tool.image_enhance.description':
          'Aumenta el brillo y el detalle de las sombras para aclarar la imagen',
      'tool.background_removal.name': 'Quitar fondo',
      'tool.background_removal.description':
          'Detecta el sujeto en el dispositivo y expórtalo con fondo transparente o sólido',
      'tool.image_converter.name': 'Convertir formato',
      'tool.image_converter.description':
          'Convierte por lotes imágenes PNG, JPG, WebP, BMP, ICO y TIFF',
      'openCurrent': 'Abrir en esta ventana',
      'openNew': 'Abrir en otra ventana',
      'privacyTitle': 'Política de privacidad',
      'privacyUpdated': 'Última actualización: 27 de julio de 2026',
      'privacyIntroTitle': 'Nuestro enfoque',
      'privacyIntro':
          'Pictools no dispone de servidores propios, no requiere una cuenta y no incluye SDK de publicidad, análisis ni seguimiento.',
      'privacyLocalTitle': 'Procesamiento de imágenes',
      'privacyLocal':
          'La comparación, el ajuste, la mejora del brillo y la conversión se realizan en el dispositivo. La aplicación no nos envía tus imágenes. La versión para Android no solicita acceso a Internet.',
      'privacyFilesTitle': 'Acceso a archivos',
      'privacyFiles':
          'Tú eliges las imágenes y el destino de exportación mediante el selector de archivos del sistema. La aplicación no examina la galería ni accede a otros archivos sin una acción tuya.',
      'privacyPrefsTitle': 'Ajustes locales',
      'privacyPrefs':
          'La preferencia de idioma solo se guarda en el dispositivo y puedes volver al idioma del sistema cuando quieras.',
      'privacyDesktopTitle': 'Modelo para quitar fondos en escritorio',
      'privacyDesktop':
          'La aplicación de escritorio solo se conecta a Hugging Face cuando decides descargar el modelo. Después, el procesamiento se realiza íntegramente en el dispositivo y las imágenes no se envían a Hugging Face.',
      'privacySharingTitle': 'Datos compartidos',
      'privacySharing':
          'No recopilamos, vendemos ni compartimos tus datos personales. El sistema operativo elimina las preferencias locales al desinstalar la aplicación.',
      'privacyContactTitle': 'Contacto',
      'privacyContact':
          'Para cualquier consulta, utiliza los datos de contacto del desarrollador que aparecen en la ficha de la tienda de aplicaciones.',
    },
    'fr': {
      ..._commonFr,
      'tagline': 'Outils de traitement d’image',
      'settings': 'Paramètres',
      'settingsSubtitle':
          'Langue, confidentialité et informations sur l’application',
      'language': 'Langue',
      'languageHint': 'Choisissez la langue de l’interface',
      'systemLanguage': 'Utiliser la langue du système',
      'privacy': 'Politique de confidentialité',
      'privacyHint':
          'Découvrez comment les données sont traitées sur cet appareil',
      'about': 'À propos',
      'version': 'Version',
      'localProcessing': 'Traitement des images sur l’appareil',
      'back': 'Retour',
      'close': 'Fermer',
      'tool.image_compare.name': 'Comparer des images',
      'tool.image_compare.description':
          'Comparez deux images et examinez les différences avec plusieurs modes d’affichage',
      'tool.image_adjust.name': 'Redimensionner et recadrer',
      'tool.image_adjust.description':
          'Redimensionnez ou recadrez selon un format pour obtenir le cadrage souhaité',
      'tool.image_enhance.name': 'Améliorer la luminosité',
      'tool.image_enhance.description':
          'Éclaircissez l’image et révélez les détails dans les ombres',
      'tool.background_removal.name': 'Supprimer l’arrière-plan',
      'tool.background_removal.description':
          'Détectez le sujet localement et exportez-le sur un fond transparent ou uni',
      'tool.image_converter.name': 'Convertir le format',
      'tool.image_converter.description':
          'Convertissez par lots des images PNG, JPG, WebP, BMP, ICO et TIFF',
      'openCurrent': 'Ouvrir dans cette fenêtre',
      'openNew': 'Ouvrir dans une nouvelle fenêtre',
      'privacyTitle': 'Politique de confidentialité',
      'privacyUpdated': 'Dernière mise à jour : 27 juillet 2026',
      'privacyIntroTitle': 'Notre approche',
      'privacyIntro':
          'Pictools ne possède aucun serveur, ne demande aucun compte et n’intègre aucun SDK publicitaire, analytique ou de suivi.',
      'privacyLocalTitle': 'Traitement des images',
      'privacyLocal':
          'La comparaison, l’ajustement, l’amélioration de la luminosité et la conversion ont lieu sur votre appareil. L’application ne nous envoie pas vos images. La version Android ne demande aucun accès à Internet.',
      'privacyFilesTitle': 'Accès aux fichiers',
      'privacyFiles':
          'Vous choisissez les images et l’emplacement d’exportation avec le sélecteur de fichiers du système. L’application n’analyse pas votre photothèque et n’accède à aucun autre fichier sans action de votre part.',
      'privacyPrefsTitle': 'Paramètres locaux',
      'privacyPrefs':
          'Votre choix de langue est enregistré uniquement sur cet appareil et peut être rétabli sur la langue du système à tout moment.',
      'privacyDesktopTitle': 'Modèle de détourage sur ordinateur',
      'privacyDesktop':
          'L’application de bureau se connecte à Hugging Face uniquement lorsque vous choisissez de télécharger le modèle. Ensuite, l’inférence s’exécute entièrement sur votre appareil et aucune image n’est envoyée à Hugging Face.',
      'privacySharingTitle': 'Partage des données',
      'privacySharing':
          'Nous ne collectons, ne vendons ni ne partageons vos données personnelles. Le système d’exploitation supprime les préférences locales lors de la désinstallation.',
      'privacyContactTitle': 'Contact',
      'privacyContact':
          'Pour toute question, utilisez les coordonnées du développeur indiquées sur la fiche de l’application.',
    },
    'de': {
      ..._commonDe,
      'tagline': 'Praktische Bildwerkzeuge',
      'settings': 'Einstellungen',
      'settingsSubtitle': 'Sprache, Datenschutz und App-Informationen',
      'language': 'Sprache',
      'languageHint': 'Sprache der Benutzeroberfläche auswählen',
      'systemLanguage': 'Systemsprache verwenden',
      'privacy': 'Datenschutzerklärung',
      'privacyHint': 'So werden Daten auf diesem Gerät verarbeitet',
      'about': 'Über die App',
      'version': 'Version',
      'localProcessing': 'Bildverarbeitung auf dem Gerät',
      'back': 'Zurück',
      'close': 'Schließen',
      'tool.image_compare.name': 'Bilder vergleichen',
      'tool.image_compare.description':
          'Zwei Bilder vergleichen und Unterschiede in mehreren Ansichten prüfen',
      'tool.image_adjust.name': 'Größe und Zuschnitt',
      'tool.image_adjust.description':
          'Bildgröße ändern oder für den gewünschten Ausschnitt auf ein Seitenverhältnis zuschneiden',
      'tool.image_enhance.name': 'Helligkeit verbessern',
      'tool.image_enhance.description':
          'Helligkeit und Schattendetails für ein klareres Bild anheben',
      'tool.background_removal.name': 'Hintergrund entfernen',
      'tool.background_removal.description':
          'Motiv lokal erkennen und mit transparentem oder einfarbigem Hintergrund exportieren',
      'tool.image_converter.name': 'Format konvertieren',
      'tool.image_converter.description':
          'PNG-, JPG-, WebP-, BMP-, ICO- und TIFF-Bilder stapelweise konvertieren',
      'openCurrent': 'In diesem Fenster öffnen',
      'openNew': 'In neuem Fenster öffnen',
      'privacyTitle': 'Datenschutzerklärung',
      'privacyUpdated': 'Stand: 27. Juli 2026',
      'privacyIntroTitle': 'Unser Ansatz',
      'privacyIntro':
          'Pictools betreibt keine eigenen Server, erfordert kein Konto und enthält keine Werbe-, Analyse- oder Tracking-SDKs.',
      'privacyLocalTitle': 'Bildverarbeitung',
      'privacyLocal':
          'Bildvergleich, Anpassung, Helligkeitsverbesserung und Formatkonvertierung erfolgen auf Ihrem Gerät. Die App lädt Ihre Bilder nicht zu uns hoch. Die Android-App fordert keine Netzwerkberechtigung an.',
      'privacyFilesTitle': 'Dateizugriff',
      'privacyFiles':
          'Sie wählen Bilder und Exportziele über die Systemdateiauswahl aus. Die App durchsucht Ihre Galerie nicht und greift ohne Ihre Aktion nicht auf andere Dateien zu.',
      'privacyPrefsTitle': 'Lokale Einstellungen',
      'privacyPrefs':
          'Ihre Sprachauswahl wird nur auf diesem Gerät gespeichert und kann jederzeit wieder auf die Systemsprache gesetzt werden.',
      'privacyDesktopTitle': 'Desktop-Modell zur Hintergrundentfernung',
      'privacyDesktop':
          'Die Desktop-App verbindet sich nur dann mit Hugging Face, wenn Sie das Modell herunterladen. Danach läuft die Verarbeitung vollständig auf Ihrem Gerät; Bilder werden nicht an Hugging Face gesendet.',
      'privacySharingTitle': 'Datenweitergabe',
      'privacySharing':
          'Wir erheben, verkaufen oder teilen keine personenbezogenen Daten. Beim Deinstallieren entfernt das Betriebssystem die lokal gespeicherten App-Einstellungen.',
      'privacyContactTitle': 'Kontakt',
      'privacyContact':
          'Bei Fragen nutzen Sie bitte die Kontaktdaten des Entwicklers im Eintrag des App Stores.',
    },
  };
}

String appText(String key) => AppLocalizations.current.t(key);

const _commonZh = <String, String>{
  'compareTitle': '图片对比',
  'compareSubtitle': '对比两张图片，清晰查看差异',
  'adjustTitle': '图片调整',
  'adjustSubtitle': '调整图片尺寸，按比例裁剪',
  'enhanceTitle': '亮度增强',
  'enhanceSubtitle': '提升图片亮度，改善暗部细节',
  'converterTitle': '图片格式转换',
  'detach': '分离到新窗口',
  'reset': '重置',
  'clear': '清除',
  'selectImage': '选择图片',
  'originalA': '原图 A',
  'overlayOriginal': '原图 A（底层）',
  'overlayComparison': '对比图 B（透明度：{opacity}%）',
  'chooseSaveFolder': '选择保存目录',
  'comparisonB': '对比图 B',
  'uploadTwoImages': '请先选择两张图片进行对比',
  'supportedFormats': '支持 PNG、JPG、GIF、WebP 和 BMP',
  'opacity': '透明度',
  'dragOrTap': '拖拽或点击选择',
  'pathCopied': '路径已复制',
  'imageCopied': '图片已复制',
  'copyPath': '复制路径',
  'replaceImage': '替换图片',
  'deleteImage': '删除图片',
  'copyImage': '复制图片',
  'pasteReplace': '粘贴替换',
  'pasteImage': '粘贴图片',
  'clipboardEmpty': '剪贴板中没有图片',
  'cropRatio': '裁剪比例',
  'exportFormat': '导出格式',
  'exportImage': '导出图片',
  'exporting': '正在导出图片…',
  'saved': '图片已保存',
  'savedTo': '图片已保存至：{path}',
  'exportFailed': '导出失败：{error}',
  'width': '宽度',
  'height': '高度',
  'originalSize': '原始尺寸：{width} × {height}',
  'ratioLocked': '比例已锁定',
  'ratioUnlocked': '比例未锁定',
  'addImages': '添加图片',
  'clearList': '清空列表',
  'tapAddImages': '点击上方按钮添加图片',
  'dropOrAddImages': '拖拽图片到这里或点击添加',
  'outputFormat': '输出格式：',
  'startConversion': '开始转换',
  'converting': '正在转换图片…',
  'conversionDone': '所有图片转换完成',
  'conversionPartial': '转换完成，{count} 个文件未保存',
  'conversionFailed': '转换出错：{error}',
  'original': '原图',
  'enhanced': '增强后',
  'waiting': '等待处理',
  'processing': '处理中…',
  'imageInfo': '图片信息',
  'fileName': '文件名',
  'dimensions': '尺寸',
  'enhanceInfo': '自动调整曝光、高光、阴影和饱和度，让画面更明亮',
  'processAgain': '重新处理',
  'startEnhance': '开始增强',
  'processingFailed': '处理失败：{error}',
  'mode.slider': '滑块',
  'mode.sideBySide': '并排',
  'mode.overlay': '叠加',
  'ratio.free': '自由',
  'adjust.resize': '尺寸调整',
  'adjust.crop': '比例裁剪',
  'adjust.resizeDescription': '自定义图片宽高',
  'adjust.cropDescription': '按比例裁剪图片',
};

const _commonZhHant = <String, String>{
  'compareTitle': '圖片比較',
  'compareSubtitle': '比較兩張圖片，清楚查看差異',
  'adjustTitle': '圖片調整',
  'adjustSubtitle': '調整圖片尺寸，依比例裁切',
  'enhanceTitle': '亮度增強',
  'enhanceSubtitle': '提升圖片亮度，改善暗部細節',
  'converterTitle': '圖片格式轉換',
  'detach': '移至新視窗',
  'reset': '重設',
  'clear': '清除',
  'selectImage': '選擇圖片',
  'originalA': '原圖 A',
  'overlayOriginal': '原圖 A（底層）',
  'overlayComparison': '比較圖 B（透明度：{opacity}%）',
  'chooseSaveFolder': '選擇儲存位置',
  'comparisonB': '比較圖 B',
  'uploadTwoImages': '請先選擇兩張圖片進行比較',
  'supportedFormats': '支援 PNG、JPG、GIF、WebP 與 BMP',
  'opacity': '透明度',
  'dragOrTap': '拖曳或點選',
  'pathCopied': '路徑已複製',
  'imageCopied': '圖片已複製',
  'copyPath': '複製路徑',
  'replaceImage': '更換圖片',
  'deleteImage': '刪除圖片',
  'copyImage': '複製圖片',
  'pasteReplace': '貼上並取代',
  'pasteImage': '貼上圖片',
  'clipboardEmpty': '剪貼簿中沒有圖片',
  'cropRatio': '裁切比例',
  'exportFormat': '匯出格式',
  'exportImage': '匯出圖片',
  'exporting': '正在匯出圖片…',
  'saved': '圖片已儲存',
  'savedTo': '圖片已儲存至：{path}',
  'exportFailed': '匯出失敗：{error}',
  'width': '寬度',
  'height': '高度',
  'originalSize': '原始尺寸：{width} × {height}',
  'ratioLocked': '比例已鎖定',
  'ratioUnlocked': '比例未鎖定',
  'addImages': '新增圖片',
  'clearList': '清除清單',
  'tapAddImages': '點選上方按鈕新增圖片',
  'dropOrAddImages': '將圖片拖到這裡或點選新增',
  'outputFormat': '輸出格式：',
  'startConversion': '開始轉換',
  'converting': '正在轉換圖片…',
  'conversionDone': '所有圖片轉換完成',
  'conversionPartial': '轉換完成，{count} 個檔案未儲存',
  'conversionFailed': '轉換失敗：{error}',
  'original': '原圖',
  'enhanced': '增強後',
  'waiting': '等待處理',
  'processing': '處理中…',
  'imageInfo': '圖片資訊',
  'fileName': '檔案名稱',
  'dimensions': '尺寸',
  'enhanceInfo': '自動調整曝光、亮部、陰影與飽和度，讓畫面更明亮',
  'processAgain': '重新處理',
  'startEnhance': '開始增強',
  'processingFailed': '處理失敗：{error}',
  'mode.slider': '滑桿',
  'mode.sideBySide': '並排',
  'mode.overlay': '疊加',
  'ratio.free': '自由',
  'adjust.resize': '尺寸調整',
  'adjust.crop': '比例裁切',
  'adjust.resizeDescription': '自訂圖片寬高',
  'adjust.cropDescription': '依比例裁切圖片',
};

const _commonEn = <String, String>{
  'compareTitle': 'Compare images',
  'compareSubtitle': 'Compare two images and inspect every difference',
  'adjustTitle': 'Resize and crop',
  'adjustSubtitle': 'Resize an image or crop it to an aspect ratio',
  'enhanceTitle': 'Enhance brightness',
  'enhanceSubtitle': 'Improve brightness and reveal shadow detail',
  'converterTitle': 'Convert image format',
  'detach': 'Open in a new window',
  'reset': 'Reset',
  'clear': 'Clear',
  'selectImage': 'Choose image',
  'originalA': 'Original A',
  'overlayOriginal': 'Original A (bottom)',
  'overlayComparison': 'Comparison B ({opacity}% opacity)',
  'chooseSaveFolder': 'Choose a save folder',
  'comparisonB': 'Comparison B',
  'uploadTwoImages': 'Choose two images to compare',
  'supportedFormats': 'Supports PNG, JPG, GIF, WebP, and BMP',
  'opacity': 'Opacity',
  'dragOrTap': 'Drop or click to choose',
  'pathCopied': 'Path copied',
  'imageCopied': 'Image copied',
  'copyPath': 'Copy path',
  'replaceImage': 'Replace image',
  'deleteImage': 'Remove image',
  'copyImage': 'Copy image',
  'pasteReplace': 'Paste and replace',
  'pasteImage': 'Paste image',
  'clipboardEmpty': 'No image on the clipboard',
  'cropRatio': 'Crop ratio',
  'exportFormat': 'Export format',
  'exportImage': 'Export image',
  'exporting': 'Exporting image…',
  'saved': 'Image saved',
  'savedTo': 'Image saved to {path}',
  'exportFailed': 'Export failed: {error}',
  'width': 'Width',
  'height': 'Height',
  'originalSize': 'Original size: {width} × {height}',
  'ratioLocked': 'Aspect ratio locked',
  'ratioUnlocked': 'Aspect ratio unlocked',
  'addImages': 'Add images',
  'clearList': 'Clear list',
  'tapAddImages': 'Use the button above to add images',
  'dropOrAddImages': 'Drop images here or click Add',
  'outputFormat': 'Output format:',
  'startConversion': 'Convert',
  'converting': 'Converting images…',
  'conversionDone': 'All images converted',
  'conversionPartial': 'Conversion complete; {count} file(s) were not saved',
  'conversionFailed': 'Conversion failed: {error}',
  'original': 'Original',
  'enhanced': 'Enhanced',
  'waiting': 'Ready to process',
  'processing': 'Processing…',
  'imageInfo': 'Image information',
  'fileName': 'File name',
  'dimensions': 'Dimensions',
  'enhanceInfo':
      'Automatically adjusts exposure, highlights, shadows, and saturation for a brighter image',
  'processAgain': 'Process again',
  'startEnhance': 'Enhance',
  'processingFailed': 'Processing failed: {error}',
  'mode.slider': 'Slider',
  'mode.sideBySide': 'Side by side',
  'mode.overlay': 'Overlay',
  'ratio.free': 'Free',
  'adjust.resize': 'Resize',
  'adjust.crop': 'Crop ratio',
  'adjust.resizeDescription': 'Set a custom width and height',
  'adjust.cropDescription': 'Crop to an aspect ratio',
};

final _commonEs = Map<String, String>.of(_commonEn)
  ..addAll({
    'compareTitle': 'Comparar imágenes',
    'compareSubtitle': 'Compara dos imágenes y examina cada diferencia',
    'adjustTitle': 'Redimensionar y recortar',
    'adjustSubtitle': 'Cambia el tamaño o recorta con una proporción',
    'enhanceTitle': 'Mejorar brillo',
    'enhanceSubtitle': 'Mejora el brillo y recupera detalles de las sombras',
    'converterTitle': 'Convertir formato de imagen',
    'detach': 'Abrir en otra ventana',
    'reset': 'Restablecer',
    'clear': 'Borrar',
    'selectImage': 'Elegir imagen',
    'originalA': 'Original A',
    'overlayOriginal': 'Original A (abajo)',
    'overlayComparison': 'Comparación B (opacidad: {opacity}%)',
    'chooseSaveFolder': 'Elegir carpeta de destino',
    'comparisonB': 'Comparación B',
    'uploadTwoImages': 'Elige dos imágenes para compararlas',
    'supportedFormats': 'Admite PNG, JPG, GIF, WebP y BMP',
    'opacity': 'Opacidad',
    'dragOrTap': 'Arrastra o haz clic para elegir',
    'pathCopied': 'Ruta copiada',
    'imageCopied': 'Imagen copiada',
    'copyPath': 'Copiar ruta',
    'replaceImage': 'Sustituir imagen',
    'deleteImage': 'Quitar imagen',
    'copyImage': 'Copiar imagen',
    'pasteReplace': 'Pegar y sustituir',
    'pasteImage': 'Pegar imagen',
    'clipboardEmpty': 'No hay ninguna imagen en el portapapeles',
    'cropRatio': 'Proporción de recorte',
    'exportFormat': 'Formato de exportación',
    'exportImage': 'Exportar imagen',
    'exporting': 'Exportando imagen…',
    'saved': 'Imagen guardada',
    'savedTo': 'Imagen guardada en {path}',
    'exportFailed': 'Error al exportar: {error}',
    'width': 'Anchura',
    'height': 'Altura',
    'originalSize': 'Tamaño original: {width} × {height}',
    'ratioLocked': 'Proporción bloqueada',
    'ratioUnlocked': 'Proporción desbloqueada',
    'addImages': 'Añadir imágenes',
    'clearList': 'Vaciar lista',
    'tapAddImages': 'Usa el botón de arriba para añadir imágenes',
    'dropOrAddImages': 'Arrastra imágenes aquí o pulsa Añadir',
    'outputFormat': 'Formato de salida:',
    'startConversion': 'Convertir',
    'converting': 'Convirtiendo imágenes…',
    'conversionDone': 'Todas las imágenes se han convertido',
    'conversionPartial':
        'Conversión terminada; no se guardaron {count} archivo(s)',
    'conversionFailed': 'Error de conversión: {error}',
    'original': 'Original',
    'enhanced': 'Mejorada',
    'waiting': 'Lista para procesar',
    'processing': 'Procesando…',
    'imageInfo': 'Información de la imagen',
    'fileName': 'Nombre del archivo',
    'dimensions': 'Dimensiones',
    'enhanceInfo':
        'Ajusta automáticamente la exposición, las luces, las sombras y la saturación',
    'processAgain': 'Procesar de nuevo',
    'startEnhance': 'Mejorar',
    'processingFailed': 'Error de procesamiento: {error}',
    'mode.slider': 'Deslizador',
    'mode.sideBySide': 'En paralelo',
    'mode.overlay': 'Superposición',
    'ratio.free': 'Libre',
    'adjust.resize': 'Redimensionar',
    'adjust.crop': 'Recortar',
    'adjust.resizeDescription': 'Define una anchura y altura personalizadas',
    'adjust.cropDescription': 'Recorta con una proporción',
  });

final _commonFr = Map<String, String>.of(_commonEn)
  ..addAll({
    'compareTitle': 'Comparer des images',
    'compareSubtitle': 'Comparez deux images et examinez chaque différence',
    'adjustTitle': 'Redimensionner et recadrer',
    'adjustSubtitle': 'Redimensionnez une image ou recadrez-la selon un format',
    'enhanceTitle': 'Améliorer la luminosité',
    'enhanceSubtitle':
        'Éclaircissez l’image et révélez les détails dans les ombres',
    'converterTitle': 'Convertir le format d’image',
    'detach': 'Ouvrir dans une nouvelle fenêtre',
    'reset': 'Réinitialiser',
    'clear': 'Effacer',
    'selectImage': 'Choisir une image',
    'originalA': 'Original A',
    'overlayOriginal': 'Original A (dessous)',
    'overlayComparison': 'Comparaison B (opacité : {opacity} %)',
    'chooseSaveFolder': 'Choisir le dossier de destination',
    'comparisonB': 'Comparaison B',
    'uploadTwoImages': 'Choisissez deux images à comparer',
    'supportedFormats': 'Formats pris en charge : PNG, JPG, GIF, WebP et BMP',
    'opacity': 'Opacité',
    'dragOrTap': 'Déposez ou cliquez pour choisir',
    'pathCopied': 'Chemin copié',
    'imageCopied': 'Image copiée',
    'copyPath': 'Copier le chemin',
    'replaceImage': 'Remplacer l’image',
    'deleteImage': 'Supprimer l’image',
    'copyImage': 'Copier l’image',
    'pasteReplace': 'Coller et remplacer',
    'pasteImage': 'Coller l’image',
    'clipboardEmpty': 'Aucune image dans le presse-papiers',
    'cropRatio': 'Format de recadrage',
    'exportFormat': 'Format d’exportation',
    'exportImage': 'Exporter l’image',
    'exporting': 'Exportation de l’image…',
    'saved': 'Image enregistrée',
    'savedTo': 'Image enregistrée dans {path}',
    'exportFailed': 'Échec de l’exportation : {error}',
    'width': 'Largeur',
    'height': 'Hauteur',
    'originalSize': 'Taille d’origine : {width} × {height}',
    'ratioLocked': 'Proportions verrouillées',
    'ratioUnlocked': 'Proportions déverrouillées',
    'addImages': 'Ajouter des images',
    'clearList': 'Vider la liste',
    'tapAddImages': 'Utilisez le bouton ci-dessus pour ajouter des images',
    'dropOrAddImages': 'Déposez des images ici ou cliquez sur Ajouter',
    'outputFormat': 'Format de sortie :',
    'startConversion': 'Convertir',
    'converting': 'Conversion des images…',
    'conversionDone': 'Toutes les images ont été converties',
    'conversionPartial':
        'Conversion terminée ; {count} fichier(s) non enregistré(s)',
    'conversionFailed': 'Échec de la conversion : {error}',
    'original': 'Original',
    'enhanced': 'Améliorée',
    'waiting': 'Prête à être traitée',
    'processing': 'Traitement…',
    'imageInfo': 'Informations sur l’image',
    'fileName': 'Nom du fichier',
    'dimensions': 'Dimensions',
    'enhanceInfo':
        'Ajuste automatiquement l’exposition, les hautes lumières, les ombres et la saturation',
    'processAgain': 'Traiter à nouveau',
    'startEnhance': 'Améliorer',
    'processingFailed': 'Échec du traitement : {error}',
    'mode.slider': 'Curseur',
    'mode.sideBySide': 'Côte à côte',
    'mode.overlay': 'Superposition',
    'ratio.free': 'Libre',
    'adjust.resize': 'Redimensionner',
    'adjust.crop': 'Recadrer',
    'adjust.resizeDescription':
        'Définir une largeur et une hauteur personnalisées',
    'adjust.cropDescription': 'Recadrer selon un format',
  });

final _commonDe = Map<String, String>.of(_commonEn)
  ..addAll({
    'compareTitle': 'Bilder vergleichen',
    'compareSubtitle': 'Zwei Bilder vergleichen und jeden Unterschied prüfen',
    'adjustTitle': 'Größe und Zuschnitt',
    'adjustSubtitle':
        'Bildgröße ändern oder auf ein Seitenverhältnis zuschneiden',
    'enhanceTitle': 'Helligkeit verbessern',
    'enhanceSubtitle': 'Helligkeit anheben und Schattendetails sichtbar machen',
    'converterTitle': 'Bildformat konvertieren',
    'detach': 'In neuem Fenster öffnen',
    'reset': 'Zurücksetzen',
    'clear': 'Leeren',
    'selectImage': 'Bild auswählen',
    'originalA': 'Original A',
    'overlayOriginal': 'Original A (unten)',
    'overlayComparison': 'Vergleich B ({opacity} % Deckkraft)',
    'chooseSaveFolder': 'Speicherordner auswählen',
    'comparisonB': 'Vergleich B',
    'uploadTwoImages': 'Wählen Sie zwei Bilder zum Vergleichen aus',
    'supportedFormats': 'Unterstützt PNG, JPG, GIF, WebP und BMP',
    'opacity': 'Deckkraft',
    'dragOrTap': 'Ablegen oder zum Auswählen klicken',
    'pathCopied': 'Pfad kopiert',
    'imageCopied': 'Bild kopiert',
    'copyPath': 'Pfad kopieren',
    'replaceImage': 'Bild ersetzen',
    'deleteImage': 'Bild entfernen',
    'copyImage': 'Bild kopieren',
    'pasteReplace': 'Einfügen und ersetzen',
    'pasteImage': 'Bild einfügen',
    'clipboardEmpty': 'Kein Bild in der Zwischenablage',
    'cropRatio': 'Seitenverhältnis',
    'exportFormat': 'Exportformat',
    'exportImage': 'Bild exportieren',
    'exporting': 'Bild wird exportiert…',
    'saved': 'Bild gespeichert',
    'savedTo': 'Bild gespeichert unter {path}',
    'exportFailed': 'Export fehlgeschlagen: {error}',
    'width': 'Breite',
    'height': 'Höhe',
    'originalSize': 'Originalgröße: {width} × {height}',
    'ratioLocked': 'Seitenverhältnis gesperrt',
    'ratioUnlocked': 'Seitenverhältnis entsperrt',
    'addImages': 'Bilder hinzufügen',
    'clearList': 'Liste leeren',
    'tapAddImages': 'Über die Schaltfläche oben Bilder hinzufügen',
    'dropOrAddImages': 'Bilder hier ablegen oder auf Hinzufügen klicken',
    'outputFormat': 'Ausgabeformat:',
    'startConversion': 'Konvertieren',
    'converting': 'Bilder werden konvertiert…',
    'conversionDone': 'Alle Bilder wurden konvertiert',
    'conversionPartial':
        'Konvertierung abgeschlossen; {count} Datei(en) nicht gespeichert',
    'conversionFailed': 'Konvertierung fehlgeschlagen: {error}',
    'original': 'Original',
    'enhanced': 'Verbessert',
    'waiting': 'Bereit zur Verarbeitung',
    'processing': 'Verarbeitung…',
    'imageInfo': 'Bildinformationen',
    'fileName': 'Dateiname',
    'dimensions': 'Abmessungen',
    'enhanceInfo':
        'Passt Belichtung, Lichter, Schatten und Sättigung automatisch an',
    'processAgain': 'Erneut verarbeiten',
    'startEnhance': 'Verbessern',
    'processingFailed': 'Verarbeitung fehlgeschlagen: {error}',
    'mode.slider': 'Schieberegler',
    'mode.sideBySide': 'Nebeneinander',
    'mode.overlay': 'Überlagern',
    'ratio.free': 'Frei',
    'adjust.resize': 'Größe ändern',
    'adjust.crop': 'Zuschneiden',
    'adjust.resizeDescription': 'Eigene Breite und Höhe festlegen',
    'adjust.cropDescription': 'Auf ein Seitenverhältnis zuschneiden',
  });

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      const {'zh', 'en', 'es', 'fr', 'de'}.contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(AppLocalizations(locale));

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
