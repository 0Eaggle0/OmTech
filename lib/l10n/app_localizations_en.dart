// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'OmTech';

  @override
  String get navHome => 'Home';

  @override
  String get navSchedule => 'Schedule';

  @override
  String get navNews => 'News';

  @override
  String get navWork => 'Tasks';

  @override
  String get navProfile => 'Profile';

  @override
  String get scheduleTitle => 'Schedule';

  @override
  String get scheduleNoGroup => 'No group selected';

  @override
  String get scheduleNoGroupMsg =>
      'Select your study group to see the schedule.';

  @override
  String get schedulePickGroup => 'Select group';

  @override
  String get scheduleNoLessons => 'No classes this week';

  @override
  String get scheduleNoLessonsMsg =>
      'Enjoy your free time or browse another week.';

  @override
  String get scheduleLoadError => 'Failed to load';

  @override
  String get scheduleLoadErrorMsg =>
      'Check your internet connection and try again.';

  @override
  String get scheduleRetry => 'Retry';

  @override
  String scheduleCachedAt(String time) {
    return 'updated at $time';
  }

  @override
  String get lessonDetailSubgroup => 'subgroup';

  @override
  String get lessonDetailNote => 'Your note';

  @override
  String get lessonDetailShare => 'Share note';

  @override
  String get lessonDetailTeacherOptions => 'Teacher actions';

  @override
  String get lessonDetailContacts => 'Show contacts';

  @override
  String get lessonDetailReviews => 'Reviews';

  @override
  String get lessonDetailOpenMaps => 'Open in maps';

  @override
  String get lessonDetailStream => 'stream';

  @override
  String get newsTitle => 'News';

  @override
  String get newsLoadError => 'Failed to load news';

  @override
  String get newsEmpty => 'No news yet';

  @override
  String get newsOpenFull => 'Read on website';

  @override
  String get gradesTitle => 'Grades';

  @override
  String get gradesSemester => 'sem';

  @override
  String get gradesDemoNote =>
      'Demo data. Real grades will appear after connecting your personal account.';

  @override
  String gradesProgress(int n) {
    return 'Study progress ($n semesters)';
  }

  @override
  String gradesCourse(int n) {
    return 'Year $n';
  }

  @override
  String get gradesExcellent => 'Excellent';

  @override
  String get gradesGood => 'Good';

  @override
  String get gradesCredited => 'Credited';

  @override
  String gradesNoGradesYet(int n) {
    return 'Semester $n: no grades yet';
  }

  @override
  String gradesSemesterLabel(int n) {
    return 'Sem. $n';
  }

  @override
  String get materialsTitle => 'Materials';

  @override
  String get materialsDemoNote =>
      'Demo data. Real materials will appear after connecting your personal account.';

  @override
  String get workTitle => 'Contact work';

  @override
  String get workSearch => 'Discipline';

  @override
  String get workTaskCount => 'tasks';

  @override
  String get workTaskNumber => 'Number';

  @override
  String get workTaskComment => 'Comment';

  @override
  String get workTaskFiles => 'Files';

  @override
  String get workTaskDate => 'Created';

  @override
  String get workTaskTeacher => 'Teacher';

  @override
  String get workTaskNoFiles => 'No files';

  @override
  String get workDemoNote =>
      'Demo data. Real tasks will appear after connecting your personal account.';

  @override
  String get workTeachers => 'Teachers';

  @override
  String get workHubTitle => 'Tasks';

  @override
  String workMaterialsCount(int n) {
    return '$n tasks/materials';
  }

  @override
  String workNewCount(int n) {
    return '+$n new';
  }

  @override
  String workSyncedAt(String time) {
    return 'Synced with OmSTU server: $time';
  }

  @override
  String get workLecturer => 'Lead lecturer';

  @override
  String get workLecturerStub =>
      'Placeholder: no lecturer data yet — the source isn\'t wired up.';

  @override
  String get workServerUnavailable => 'Server unavailable';

  @override
  String get reportWorksTitle => 'Submitted works';

  @override
  String get reportWorksDashboardTile => 'Submitted works';

  @override
  String get reportCourseWorks => 'Course works';

  @override
  String get reportOtherWorks => 'Other works';

  @override
  String get reportStatusPending => 'In review';

  @override
  String get reportStatusAccepted => 'Accepted';

  @override
  String get reportStatusRejected => 'Needs revision';

  @override
  String get reportFilterAll => 'All';

  @override
  String get reportSearch => 'Search by title or subject';

  @override
  String get reportTeacher => 'Teacher';

  @override
  String get reportComment => 'Comment';

  @override
  String get reportEmpty => 'No submitted works yet';

  @override
  String get reportDemoNote =>
      'Demo data. Real list of works will appear after connecting your personal account.';

  @override
  String get reportWorkNumberLabel => 'No.';

  @override
  String get reportSemesterLabel => 'semester';

  @override
  String get reportAcademicYear => 'Academic year';

  @override
  String get reportRegistrationNumber => 'Registration No.';

  @override
  String get reportCopied => 'Copied';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileNameHint => 'Your full name';

  @override
  String get profileNameLabel => 'Enter full name';

  @override
  String get profileNameEdit => 'Edit name';

  @override
  String get profileGroup => 'Group';

  @override
  String get profileGroupNotSelected => 'No group selected';

  @override
  String get profileGroupTap => 'Tap to select';

  @override
  String get profileUniversity => 'Omsk State Technical University';

  @override
  String get profileServices => 'University services';

  @override
  String get profileSiteOmgtu => 'OMGTU website';

  @override
  String get profileSiteSchedule => 'Schedule (website)';

  @override
  String get profileSiteNews => 'News';

  @override
  String get profileSitePortal => 'Portal up.omgtu.ru';

  @override
  String get profileSettings => 'Settings';

  @override
  String get profileBuildBy => 'build by Eaggle';

  @override
  String get lkSection => 'OmGTU personal account';

  @override
  String get lkNotConnected => 'Not connected';

  @override
  String get lkConnect => 'Connect';

  @override
  String get lkDisconnect => 'Disconnect';

  @override
  String get lkLoginTitle => 'Sign in to personal account';

  @override
  String get lkLoginSubtitle => 'OmSTU • Information system';

  @override
  String get lkLoginHint => 'Use the same credentials as on up.omgtu.ru';

  @override
  String get lkUsername => 'Student login';

  @override
  String get lkPassword => 'Password';

  @override
  String get lkLoginButton => 'Sign in';

  @override
  String get lkForgotPassword => 'Forgot?';

  @override
  String get lkSkipGuest => 'Skip (continue as guest)';

  @override
  String get lkSslNote => 'Secure SSL connection to OmSTU';

  @override
  String get lkInvalidCredentials => 'Invalid username or password';

  @override
  String get lkNetworkError => 'Failed to reach the portal';

  @override
  String get lkConnected => 'Connected';

  @override
  String get lkBookNumber => 'Record book No.';

  @override
  String get lkLoadError => 'Failed to refresh data';

  @override
  String get lkCacheShown => 'Showing last saved data';

  @override
  String get lkDisconnectConfirm =>
      'Disconnect the account? Password will be removed from this device.';

  @override
  String get lkExamsSection => 'Exams';

  @override
  String get lkCreditsSection => 'Credits';

  @override
  String get lkCourseworkSection => 'Coursework';

  @override
  String get lkRequired => 'Sign in required';

  @override
  String get lkRequiredMsg =>
      'Sign in to your personal account to access this data.';

  @override
  String get lkRequiredAction => 'Sign in';

  @override
  String get profileEditTitle => 'Edit profile';

  @override
  String get profilePhotoChange => 'Change photo';

  @override
  String get profilePhotoRemove => 'Remove photo';

  @override
  String get profilePhotoGallery => 'Gallery';

  @override
  String get profilePhotoCamera => 'Camera';

  @override
  String get profileNameFromLk => 'Name pulled from personal account';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLangRu => 'Русский';

  @override
  String get settingsLangEn => 'English';

  @override
  String get settingsTheme => 'Appearance';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsAboutApp => 'OmTech';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotifTasks => 'New tasks';

  @override
  String get settingsNotifTasksHint => 'Contact work: new tasks appeared';

  @override
  String get settingsNotifReports => 'Submitted work status';

  @override
  String get settingsNotifReportsHint =>
      'Work accepted or sent back for revision';

  @override
  String get settingsNotifGrades => 'New grades';

  @override
  String get settingsNotifGradesHint => 'New grades appeared in your record';

  @override
  String get settingsNotifTest => 'Send a test notification';

  @override
  String get settingsNotifTestTask => 'New task';

  @override
  String get settingsNotifTestAccepted => 'Work accepted';

  @override
  String get settingsNotifTestRejected => 'Work needs revision';

  @override
  String get settingsNotifTestGrade => 'New grade';

  @override
  String get settingsData => 'Data';

  @override
  String get settingsClearCache => 'Clear cache';

  @override
  String settingsCacheSize(String size) {
    return 'Using: $size';
  }

  @override
  String get settingsCacheCounting => 'Measuring…';

  @override
  String get settingsClearCacheTitle => 'Clear cache?';

  @override
  String get settingsClearCacheBody =>
      'This removes: saved schedule, personal account data, news cache, downloaded files and search history.';

  @override
  String get settingsClearCacheKept =>
      'Your sign-in, group, theme and language stay untouched.';

  @override
  String get settingsCacheCleared => 'Cache cleared';

  @override
  String get dashboardGreeting => 'Welcome!';

  @override
  String dashboardHello(String name) {
    return 'Hi, $name!';
  }

  @override
  String get dashboardNoGroup => 'No group selected';

  @override
  String get dashboardNextLesson => 'Current/next class';

  @override
  String get dashboardNoNextLesson => 'No classes today';

  @override
  String get dashboardGrades => 'Grades';

  @override
  String get dashboardMaterials => 'Materials';

  @override
  String get dashboardTasks => 'Contact work';

  @override
  String get dashboardReportWorks => 'Submitted works';

  @override
  String get dashboardNews => 'News';

  @override
  String get dashboardAllNews => 'All news';

  @override
  String get dashboardSelectGroup => 'Select group';

  @override
  String get dashboardSubtitle => 'Digital campus';

  @override
  String get dashboardWeekOdd => 'Odd';

  @override
  String get dashboardWeekEven => 'Even';

  @override
  String dashboardLessonsToday(int n) {
    return '$n classes today';
  }

  @override
  String get dashboardNoLessonsToday => 'No classes today';

  @override
  String dashboardGpaCaption(String gpa) {
    return 'GPA $gpa';
  }

  @override
  String get groupSearchTitle => 'Search group';

  @override
  String get groupSearchHint => 'Enter group number...';

  @override
  String get groupSearchEmpty => 'No groups found';

  @override
  String get groupSearchLoading => 'Searching...';

  @override
  String get groupSearchError =>
      'Couldn\'t find groups. Check your connection.';

  @override
  String get searchTitle => 'Search';

  @override
  String get searchSubtitle => 'Groups, teachers and rooms at OmSTU';

  @override
  String get searchHint => 'e.g. IST, Smith, 8-418...';

  @override
  String get searchStartTyping => 'Start typing to search';

  @override
  String get searchNoResults => 'Nothing found';

  @override
  String get searchRecentTitle => 'Recent searches';

  @override
  String get searchClearAll => 'Clear all';

  @override
  String get searchAll => 'All';

  @override
  String get searchOpenSchedule => 'Schedule';

  @override
  String get entitySearchTeacherTitle => 'Search teacher';

  @override
  String get entitySearchTeacherHint => 'Last name, e.g. Smith';

  @override
  String get entitySearchAuditoriumTitle => 'Search room';

  @override
  String get entitySearchAuditoriumHint => 'Room number, e.g. 8-418';

  @override
  String get entitySearchNoResults => 'Nothing found';

  @override
  String get entitySearchHintShort => 'Type at least 2 characters';

  @override
  String get entitySearchError => 'Search failed. Check your connection.';

  @override
  String scheduleOnlyMySubgroup(int n) {
    return 'Only subgroup $n';
  }

  @override
  String get scheduleSubgroup => 'Subgroup';

  @override
  String get scheduleStream => 'Stream';

  @override
  String get scheduleWeekView => 'Week';

  @override
  String get scheduleDayView => 'Day';

  @override
  String get scheduleNoLessonsToday =>
      'Go touch some grass!\nNo classes today 🌿';

  @override
  String get scheduleNoLessonsTodayMsg =>
      'Enjoy your free time or check another day.';

  @override
  String get scheduleShowWeek => 'Show full week';

  @override
  String get schedulePickDate => 'Pick date';

  @override
  String get scheduleModeGroup => 'Group';

  @override
  String get scheduleModeTeacher => 'Teacher';

  @override
  String get scheduleModeAuditorium => 'Room';

  @override
  String get scheduleSearch => 'Search';

  @override
  String get scheduleAllSubgroups => 'All subgroups';

  @override
  String scheduleSubgroupN(int n) {
    return 'Subgroup $n';
  }

  @override
  String get scheduleHideRetake => 'Hide retakes';

  @override
  String get schedulePickTeacher => 'Pick teacher';

  @override
  String get schedulePickAuditorium => 'Pick room';

  @override
  String get scheduleNoTeacher => 'No teacher selected';

  @override
  String get scheduleNoTeacherMsg =>
      'Find a teacher to see their weekly schedule.';

  @override
  String get scheduleNoAuditorium => 'No room selected';

  @override
  String get scheduleNoAuditoriumMsg =>
      'Find a room to see how it is booked this week.';

  @override
  String get scheduleSunday => 'Sunday!';

  @override
  String get scheduleSundayMsg => 'A well-earned day off — go touch grass 🌿';

  @override
  String get scheduleNoLessonsDay => 'No classes';

  @override
  String get scheduleNoLessonsDayMsg =>
      'There are no classes on the selected day.';

  @override
  String get scheduleRoute => 'Route';

  @override
  String get profileFirstName => 'First name';

  @override
  String get profileLastName => 'Last name';

  @override
  String get profilePatronymic => 'Patronymic';

  @override
  String get profileSubgroup => 'Subgroup';

  @override
  String get profileSubgroupAll => 'All';

  @override
  String get profileSubgroupHint => 'Set your subgroup to filter the schedule';

  @override
  String get profileGroupAutoFilled => 'Group filled from personal account';

  @override
  String get reportSubjectFilter => 'Subject';

  @override
  String get reportSemesterFilter => 'Semester';

  @override
  String get reportDownload => 'Download';

  @override
  String get reportDownloading => 'Downloading...';

  @override
  String get reportNoFiles => 'File not available';

  @override
  String get reportAllSubjects => 'All subjects';

  @override
  String get reportShareHtml => 'Share page HTML';

  @override
  String get fileOpen => 'Open';

  @override
  String get fileSave => 'Save';

  @override
  String fileSavedTo(String path) {
    return 'Saved: $path';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get close => 'Close';

  @override
  String get ok => 'OK';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get retry => 'Retry';

  @override
  String get noInternet => 'No internet connection';
}
