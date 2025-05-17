import 'dart:async';
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
  _AppLocalizationsDelegate();

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
      'parametrs': 'Parameters',
      'noise': 'Noise',
      'exposure': 'Exposure',
      'warmth': 'Warmth',
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
      'remove': 'Remove',
      'tapToPlaceEmoji': 'Tap to place emoji',
      'eraser': 'Eraser',
      'brush': 'Brush',
      'error': 'Error',
      'permissionDenied': 'Permission denied',
      'clearAll': 'Clear all',
      'undo': 'Undo',
      'redo': 'Redo',
      'noImages': 'No valid images provided',
      'noTemplates': 'No templates',
      'previous': 'Previous',
      'errorTitle': 'Error',
      'tooFewImages': 'Please select at least 2 images for a collage.',
      'tooManyImages': 'You selected more than 6 images. Only the first 6 will be used.',
      'permissionDeniedTitle': 'Permission Denied',
      'ok': 'OK',
      'borderWidth': 'Border Width',
      'borderRadius': 'Border Radius',
      'borderColor': 'Border Color',
      'selectFormat': 'Select format',
      'removeBackground': 'Remove background',
      'removeObject': 'Remove object',
      'notEnoughPhotos': 'Not enough photos',
      'edit': 'Edit',
      'loading': 'Loading',
      'errorRemovBack': 'Error removing background:',
      'fun': 'Fun',
      'animals': 'Animals',
      'birthday': 'Birthday',
      'nature': 'Nature',
      'christmas': 'Christmas',
      'custom': 'Custom',
      'addPhoto': 'Add photo',
      'background': 'Background',
      'font': 'Font',
      'align': 'Align',
      'bold': 'Bold',
      'italic': 'Italic',
      'shadow': 'Shadow',
      'add': 'Add',
      'textBackground': 'Text Background',
      'fontFamily': 'Font Family',
      'textAlignment': 'Text Alignment',
      'left': 'Left',
      'center': 'Center',
      'right': 'Right',
      'close': 'Close',
      'history': 'History',
      'selectColor': 'Select Color',
      'blurIntensity': 'Blur Intensity',
      'processingError': 'Image processing failed',
      'backgroundEditing': 'Background Editing',
      'blurBackground': 'Blur Background',
      'changeBackground': 'Change Background',
      'backgroundOptions': 'Background Options',
      'selectImage': 'Select Image',
      'removingBackground': 'Removing Background...',
      'blurringBackground': 'Blurring Background...',
      'changingBackground': 'Changing Background...',
      'processingImage': 'Processing Image...',
      'chooseFormat': 'Choose format',
      'pngTr': 'PNG (transparency)',
      'unsavedChangesWarning': 'Are you sure you want to go back? All unsaved changes will be lost.',
      'yes': 'Yes',
      'selectedImage': 'Selected image',
      'currentColor': 'Current color',
      'delete': 'Delete',
      'confirmDeleteMessage': 'Are you sure you want to delete this sticker?',
      'confirmDelete': 'Delete Sticker',
      'alignment': 'Alignment',
      'scale': 'Scale',
      'rotation': 'Rotation',
      'color': 'Color',
      'image': 'Image',
      'invalidImage': 'Invalid image format',
      'processingEffect': 'Processing effect...',
      'invalidFilter': 'Invalid filter matrix',
      'processingFilter': 'Processing filter...',
      'cancelPreview': 'Cancel preview',
      'filter': 'Filter',
      'description': 'Description',
      'autoCorrect': 'Autocorrect',
      'input': 'Input',
      'style': 'Style',
      'addText': 'Add Text',
      'alignLeft': 'Align Left',
      'alignCenter': 'Align Center',
      'alignRight': 'Align Right',
      'removeBackgroundTitle': 'Remove Background',
      'pickImagePrompt': 'Pick an image to remove the background',
      'pickImageTooltip': 'Select Image',
      'objectRemoval': 'Object removal',
      'changeBackgroundTitle': 'Change background title',
      'changeImagePrompt': 'Change image prompt',
      'changeImageTooltip': 'Change image tooltip',
      'blurBackgroundTitle': 'Blur background title',
      'blurImagePrompt': 'Blur image prompt',
      'blurImageTooltip': 'Blur image tooltip',
      'errorDecode': 'Failed to decode image',
      'errorSaveGallery': 'Failed to save image to gallery',
      'errorDownload': 'Failed to download image',
      'errorLoadDrawings': 'Failed to load drawings',
      'errorSaveDrawing': 'Failed to save drawing',
      'errorLoadImage': 'Failed to load image',
      'errorApi': 'Failed to remove object',
      'errorPickImage': 'Failed to pick image',
      'errorApplyAdjustments': 'Failed to apply adjustments',
      'errorEncode': 'Image encoding error',
      'errorEmptyImage': 'Empty image bytes',
      'saveSuccess': 'Image saved successfully',
      'applyFilter': 'Apply Filter',
      'applyEffect': 'Apply Effect',
      'invalidEffect': 'Invalid effect parameters',
      'applyCrop': 'Apply Crop',
      'invalidCrop': 'Invalid crop parameters',
      'processingCrop': 'Processing crop...',
      'errorApplyFilter': 'Error applying filter',
      'errorApplyEffect': 'Error applying effect',
      'errorApplyCrop': 'Error applying crop',
      'zoomIn': 'Zoom In',
      'zoomOut': 'Zoom Out',
      'rotateLeft': 'Rotate Left',
      'rotateRight': 'Rotate Right',
      'replace': 'Replace',
      'borderOptions': 'Border Options',
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
      'insRigh': 'Недостат ballroomочно прав',
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
      'remove': 'Удалить',
      'tapToPlaceEmoji': 'Нажмите, чтобы разместить эмодзи',
      'eraser': 'Ластик',
      'brush': 'Кисть',
      'error': 'Ошибка',
      'clearAll': 'У852брать все',
      'permissionDenied': 'Доступ запрещен',
      'undo': 'Назад',
      'redo': 'Вперед',
      'noImages': 'Не предоставлено ни одного допустимого изображения.',
      'noTemplates': 'Нет шаблонов',
      'previous': 'Предыдущий',
      'errorTitle': 'Ошибка',
      'tooFewImages': 'Выберите как минимум 2 изображения для коллажа.',
      'tooManyImages': 'Вы выбрали более 6 изображений. Будут использованы только первые 6.',
      'permissionDeniedTitle': 'Доступ запрещен',
      'ok': 'ОК',
      'borderWidth': 'Толщина границы',
      'borderRadius': 'Радиус углов',
      'borderColor': 'Цвет границы',
      'selectFormat': 'Выберите формат',
      'removeBackground': 'Удалить фон',
      'removeObject': 'Удалить объект',
      'notEnoughPhotos': 'Недостаточно фото',
      'edit': 'Изменить',
      'loading': 'Загрузка',
      'errorRemovBack': 'Ошибка удаления фона:',
      'fun': 'Веселье',
      'animals': 'Животные',
      'birthday': 'День рождения',
      'nature': 'Природа',
      'christmas': 'Рождество',
      'custom': 'Пользовательский',
      'addPhoto': 'Добавить фото',
      'background': 'Фон',
      'font': 'Шрифт',
      'align': 'Выровнять',
      'bold': 'Жирный',
      'italic': 'Курсив',
      'shadow': 'Тень',
      'add': 'Добавить',
      'textBackground': 'Фон текста',
      'fontFamily': 'Семейство шрифтов',
      'textAlignment': 'Выравнивание текста',
      'left': 'По левому краю',
      'center': 'По центру',
      'right': 'Вправо',
      'close': 'Закрыть',
      'history': 'История',
      'selectColor': 'Выбрать цвет',
      'blurIntensity': 'Интенсивность размытия',
      'processingError': 'Ошибка обработки изображения',
      'backgroundEditing': 'Редактирование фона',
      'blurBackground': 'Размыть фон',
      'changeBackground': 'Изменить фон',
      'backgroundOptions': 'Опции фона',
      'selectImage': 'Выбрать изображение',
      'removingBackground': 'Удаление фона...',
      'blurringBackground': 'Размытие фона...',
      'changingBackground': 'Изменение фона...',
      'processingImage': 'Обработка изображения...',
      'chooseFormat': 'Выберите формат',
      'pngTr': 'PNG (поддерживает прозрачность)',
      'unsavedChangesWarning': 'Вы уверены, что хотите вернуться? Все несохраненные изменения будут потеряны.',
      'yes': 'Да',
      'selectedImage': 'Выбранное изображение',
      'currentColor': 'Текущий цвет',
      'delete': 'Удалить',
      'confirmDeleteMessage': 'Вы уверены, что хотите удалить этот стикер?',
      'confirmDelete': 'Удалить стикер',
      'alignment': 'Выравнивание',
      'scale': 'Масштаб',
      'rotation': 'Поворот',
      'color': 'Цвет',
      'image': 'Изображение',
      'invalidImage': 'Недопустимый формат изображения',
      'processingEffect': 'Эффект обработки...',
      'invalidFilter': 'Недопустимая матрица фильтра',
      'processingFilter': 'Фильтр обработки...',
      'cancelPreview': 'Отменить предварительный просмотр',
      'filter': 'Фильтр',
      'description': 'Описание',
      'autoCorrect': 'Автокоррекция',
      'input': 'Ввод',
      'style': 'Стиль',
      'addText': 'Добавить текст',
      'alignLeft': 'Выровнять по левому краю',
      'alignCenter': 'Выровнять по центру',
      'alignRight': 'Выровнять по правому краю',
      'removeBackgroundTitle': 'Удалить фон',
      'pickImagePrompt': 'Выберите изображение для удаления фона',
      'pickImageTooltip': 'Выбрать изображение',
      'objectRemoval': 'Удаление объекта',
      'changeBackgroundTitle': 'Изменить заголовок фона',
      'changeImagePrompt': 'Изменить запрос изображения',
      'changeImageTooltip': 'Изменить подсказку изображения',
      'blurBackgroundTitle': 'Размытие заголовка фона',
      'blurImagePrompt': 'Размытие запроса изображения',
      'blurImageTooltip': 'Размытие подсказки изображения',
      'errorDecode': 'Не удалось декодировать изображение',
      'errorSaveGallery': 'Не удалось сохранить изображение в галерею',
      'errorDownload': 'Не удалось скачать изображение',
      'errorLoadDrawings': 'Не удалось загрузить рисунки',
      'errorSaveDrawing': 'Не удалось сохранить рисунок',
      'errorLoadImage': 'Не удалось загрузить изображение',
      'errorApi': 'Не удалось удалить объект',
      'errorPickImage': 'Не удалось выбрать изображение',
      'errorApplyAdjustments': 'Не удалось применить настройки',
      'errorEncode': 'Ошибка кодирования изображения',
      'errorEmptyImage': 'Пустые байты изображения',
      'saveSuccess': 'Изображение успешно сохранено',
      'applyFilter': 'Применить фильтр',
      'applyEffect': 'Применить эффект',
      'invalidEffect': 'Недопустимые параметры эффекта',
      'applyCrop': 'Применить обрезку',
      'invalidCrop': 'Недопустимые параметры обрезки',
      'processingCrop': 'Обработка обрезки...',
      'errorApplyFilter': 'Ошибка при применении фильтра',
      'errorApplyEffect': 'Ошибка при применении эффекта',
      'errorApplyCrop': 'Ошибка при применении обрезки',
      'zoomIn': 'Увеличить',
      'zoomOut': 'Уменьшить',
      'rotateLeft': 'Повернуть влево',
      'rotateRight': 'Повернуть вправо',
      'replace': 'Заменить',
      'borderOptions': 'Параметры границы',
    },
  };

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
  String get clearAll => _localizedValues[locale.languageCode]!['clearAll']!;
  String get areYouSure =>
      _localizedValues[locale.languageCode]!['areYouSure']!;
  String get error => _localizedValues[locale.languageCode]!['error']!;
  String get undo => _localizedValues[locale.languageCode]!['undo']!;
  String get redo => _localizedValues[locale.languageCode]!['redo']!;
  String get loading => _localizedValues[locale.languageCode]!['loading']!;
  String get permissionDenied => _localizedValues[locale.languageCode]!['permissionDenied']!;
  String get noImages => _localizedValues[locale.languageCode]!['noImages']!;
  String get noTemplates => _localizedValues[locale.languageCode]!['noTemplates']!;
  String get previous => _localizedValues[locale.languageCode]!['previous']!;
  String get errorTitle => _localizedValues[locale.languageCode]!['errorTitle']!;
  String get tooFewImages => _localizedValues[locale.languageCode]!['tooFewImages']!;
  String get tooManyImages => _localizedValues[locale.languageCode]!['tooManyImages']!;
  String get permissionDeniedTitle => _localizedValues[locale.languageCode]!['permissionDeniedTitle']!;
  String get ok => _localizedValues[locale.languageCode]!['ok']!;
  String get borderWidth => _localizedValues[locale.languageCode]!['borderWidth']!;
  String get borderRadius => _localizedValues[locale.languageCode]!['borderRadius']!;
  String get borderColor => _localizedValues[locale.languageCode]!['borderColor']!;
  String get selectFormat => _localizedValues[locale.languageCode]!['selectFormat']!;
  String get removeBackground => _localizedValues[locale.languageCode]!['removeBackground']!;
  String get removeObject => _localizedValues[locale.languageCode]!['removeObject']!;
  String get notEnoughPhotos => _localizedValues[locale.languageCode]!['notEnoughPhotos']!;
  String get edit => _localizedValues[locale.languageCode]!['edit']!;
  String get errorRemovBack => _localizedValues[locale.languageCode]!['errorRemovBack']!;
  String get fun => _localizedValues[locale.languageCode]!['fun']!;
  String get animals => _localizedValues[locale.languageCode]!['animals']!;
  String get birthday => _localizedValues[locale.languageCode]!['birthday']!;
  String get nature => _localizedValues[locale.languageCode]!['nature']!;
  String get christmas => _localizedValues[locale.languageCode]!['christmas']!;
  String get custom => _localizedValues[locale.languageCode]!['custom']!;
  String get addPhoto => _localizedValues[locale.languageCode]!['addPhoto']!;
  String get background => _localizedValues[locale.languageCode]!['background']!;
  String get font => _localizedValues[locale.languageCode]!['font']!;
  String get align => _localizedValues[locale.languageCode]!['align']!;
  String get bold => _localizedValues[locale.languageCode]!['bold']!;
  String get italic => _localizedValues[locale.languageCode]!['italic']!;
  String get shadow => _localizedValues[locale.languageCode]!['shadow']!;
  String get add => _localizedValues[locale.languageCode]!['add']!;
  String get textBackground => _localizedValues[locale.languageCode]!['textBackground']!;
  String get fontFamily => _localizedValues[locale.languageCode]!['fontFamily']!;
  String get textAlignment => _localizedValues[locale.languageCode]!['textAlignment']!;
  String get left => _localizedValues[locale.languageCode]!['left']!;
  String get center => _localizedValues[locale.languageCode]!['center']!;
  String get right => _localizedValues[locale.languageCode]!['right']!;
  String get close => _localizedValues[locale.languageCode]!['close']!;
  String get history => _localizedValues[locale.languageCode]!['history']!;
  String get selectColor => _localizedValues[locale.languageCode]!['selectColor']!;
  String get blurIntensity => _localizedValues[locale.languageCode]!['blurIntensity']!;
  String get processingError => _localizedValues[locale.languageCode]!['processingError']!;
  String get backgroundEditing => _localizedValues[locale.languageCode]!['backgroundEditing']!;
  String get blurBackground => _localizedValues[locale.languageCode]!['blurBackground']!;
  String get changeBackground => _localizedValues[locale.languageCode]!['changeBackground']!;
  String get backgroundOptions => _localizedValues[locale.languageCode]!['backgroundOptions']!;
  String get selectImage => _localizedValues[locale.languageCode]!['selectImage']!;
  String get removingBackground => _localizedValues[locale.languageCode]!['removingBackground']!;
  String get blurringBackground => _localizedValues[locale.languageCode]!['blurringBackground']!;
  String get changingBackground => _localizedValues[locale.languageCode]!['changingBackground']!;
  String get processingImage => _localizedValues[locale.languageCode]!['processingImage']!;
  String get chooseFormat => _localizedValues[locale.languageCode]!['chooseFormat']!;
  String get pngTr => _localizedValues[locale.languageCode]!['pngTr']!;
  String get unsavedChangesWarning => _localizedValues[locale.languageCode]!['unsavedChangesWarning']!;
  String get yes => _localizedValues[locale.languageCode]!['yes']!;
  String get selectedImage => _localizedValues[locale.languageCode]!['selectedImage']!;
  String get currentColor => _localizedValues[locale.languageCode]!['currentColor']!;
  String get delete => _localizedValues[locale.languageCode]!['delete']!;
  String get confirmDeleteMessage => _localizedValues[locale.languageCode]!['confirmDeleteMessage']!;
  String get confirmDelete => _localizedValues[locale.languageCode]!['confirmDelete']!;
  String get alignment => _localizedValues[locale.languageCode]!['alignment']!;
  String get scale => _localizedValues[locale.languageCode]!['scale']!;
  String get rotation => _localizedValues[locale.languageCode]!['rotation']!;
  String get color => _localizedValues[locale.languageCode]!['color']!;
  String get image => _localizedValues[locale.languageCode]!['image']!;
  String get invalidImage => _localizedValues[locale.languageCode]!['invalidImage']!;
  String get processingEffect => _localizedValues[locale.languageCode]!['processingEffect']!;
  String get invalidFilter => _localizedValues[locale.languageCode]!['invalidFilter']!;
  String get processingFilter => _localizedValues[locale.languageCode]!['processingFilter']!;
  String get cancelPreview => _localizedValues[locale.languageCode]!['cancelPreview']!;
  String get filter => _localizedValues[locale.languageCode]!['filter']!;
  String get description => _localizedValues[locale.languageCode]!['description']!;
  String get autoCorrect => _localizedValues[locale.languageCode]!['autoCorrect']!;
  String get input => _localizedValues[locale.languageCode]!['input']!;
  String get style => _localizedValues[locale.languageCode]!['style']!;
  String get addText => _localizedValues[locale.languageCode]!['addText']!;
  String get alignLeft => _localizedValues[locale.languageCode]!['alignLeft']!;
  String get alignCenter => _localizedValues[locale.languageCode]!['alignCenter']!;
  String get alignRight => _localizedValues[locale.languageCode]!['alignRight']!;
  String get removeBackgroundTitle => _localizedValues[locale.languageCode]!['removeBackgroundTitle']!;
  String get pickImagePrompt => _localizedValues[locale.languageCode]!['pickImagePrompt']!;
  String get pickImageTooltip => _localizedValues[locale.languageCode]!['pickImageTooltip']!;
  String get objectRemoval => _localizedValues[locale.languageCode]!['objectRemoval']!;
  String get changeBackgroundTitle => _localizedValues[locale.languageCode]!['changeBackgroundTitle']!;
  String get changeImagePrompt => _localizedValues[locale.languageCode]!['changeImagePrompt']!;
  String get changeImageTooltip => _localizedValues[locale.languageCode]!['changeImageTooltip']!;
  String get blurBackgroundTitle => _localizedValues[locale.languageCode]!['blurBackgroundTitle']!;
  String get blurImagePrompt => _localizedValues[locale.languageCode]!['blurImagePrompt']!;
  String get blurImageTooltip => _localizedValues[locale.languageCode]!['blurImageTooltip']!;
  String get errorDecode => _localizedValues[locale.languageCode]!['errorDecode']!;
  String get errorSaveGallery => _localizedValues[locale.languageCode]!['errorSaveGallery']!;
  String get errorDownload => _localizedValues[locale.languageCode]!['errorDownload']!;
  String get errorLoadDrawings => _localizedValues[locale.languageCode]!['errorLoadDrawings']!;
  String get errorSaveDrawing => _localizedValues[locale.languageCode]!['errorSaveDrawing']!;
  String get errorLoadImage => _localizedValues[locale.languageCode]!['errorLoadImage']!;
  String get errorApi => _localizedValues[locale.languageCode]!['errorApi']!;
  String get errorPickImage => _localizedValues[locale.languageCode]!['errorPickImage']!;
  String get errorApplyAdjustments => _localizedValues[locale.languageCode]!['errorApplyAdjustments']!;
  String get errorEncode => _localizedValues[locale.languageCode]!['errorEncode']!;
  String get errorEmptyImage => _localizedValues[locale.languageCode]!['errorEmptyImage']!;
  String get saveSuccess => _localizedValues[locale.languageCode]!['saveSuccess']!;
  String get applyFilter => _localizedValues[locale.languageCode]!['applyFilter']!;
  String get applyEffect => _localizedValues[locale.languageCode]!['applyEffect']!;
  String get invalidEffect => _localizedValues[locale.languageCode]!['invalidEffect']!;
  String get applyCrop => _localizedValues[locale.languageCode]!['applyCrop']!;
  String get invalidCrop => _localizedValues[locale.languageCode]!['invalidCrop']!;
  String get processingCrop => _localizedValues[locale.languageCode]!['processingCrop']!;
  String get errorApplyFilter => _localizedValues[locale.languageCode]!['errorApplyFilter']!;
  String get errorApplyEffect => _localizedValues[locale.languageCode]!['errorApplyEffect']!;
  String get errorApplyCrop => _localizedValues[locale.languageCode]!['errorApplyCrop']!;
  String get zoomIn => _localizedValues[locale.languageCode]!['zoomIn']!;
  String get zoomOut => _localizedValues[locale.languageCode]!['zoomOut']!;
  String get rotateLeft => _localizedValues[locale.languageCode]!['rotateLeft']!;
  String get rotateRight => _localizedValues[locale.languageCode]!['rotateRight']!;
  String get replace => _localizedValues[locale.languageCode]!['replace']!;
  String get borderOptions => _localizedValues[locale.languageCode]!['borderOptions']!;
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