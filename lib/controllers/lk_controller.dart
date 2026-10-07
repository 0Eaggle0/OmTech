import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/group.dart';
import '../models/student_record.dart';
import '../services/lk/lk_contact_work_api.dart';
import '../services/lk/lk_credentials_storage.dart';
import '../services/lk/lk_grades_api.dart';
import '../services/lk/lk_report_work_api.dart';
import '../services/lk/lk_session.dart';
import '../services/schedule_api.dart';
import '../services/teacher_contacts_service.dart';
import 'group_controller.dart';
import '../services/app_prefs.dart';

enum LkStatus { disconnected, connecting, connected, error }

/// Центральный контроллер состояния ЛК.
/// - Хранит сессию (cookie-jar) в [LkSession].
/// - Знает текущий профиль студента (доступен сразу после успешного логина).
/// - Управляет авто-логином из secure storage.
class LkController extends ChangeNotifier {
  final LkSession _session;
  final LkCredentialsStorage _credentials;
  late final LkGradesApi gradesApi = LkGradesApi(_session);
  late final LkContactWorkApi contactWorkApi = LkContactWorkApi(_session);
  late final LkReportWorkApi reportWorkApi = LkReportWorkApi(_session);

  LkStatus _status = LkStatus.disconnected;
  StudentProfile? _profile;
  String? _errorMessage;
  bool _interactiveLogin = false;
  DateTime? _lastSessionCheck;

  /// Чаще этого сессию при возврате в приложение не проверяем.
  static const _resumeCheckInterval = Duration(minutes: 10);

  LkController({
    LkSession? session,
    LkCredentialsStorage? credentials,
  })  : _session = session ?? LkSession(),
        _credentials = credentials ?? LkCredentialsStorage() {
    _session.onCredentialsRejected = _onCredentialsRejected;
  }

  /// Создаёт контроллер с персистентной сессией (cookies на диске) и
  /// сразу подтягивает кэшированный профиль, чтобы UI заполнялся без сети.
  ///
  /// Если креды сохранены, ЛК сразу считается подключённым: экраны работают
  /// на кэше, а протухшую сессию [LkSession] сама восстановит при первом
  /// запросе. «Подключение…» при каждом запуске больше не показываем.
  static Future<LkController> create({
    LkCredentialsStorage? credentials,
  }) async {
    final storage = credentials ?? LkCredentialsStorage();
    final session = await LkSession.create(credentials: storage.read);
    final ctrl = LkController(session: session, credentials: storage);
    try {
      final cached = await ctrl.gradesApi.readCache();
      if (cached != null) {
        ctrl._profile = cached.profile;
      }
    } catch (_) {}
    try {
      if (await storage.read() != null) ctrl._status = LkStatus.connected;
    } catch (_) {}
    return ctrl;
  }

  LkStatus get status => _status;
  StudentProfile? get profile => _profile;
  String? get errorMessage => _errorMessage;
  bool get isConnected => _status == LkStatus.connected;
  LkSession get session => _session;

  /// Текущий/последний вход начат пользователем (форма входа), а не
  /// автологином. Плашка подключения показывается только для таких.
  bool get interactiveLogin => _interactiveLogin;

  /// Тихо восстанавливает сессию при старте приложения. Статус не трогает:
  /// при сохранённых кредах он уже `connected` (см. [create]). Сеть
  /// недоступна — ничего страшного, работаем на кэше. Выход в «войдите
  /// заново» — только если сервер отверг пароль.
  Future<void> tryAutoLogin() async {
    final creds = await _credentials.read();
    if (creds == null) return;
    if (_status != LkStatus.connected) {
      _status = LkStatus.connected;
      notifyListeners();
    }
    await _validateSilently();
  }

  /// Вызывается при возврате приложения на экран: прогреваем сессию заранее,
  /// чтобы первый тап по оценкам не ждал SSO-мост.
  Future<void> refreshIfStale() async {
    if (!isConnected) return;
    final last = _lastSessionCheck;
    if (last != null &&
        DateTime.now().difference(last) < _resumeCheckInterval) {
      return;
    }
    await _validateSilently();
  }

