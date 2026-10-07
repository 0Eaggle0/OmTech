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

  /// No description provided for @scheduleCachedAt.
  ///
  /// In ru, this message translates to:
  /// **'обновлено в {time}'**
  String scheduleCachedAt(String time);

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

  /// No description provided for @lessonDetailOpenMaps.
  ///
  /// In ru, this message translates to:
  /// **'Открыть на карте'**
  String get lessonDetailOpenMaps;

  /// No description provided for @lessonDetailStream.
  ///
  /// In ru, this message translates to:
  /// **'Группы'**
  String get lessonDetailStream;

  /// No description provided for @teacherContactsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Контакты'**
  String get teacherContactsTitle;

  /// No description provided for @teacherContactsFor.
  ///
  /// In ru, this message translates to:
  /// **'Контакты · {name}'**
  String teacherContactsFor(String name);

  /// No description provided for @teacherContactsSource.
  ///
  /// In ru, this message translates to:
  /// **'Из контактной работы · {discipline}'**
  String teacherContactsSource(String discipline);

  /// No description provided for @contactKindEmail.
  ///
  /// In ru, this message translates to:
  /// **'Почта'**
  String get contactKindEmail;

  /// No description provided for @contactKindPhone.
  ///
  /// In ru, this message translates to:
  /// **'Телефон'**
  String get contactKindPhone;

  /// No description provided for @contactKindVk.
  ///
  /// In ru, this message translates to:
  /// **'ВКонтакте'**
  String get contactKindVk;

  /// No description provided for @contactCopy.
  ///
  /// In ru, this message translates to:
  /// **'Копировать'**
  String get contactCopy;

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

  /// No description provided for @gradesProgress.
  ///
  /// In ru, this message translates to:
  /// **'Прогресс обучения ({n} семестров)'**
  String gradesProgress(int n);

  /// No description provided for @gradesCourse.
  ///
  /// In ru, this message translates to:
  /// **'Курс {n}'**
  String gradesCourse(int n);

  /// No description provided for @gradesExcellent.
  ///
  /// In ru, this message translates to:
  /// **'Отлично'**
  String get gradesExcellent;

  /// No description provided for @gradesGood.
  ///
  /// In ru, this message translates to:
  /// **'Хорошо'**
  String get gradesGood;

  /// No description provided for @gradesCredited.
  ///
  /// In ru, this message translates to:
  /// **'Зачтено'**
  String get gradesCredited;

  /// No description provided for @gradesNoGradesYet.
  ///
  /// In ru, this message translates to:
  /// **'{n} сем: пока нет оценок'**
  String gradesNoGradesYet(int n);

  /// No description provided for @gradesSemesterLabel.
  ///
  /// In ru, this message translates to:
  /// **'{n} сем'**
  String gradesSemesterLabel(int n);

  /// No description provided for @workTitle.
  ///
  /// In ru, this message translates to:
  /// **'Контактная работа'**
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

  /// No description provided for @workHubTitle.
  ///
  /// In ru, this message translates to:
  /// **'Задания'**
  String get workHubTitle;

  /// No description provided for @workMaterialsCount.
  ///
  /// In ru, this message translates to:
  /// **'{n} заданий/материалов'**
  String workMaterialsCount(int n);

  /// No description provided for @workNewCount.
  ///
  /// In ru, this message translates to:
  /// **'+{n} новых'**
  String workNewCount(int n);

  /// No description provided for @workSyncedAt.
  ///
  /// In ru, this message translates to:
  /// **'Синхронизировано с сервером ОмГТУ: {time}'**
  String workSyncedAt(String time);

  /// No description provided for @workLecturer.
  ///
  /// In ru, this message translates to:
  /// **'Ведущий лектор'**
  String get workLecturer;

  /// No description provided for @workServerUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Сервер недоступен'**
  String get workServerUnavailable;

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
  /// **'Доработка'**
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

  /// No description provided for @reportRegistrationNumber.
  ///
  /// In ru, this message translates to:
  /// **'Регистрационный №'**
  String get reportRegistrationNumber;

  /// No description provided for @reportCopied.
  ///
  /// In ru, this message translates to:
  /// **'Скопировано'**
  String get reportCopied;

  /// No description provided for @reportUploadCta.
  ///
  /// In ru, this message translates to:
  /// **'Загрузить работу'**
  String get reportUploadCta;

  /// No description provided for @reportUploadCtaHint.
  ///
  /// In ru, this message translates to:
  /// **'PDF до 10 МБ — в «Прочие работы»'**
  String get reportUploadCtaHint;

  /// No description provided for @reportUploadTitle.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка работы'**
  String get reportUploadTitle;

  /// No description provided for @reportUploadHeroSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Выберите дисциплину, назовите работу и прикрепите PDF'**
  String get reportUploadHeroSubtitle;

  /// No description provided for @reportUploadDiscipline.
  ///
  /// In ru, this message translates to:
  /// **'Дисциплина'**
  String get reportUploadDiscipline;

  /// No description provided for @reportUploadDisciplineHint.
  ///
  /// In ru, this message translates to:
  /// **'Выберите дисциплину'**
  String get reportUploadDisciplineHint;

  /// No description provided for @reportUploadDisciplinesLoading.
  ///
  /// In ru, this message translates to:
  /// **'Загружаем список дисциплин…'**
  String get reportUploadDisciplinesLoading;

  /// No description provided for @reportUploadDisciplinesError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось получить список дисциплин'**
  String get reportUploadDisciplinesError;

  /// No description provided for @reportUploadNoDisciplines.
  ///
  /// In ru, this message translates to:
  /// **'Сайт не вернул дисциплин для загрузки'**
  String get reportUploadNoDisciplines;

  /// No description provided for @reportUploadSearch.
  ///
  /// In ru, this message translates to:
  /// **'Поиск дисциплины'**
  String get reportUploadSearch;

  /// No description provided for @reportUploadWorkTitle.
  ///
  /// In ru, this message translates to:
  /// **'Название работы'**
  String get reportUploadWorkTitle;

  /// No description provided for @reportUploadWorkTitleHint.
  ///
  /// In ru, this message translates to:
  /// **'Например: Отчёт по лабораторной работе №1'**
  String get reportUploadWorkTitleHint;

  /// No description provided for @reportUploadTitleRequired.
  ///
  /// In ru, this message translates to:
  /// **'Введите название работы'**
  String get reportUploadTitleRequired;

  /// No description provided for @reportUploadFile.
  ///
  /// In ru, this message translates to:
  /// **'Файл работы'**
  String get reportUploadFile;

  /// No description provided for @reportUploadPickFile.
  ///
  /// In ru, this message translates to:
  /// **'Выберите файл'**
  String get reportUploadPickFile;

  /// No description provided for @reportUploadFileHint.
  ///
  /// In ru, this message translates to:
  /// **'PDF, не более 10 МБ'**
  String get reportUploadFileHint;

  /// No description provided for @reportUploadFileRequired.
  ///
  /// In ru, this message translates to:
  /// **'Прикрепите PDF-файл'**
  String get reportUploadFileRequired;

  /// No description provided for @reportUploadOnlyPdf.
  ///
  /// In ru, this message translates to:
  /// **'Нужен файл в формате PDF'**
  String get reportUploadOnlyPdf;

  /// No description provided for @reportUploadTooLarge.
  ///
  /// In ru, this message translates to:
  /// **'Файл больше 10 МБ — сайт его не примет'**
  String get reportUploadTooLarge;

  /// No description provided for @reportUploadPickFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось выбрать файл'**
  String get reportUploadPickFailed;

  /// No description provided for @reportUploadRemoveFile.
  ///
  /// In ru, this message translates to:
  /// **'Убрать файл'**
  String get reportUploadRemoveFile;

  /// No description provided for @reportUploadSend.
  ///
  /// In ru, this message translates to:
  /// **'Загрузить'**
  String get reportUploadSend;

  /// No description provided for @reportUploadSending.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка {percent}%'**
  String reportUploadSending(int percent);

  /// No description provided for @reportUploadProcessing.
  ///
  /// In ru, this message translates to:
  /// **'Обрабатываем файл…'**
  String get reportUploadProcessing;

  /// No description provided for @reportUploadDone.
  ///
  /// In ru, this message translates to:
  /// **'Работа загружена'**
  String get reportUploadDone;

  /// No description provided for @reportUploadFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить работу. Попробуйте ещё раз'**
  String get reportUploadFailed;

  /// No description provided for @reportUploadServerError.
  ///
  /// In ru, this message translates to:
  /// **'Работа не загружена'**
  String get reportUploadServerError;

  /// No description provided for @reportUploadNote.
  ///
  /// In ru, this message translates to:
  /// **'После загрузки работа появится в списке со статусом «На проверке»'**
  String get reportUploadNote;

  /// No description provided for @reportDelete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить работу'**
  String get reportDelete;

  /// No description provided for @reportDeleteTitle.
  ///
  /// In ru, this message translates to:
  /// **'Удалить работу?'**
  String get reportDeleteTitle;

  /// No description provided for @reportDeleteBody.
  ///
  /// In ru, this message translates to:
  /// **'«{title}» будет удалена с сайта ОмГТУ. Отменить это нельзя.'**
  String reportDeleteBody(String title);

  /// No description provided for @reportDeleted.
  ///
  /// In ru, this message translates to:
  /// **'Работа удалена'**
  String get reportDeleted;

  /// No description provided for @reportDeleteFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось удалить работу'**
  String get reportDeleteFailed;

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

  /// No description provided for @profileSitePortal.
  ///
  /// In ru, this message translates to:
  /// **'Портал up.omgtu.ru'**
  String get profileSitePortal;

  /// No description provided for @profileSettings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get profileSettings;

  /// No description provided for @profileBuildBy.
  ///
  /// In ru, this message translates to:
  /// **'сборка by Eaggle'**
  String get profileBuildBy;

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

  /// No description provided for @lkLoginSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'ОмГТУ • Информационная система'**
  String get lkLoginSubtitle;

  /// No description provided for @lkLoginHint.
  ///
  /// In ru, this message translates to:
  /// **'Используются те же логин и пароль, что и на up.omgtu.ru'**
  String get lkLoginHint;

  /// No description provided for @lkUsername.
  ///
  /// In ru, this message translates to:
  /// **'Логин студента'**
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

  /// No description provided for @lkForgotPassword.
  ///
  /// In ru, this message translates to:
  /// **'Забыли?'**
  String get lkForgotPassword;

  /// No description provided for @lkSkipGuest.
  ///
  /// In ru, this message translates to:
  /// **'Пропустить (продолжить как гость)'**
  String get lkSkipGuest;

  /// No description provided for @lkSslNote.
  ///
  /// In ru, this message translates to:
  /// **'Логин и пароль уходят только на сайт ОмГТУ по защищённому соединению'**
  String get lkSslNote;

  /// No description provided for @lkPrivacyNote.
  ///
  /// In ru, this message translates to:
  /// **'Приложение работает автономно: данные хранятся в зашифрованном хранилище телефона и больше никуда не передаются — ни на сторонние серверы, ни разработчику'**
  String get lkPrivacyNote;

  /// No description provided for @lkOnboardingTitle.
  ///
  /// In ru, this message translates to:
  /// **'Войдите в личный кабинет'**
  String get lkOnboardingTitle;

  /// No description provided for @lkOnboardingMessage.
  ///
  /// In ru, this message translates to:
  /// **'Для доступа к контактным работам, отчётам и оценкам нужен аккаунт up.omgtu.ru — те же логин и пароль, что на сайте.'**
  String get lkOnboardingMessage;

  /// No description provided for @lkConnecting.
  ///
  /// In ru, this message translates to:
  /// **'Подключение к сайту…'**
  String get lkConnecting;

  /// No description provided for @lkConnectError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка подключения'**
  String get lkConnectError;

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

  /// No description provided for @settingsNotifications.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления'**
  String get settingsNotifications;

  /// No description provided for @settingsNotifTasks.
  ///
  /// In ru, this message translates to:
  /// **'Новые задания'**
  String get settingsNotifTasks;

  /// No description provided for @settingsNotifTasksHint.
  ///
  /// In ru, this message translates to:
  /// **'Контактная работа: появились новые задания'**
  String get settingsNotifTasksHint;

  /// No description provided for @settingsNotifReports.
  ///
  /// In ru, this message translates to:
  /// **'Статусы отчётных работ'**
  String get settingsNotifReports;

  /// No description provided for @settingsNotifReportsHint.
  ///
  /// In ru, this message translates to:
  /// **'Работу приняли или вернули на доработку'**
  String get settingsNotifReportsHint;

  /// No description provided for @settingsNotifGrades.
  ///
  /// In ru, this message translates to:
  /// **'Новые оценки'**
  String get settingsNotifGrades;

  /// No description provided for @settingsNotifGradesHint.
  ///
  /// In ru, this message translates to:
  /// **'В зачётке появились новые оценки'**
  String get settingsNotifGradesHint;

  /// No description provided for @settingsNotifSchedule.
  ///
  /// In ru, this message translates to:
  /// **'Изменения в расписании'**
  String get settingsNotifSchedule;

  /// No description provided for @settingsNotifScheduleHint.
  ///
  /// In ru, this message translates to:
  /// **'Перенос или отмена пар на этой и следующей неделе'**
  String get settingsNotifScheduleHint;

  /// No description provided for @settingsNotifTestSchedule.
  ///
  /// In ru, this message translates to:
  /// **'Изменение расписания'**
  String get settingsNotifTestSchedule;

  /// No description provided for @settingsNotifTest.
  ///
  /// In ru, this message translates to:
  /// **'Проверить уведомление'**
  String get settingsNotifTest;

  /// No description provided for @settingsNotifTestTask.
  ///
  /// In ru, this message translates to:
  /// **'Новое задание'**
  String get settingsNotifTestTask;

  /// No description provided for @settingsNotifTestAccepted.
  ///
  /// In ru, this message translates to:
  /// **'Работа принята'**
  String get settingsNotifTestAccepted;

  /// No description provided for @settingsNotifTestRejected.
  ///
  /// In ru, this message translates to:
  /// **'Работа на доработку'**
  String get settingsNotifTestRejected;

  /// No description provided for @settingsNotifTestGrade.
  ///
  /// In ru, this message translates to:
  /// **'Новая оценка'**
  String get settingsNotifTestGrade;

  /// No description provided for @settingsData.
  ///
  /// In ru, this message translates to:
  /// **'Данные'**
  String get settingsData;

  /// No description provided for @settingsClearCache.
  ///
  /// In ru, this message translates to:
  /// **'Очистить кэш'**
  String get settingsClearCache;

  /// No description provided for @settingsCacheSize.
  ///
  /// In ru, this message translates to:
  /// **'Занято: {size}'**
  String settingsCacheSize(String size);

  /// No description provided for @settingsCacheCounting.
  ///
  /// In ru, this message translates to:
  /// **'Считаем размер…'**
  String get settingsCacheCounting;

  /// No description provided for @settingsClearCacheTitle.
  ///
  /// In ru, this message translates to:
  /// **'Очистить кэш?'**
  String get settingsClearCacheTitle;

  /// No description provided for @settingsClearCacheBody.
  ///
  /// In ru, this message translates to:
  /// **'Будут удалены: сохранённое расписание, данные ЛК, кэш новостей, скачанные файлы и история поиска.'**
  String get settingsClearCacheBody;

  /// No description provided for @settingsClearCacheKept.
  ///
  /// In ru, this message translates to:
  /// **'Вход в ЛК, группа, тема и язык останутся на месте.'**
  String get settingsClearCacheKept;

  /// No description provided for @settingsCacheCleared.
  ///
  /// In ru, this message translates to:
  /// **'Кэш очищен'**
  String get settingsCacheCleared;

  /// No description provided for @bugReportAction.
  ///
  /// In ru, this message translates to:
  /// **'Сообщить об ошибке'**
  String get bugReportAction;

  /// No description provided for @bugReportSettingsHint.
  ///
  /// In ru, this message translates to:
  /// **'Письмо разработчику с файлом диагностики'**
  String get bugReportSettingsHint;

  /// No description provided for @bugReportTitle.
  ///
  /// In ru, this message translates to:
  /// **'Сообщить об ошибке'**
  String get bugReportTitle;

  /// No description provided for @bugReportSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Письмо уйдёт на {email}'**
  String bugReportSubtitle(String email);

  /// No description provided for @bugReportHint.
  ///
  /// In ru, this message translates to:
  /// **'Что пошло не так? Что вы делали перед этим?'**
  String get bugReportHint;

  /// No description provided for @bugReportIncluded.
  ///
  /// In ru, this message translates to:
  /// **'В письмо попадёт'**
  String get bugReportIncluded;

  /// No description provided for @bugReportIncDevice.
  ///
  /// In ru, this message translates to:
  /// **'Версия приложения, система, группа и состояние ЛК'**
  String get bugReportIncDevice;

  /// No description provided for @bugReportIncLog.
  ///
  /// In ru, this message translates to:
  /// **'Журнал последних действий — без логина и пароля'**
  String get bugReportIncLog;

  /// No description provided for @bugReportAttachPages.
  ///
  /// In ru, this message translates to:
  /// **'Приложить страницы ЛК'**
  String get bugReportAttachPages;

  /// No description provided for @bugReportAttachPagesHint.
  ///
  /// In ru, this message translates to:
  /// **'Помогает починить разбор данных. В них есть ваше ФИО и список работ'**
  String get bugReportAttachPagesHint;

  /// No description provided for @bugReportScreens.
  ///
  /// In ru, this message translates to:
  /// **'Скриншоты'**
  String get bugReportScreens;

  /// No description provided for @bugReportAddScreen.
  ///
  /// In ru, this message translates to:
  /// **'Добавить'**
  String get bugReportAddScreen;

  /// No description provided for @bugReportScreensHint.
  ///
  /// In ru, this message translates to:
  /// **'Снимок экрана, где вы открыли отчёт, уже приложен. Уберите его, если на нём личное'**
  String get bugReportScreensHint;

  /// No description provided for @bugReportSend.
  ///
  /// In ru, this message translates to:
  /// **'Составить письмо'**
  String get bugReportSend;

  /// No description provided for @bugReportFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть почту. Адрес {email} скопирован'**
  String bugReportFailed(String email);

  /// No description provided for @dashboardGreeting.
  ///
  /// In ru, this message translates to:
  /// **'Добро пожаловать!'**
  String get dashboardGreeting;

  /// No description provided for @dashboardStudent.
  ///
  /// In ru, this message translates to:
  /// **'Студент'**
  String get dashboardStudent;

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
  /// **'Контактная работа'**
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

  /// No description provided for @dashboardSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Цифровой кампус'**
  String get dashboardSubtitle;

  /// No description provided for @dashboardWeekOdd.
  ///
  /// In ru, this message translates to:
  /// **'Нечётная'**
  String get dashboardWeekOdd;

  /// No description provided for @dashboardWeekEven.
  ///
  /// In ru, this message translates to:
  /// **'Чётная'**
  String get dashboardWeekEven;

  /// No description provided for @dashboardLessonsToday.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня {n} пар'**
  String dashboardLessonsToday(int n);

  /// No description provided for @dashboardNoLessonsToday.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня пар нет'**
  String get dashboardNoLessonsToday;

  /// No description provided for @dashboardGpaCaption.
  ///
  /// In ru, this message translates to:
  /// **'Ср. балл {gpa}'**
  String dashboardGpaCaption(String gpa);

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

  /// No description provided for @searchTitle.
  ///
  /// In ru, this message translates to:
  /// **'Общий поиск'**
  String get searchTitle;

  /// No description provided for @searchSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Группы, преподаватели и аудитории ОмГТУ'**
  String get searchSubtitle;

  /// No description provided for @searchHint.
  ///
  /// In ru, this message translates to:
  /// **'Например: ИВТ, Иванов, 8-418...'**
  String get searchHint;

  /// No description provided for @searchStartTyping.
  ///
  /// In ru, this message translates to:
  /// **'Начните вводить запрос'**
  String get searchStartTyping;

  /// No description provided for @searchNoResults.
  ///
  /// In ru, this message translates to:
  /// **'Ничего не найдено'**
  String get searchNoResults;

  /// No description provided for @searchRecentTitle.
  ///
  /// In ru, this message translates to:
  /// **'Недавние запросы'**
  String get searchRecentTitle;

  /// No description provided for @searchClearAll.
  ///
  /// In ru, this message translates to:
  /// **'Очистить всё'**
  String get searchClearAll;

  /// No description provided for @searchAll.
  ///
  /// In ru, this message translates to:
  /// **'Все'**
  String get searchAll;

  /// No description provided for @searchOpenSchedule.
  ///
  /// In ru, this message translates to:
  /// **'Расписание'**
  String get searchOpenSchedule;

  /// No description provided for @entitySearchTeacherTitle.
  ///
  /// In ru, this message translates to:
  /// **'Поиск преподавателя'**
  String get entitySearchTeacherTitle;

  /// No description provided for @entitySearchTeacherHint.
  ///
  /// In ru, this message translates to:
  /// **'Фамилия, например: Иванов'**
  String get entitySearchTeacherHint;

  /// No description provided for @entitySearchAuditoriumTitle.
  ///
  /// In ru, this message translates to:
  /// **'Поиск аудитории'**
  String get entitySearchAuditoriumTitle;

  /// No description provided for @entitySearchAuditoriumHint.
  ///
  /// In ru, this message translates to:
  /// **'Номер, например: 8-418'**
  String get entitySearchAuditoriumHint;

  /// No description provided for @entitySearchError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось выполнить поиск. Проверьте соединение.'**
  String get entitySearchError;

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

  /// No description provided for @scheduleModeGroup.
  ///
  /// In ru, this message translates to:
  /// **'Группа'**
  String get scheduleModeGroup;

  /// No description provided for @scheduleModeTeacher.
  ///
  /// In ru, this message translates to:
  /// **'Препод.'**
  String get scheduleModeTeacher;

  /// No description provided for @scheduleModeAuditorium.
  ///
  /// In ru, this message translates to:
  /// **'Аудит.'**
  String get scheduleModeAuditorium;

  /// No description provided for @scheduleSearch.
  ///
  /// In ru, this message translates to:
  /// **'Поиск'**
  String get scheduleSearch;

  /// No description provided for @scheduleFilters.
  ///
  /// In ru, this message translates to:
  /// **'Фильтры'**
  String get scheduleFilters;

  /// No description provided for @scheduleAllSubgroups.
  ///
  /// In ru, this message translates to:
  /// **'Все подгруппы'**
  String get scheduleAllSubgroups;

  /// No description provided for @scheduleSubgroupN.
  ///
  /// In ru, this message translates to:
  /// **'{n}-я подгруппа'**
  String scheduleSubgroupN(int n);

  /// No description provided for @scheduleHideRetake.
  ///
  /// In ru, this message translates to:
  /// **'Скрыть пересдачи'**
  String get scheduleHideRetake;

  /// No description provided for @schedulePickTeacher.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать преподавателя'**
  String get schedulePickTeacher;

  /// No description provided for @schedulePickAuditorium.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать аудиторию'**
  String get schedulePickAuditorium;

  /// No description provided for @scheduleNoTeacher.
  ///
  /// In ru, this message translates to:
  /// **'Преподаватель не выбран'**
  String get scheduleNoTeacher;

  /// No description provided for @scheduleNoTeacherMsg.
  ///
  /// In ru, this message translates to:
  /// **'Найдите преподавателя и смотрите его расписание на неделю.'**
  String get scheduleNoTeacherMsg;

  /// No description provided for @scheduleNoAuditorium.
  ///
  /// In ru, this message translates to:
  /// **'Аудитория не выбрана'**
  String get scheduleNoAuditorium;

  /// No description provided for @scheduleNoAuditoriumMsg.
  ///
  /// In ru, this message translates to:
  /// **'Найдите аудиторию и смотрите её занятость на неделю.'**
  String get scheduleNoAuditoriumMsg;

  /// No description provided for @scheduleSunday.
  ///
  /// In ru, this message translates to:
  /// **'Воскресенье!'**
  String get scheduleSunday;

  /// No description provided for @scheduleSundayMsg.
  ///
  /// In ru, this message translates to:
  /// **'Законный выходной — трогай траву! 🌿'**
  String get scheduleSundayMsg;

  /// No description provided for @scheduleNoLessonsDay.
  ///
  /// In ru, this message translates to:
  /// **'Нет занятий'**
  String get scheduleNoLessonsDay;

  /// No description provided for @scheduleNoLessonsDayMsg.
  ///
  /// In ru, this message translates to:
  /// **'В выбранный день пар нет.'**
  String get scheduleNoLessonsDayMsg;

  /// No description provided for @scheduleRoute.
  ///
  /// In ru, this message translates to:
  /// **'Маршрут'**
  String get scheduleRoute;

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

  /// No description provided for @fileOpen.
  ///
  /// In ru, this message translates to:
  /// **'Открыть'**
  String get fileOpen;

  /// No description provided for @fileSave.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get fileSave;

  /// No description provided for @fileSavedTo.
  ///
  /// In ru, this message translates to:
  /// **'Сохранено: {path}'**
  String fileSavedTo(String path);

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

  /// No description provided for @updateEyebrow.
  ///
  /// In ru, this message translates to:
  /// **'Новая версия'**
  String get updateEyebrow;

  /// No description provided for @updateCurrent.
  ///
  /// In ru, this message translates to:
  /// **'у вас {version}'**
  String updateCurrent(String version);

  /// No description provided for @updateBody.
  ///
  /// In ru, this message translates to:
  /// **'Встанет поверх текущей — удалять ничего не нужно.'**
  String get updateBody;

  /// No description provided for @updateSize.
  ///
  /// In ru, this message translates to:
  /// **'{size} МБ'**
  String updateSize(String size);

  /// No description provided for @updateSizeCaption.
  ///
  /// In ru, this message translates to:
  /// **'загрузка'**
  String get updateSizeCaption;

  /// No description provided for @updateKeeps.
  ///
  /// In ru, this message translates to:
  /// **'Всё на месте'**
  String get updateKeeps;

  /// No description provided for @updateKeepsCaption.
  ///
  /// In ru, this message translates to:
  /// **'вход и настройки'**
  String get updateKeepsCaption;

  /// No description provided for @updateInstall.
  ///
  /// In ru, this message translates to:
  /// **'Обновить'**
  String get updateInstall;

  /// No description provided for @updateLater.
  ///
  /// In ru, this message translates to:
  /// **'Позже'**
  String get updateLater;

  /// No description provided for @updateDownloading.
  ///
  /// In ru, this message translates to:
  /// **'Скачивание'**
  String get updateDownloading;

  /// No description provided for @updateOpening.
  ///
  /// In ru, this message translates to:
  /// **'Открываю установщик'**
  String get updateOpening;

  /// No description provided for @updateFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось скачать. Проверьте интернет и попробуйте ещё раз.'**
  String get updateFailed;

  /// No description provided for @settingsBackground.
  ///
  /// In ru, this message translates to:
  /// **'Фоновая работа'**
  String get settingsBackground;

  /// No description provided for @settingsBackgroundAllowed.
  ///
  /// In ru, this message translates to:
  /// **'Разрешена — уведомления приходят и при закрытом приложении'**
  String get settingsBackgroundAllowed;

  /// No description provided for @settingsBackgroundRestricted.
  ///
  /// In ru, this message translates to:
  /// **'Ограничена системой — уведомления могут не приходить'**
  String get settingsBackgroundRestricted;

  /// No description provided for @settingsBackgroundAllow.
  ///
  /// In ru, this message translates to:
  /// **'Разрешить'**
  String get settingsBackgroundAllow;

  /// No description provided for @settingsBackgroundLastRun.
  ///
  /// In ru, this message translates to:
  /// **'Последняя проверка: {time} — {result}'**
  String settingsBackgroundLastRun(String time, String result);

  /// No description provided for @settingsBackgroundNever.
  ///
  /// In ru, this message translates to:
  /// **'Фоновая проверка ещё не запускалась'**
  String get settingsBackgroundNever;

  /// No description provided for @bgResultOk.
  ///
  /// In ru, this message translates to:
  /// **'успешно'**
  String get bgResultOk;

  /// No description provided for @bgResultUiActive.
  ///
  /// In ru, this message translates to:
  /// **'пропущена, приложение было открыто'**
  String get bgResultUiActive;

  /// No description provided for @bgResultNoCreds.
  ///
  /// In ru, this message translates to:
  /// **'нет входа в ЛК'**
  String get bgResultNoCreds;

  /// No description provided for @bgResultAuthFailed.
  ///
  /// In ru, this message translates to:
  /// **'пароль не подошёл'**
  String get bgResultAuthFailed;

  /// No description provided for @bgResultNetwork.
  ///
  /// In ru, this message translates to:
  /// **'нет связи'**
  String get bgResultNetwork;

  /// No description provided for @bgResultError.
  ///
  /// In ru, this message translates to:
  /// **'ошибка'**
  String get bgResultError;

  /// No description provided for @batteryHintTitle.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления при закрытом приложении'**
  String get batteryHintTitle;

  /// No description provided for @batteryHintBody.
  ///
  /// In ru, this message translates to:
  /// **'Чтобы узнавать о новых заданиях, оценках и проверке отчётов, не открывая приложение, разрешите OmTech работать в фоне. Иначе система может не запускать проверку.'**
  String get batteryHintBody;

  /// No description provided for @batteryHintLater.
  ///
  /// In ru, this message translates to:
  /// **'Не сейчас'**
  String get batteryHintLater;
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
