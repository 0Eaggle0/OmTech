import 'package:flutter/foundation.dart';

import '../models/student_record.dart';
import '../services/lk/lk_credentials_storage.dart';
import '../services/lk/lk_grades_api.dart';
import '../services/lk/lk_session.dart';

enum LkStatus { disconnected, connecting, connected, error }

/// Центральный контроллер состояния ЛК.
/// - Хранит сессию (cookie-jar) в [LkSession].
/// - Знает текущий профиль студента (доступен сразу после успешного логина).
/// - Управляет авто-логином из secure storage.
class LkController extends ChangeNotifier {
  final LkSession _session;
  final LkCredentialsStorage _credentials;
  late final LkGradesApi gradesApi = LkGradesApi(_session);

  LkStatus _status = LkStatus.disconnected;
  StudentProfile? _profile;
  String? _errorMessage;

  LkController({
    LkSession? session,
    LkCredentialsStorage? credentials,
  })  : _session = session ?? LkSession(),
        _credentials = credentials ?? LkCredentialsStorage();

  LkStatus get status => _status;
  StudentProfile? get profile => _profile;
  String? get errorMessage => _errorMessage;
  bool get isConnected => _status == LkStatus.connected;

  /// Пытается восстановить сессию: читает креды из secure storage и логинится.
  /// Запускается из main.dart при старте приложения.
  Future<void> tryAutoLogin() async {
    final creds = await _credentials.read();
    if (creds == null) return;
    await _doLogin(creds.username, creds.password, persist: false);
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

  Future<void> logout() async {
    await _session.logout();
    await _credentials.clear();
    await gradesApi.clearCache();
    _status = LkStatus.disconnected;
    _profile = null;
    _errorMessage = null;
    notifyListeners();
  }
}
