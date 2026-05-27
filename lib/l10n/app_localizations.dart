import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ru, this message translates to:
  /// **'OmTech'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In ru, this message translates to:
  /// **'Главная'**
  String get navHome;

  /// No description provided for @navSchedule.
  ///
  /// In ru, this message translates to:
  /// **'Расписание'**
  String get navSchedule;

  /// No description provided for @navNews.
  ///
  /// In ru, this message translates to:
  /// **'Новости'**
  String get navNews;

  /// No description provided for @navWork.
  ///
  /// In ru, this message translates to:
  /// **'Задания'**
  String get navWork;

  /// No description provided for @navProfile.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get navProfile;

  /// No description provided for @scheduleTitle.
  ///
  /// In ru, this message translates to:
  /// **'Расписание'**
  String get scheduleTitle;

  /// No description provided for @scheduleNoGroup.
  ///
  /// In ru, this message translates to:
  /// **'Группа не выбрана'**
  String get scheduleNoGroup;

  /// No description provided for @scheduleNoGroupMsg.
  ///
  /// In ru, this message translates to:
  /// **'Выберите свою учебную группу, чтобы увидеть расписание.'**
  String get scheduleNoGroupMsg;

  /// No description provided for @schedulePickGroup.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать группу'**
  String get schedulePickGroup;

  /// No description provided for @scheduleNoLessons.
  ///
  /// In ru, this message translates to:
  /// **'На этой неделе пар нет'**
  String get scheduleNoLessons;

  /// No description provided for @scheduleNoLessonsMsg.
  ///
  /// In ru, this message translates to:
  /// **'Можно отдохнуть или пролистать другую неделю.'**
  String get scheduleNoLessonsMsg;

  /// No description provided for @scheduleLoadError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить'**
  String get scheduleLoadError;

  /// No description provided for @scheduleLoadErrorMsg.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте подключение к интернету и повторите.'**
  String get scheduleLoadErrorMsg;

  /// No description provided for @scheduleRetry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get scheduleRetry;

  /// No description provided for @lessonDetailSubgroup.
  ///
  /// In ru, this message translates to:
  /// **'подгруппа'**
  String get lessonDetailSubgroup;

  /// No description provided for @lessonDetailNote.
  ///
  /// In ru, this message translates to:
  /// **'Ваша заметка'**
  String get lessonDetailNote;

  /// No description provided for @lessonDetailShare.
  ///
  /// In ru, this message translates to:
  /// **'Поделиться заметкой'**
  String get lessonDetailShare;

  /// No description provided for @lessonDetailTeacherOptions.
  ///
  /// In ru, this message translates to:
  /// **'Действия с преподавателем'**
  String get lessonDetailTeacherOptions;

  /// No description provided for @lessonDetailContacts.
  ///
  /// In ru, this message translates to:
  /// **'Показать контакты'**
  String get lessonDetailContacts;

  /// No description provided for @lessonDetailReviews.
  ///
  /// In ru, this message translates to:
  /// **'Отзывы'**
  String get lessonDetailReviews;

  /// No description provided for @lessonDetailOpenMaps.
  ///
  /// In ru, this message translates to:
  /// **'Открыть на карте'**
  String get lessonDetailOpenMaps;

  /// No description provided for @lessonDetailStream.
  ///
  /// In ru, this message translates to:
  /// **'поток'**
  String get lessonDetailStream;

  /// No description provided for @newsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Новости'**
  String get newsTitle;

  /// No description provided for @newsLoadError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить новости'**
  String get newsLoadError;

  /// No description provided for @newsEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Новостей пока нет'**
  String get newsEmpty;

  /// No description provided for @newsOpenFull.
  ///
  /// In ru, this message translates to:
  /// **'Читать на сайте'**
  String get newsOpenFull;

  /// No description provided for @gradesTitle.
  ///
  /// In ru, this message translates to:
  /// **'Оценки'**
  String get gradesTitle;

  /// No description provided for @gradesSemester.
  ///
  /// In ru, this message translates to:
  /// **'сем'**
  String get gradesSemester;

  /// No description provided for @gradesDemoNote.
  ///
  /// In ru, this message translates to:
  /// **'Демонстрационные данные. Реальные оценки появятся после подключения личного кабинета.'**
  String get gradesDemoNote;

  /// No description provided for @materialsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Материалы'**
  String get materialsTitle;

  /// No description provided for @materialsDemoNote.
  ///
  /// In ru, this message translates to:
  /// **'Демонстрационные данные. Реальные материалы появятся после подключения личного кабинета.'**
  String get materialsDemoNote;

  /// No description provided for @workTitle.
  ///
  /// In ru, this message translates to:
  /// **'Задания'**
  String get workTitle;

  /// No description provided for @workSearch.
  ///
  /// In ru, this message translates to:
  /// **'Дисциплина'**
  String get workSearch;

  /// No description provided for @workTaskCount.
  ///
  /// In ru, this message translates to:
  /// **'заданий'**
  String get workTaskCount;

  /// No description provided for @workTaskNumber.
  ///
  /// In ru, this message translates to:
  /// **'Номер'**
  String get workTaskNumber;

  /// No description provided for @workTaskComment.
  ///
  /// In ru, this message translates to:
  /// **'Комментарий'**
  String get workTaskComment;

  /// No description provided for @workTaskFiles.
  ///
  /// In ru, this message translates to:
  /// **'Файлы'**
  String get workTaskFiles;

  /// No description provided for @workTaskDate.
  ///
  /// In ru, this message translates to:
  /// **'Дата создания'**
  String get workTaskDate;

  /// No description provided for @workTaskTeacher.
  ///
  /// In ru, this message translates to:
  /// **'Преподаватель'**
  String get workTaskTeacher;

  /// No description provided for @workTaskNoFiles.
  ///
  /// In ru, this message translates to:
  /// **'Нет файлов'**
  String get workTaskNoFiles;

  /// No description provided for @workDemoNote.
  ///
  /// In ru, this message translates to:
  /// **'Демонстрационные данные. Реальные задания появятся после подключения личного кабинета.'**
  String get workDemoNote;

  /// No description provided for @workTeachers.
  ///
  /// In ru, this message translates to:
  /// **'Преподаватели'**
  String get workTeachers;

  /// No description provided for @profileTitle.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get profileTitle;

  /// No description provided for @profileNameHint.
  ///
  /// In ru, this message translates to:
  /// **'Ваше ФИО'**
  String get profileNameHint;

  /// No description provided for @profileNameLabel.
  ///
  /// In ru, this message translates to:
  /// **'Введите ФИО'**
  String get profileNameLabel;

  /// No description provided for @profileNameEdit.
  ///
  /// In ru, this message translates to:
  /// **'Изменить имя'**
  String get profileNameEdit;

  /// No description provided for @profileGroup.
  ///
  /// In ru, this message translates to:
  /// **'Группа'**
  String get profileGroup;

  /// No description provided for @profileGroupNotSelected.
  ///
  /// In ru, this message translates to:
  /// **'Группа не выбрана'**
  String get profileGroupNotSelected;

  /// No description provided for @profileGroupTap.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите, чтобы выбрать'**
  String get profileGroupTap;

  /// No description provided for @profileUniversity.
  ///
  /// In ru, this message translates to:
  /// **'Омский государственный технический университет'**
  String get profileUniversity;

  /// No description provided for @profileServices.
  ///
  /// In ru, this message translates to:
  /// **'Сервисы университета'**
  String get profileServices;

  /// No description provided for @profileSiteOmgtu.
  ///
  /// In ru, this message translates to:
  /// **'Сайт ОМГТУ'**
  String get profileSiteOmgtu;

  /// No description provided for @profileSiteSchedule.
  ///
  /// In ru, this message translates to:
  /// **'Расписание (сайт)'**
  String get profileSiteSchedule;

  /// No description provided for @profileSiteNews.
  ///
  /// In ru, this message translates to:
  /// **'Новости'**
  String get profileSiteNews;

  /// No description provided for @profileSettings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get profileSettings;

  /// No description provided for @settingsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In ru, this message translates to:
  /// **'Язык'**
  String get settingsLanguage;

  /// No description provided for @settingsLangRu.
  ///
  /// In ru, this message translates to:
  /// **'Русский'**
  String get settingsLangRu;

  /// No description provided for @settingsLangEn.
  ///
  /// In ru, this message translates to:
  /// **'English'**
  String get settingsLangEn;

  /// No description provided for @settingsTheme.
  ///
  /// In ru, this message translates to:
  /// **'Оформление'**
  String get settingsTheme;

  /// No description provided for @settingsThemeDark.
  ///
  /// In ru, this message translates to:
  /// **'Тёмная'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeLight.
  ///
  /// In ru, this message translates to:
  /// **'Светлая'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In ru, this message translates to:
  /// **'Как в системе'**
  String get settingsThemeSystem;

  /// No description provided for @settingsAbout.
  ///
  /// In ru, this message translates to:
  /// **'О приложении'**
  String get settingsAbout;

  /// No description provided for @settingsVersion.
  ///
  /// In ru, this message translates to:
  /// **'Версия'**
  String get settingsVersion;

  /// No description provided for @settingsAboutApp.
  ///
  /// In ru, this message translates to:
  /// **'OmTech'**
  String get settingsAboutApp;

  /// No description provided for @dashboardGreeting.
  ///
  /// In ru, this message translates to:
  /// **'Добро пожаловать!'**
  String get dashboardGreeting;

  /// No description provided for @dashboardNoGroup.
  ///
  /// In ru, this message translates to:
  /// **'Группа не выбрана'**
  String get dashboardNoGroup;

  /// No description provided for @dashboardNextLesson.
  ///
  /// In ru, this message translates to:
  /// **'Ближайшая пара'**
  String get dashboardNextLesson;

  /// No description provided for @dashboardNoNextLesson.
  ///
  /// In ru, this message translates to:
  /// **'Пар на сегодня нет'**
  String get dashboardNoNextLesson;

  /// No description provided for @dashboardGrades.
  ///
  /// In ru, this message translates to:
  /// **'Оценки'**
  String get dashboardGrades;

  /// No description provided for @dashboardMaterials.
  ///
  /// In ru, this message translates to:
  /// **'Материалы'**
  String get dashboardMaterials;

  /// No description provided for @dashboardNews.
  ///
  /// In ru, this message translates to:
  /// **'Новости'**
  String get dashboardNews;

  /// No description provided for @dashboardAllNews.
  ///
  /// In ru, this message translates to:
  /// **'Все новости'**
  String get dashboardAllNews;

  /// No description provided for @dashboardSelectGroup.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать группу'**
  String get dashboardSelectGroup;

  /// No description provided for @groupSearchTitle.
  ///
  /// In ru, this message translates to:
  /// **'Поиск группы'**
  String get groupSearchTitle;

  /// No description provided for @groupSearchHint.
  ///
  /// In ru, this message translates to:
  /// **'Введите номер группы...'**
  String get groupSearchHint;

  /// No description provided for @groupSearchEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Группы не найдены'**
  String get groupSearchEmpty;

  /// No description provided for @groupSearchLoading.
  ///
  /// In ru, this message translates to:
  /// **'Поиск...'**
  String get groupSearchLoading;

  /// No description provided for @cancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get save;

  /// No description provided for @close.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get close;

  /// No description provided for @ok.
  ///
  /// In ru, this message translates to:
  /// **'ОК'**
  String get ok;

  /// No description provided for @loading.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get retry;

  /// No description provided for @noInternet.
  ///
  /// In ru, this message translates to:
  /// **'Нет подключения к интернету'**
  String get noInternet;
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
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
