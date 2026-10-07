// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'OmTech';

  @override
  String get navHome => 'Главная';

  @override
  String get navSchedule => 'Расписание';

  @override
  String get navNews => 'Новости';

  @override
  String get navWork => 'Задания';

  @override
  String get navProfile => 'Профиль';

  @override
  String get scheduleTitle => 'Расписание';

  @override
  String get scheduleNoGroup => 'Группа не выбрана';

  @override
  String get scheduleNoGroupMsg =>
      'Выберите свою учебную группу, чтобы увидеть расписание.';

  @override
  String get schedulePickGroup => 'Выбрать группу';

  @override
  String get scheduleNoLessons => 'На этой неделе пар нет';

  @override
  String get scheduleNoLessonsMsg =>
      'Можно отдохнуть или пролистать другую неделю.';

  @override
  String get scheduleLoadError => 'Не удалось загрузить';

  @override
  String get scheduleLoadErrorMsg =>
      'Проверьте подключение к интернету и повторите.';

  @override
  String get scheduleRetry => 'Повторить';

  @override
  String scheduleCachedAt(String time) {
    return 'обновлено в $time';
  }

  @override
  String get lessonDetailSubgroup => 'подгруппа';

  @override
  String get lessonDetailNote => 'Ваша заметка';

  @override
  String get lessonDetailShare => 'Поделиться заметкой';

  @override
  String get lessonDetailOpenMaps => 'Открыть на карте';

  @override
  String get lessonDetailStream => 'Группы';

  @override
  String get teacherContactsTitle => 'Контакты';

  @override
  String teacherContactsFor(String name) {
    return 'Контакты · $name';
  }

  @override
  String teacherContactsSource(String discipline) {
    return 'Из контактной работы · $discipline';
  }

  @override
  String get contactKindEmail => 'Почта';

  @override
  String get contactKindPhone => 'Телефон';

  @override
  String get contactKindVk => 'ВКонтакте';

  @override
  String get contactCopy => 'Копировать';

  @override
  String get newsTitle => 'Новости';

  @override
  String get newsLoadError => 'Не удалось загрузить новости';

  @override
  String get newsEmpty => 'Новостей пока нет';

  @override
  String get newsOpenFull => 'Читать на сайте';

  @override
  String get gradesTitle => 'Оценки';

  @override
  String get gradesSemester => 'сем';

  @override
  String get gradesDemoNote =>
      'Демонстрационные данные. Реальные оценки появятся после подключения личного кабинета.';

  @override
  String gradesProgress(int n) {
    return 'Прогресс обучения ($n семестров)';
  }

  @override
  String gradesCourse(int n) {
    return 'Курс $n';
  }

  @override
  String get gradesExcellent => 'Отлично';

  @override
  String get gradesGood => 'Хорошо';

  @override
  String get gradesCredited => 'Зачтено';

  @override
  String gradesNoGradesYet(int n) {
    return '$n сем: пока нет оценок';
  }

  @override
  String gradesSemesterLabel(int n) {
    return '$n сем';
  }

  @override
  String get workTitle => 'Контактная работа';

  @override
  String get workSearch => 'Дисциплина';

  @override
  String get workTaskCount => 'заданий';

  @override
  String get workTaskNumber => 'Номер';

  @override
  String get workTaskComment => 'Комментарий';

  @override
  String get workTaskFiles => 'Файлы';

  @override
  String get workTaskDate => 'Дата создания';

  @override
  String get workTaskTeacher => 'Преподаватель';

  @override
  String get workTaskNoFiles => 'Нет файлов';

  @override
  String get workDemoNote =>
      'Демонстрационные данные. Реальные задания появятся после подключения личного кабинета.';

  @override
  String get workTeachers => 'Преподаватели';

  @override
  String get workHubTitle => 'Задания';

  @override
  String workMaterialsCount(int n) {
    return '$n заданий/материалов';
  }

  @override
  String workNewCount(int n) {
    return '+$n новых';
  }

  @override
  String workSyncedAt(String time) {
    return 'Синхронизировано с сервером ОмГТУ: $time';
  }

  @override
  String get workLecturer => 'Ведущий лектор';

  @override
  String get workServerUnavailable => 'Сервер недоступен';

  @override
  String get reportWorksTitle => 'Отчётные работы';

  @override
  String get reportWorksDashboardTile => 'Отчётные работы';

  @override
  String get reportCourseWorks => 'Курсовые работы';

  @override
  String get reportOtherWorks => 'Прочие работы';

  @override
  String get reportStatusPending => 'На проверке';

  @override
  String get reportStatusAccepted => 'Принята';

  @override
  String get reportStatusRejected => 'Доработка';

  @override
  String get reportFilterAll => 'Все';

  @override
  String get reportSearch => 'Поиск по названию или предмету';

  @override
  String get reportTeacher => 'Преподаватель';

  @override
  String get reportComment => 'Комментарий';

  @override
  String get reportEmpty => 'Загруженных работ пока нет';

  @override
  String get reportDemoNote =>
      'Демонстрационные данные. Реальный список работ появится после подключения личного кабинета.';

  @override
  String get reportWorkNumberLabel => '№';

  @override
  String get reportSemesterLabel => 'семестр';

  @override
  String get reportAcademicYear => 'Учебный год';

  @override
  String get reportRegistrationNumber => 'Регистрационный №';

  @override
  String get reportCopied => 'Скопировано';

  @override
  String get reportUploadCta => 'Загрузить работу';

  @override
  String get reportUploadCtaHint => 'PDF до 10 МБ — в «Прочие работы»';

  @override
  String get reportUploadTitle => 'Загрузка работы';

  @override
  String get reportUploadHeroSubtitle =>
      'Выберите дисциплину, назовите работу и прикрепите PDF';

  @override
  String get reportUploadDiscipline => 'Дисциплина';

  @override
  String get reportUploadDisciplineHint => 'Выберите дисциплину';

  @override
  String get reportUploadDisciplinesLoading => 'Загружаем список дисциплин…';

  @override
  String get reportUploadDisciplinesError =>
      'Не удалось получить список дисциплин';

  @override
  String get reportUploadNoDisciplines =>
      'Сайт не вернул дисциплин для загрузки';

  @override
  String get reportUploadSearch => 'Поиск дисциплины';

  @override
  String get reportUploadWorkTitle => 'Название работы';

  @override
  String get reportUploadWorkTitleHint =>
      'Например: Отчёт по лабораторной работе №1';

  @override
  String get reportUploadTitleRequired => 'Введите название работы';

  @override
  String get reportUploadFile => 'Файл работы';

  @override
  String get reportUploadPickFile => 'Выберите файл';

  @override
  String get reportUploadFileHint => 'PDF, не более 10 МБ';

  @override
  String get reportUploadFileRequired => 'Прикрепите PDF-файл';

  @override
  String get reportUploadOnlyPdf => 'Нужен файл в формате PDF';

  @override
  String get reportUploadTooLarge => 'Файл больше 10 МБ — сайт его не примет';

  @override
  String get reportUploadPickFailed => 'Не удалось выбрать файл';

  @override
  String get reportUploadRemoveFile => 'Убрать файл';

  @override
  String get reportUploadSend => 'Загрузить';

  @override
  String reportUploadSending(int percent) {
    return 'Загрузка $percent%';
  }

  @override
  String get reportUploadProcessing => 'Обрабатываем файл…';

  @override
  String get reportUploadDone => 'Работа загружена';

  @override
  String get reportUploadFailed =>
      'Не удалось загрузить работу. Попробуйте ещё раз';

  @override
  String get reportUploadServerError => 'Работа не загружена';

  @override
  String get reportUploadNote =>
      'После загрузки работа появится в списке со статусом «На проверке»';

  @override
  String get reportDelete => 'Удалить работу';

  @override
  String get reportDeleteTitle => 'Удалить работу?';

  @override
  String reportDeleteBody(String title) {
    return '«$title» будет удалена с сайта ОмГТУ. Отменить это нельзя.';
  }

  @override
  String get reportDeleted => 'Работа удалена';

  @override
  String get reportDeleteFailed => 'Не удалось удалить работу';

  @override
  String get profileTitle => 'Профиль';

  @override
  String get profileNameHint => 'Ваше ФИО';

  @override
  String get profileNameLabel => 'Введите ФИО';

  @override
  String get profileNameEdit => 'Изменить имя';

  @override
  String get profileGroup => 'Группа';

  @override
  String get profileGroupNotSelected => 'Группа не выбрана';

  @override
  String get profileGroupTap => 'Нажмите, чтобы выбрать';

  @override
  String get profileUniversity =>
      'Омский государственный технический университет';

  @override
  String get profileServices => 'Сервисы университета';

  @override
  String get profileSiteOmgtu => 'Сайт ОМГТУ';

  @override
  String get profileSiteSchedule => 'Расписание (сайт)';

  @override
  String get profileSiteNews => 'Новости';

  @override
  String get profileSitePortal => 'Портал up.omgtu.ru';

  @override
  String get profileSettings => 'Настройки';

  @override
  String get profileBuildBy => 'сборка by Eaggle';

  @override
  String get lkSection => 'Личный кабинет ОмГТУ';

  @override
  String get lkNotConnected => 'Не подключён';

  @override
  String get lkConnect => 'Подключить';

  @override
  String get lkDisconnect => 'Отключить';

  @override
  String get lkLoginTitle => 'Вход в личный кабинет';

  @override
  String get lkLoginSubtitle => 'ОмГТУ • Информационная система';

  @override
  String get lkLoginHint =>
      'Используются те же логин и пароль, что и на up.omgtu.ru';

  @override
  String get lkUsername => 'Логин студента';

  @override
  String get lkPassword => 'Пароль';

  @override
  String get lkLoginButton => 'Войти';

  @override
  String get lkForgotPassword => 'Забыли?';

  @override
  String get lkSkipGuest => 'Пропустить (продолжить как гость)';

  @override
  String get lkSslNote =>
      'Логин и пароль уходят только на сайт ОмГТУ по защищённому соединению';

  @override
  String get lkPrivacyNote =>
      'Приложение работает автономно: данные хранятся в зашифрованном хранилище телефона и больше никуда не передаются — ни на сторонние серверы, ни разработчику';

  @override
  String get lkOnboardingTitle => 'Войдите в личный кабинет';

  @override
  String get lkOnboardingMessage =>
      'Для доступа к контактным работам, отчётам и оценкам нужен аккаунт up.omgtu.ru — те же логин и пароль, что на сайте.';

  @override
  String get lkConnecting => 'Подключение к сайту…';

  @override
  String get lkConnectError => 'Ошибка подключения';

  @override
  String get lkInvalidCredentials => 'Неверный логин или пароль';

  @override
  String get lkNetworkError => 'Не удалось подключиться к ЛК';

  @override
  String get lkConnected => 'Подключён';

  @override
  String get lkBookNumber => 'Зачётная книжка №';

  @override
  String get lkLoadError => 'Не удалось обновить данные';

  @override
  String get lkCacheShown => 'Показаны последние сохранённые данные';

  @override
  String get lkDisconnectConfirm =>
      'Отключить личный кабинет? Пароль будет удалён с устройства.';

  @override
  String get lkExamsSection => 'Экзамены';

  @override
  String get lkCreditsSection => 'Зачёты';

  @override
  String get lkCourseworkSection => 'Курсовые';

  @override
  String get lkRequired => 'Только для авторизованных';

  @override
  String get lkRequiredMsg =>
      'Войдите в личный кабинет, чтобы получить доступ к этим данным.';

  @override
  String get lkRequiredAction => 'Войти в ЛК';

  @override
  String get profileEditTitle => 'Редактировать профиль';

  @override
  String get profilePhotoChange => 'Изменить фото';

  @override
  String get profilePhotoRemove => 'Удалить фото';

  @override
  String get profilePhotoGallery => 'Галерея';

  @override
  String get profilePhotoCamera => 'Камера';

  @override
  String get profileNameFromLk => 'Имя подтянуто из личного кабинета';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get settingsLangRu => 'Русский';

  @override
  String get settingsLangEn => 'English';

  @override
  String get settingsTheme => 'Оформление';

  @override
  String get settingsThemeDark => 'Тёмная';

  @override
  String get settingsThemeLight => 'Светлая';

  @override
  String get settingsThemeSystem => 'Как в системе';

  @override
  String get settingsAbout => 'О приложении';

  @override
  String get settingsVersion => 'Версия';

  @override
  String get settingsAboutApp => 'OmTech';

  @override
  String get settingsNotifications => 'Уведомления';

  @override
  String get settingsNotifTasks => 'Новые задания';

  @override
  String get settingsNotifTasksHint =>
      'Контактная работа: появились новые задания';

  @override
  String get settingsNotifReports => 'Статусы отчётных работ';

  @override
  String get settingsNotifReportsHint =>
      'Работу приняли или вернули на доработку';

  @override
  String get settingsNotifGrades => 'Новые оценки';

  @override
  String get settingsNotifGradesHint => 'В зачётке появились новые оценки';

  @override
  String get settingsNotifSchedule => 'Изменения в расписании';

  @override
  String get settingsNotifScheduleHint =>
      'Перенос или отмена пар на этой и следующей неделе';

  @override
  String get settingsNotifTestSchedule => 'Изменение расписания';

  @override
  String get settingsNotifTest => 'Проверить уведомление';

  @override
  String get settingsNotifTestTask => 'Новое задание';

  @override
  String get settingsNotifTestAccepted => 'Работа принята';

  @override
  String get settingsNotifTestRejected => 'Работа на доработку';

  @override
  String get settingsNotifTestGrade => 'Новая оценка';

  @override
  String get settingsData => 'Данные';

  @override
  String get settingsClearCache => 'Очистить кэш';

  @override
  String settingsCacheSize(String size) {
    return 'Занято: $size';
  }

  @override
  String get settingsCacheCounting => 'Считаем размер…';

  @override
  String get settingsClearCacheTitle => 'Очистить кэш?';

  @override
  String get settingsClearCacheBody =>
      'Будут удалены: сохранённое расписание, данные ЛК, кэш новостей, скачанные файлы и история поиска.';

  @override
  String get settingsClearCacheKept =>
      'Вход в ЛК, группа, тема и язык останутся на месте.';

  @override
  String get settingsCacheCleared => 'Кэш очищен';

  @override
  String get bugReportAction => 'Сообщить об ошибке';

  @override
  String get bugReportSettingsHint =>
      'Письмо разработчику с файлом диагностики';

  @override
  String get bugReportTitle => 'Сообщить об ошибке';

  @override
  String bugReportSubtitle(String email) {
    return 'Письмо уйдёт на $email';
  }

  @override
  String get bugReportHint => 'Что пошло не так? Что вы делали перед этим?';

  @override
  String get bugReportIncluded => 'В письмо попадёт';

  @override
  String get bugReportIncDevice =>
      'Версия приложения, система, группа и состояние ЛК';

  @override
  String get bugReportIncLog =>
      'Журнал последних действий — без логина и пароля';

  @override
  String get bugReportAttachPages => 'Приложить страницы ЛК';

  @override
  String get bugReportAttachPagesHint =>
      'Помогает починить разбор данных. В них есть ваше ФИО и список работ';

  @override
  String get bugReportScreens => 'Скриншоты';

  @override
  String get bugReportAddScreen => 'Добавить';

  @override
  String get bugReportScreensHint =>
      'Снимок экрана, где вы открыли отчёт, уже приложен. Уберите его, если на нём личное';

  @override
  String get bugReportSend => 'Составить письмо';

  @override
  String bugReportFailed(String email) {
    return 'Не удалось открыть почту. Адрес $email скопирован';
  }

  @override
  String get dashboardGreeting => 'Добро пожаловать!';

  @override
  String get dashboardStudent => 'Студент';

  @override
  String dashboardHello(String name) {
    return 'Привет, $name!';
  }

  @override
  String get dashboardNoGroup => 'Группа не выбрана';

  @override
  String get dashboardNextLesson => 'Текущая/ближайшая пара';

  @override
  String get dashboardNoNextLesson => 'Пар на сегодня нет';

  @override
  String get dashboardGrades => 'Оценки';

  @override
  String get dashboardMaterials => 'Материалы';

  @override
  String get dashboardTasks => 'Контактная работа';

  @override
  String get dashboardReportWorks => 'Отчётные работы';

  @override
  String get dashboardNews => 'Новости';

  @override
  String get dashboardAllNews => 'Все новости';

  @override
  String get dashboardSelectGroup => 'Выбрать группу';

  @override
  String get dashboardSubtitle => 'Цифровой кампус';

  @override
  String get dashboardWeekOdd => 'Нечётная';

  @override
  String get dashboardWeekEven => 'Чётная';

  @override
  String dashboardLessonsToday(int n) {
    return 'Сегодня $n пар';
  }

  @override
  String get dashboardNoLessonsToday => 'Сегодня пар нет';

  @override
  String dashboardGpaCaption(String gpa) {
    return 'Ср. балл $gpa';
  }

  @override
  String get groupSearchTitle => 'Поиск группы';

  @override
  String get groupSearchHint => 'Введите номер группы...';

  @override
  String get searchTitle => 'Общий поиск';

  @override
  String get searchSubtitle => 'Группы, преподаватели и аудитории ОмГТУ';

  @override
  String get searchHint => 'Например: ИВТ, Иванов, 8-418...';

  @override
  String get searchStartTyping => 'Начните вводить запрос';

  @override
  String get searchNoResults => 'Ничего не найдено';

  @override
  String get searchRecentTitle => 'Недавние запросы';

  @override
  String get searchClearAll => 'Очистить всё';

  @override
  String get searchAll => 'Все';

  @override
  String get searchOpenSchedule => 'Расписание';

  @override
  String get entitySearchTeacherTitle => 'Поиск преподавателя';

  @override
  String get entitySearchTeacherHint => 'Фамилия, например: Иванов';

  @override
  String get entitySearchAuditoriumTitle => 'Поиск аудитории';

  @override
  String get entitySearchAuditoriumHint => 'Номер, например: 8-418';

  @override
  String get entitySearchError =>
      'Не удалось выполнить поиск. Проверьте соединение.';

  @override
  String scheduleOnlyMySubgroup(int n) {
    return 'Только $n-я подгруппа';
  }

  @override
  String get scheduleSubgroup => 'Подгруппа';

  @override
  String get scheduleStream => 'Поток';

  @override
  String get scheduleWeekView => 'Неделя';

  @override
  String get scheduleDayView => 'День';

  @override
  String get scheduleNoLessonsToday => 'Иди трогать траву!\nСегодня пар нет 🌿';

  @override
  String get scheduleNoLessonsTodayMsg =>
      'Наслаждайся свободным временем или посмотри другой день.';

  @override
  String get scheduleShowWeek => 'Показать всю неделю';

  @override
  String get schedulePickDate => 'Выбрать дату';

  @override
  String get scheduleModeGroup => 'Группа';

  @override
  String get scheduleModeTeacher => 'Препод.';

  @override
  String get scheduleModeAuditorium => 'Аудит.';

  @override
  String get scheduleSearch => 'Поиск';

  @override
  String get scheduleFilters => 'Фильтры';

  @override
  String get scheduleAllSubgroups => 'Все подгруппы';

  @override
  String scheduleSubgroupN(int n) {
    return '$n-я подгруппа';
  }

  @override
  String get scheduleHideRetake => 'Скрыть пересдачи';

  @override
  String get schedulePickTeacher => 'Выбрать преподавателя';

  @override
  String get schedulePickAuditorium => 'Выбрать аудиторию';

  @override
  String get scheduleNoTeacher => 'Преподаватель не выбран';

  @override
  String get scheduleNoTeacherMsg =>
      'Найдите преподавателя и смотрите его расписание на неделю.';

  @override
  String get scheduleNoAuditorium => 'Аудитория не выбрана';

  @override
  String get scheduleNoAuditoriumMsg =>
      'Найдите аудиторию и смотрите её занятость на неделю.';

  @override
  String get scheduleSunday => 'Воскресенье!';

  @override
  String get scheduleSundayMsg => 'Законный выходной — трогай траву! 🌿';

  @override
  String get scheduleNoLessonsDay => 'Нет занятий';

  @override
  String get scheduleNoLessonsDayMsg => 'В выбранный день пар нет.';

  @override
  String get scheduleRoute => 'Маршрут';

  @override
  String get profileFirstName => 'Имя';

  @override
  String get profileLastName => 'Фамилия';

  @override
  String get profilePatronymic => 'Отчество';

  @override
  String get profileSubgroup => 'Подгруппа';

  @override
  String get profileSubgroupAll => 'Все';

  @override
  String get profileSubgroupHint =>
      'Укажите подгруппу для фильтрации расписания';

  @override
  String get profileGroupAutoFilled => 'Группа заполнена из личного кабинета';

  @override
  String get reportSubjectFilter => 'Предмет';

  @override
  String get reportSemesterFilter => 'Семестр';

  @override
  String get reportDownload => 'Скачать';

  @override
  String get reportDownloading => 'Скачивание...';

  @override
  String get reportNoFiles => 'Файл недоступен';

  @override
  String get reportAllSubjects => 'Все предметы';

  @override
  String get fileOpen => 'Открыть';

  @override
  String get fileSave => 'Сохранить';

  @override
  String fileSavedTo(String path) {
    return 'Сохранено: $path';
  }

  @override
  String get cancel => 'Отмена';

  @override
  String get save => 'Сохранить';

  @override
  String get close => 'Закрыть';

  @override
  String get ok => 'ОК';

  @override
  String get loading => 'Загрузка...';

  @override
  String get error => 'Ошибка';

  @override
  String get retry => 'Повторить';

  @override
  String get noInternet => 'Нет подключения к интернету';

  @override
  String get updateEyebrow => 'Новая версия';

  @override
  String updateCurrent(String version) {
    return 'у вас $version';
  }

  @override
  String get updateBody => 'Встанет поверх текущей — удалять ничего не нужно.';

  @override
  String updateSize(String size) {
    return '$size МБ';
  }

  @override
  String get updateSizeCaption => 'загрузка';

  @override
  String get updateKeeps => 'Всё на месте';

  @override
  String get updateKeepsCaption => 'вход и настройки';

  @override
  String get updateInstall => 'Обновить';

  @override
  String get updateLater => 'Позже';

  @override
  String get updateDownloading => 'Скачивание';

  @override
  String get updateOpening => 'Открываю установщик';

  @override
  String get updateFailed =>
      'Не удалось скачать. Проверьте интернет и попробуйте ещё раз.';

  @override
  String get settingsBackground => 'Фоновая работа';

  @override
  String get settingsBackgroundAllowed =>
      'Разрешена — уведомления приходят и при закрытом приложении';

  @override
  String get settingsBackgroundRestricted =>
      'Ограничена системой — уведомления могут не приходить';

  @override
  String get settingsBackgroundAllow => 'Разрешить';

  @override
  String settingsBackgroundLastRun(String time, String result) {
    return 'Последняя проверка: $time — $result';
  }

  @override
  String get settingsBackgroundNever => 'Фоновая проверка ещё не запускалась';

  @override
  String get bgResultOk => 'успешно';

  @override
  String get bgResultUiActive => 'пропущена, приложение было открыто';

  @override
  String get bgResultNoCreds => 'нет входа в ЛК';

  @override
  String get bgResultAuthFailed => 'пароль не подошёл';

  @override
  String get bgResultNetwork => 'нет связи';

  @override
  String get bgResultError => 'ошибка';

  @override
  String get batteryHintTitle => 'Уведомления при закрытом приложении';

  @override
  String get batteryHintBody =>
      'Чтобы узнавать о новых заданиях, оценках и проверке отчётов, не открывая приложение, разрешите OmTech работать в фоне. Иначе система может не запускать проверку.';

  @override
  String get batteryHintLater => 'Не сейчас';
}
