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
      'app_title': 'Application language',
      'russian': 'Russian',
      'english': 'English',
      'back': 'Back',
      'change': 'Change',
      'app_theme': 'App theme',
      'theme': 'Theme',
      'create': 'Create',
      'collage': 'Collage',
      'challenge_text':
          'Can you apply a filter, crop a photo to the golden ratio, or add text with a "neon glow" effect in a minute?',
      'light_theme': 'Light theme',
      'dark_theme': 'Dark theme',
      'image_format': 'Image format',
      'lang': 'Language',
      'save': 'Save',
      'crop': 'Crop',
      'brightness': 'Brightness',
      'contrast': 'Contrast',
      'adjust': 'Adjust',
      'filters': 'Filters',
      'draw': 'Draw',
      'text': 'Text',
      'effects': 'Effects',
      'next': 'Next',
      'nextEdit': 'Next to editing',
      'template': 'Template',
      'format_im': 'Format images',
      'settings': 'Settings',
      'choose': 'Select source',
      'from': 'Where do you want to select an image from?',
      'camera': 'Camera',
      'returnd': 'Return',
      'cancel': 'Cancel',
      'gallery': 'Gallery',
      'selectedNon': 'Nothing is selected',
      'pngText': '— for graphics with transparency',
      'jpegText': '— for photos',
      'insRigh': 'Insufficient rights',
      'righText': 'Grant access to your camera and gallery in settings!',
      'freeCrop': 'Free',
      'portraitCrop': 'Portrait',
      'rotateCrop': 'Rotate',
      'reset': 'Reset',
      'apply': 'Apply',
      'parametrs': 'Parametrs',
      'noise': 'Noise',
      'exposure': 'Exposure',
      'warmth': 'Теплота',
      'saturation': 'Saturation',
      'smooth': 'Smooth',
      'emoji': 'Emoji',
      'enterText': 'Enter text',
      'textColor': 'Text color',
      'textSize': 'Text size',
      'selectEmoji': 'Select emoji',
      'size': 'Size',
      'brushSize': 'Brush size',
      'warning': 'Warning',
      'exit': 'Exit',
      'areYouSure':
          'Are you sure you want to exit? All unsaved changes will be deleted.',
      'remove' : 'Remove',
      'tapToPlaceEmoji' : 'Tap to place emoji',
      'eraser' : 'Eraser',
      'brush' : 'Brush',
    },
    'ru': {
      'app_title': 'Язык приложения',
      'russian': 'Русский',
      'english': 'Английский',
      'back': 'Назад',
      'change': 'Изменить',
      'app_theme': 'Тема приложения',
      'create': 'Создать',
      'collage': 'Коллаж',
      'lang': 'Язык',
      'challenge_text':
          'Сможете ли вы за минуту применить фильтр, обрезать фото по золотому сечению или добавить текст с эффектом "неоновое свечение"?',
      'light_theme': 'Светлая тема',
      'dark_theme': 'Темная тема',
      'theme': 'Тема',
      'image_format': 'Формат фото',
      'save': 'Сохранить',
      'crop': 'Обрезка',
      'brightness': 'Яркость',
      'contrast': 'Контраст',
      'adjust': 'Регулировка',
      'filters': 'Фильтры',
      'draw': 'Рисовать',
      'returnd': 'Вернуть',
      'cancel': 'Отменить',
      'text': 'Текст',
      'effects': 'Эффекты',
      'next': 'Вперед',
      'nextEdit': 'Далее к редактированию',
      'template': 'Шаблон',
      'format_im': 'Формат изображения',
      'settings': 'Настройки',
      'choose': 'Выберите источник',
      'from': 'Откуда вы хотите выбрать изображение?',
      'camera': 'Камера',
      'gallery': 'Галерея',
      'selectedNon': 'Ничего не выбрано',
      'pngText': ' — для графики с прозрачностью',
      'jpegText': ' — для фотографий',
      'insRigh': 'Недостаточно прав',
      'righText': 'Предоставьте в настройках доступ к вашей камере и галерее!',
      'freeCrop': 'Свободная',
      'portraitCrop': 'Портрет',
      'rotateCrop': 'Поворот',
      'reset': 'Сброс',
      'apply': 'Применить',
      'parametrs': 'Параметры',
      'noise': 'Зернистость',
      'exposure': 'Экспозиция',
      'warmth': 'Теплота',
      'saturation': 'Насыщенность',
      'smooth': 'Гладкость',
      'emoji': 'Эмоджи',
      'enterText': 'Введите текст',
      'textColor': 'Цвет текста',
      'textSize': 'Размер текста',
      'selectEmoji': 'Выберите эмоджи',
      'size': 'Размер',
      'brushSize': 'Размер кисти',
      'warning': 'Предупреждение',
      'exit': 'Выход',
      'areYouSure':
          'Вы точно хотите выйти? Все несохраненные изменения будут удалены.',
      'remove' : 'Удалить',
      'tapToPlaceEmoji' : 'Нажмите, чтобы разместить эмодзи',
      'eraser' : 'Ластик',
      'brush' : 'Кисть',
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
  String get lightTheme =>
      _localizedValues[locale.languageCode]!['light_theme']!;
  String get darkTheme => _localizedValues[locale.languageCode]!['dark_theme']!;
  String get imageFormat =>
      _localizedValues[locale.languageCode]!['image_format']!;
  String get save => _localizedValues[locale.languageCode]!['save']!;
  String get crop => _localizedValues[locale.languageCode]!['crop']!;
  String get brightness =>
      _localizedValues[locale.languageCode]!['brightness']!;
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
  String get selectedNon =>
      _localizedValues[locale.languageCode]!['selectedNon']!;
  String get returnd => _localizedValues[locale.languageCode]!['returnd']!;
  String get cancel => _localizedValues[locale.languageCode]!['cancel']!;
  String get freeCrop => _localizedValues[locale.languageCode]!['freeCrop']!;
  String get portraitCrop =>
      _localizedValues[locale.languageCode]!['portraitCrop']!;
  String get rotateCrop =>
      _localizedValues[locale.languageCode]!['rotateCrop']!;
  String get reset => _localizedValues[locale.languageCode]!['reset']!;
  String get apply => _localizedValues[locale.languageCode]!['apply']!;
  String get parametrs => _localizedValues[locale.languageCode]!['parametrs']!;
  String get noise => _localizedValues[locale.languageCode]!['noise']!;
  String get warmth => _localizedValues[locale.languageCode]!['warmth']!;
  String get exposure => _localizedValues[locale.languageCode]!['exposure']!;
  String get saturation =>
      _localizedValues[locale.languageCode]!['saturation']!;
  String get smooth => _localizedValues[locale.languageCode]!['smooth']!;
  String get emoji => _localizedValues[locale.languageCode]!['emoji']!;
  String get enterText => _localizedValues[locale.languageCode]!['enterText']!;
  String get textColor => _localizedValues[locale.languageCode]!['textColor']!;
  String get textSize => _localizedValues[locale.languageCode]!['textSize']!;
  String get selectEmoji =>
      _localizedValues[locale.languageCode]!['selectEmoji']!;
  String get size => _localizedValues[locale.languageCode]!['size']!;
  String get brushSize => _localizedValues[locale.languageCode]!['brushSize']!;
  String get warning => _localizedValues[locale.languageCode]!['warning']!;
  String get exit => _localizedValues[locale.languageCode]!['exit']!;
  String get remove => _localizedValues[locale.languageCode]!['remove']!;
  String get tapToPlaceEmoji => _localizedValues[locale.languageCode]!['tapToPlaceEmoji']!;
  String get eraser => _localizedValues[locale.languageCode]!['eraser']!;
  String get brush => _localizedValues[locale.languageCode]!['brush']!;
  String get areYouSure =>
      _localizedValues[locale.languageCode]!['areYouSure']!;
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