  Future<void> _validateSilently() async {
    _lastSessionCheck = DateTime.now();
    final check = await _session.checkSession();
    if (check == SessionCheck.unknown) return; // офлайн — живём на кэше
    if (check == SessionCheck.invalid) {
      try {
        if (!await _session.reauthenticate()) return;
      } catch (_) {
        // Отвергнутый пароль обработает _onCredentialsRejected, сетевой
        // сбой — не повод выкидывать пользователя из ЛК.
        return;
      }
    }
    if (_profile == null) unawaited(_refreshProfileSilently());
  }

  /// Пароль сменили на сайте — дальше без пользователя не войти.
  void _onCredentialsRejected() {
    _interactiveLogin = false;
    _status = LkStatus.error;
    _errorMessage = 'Пароль от ЛК не подходит — войдите заново';
    notifyListeners();
  }

  Future<void> _refreshProfileSilently() async {
    try {
      final record = await gradesApi.fetchFresh();
      _profile = record.profile;
      notifyListeners();
    } catch (_) {}
  }

  /// Вход из формы: креды сохраняются только после успешного логина.
  Future<bool> login(String username, String password) async {
    _interactiveLogin = true;
    _status = LkStatus.connecting;
    _errorMessage = null;
    notifyListeners();

    try {
      await _session.login(username, password);
      await _credentials.save(
        LkCredentials(username: username, password: password),
      );
      _lastSessionCheck = DateTime.now();
      // Сессия активна — сразу переходим в connected, не дожидаясь профиля.
      // Профиль подтянем в фоне (UI умеет рендериться с _profile == null).
      _status = LkStatus.connected;
      notifyListeners();
      unawaited(_refreshProfileSilently());
      return true;
    } on LkLoginException catch (e) {
      debugPrint('[LK] логин не удался: ${e.diagnostics ?? e.result.name}');
      _fail(e.message);
      return false;
    } catch (e) {
      debugPrint('[LK] логин не удался: $e');
      _fail('Не удалось войти, попробуйте позже');
      return false;
    }
  }

  void _fail(String message) {
    _status = LkStatus.error;
    _errorMessage = message;
    notifyListeners();
  }

  /// Если профиль ЛК содержит группу и пользователь ещё не выбрал группу,
  /// ищет группу в API расписания и автоматически выбирает её.
  Future<void> autoFillGroupIfNeeded(GroupController groupController) async {
    if (!isConnected) return;
    if (groupController.hasGroup) return;
    final label = _profile?.groupLabel ?? '';
    if (label.isEmpty) return;
    try {
      final api = ScheduleApi.instance;
      final results = await api.searchGroups(label);
      final match = results.where((g) => g.label == label).firstOrNull;
      if (match != null) {
        await groupController.select(Group(
          id: match.id,
          label: match.label,
          description: match.description,
        ));
      }
    } catch (_) {
      // Не критично — пользователь выберет группу вручную.
    }
  }

  Future<void> logout() async {
    await _session.logout();
    await _credentials.clear();
    await gradesApi.clearCache();
    await contactWorkApi.clearCache();
    await reportWorkApi.clearCache();
    await TeacherContactsService.clearCache();
    // Дампы страниц ЛК содержат ФИО, группу и статусы работ — после выхода
    // им на диске делать нечего.
    await LkReportWorkApi.clearDumps();
    await _clearLocalProfileTraces();
    _status = LkStatus.disconnected;
    _profile = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Данные, приехавшие из ЛК и осевшие в обычных prefs. Аватар не трогаем:
  /// его пользователь выбрал сам, из ЛК он не приходит.
  Future<void> _clearLocalProfileTraces() async {
    final prefs = appPrefs;
    for (final key in const [
      'user_first_name',
      'notif_report_snapshot',
      'notif_grades_snapshot',
      'notif_tasks_snapshot',
    ]) {
      await prefs.remove(key);
    }
  }
}
