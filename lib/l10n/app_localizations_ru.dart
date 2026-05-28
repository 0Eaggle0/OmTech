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
  String get lessonDetailSubgroup => 'подгруппа';

  @override
  String get lessonDetailNote => 'Ваша заметка';

  @override
  String get lessonDetailShare => 'Поделиться заметкой';

  @override
  String get lessonDetailTeacherOptions => 'Действия с преподавателем';

  @override
  String get lessonDetailContacts => 'Показать контакты';

  @override
  String get lessonDetailReviews => 'Отзывы';

  @override
  String get lessonDetailOpenMaps => 'Открыть на карте';

  @override
  String get lessonDetailStream => 'поток';

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
  String get materialsTitle => 'Материалы';

  @override
  String get materialsDemoNote =>
      'Демонстрационные данные. Реальные материалы появятся после подключения личного кабинета.';

  @override
  String get workTitle => 'Задания';

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
  String get reportStatusRejected => 'Отклонена';

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
  String get reportUploadStub => 'Загрузка работ — в разработке';

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
  String get profileSettings => 'Настройки';

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
  String get lkLoginHint =>
      'Используются те же логин и пароль, что и на up.omgtu.ru';

  @override
  String get lkUsername => 'Логин';

  @override
  String get lkPassword => 'Пароль';

  @override
  String get lkLoginButton => 'Войти';

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
  String get dashboardGreeting => 'Добро пожаловать!';

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
  String get dashboardTasks => 'Задания';

  @override
  String get dashboardReportWorks => 'Отчётные работы';

  @override
  String get dashboardNews => 'Новости';

  @override
  String get dashboardAllNews => 'Все новости';

  @override
  String get dashboardSelectGroup => 'Выбрать группу';

  @override
  String get groupSearchTitle => 'Поиск группы';

  @override
  String get groupSearchHint => 'Введите номер группы...';

  @override
  String get groupSearchEmpty => 'Группы не найдены';

  @override
  String get groupSearchLoading => 'Поиск...';

  @override
  String get scheduleMySubgroup => 'Моя подгруппа';

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
}
