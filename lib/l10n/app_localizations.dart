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

  /// No description provided for @reportWorksTitle.
  ///
  /// In ru, this message translates to:
  /// **'Отчётные работы'**
  String get reportWorksTitle;

  /// No description provided for @reportWorksDashboardTile.
  ///
  /// In ru, this message translates to:
  /// **'Отчётные работы'**
  String get reportWorksDashboardTile;

  /// No description provided for @reportCourseWorks.
  ///
  /// In ru, this message translates to:
  /// **'Курсовые работы'**
  String get reportCourseWorks;

  /// No description provided for @reportOtherWorks.
  ///
  /// In ru, this message translates to:
  /// **'Прочие работы'**
  String get reportOtherWorks;

  /// No description provided for @reportStatusPending.
  ///
  /// In ru, this message translates to:
  /// **'На проверке'**
  String get reportStatusPending;

  /// No description provided for @reportStatusAccepted.
  ///
  /// In ru, this message translates to:
  /// **'Принята'**
  String get reportStatusAccepted;

  /// No description provided for @reportStatusRejected.
  ///
  /// In ru, this message translates to:
  /// **'Отклонена'**
  String get reportStatusRejected;

  /// No description provided for @reportFilterAll.
  ///
  /// In ru, this message translates to:
  /// **'Все'**
  String get reportFilterAll;

  /// No description provided for @reportSearch.
  ///
  /// In ru, this message translates to:
  /// **'Поиск по названию или предмету'**
  String get reportSearch;

  /// No description provided for @reportTeacher.
  ///
  /// In ru, this message translates to:
  /// **'Преподаватель'**
  String get reportTeacher;

  /// No description provided for @reportComment.
  ///
  /// In ru, this message translates to:
  /// **'Комментарий'**
  String get reportComment;

  /// No description provided for @reportEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Загруженных работ пока нет'**
  String get reportEmpty;

  /// No description provided for @reportUploadStub.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка работ — в разработке'**
  String get reportUploadStub;

  /// No description provided for @reportDemoNote.
  ///
  /// In ru, this message translates to:
  /// **'Демонстрационные данные. Реальный список работ появится после подключения личного кабинета.'**
  String get reportDemoNote;

  /// No description provided for @reportWorkNumberLabel.
  ///
  /// In ru, this message translates to:
  /// **'№'**
  String get reportWorkNumberLabel;

  /// No description provided for @reportSemesterLabel.
  ///
  /// In ru, this message translates to:
  /// **'семестр'**
  String get reportSemesterLabel;

  /// No description provided for @reportAcademicYear.
  ///
  /// In ru, this message translates to:
  /// **'Учебный год'**
  String get reportAcademicYear;

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

  /// No description provided for @lkSection.
  ///
  /// In ru, this message translates to:
  /// **'Личный кабинет ОмГТУ'**
  String get lkSection;

  /// No description provided for @lkNotConnected.
  ///
  /// In ru, this message translates to:
  /// **'Не подключён'**
  String get lkNotConnected;

  /// No description provided for @lkConnect.
  ///
  /// In ru, this message translates to:
  /// **'Подключить'**
  String get lkConnect;

  /// No description provided for @lkDisconnect.
  ///
  /// In ru, this message translates to:
  /// **'Отключить'**
  String get lkDisconnect;

  /// No description provided for @lkLoginTitle.
  ///
  /// In ru, this message translates to:
  /// **'Вход в личный кабинет'**
  String get lkLoginTitle;

  /// No description provided for @lkLoginHint.
  ///
  /// In ru, this message translates to:
  /// **'Используются те же логин и пароль, что и на up.omgtu.ru'**
  String get lkLoginHint;

  /// No description provided for @lkUsername.
  ///
  /// In ru, this message translates to:
  /// **'Логин'**
  String get lkUsername;

  /// No description provided for @lkPassword.
  ///
  /// In ru, this message translates to:
  /// **'Пароль'**
  String get lkPassword;

  /// No description provided for @lkLoginButton.
  ///
  /// In ru, this message translates to:
  /// **'Войти'**
  String get lkLoginButton;

  /// No description provided for @lkInvalidCredentials.
  ///
  /// In ru, this message translates to:
  /// **'Неверный логин или пароль'**
  String get lkInvalidCredentials;

  /// No description provided for @lkNetworkError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось подключиться к ЛК'**
  String get lkNetworkError;

  /// No description provided for @lkConnected.
  ///
  /// In ru, this message translates to:
  /// **'Подключён'**
  String get lkConnected;

  /// No description provided for @lkBookNumber.
  ///
  /// In ru, this message translates to:
  /// **'Зачётная книжка №'**
  String get lkBookNumber;

  /// No description provided for @lkLoadError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось обновить данные'**
  String get lkLoadError;

  /// No description provided for @lkCacheShown.
  ///
  /// In ru, this message translates to:
  /// **'Показаны последние сохранённые данные'**
  String get lkCacheShown;

  /// No description provided for @lkDisconnectConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Отключить личный кабинет? Пароль будет удалён с устройства.'**
  String get lkDisconnectConfirm;

  /// No description provided for @lkExamsSection.
  ///
  /// In ru, this message translates to:
  /// **'Экзамены'**
  String get lkExamsSection;

  /// No description provided for @lkCreditsSection.
  ///
  /// In ru, this message translates to:
  /// **'Зачёты'**
  String get lkCreditsSection;

  /// No description provided for @lkCourseworkSection.
  ///
  /// In ru, this message translates to:
  /// **'Курсовые'**
  String get lkCourseworkSection;

  /// No description provided for @lkRequired.
  ///
  /// In ru, this message translates to:
  /// **'Только для авторизованных'**
  String get lkRequired;

  /// No description provided for @lkRequiredMsg.
  ///
  /// In ru, this message translates to:
  /// **'Войдите в личный кабинет, чтобы получить доступ к этим данным.'**
  String get lkRequiredMsg;

  /// No description provided for @lkRequiredAction.
  ///
  /// In ru, this message translates to:
  /// **'Войти в ЛК'**
  String get lkRequiredAction;

  /// No description provided for @profileEditTitle.
  ///
  /// In ru, this message translates to:
  /// **'Редактировать профиль'**
  String get profileEditTitle;

  /// No description provided for @profilePhotoChange.
  ///
  /// In ru, this message translates to:
  /// **'Изменить фото'**
  String get profilePhotoChange;

  /// No description provided for @profilePhotoRemove.
  ///
  /// In ru, this message translates to:
  /// **'Удалить фото'**
  String get profilePhotoRemove;

  /// No description provided for @profilePhotoGallery.
  ///
  /// In ru, this message translates to:
  /// **'Галерея'**
  String get profilePhotoGallery;

  /// No description provided for @profilePhotoCamera.
  ///
  /// In ru, this message translates to:
  /// **'Камера'**
  String get profilePhotoCamera;

  /// No description provided for @profileNameFromLk.
  ///
  /// In ru, this message translates to:
  /// **'Имя подтянуто из личного кабинета'**
  String get profileNameFromLk;

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

  /// No description provided for @dashboardHello.
  ///
  /// In ru, this message translates to:
  /// **'Привет, {name}!'**
  String dashboardHello(String name);

  /// No description provided for @dashboardNoGroup.
  ///
  /// In ru, this message translates to:
  /// **'Группа не выбрана'**
  String get dashboardNoGroup;

  /// No description provided for @dashboardNextLesson.
  ///
  /// In ru, this message translates to:
  /// **'Текущая/ближайшая пара'**
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

  /// No description provided for @dashboardTasks.
  ///
  /// In ru, this message translates to:
  /// **'Задания'**
  String get dashboardTasks;

  /// No description provided for @dashboardReportWorks.
  ///
  /// In ru, this message translates to:
  /// **'Отчётные работы'**
  String get dashboardReportWorks;

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

  /// No description provided for @scheduleOnlyMySubgroup.
  ///
  /// In ru, this message translates to:
  /// **'Только {n}-я подгруппа'**
  String scheduleOnlyMySubgroup(int n);

  /// No description provided for @scheduleSubgroup.
  ///
  /// In ru, this message translates to:
  /// **'Подгруппа'**
  String get scheduleSubgroup;

  /// No description provided for @scheduleStream.
  ///
  /// In ru, this message translates to:
  /// **'Поток'**
  String get scheduleStream;

  /// No description provided for @scheduleWeekView.
  ///
  /// In ru, this message translates to:
  /// **'Неделя'**
  String get scheduleWeekView;

  /// No description provided for @scheduleDayView.
  ///
  /// In ru, this message translates to:
  /// **'День'**
  String get scheduleDayView;

  /// No description provided for @scheduleNoLessonsToday.
  ///
  /// In ru, this message translates to:
  /// **'Иди трогать траву!\nСегодня пар нет 🌿'**
  String get scheduleNoLessonsToday;

  /// No description provided for @scheduleNoLessonsTodayMsg.
  ///
  /// In ru, this message translates to:
  /// **'Наслаждайся свободным временем или посмотри другой день.'**
  String get scheduleNoLessonsTodayMsg;

  /// No description provided for @scheduleShowWeek.
  ///
  /// In ru, this message translates to:
  /// **'Показать всю неделю'**
  String get scheduleShowWeek;

  /// No description provided for @schedulePickDate.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать дату'**
  String get schedulePickDate;

  /// No description provided for @profileFirstName.
  ///
  /// In ru, this message translates to:
  /// **'Имя'**
  String get profileFirstName;

  /// No description provided for @profileLastName.
  ///
  /// In ru, this message translates to:
  /// **'Фамилия'**
  String get profileLastName;

  /// No description provided for @profilePatronymic.
  ///
  /// In ru, this message translates to:
  /// **'Отчество'**
  String get profilePatronymic;

  /// No description provided for @profileSubgroup.
  ///
  /// In ru, this message translates to:
  /// **'Подгруппа'**
  String get profileSubgroup;

  /// No description provided for @profileSubgroupAll.
  ///
  /// In ru, this message translates to:
  /// **'Все'**
  String get profileSubgroupAll;

  /// No description provided for @profileSubgroupHint.
  ///
  /// In ru, this message translates to:
  /// **'Укажите подгруппу для фильтрации расписания'**
  String get profileSubgroupHint;

  /// No description provided for @profileGroupAutoFilled.
  ///
  /// In ru, this message translates to:
  /// **'Группа заполнена из личного кабинета'**
  String get profileGroupAutoFilled;

  /// No description provided for @reportSubjectFilter.
  ///
  /// In ru, this message translates to:
  /// **'Предмет'**
  String get reportSubjectFilter;

  /// No description provided for @reportSemesterFilter.
  ///
  /// In ru, this message translates to:
  /// **'Семестр'**
  String get reportSemesterFilter;

  /// No description provided for @reportDownload.
  ///
  /// In ru, this message translates to:
  /// **'Скачать'**
  String get reportDownload;

  /// No description provided for @reportDownloading.
  ///
  /// In ru, this message translates to:
  /// **'Скачивание...'**
  String get reportDownloading;

  /// No description provided for @reportNoFiles.
  ///
  /// In ru, this message translates to:
  /// **'Файл недоступен'**
  String get reportNoFiles;

  /// No description provided for @reportAllSubjects.
  ///
  /// In ru, this message translates to:
  /// **'Все предметы'**
  String get reportAllSubjects;

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
