import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
  _AppLocalizationsDelegate();

  // Локализованные строки
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_title': 'application language',
      'russian': 'russian',
      'english': 'english',
      'back': 'back',
      'change': 'change',
      'app_theme': 'app theme',
      'theme': 'theme',
      'create': 'create',
      'collage': 'collage',
      'challenge_text':
      'Can you apply a filter, crop a photo to the golden ratio, or add text with a "neon glow" effect in a minute?',
      'light_theme': 'light theme',
      'dark_theme': 'dark theme',
      'image_format': 'image format',
      'lang': 'language',
      'save': 'save',
      'crop': 'crop',
      'brightness': 'brightness',
      'contrast': 'contrast',
      'adjust': 'adjust',
      'filters': 'filters',
      'draw': 'draw',
      'text': 'text',
      'effects': 'effects',
      'next': 'next',
      'nextEdit': 'next to editing',
      'template': 'template',
      'format_im': 'format images',
      'settings': 'settings',
      'choose' : 'select source',
      'from' : 'where do you want to select an image from?',
      'camera' : 'camera',
      'returnd': 'return',
      'cancel': 'cancel',
      'gallery' : 'gallery',
      'selectedNon' : 'Nothing is selected',
      'pngText' : '— for graphics with transparency',
      'jpegText' : '— for photos',
      'insRigh' : 'Insufficient rights',
      'righText' : 'Grant access to your camera and gallery in settings!',
      'freeCrop' : 'Free',
      'portraitCrop' : 'Portrait',
      'rotateCrop' : 'Rotate',
      'reset' : 'Reset',
      'apply' : 'Apply'
    },
    'ru': {
      'app_title': 'язык приложения',
      'russian': 'русский',
      'english': 'английский',
      'back': 'назад',
      'change': 'изменить',
      'app_theme': 'тема приложения',
      'create': 'создать',
      'collage': 'коллаж',
      'lang': 'язык',
      'challenge_text':
      'Сможете ли вы за минуту применить фильтр, обрезать фото по золотому сечению или добавить текст с эффектом "неоновое свечение"?',
      'light_theme': 'светлая тема',
      'dark_theme': 'темная тема',
      'theme': 'тема',
      'image_format': 'формат фото',
      'save': 'сохранить',
      'crop': 'обрезка',
      'brightness': 'яркость',
      'contrast': 'контраст',
      'adjust': 'регулировка',
      'filters': 'фильтры',
      'draw': 'рисовать',
      'returnd': 'вернуть',
      'cancel': 'отменить',
      'text': 'текст',
      'effects': 'эффекты',
      'next': 'вперед',
      'nextEdit': 'далее к редактированию',
      'template': 'шаблон',
      'format_im': 'формат изображения',
      'settings': 'настройки',
      'choose' : 'выберите источник',
      'from' : 'откуда вы хотите выбрать изображение?',
      'camera' : 'камера',
      'gallery' : 'галерея',
      'selectedNon' : 'Ничего не выбрано',
      'pngText' : ' — для графики с прозрачностью',
      'jpegText' : ' — для фотографий',
      'insRigh' : 'Недостаточно прав',
      'righText' : 'Предоставьте в настройках доступ к вашей камере и галерее!',
      'freeCrop' : 'Свободная',
      'portraitCrop' : 'Портрет',
      'rotateCrop' : 'Поворот',
      'reset' : 'Сброс',
      'apply' : 'Применить'
    },
  };

  // Геттеры для локализованных строк
  String get appTitle => _localizedValues[locale.languageCode]!['app_title']!;
  String get russian => _localizedValues[locale.languageCode]!['russian']!;
  String get english => _localizedValues[locale.languageCode]!['english']!;
  String get back => _localizedValues[locale.languageCode]!['back']!;
  String get change => _localizedValues[locale.languageCode]!['change']!;
  String get appTheme => _localizedValues[locale.languageCode]!['app_theme']!;
  String get create => _localizedValues[locale.languageCode]!['create']!;
  String get collage => _localizedValues[locale.languageCode]!['collage']!;
  String get challengeText =>
      _localizedValues[locale.languageCode]!['challenge_text']!;
  String get lightTheme => _localizedValues[locale.languageCode]!['light_theme']!;
  String get darkTheme => _localizedValues[locale.languageCode]!['dark_theme']!;
  String get imageFormat => _localizedValues[locale.languageCode]!['image_format']!;
  String get save => _localizedValues[locale.languageCode]!['save']!;
  String get crop => _localizedValues[locale.languageCode]!['crop']!;
  String get brightness => _localizedValues[locale.languageCode]!['brightness']!;
  String get contrast => _localizedValues[locale.languageCode]!['contrast']!;
  String get adjust => _localizedValues[locale.languageCode]!['adjust']!;
  String get filters => _localizedValues[locale.languageCode]!['filters']!;
  String get draw => _localizedValues[locale.languageCode]!['draw']!;
  String get text => _localizedValues[locale.languageCode]!['text']!;
  String get effects => _localizedValues[locale.languageCode]!['effects']!;
  String get next => _localizedValues[locale.languageCode]!['next']!;
  String get nextEdit => _localizedValues[locale.languageCode]!['nextEdit']!;
  String get template => _localizedValues[locale.languageCode]!['template']!;
  String get format => _localizedValues[locale.languageCode]!['format_im']!;
  String get settings => _localizedValues[locale.languageCode]!['settings']!;
  String get lang => _localizedValues[locale.languageCode]!['lang']!;
  String get theme => _localizedValues[locale.languageCode]!['theme']!;
  String get choose => _localizedValues[locale.languageCode]!['choose']!;
  String get from => _localizedValues[locale.languageCode]!['from']!;
  String get camera => _localizedValues[locale.languageCode]!['camera']!;
  String get gallery => _localizedValues[locale.languageCode]!['gallery']!;
  String get jpegText => _localizedValues[locale.languageCode]!['jpegText']!;
  String get pngText => _localizedValues[locale.languageCode]!['pngText']!;
  String get insRigh => _localizedValues[locale.languageCode]!['insRigh']!;
  String get righText => _localizedValues[locale.languageCode]!['righText']!;
  String get selectedNon => _localizedValues[locale.languageCode]!['selectedNon']!;
  String get returnd => _localizedValues[locale.languageCode]!['returnd']!;
  String get cancel => _localizedValues[locale.languageCode]!['cancel']!;
  String get freeCrop => _localizedValues[locale.languageCode]!['freeCrop']!;
  String get portraitCrop => _localizedValues[locale.languageCode]!['portraitCrop']!;
  String get rotateCrop => _localizedValues[locale.languageCode]!['rotateCrop']!;
  String get reset => _localizedValues[locale.languageCode]!['reset']!;
  String get apply => _localizedValues[locale.languageCode]!['apply']!;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ru'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}