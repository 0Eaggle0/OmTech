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
  String get lessonDetailOpenMaps => 'Open in maps';

  @override
  String get lessonDetailStream => 'Groups';

  @override
  String get teacherContactsTitle => 'Contacts';

  @override
  String teacherContactsFor(String name) {
    return 'Contacts · $name';
  }

  @override
  String teacherContactsSource(String discipline) {
    return 'From contact work · $discipline';
  }

  @override
  String get contactKindEmail => 'Email';

  @override
  String get contactKindPhone => 'Phone';

  @override
  String get contactKindVk => 'VK';

  @override
  String get contactCopy => 'Copy';

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
  String get reportUploadCta => 'Upload a work';

  @override
  String get reportUploadCtaHint => 'PDF up to 10 MB — to “Other works”';

  @override
  String get reportUploadTitle => 'Upload work';

  @override
  String get reportUploadHeroSubtitle =>
      'Pick a discipline, name the work and attach a PDF';

  @override
  String get reportUploadDiscipline => 'Discipline';

  @override
  String get reportUploadDisciplineHint => 'Choose a discipline';

  @override
  String get reportUploadDisciplinesLoading => 'Loading disciplines…';

  @override
  String get reportUploadDisciplinesError =>
      'Couldn\'t load the list of disciplines';

  @override
  String get reportUploadNoDisciplines =>
      'The site returned no disciplines to upload to';

  @override
  String get reportUploadSearch => 'Search discipline';

  @override
  String get reportUploadWorkTitle => 'Work title';

  @override
  String get reportUploadWorkTitleHint => 'e.g. Lab report #1';

  @override
  String get reportUploadTitleRequired => 'Enter the work title';

  @override
  String get reportUploadFile => 'Work file';

  @override
  String get reportUploadPickFile => 'Choose a file';

  @override
  String get reportUploadFileHint => 'PDF, up to 10 MB';

  @override
  String get reportUploadFileRequired => 'Attach a PDF file';

  @override
  String get reportUploadOnlyPdf => 'The file must be a PDF';

  @override
  String get reportUploadTooLarge =>
      'The file is over 10 MB — the site won\'t accept it';

  @override
  String get reportUploadPickFailed => 'Couldn\'t pick the file';

  @override
  String get reportUploadRemoveFile => 'Remove file';

  @override
  String get reportUploadSend => 'Upload';

  @override
  String reportUploadSending(int percent) {
    return 'Uploading $percent%';
  }

  @override
  String get reportUploadProcessing => 'Processing file…';

  @override
  String get reportUploadDone => 'Work uploaded';

  @override
  String get reportUploadFailed =>
      'Couldn\'t upload the work. Please try again';

  @override
  String get reportUploadServerError => 'Work not uploaded';

  @override
  String get reportUploadNote =>
      'Once uploaded, the work appears in the list as “In review”';

  @override
  String get reportDelete => 'Delete work';

  @override
  String get reportDeleteTitle => 'Delete this work?';

  @override
  String reportDeleteBody(String title) {
    return '“$title” will be removed from the OmSTU site. This can\'t be undone.';
  }

  @override
  String get reportDeleted => 'Work deleted';

  @override
  String get reportDeleteFailed => 'Couldn\'t delete the work';

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
  String get lkSslNote =>
      'Your login and password go only to the OmSTU site over a secure connection';

  @override
  String get lkPrivacyNote =>
      'The app works on its own: your data stays in the phone\'s encrypted storage and is never sent anywhere else — not to third-party servers, not to the developer';

  @override
  String get lkOnboardingTitle => 'Sign in to your personal account';

  @override
  String get lkOnboardingMessage =>
      'Contact work, reports and grades require an up.omgtu.ru account — the same credentials you use on the site.';

  @override
  String get lkConnecting => 'Connecting to the site…';

  @override
  String get lkConnectError => 'Connection error';

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
  String get bugReportAction => 'Report a problem';

  @override
  String get bugReportSettingsHint =>
      'Email the developer with a diagnostics file';

  @override
  String get bugReportTitle => 'Report a problem';

  @override
  String bugReportSubtitle(String email) {
    return 'The email goes to $email';
  }

  @override
  String get bugReportHint =>
      'What went wrong? What were you doing before that?';

  @override
  String get bugReportIncluded => 'The email will include';

  @override
  String get bugReportIncDevice => 'App version, OS, group and account status';

  @override
  String get bugReportIncLog =>
      'Recent activity log — without login or password';

  @override
  String get bugReportAttachPages => 'Attach account pages';

  @override
  String get bugReportAttachPagesHint =>
      'Helps fix data parsing. They contain your name and list of works';

  @override
  String get bugReportScreens => 'Screenshots';

  @override
  String get bugReportAddScreen => 'Add';

  @override
  String get bugReportScreensHint =>
      'A snapshot of the screen you reported from is attached. Remove it if it shows something private';

  @override
  String get bugReportSend => 'Compose email';

  @override
  String bugReportFailed(String email) {
    return 'Couldn\'t open email. The address $email was copied';
  }

  @override
  String get dashboardGreeting => 'Welcome!';

  @override
  String get dashboardStudent => 'Student';

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
  String get scheduleFilters => 'Filters';

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

  @override
  String get updateEyebrow => 'New version';

  @override
  String updateCurrent(String version) {
    return 'you have $version';
  }

  @override
  String get updateBody =>
      'Installs over the current one — nothing to uninstall.';

  @override
  String updateSize(String size) {
    return '$size MB';
  }

  @override
  String get updateSizeCaption => 'download';

  @override
  String get updateKeeps => 'Nothing lost';

  @override
  String get updateKeepsCaption => 'login & settings';

  @override
  String get updateInstall => 'Update';

  @override
  String get updateLater => 'Later';

  @override
  String get updateDownloading => 'Downloading';

  @override
  String get updateOpening => 'Opening installer';

  @override
  String get updateFailed =>
      'Download failed. Check your connection and try again.';

  @override
  String get settingsBackground => 'Background work';

  @override
  String get settingsBackgroundAllowed =>
      'Allowed — notifications arrive even when the app is closed';

  @override
  String get settingsBackgroundRestricted =>
      'Restricted by the system — notifications may not arrive';

  @override
  String get settingsBackgroundAllow => 'Allow';

  @override
  String settingsBackgroundLastRun(String time, String result) {
    return 'Last check: $time — $result';
  }

  @override
  String get settingsBackgroundNever => 'The background check has not run yet';

  @override
  String get bgResultOk => 'ok';

  @override
  String get bgResultUiActive => 'skipped, the app was open';

  @override
  String get bgResultNoCreds => 'not signed in';

  @override
  String get bgResultAuthFailed => 'password rejected';

  @override
  String get bgResultNetwork => 'no connection';

  @override
  String get bgResultError => 'error';

  @override
  String get batteryHintTitle => 'Notifications while the app is closed';

  @override
  String get batteryHintBody =>
      'To hear about new tasks, grades and report reviews without opening the app, let OmTech run in the background. Otherwise the system may never run the check.';

  @override
  String get batteryHintLater => 'Not now';
}
