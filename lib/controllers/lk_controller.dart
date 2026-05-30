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
import 'group_controller.dart';

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

  LkController({
    LkSession? session,
    LkCredentialsStorage? credentials,
  })  : _session = session ?? LkSession(),
        _credentials = credentials ?? LkCredentialsStorage();

  /// Создаёт контроллер с персистентной сессией (cookies на диске) и
  /// сразу подтягивает кэшированный профиль, чтобы UI заполнялся без сети.
  static Future<LkController> create({
    LkCredentialsStorage? credentials,
  }) async {
    final session = await LkSession.create();
    final ctrl = LkController(session: session, credentials: credentials);
    try {
      final cached = await ctrl.gradesApi.readCache();
      if (cached != null) {
        ctrl._profile = cached.profile;
      }
    } catch (_) {}
    return ctrl;
  }

  LkStatus get status => _status;
  StudentProfile? get profile => _profile;
  String? get errorMessage => _errorMessage;
  bool get isConnected => _status == LkStatus.connected;
  LkSession get session => _session;

  /// Пытается восстановить сессию: читает креды из secure storage и логинится.
  /// Запускается из main.dart при старте приложения.
  ///
  /// Быстрый путь: если cookies на диске ещё валидны, переходим в `connected`
  /// после одного HTTP-запроса (~300мс) вместо полного цикла логина (~3 сек).
  Future<void> tryAutoLogin() async {
    final creds = await _credentials.read();
    if (creds == null) return;

    _status = LkStatus.connecting;
    _errorMessage = null;
    notifyListeners();

    try {
      if (await _session.isAuthenticated()) {
        _status = LkStatus.connected;
        notifyListeners();
        // Подтягиваем профиль в фоне, чтобы обновить кэш.
        unawaited(_refreshProfileSilently());
        return;
      }
    } catch (_) {
      // Сеть упала — попробуем полный логин ниже.
    }

    await _doLogin(creds.username, creds.password, persist: false);
  }

  Future<void> _refreshProfileSilently() async {
    try {
      final record = await gradesApi.fetchFresh();
      _profile = record.profile;
      notifyListeners();
    } catch (_) {}
  }

  /// Вызывается из UI диалога логина.
  Future<bool> login(String username, String password) async {
    return _doLogin(username, password, persist: true);
  }

  Future<bool> _doLogin(String username, String password,
      {required bool persist}) async {
    _status = LkStatus.connecting;
    _errorMessage = null;
    notifyListeners();

    try {
      await _session.login(username, password);
      if (persist) {
        await _credentials.save(
          LkCredentials(username: username, password: password),
        );
      }
      // Подтягиваем профиль из зачётки.
      try {
        final record = await gradesApi.fetchFresh();
        _profile = record.profile;
      } catch (_) {
        // Профиль подгрузим позже, главное — сессия активна.
      }
      _status = LkStatus.connected;
      notifyListeners();
      return true;
    } on LkLoginException catch (e) {
      _status = LkStatus.error;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _status = LkStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Если профиль ЛК содержит группу и пользователь ещё не выбрал группу,
  /// ищет группу в API расписания и автоматически выбирает её.
  Future<void> autoFillGroupIfNeeded(GroupController groupController) async {
    if (!isConnected) return;
    if (groupController.hasGroup) return;
    final label = _profile?.groupLabel ?? '';
    if (label.isEmpty) return;
    try {
      final api = ScheduleApi();
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
    _status = LkStatus.disconnected;
    _profile = null;
    _errorMessage = null;
    notifyListeners();
  }
}
