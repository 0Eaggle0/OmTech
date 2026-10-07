import 'dart:convert';
import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'cookie_store_lock.dart';
import 'cp1251.dart';
import 'lk_credentials_storage.dart';

/// Возможные исходы попытки логина.
enum LkLoginResult { ok, invalidCredentials, networkError }

/// Итог проверки сессии. [unknown] — сеть не ответила, судить нельзя:
/// считать сессию невалидной в этом случае значит зря запускать полный логин.
enum SessionCheck { valid, invalid, unknown }

class LkLoginException implements Exception {
  final LkLoginResult result;

  /// Человеческий текст для UI. Технику сюда класть нельзя — она видна
  /// пользователю в баннере и в диалоге входа.
  final String message;

  /// Технические подробности для debug-лога.
  final String? diagnostics;

  /// Запрос упёрся в форму логина: сессия протухла, но креды, скорее всего,
  /// в порядке — такой сбой лечится перелогином.
  final bool sessionExpired;

  LkLoginException(this.result, this.message,
      {this.diagnostics, this.sessionExpired = false});

  @override
  String toString() =>
      'LkLoginException($result): $message'
      '${diagnostics == null ? '' : ' | $diagnostics'}';
}

/// Низкоуровневый клиент личного кабинета ОмГТУ.
/// Особенность: SSO. Форма логина находится на bitrix-странице
/// https://omgtu.ru/ecab/ (POST на /ecab/index.php?login=yes),
/// а данные зачётки — на Yii2-портале https://up.omgtu.ru.
/// Cookie ставятся на домен .omgtu.ru, поэтому одна сессия работает
/// для обоих хостов.
class LkSession {
  static const _ecabHost = 'https://omgtu.ru';
  static const _ecabLoginUrl = '$_ecabHost/ecab/index.php?login=yes';
  static const _ecabHomeUrl = '$_ecabHost/ecab/';
  static const _ecabSsoUrl = '$_ecabHost/ecab/up.php?student=1';
  static const _upBaseUrl = 'https://up.omgtu.ru';
  static const _studentIndexUrl = '$_upBaseUrl/index.php?r=student/index';

  static const _msgBadCredentials = 'Неверный логин или пароль';
  static const _msgNoNetwork = 'Нет связи с сайтом ОмГТУ';
  static const _msgServerDown = 'Сайт не отвечает, попробуйте позже';
  static const _msgSessionExpired = 'Сессия истекла';

  static const _userAgent =
      'Mozilla/5.0 (Linux; Android 12) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';

  final Dio _dio;
  CookieJar _cookieJar;

  /// Папка cookies на диске (`null` — cookies только в памяти, в тестах).
  final String? _cookiesDir;
  final CookieStoreLock? _lock;

  /// Откуда брать логин/пароль для тихого перелогина, когда сессия
  /// протухла посреди работы. `null` — перелогин только по cookies.
  final Future<LkCredentials?> Function()? _credentials;

  /// Сервер отверг сохранённый пароль при тихом перелогине (пароль сменили
  /// на сайте). Контроллер переводит ЛК в состояние «войдите заново».
  void Function()? onCredentialsRejected;

  Future<bool>? _reauthInFlight;

  LkSession({
    Dio? dio,
    CookieJar? cookieJar,
    Future<LkCredentials?> Function()? credentials,
    String? cookiesDir,
  })  : _dio = dio ?? Dio(),
        _cookieJar = cookieJar ?? CookieJar(),
        _credentials = credentials,
        _cookiesDir = cookiesDir,
        _lock = cookiesDir == null ? null : CookieStoreLock(cookiesDir) {
    _dio.options
      ..connectTimeout = const Duration(seconds: 20)
      ..receiveTimeout = const Duration(seconds: 20)
      ..sendTimeout = const Duration(seconds: 20)
      ..followRedirects = true
      ..maxRedirects = 5
      ..responseType = ResponseType.plain
      ..validateStatus = ((s) => s != null && s < 500)
      ..headers.addAll({
        'User-Agent': _userAgent,
        'Accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'ru-RU,ru;q=0.9',
      });
    _dio.interceptors.add(CookieManager(_cookieJar));
  }

  /// Создаёт сессию с персистентной банкой cookies на диске.
  /// Cookies лежат в `<appSupportDir>/lk_cookies/`, что переживает перезапуск
  /// приложения. Доступно как UI-изоляту, так и фоновому worker'у.
  static Future<LkSession> create({
    Dio? dio,
    Future<LkCredentials?> Function()? credentials,
  }) async {
    final dir = await getApplicationSupportDirectory();
    final cookiesPath = p.join(dir.path, 'lk_cookies');
    await Directory(cookiesPath).create(recursive: true);
    return LkSession(
      dio: dio,
      cookieJar: _diskJar(cookiesPath),
      credentials: credentials,
      cookiesDir: cookiesPath,
    );
  }

  static PersistCookieJar _diskJar(String dir) => PersistCookieJar(
        ignoreExpires: false,
        storage: FileStorage('$dir${Platform.pathSeparator}'),
      );

  /// Вход под замком папки cookies (см. [CookieStoreLock]). Под замком jar
  /// сначала перечитывается с диска: другой изолят мог только что войти, а
  /// PersistCookieJar держит прочитанные cookies в памяти и об этом не узнает.
  Future<T> _underCookieLock<T>(Future<T> Function() body) {
    final lock = _lock;
    final dir = _cookiesDir;
    if (lock == null || dir == null) return body();
    return lock.run(() {
      _cookieJar = _diskJar(dir);
      _dio.interceptors
        ..removeWhere((i) => i is CookieManager)
        ..add(CookieManager(_cookieJar));
      return body();
    });
  }

  // ─────────────────────────── Проверка сессии ───────────────────────────

  /// Проверка сессии. Дёргаем зачётку и смотрим, куда нас редиректнули:
  /// если конечный URL ушёл на /ecab/ — мы не залогинены.
  ///
  /// Сетевая ошибка и 5xx дают [SessionCheck.unknown]: сессия может быть
  /// в полном порядке, просто ответа нет.
  Future<SessionCheck> checkSession() async {
    try {
      final res = await _dio.get(_studentIndexUrl);
      if (res.statusCode != 200) return SessionCheck.invalid;
      final finalUrl = res.realUri.toString();
      if (finalUrl.contains('/ecab/')) return SessionCheck.invalid;
      final html = _decodeBody(res);
      if (_looksLikeLoginPage(html)) return SessionCheck.invalid;
      // На странице зачётки точно встречается «Номер книжки».
      final ok = html.contains('Номер книжки') || html.contains('student/index');
      return ok ? SessionCheck.valid : SessionCheck.invalid;
    } catch (_) {
      return SessionCheck.unknown;
    }
  }

  Future<bool> isAuthenticated() async =>
      await checkSession() == SessionCheck.valid;

  // ─────────────────────────────── Логин ─────────────────────────────────

  /// Логин через Bitrix-форму ecab. Бросает [LkLoginException] на ошибки.
  Future<void> login(String username, String password) =>
      _underCookieLock(() => _login(username, password));

  Future<void> _login(String username, String password) async {
    // Шаг 1: GET страницу логина, чтобы получить начальные cookies.
    await _sendWithRetry(() => _dio.get(_ecabHomeUrl));

    // Шаг 2: POST формы.
    final formData = {
      'AUTH_FORM': 'Y',
      'TYPE': 'AUTH',
      'backurl': '/ecab/index.php',
      'USER_LOGIN': username,
      'USER_PASSWORD': password,
      'USER_REMEMBER': 'Y',
      'Login': 'Войти',
    };

    final res = await _sendWithRetry(
      () => _dio.post(
        _ecabLoginUrl,
        data: _encodeForm(formData),
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            'Referer': _ecabHomeUrl,
            'Origin': _ecabHost,
          },
        ),
      ),
    );

    final html = _decodeBody(res);
    final explicitError = _bitrixExplicitError(html);
    if (explicitError != null) {
      throw LkLoginException(LkLoginResult.invalidCredentials, explicitError);
    }

    // Признак успеха №1 — Bitrix выставил сессионную cookie BITRIX_SM_LOGIN
    // (или USER_ID/UIDH). При неудаче этих cookies не будет.
    if (!await _hasBitrixLoginCookie()) {
      throw LkLoginException(
          LkLoginResult.invalidCredentials, _msgBadCredentials);
    }

    // Шаг 3: получить рабочую сессию на up.omgtu.ru.
    if (!await _ensureUpSession()) {
      throw LkLoginException(LkLoginResult.networkError, _msgServerDown,
          diagnostics: 'SSO не установил сессию на up.omgtu.ru');
    }
  }

  Future<bool> _hasBitrixLoginCookie() async {
    final cookies = await _cookieJar.loadForRequest(Uri.parse(_ecabHost));
    for (final c in cookies) {
      final n = c.name.toUpperCase();
      if (n == 'BITRIX_SM_LOGIN' ||
          n == 'BITRIX_SM_UIDH' ||
          n == 'BITRIX_SM_USER_ID') {
        if (c.value.isNotEmpty) return true;
      }
    }
    return false;
  }

  Future<void> logout() async {
    await _cookieJar.deleteAll();
  }

  /// Повтор сетевого шага: 3 попытки с задержками 400/1200 мс.
  /// Ретраятся только сетевые сбои и 5xx. Неверные креды не ретраим никогда —
  /// иначе можно упереться в блокировку аккаунта.
  Future<Response> _sendWithRetry(Future<Response> Function() send) async {
    const delays = [Duration(milliseconds: 400), Duration(milliseconds: 1200)];
    DioException? lastError;
    for (var attempt = 0; attempt <= delays.length; attempt++) {
      if (attempt > 0) await Future<void>.delayed(delays[attempt - 1]);
      try {
        return await send();
      } on DioException catch (e) {
        lastError = e;
        debugPrint('[LK] попытка ${attempt + 1}/${delays.length + 1}'
            ' не удалась: ${e.type.name}');
      }
    }
    // response != null означает 5xx: сайт жив, но отвечает ошибкой.
    final serverFault = lastError?.response != null;
    throw LkLoginException(
      LkLoginResult.networkError,
      serverFault ? _msgServerDown : _msgNoNetwork,
      diagnostics: lastError?.message ?? lastError?.type.name,
    );
  }

  // ──────────────────────────────── SSO ──────────────────────────────────

  /// Добивается рабочей сессии на up.omgtu.ru. Единственный источник истины —
  /// [checkSession]: промежуточные коды ответов в цепочке редиректов ничего
  /// не решают, сервер спокойно отдаёт 404 на хопе, уже установив cookie.
  ///
  /// Порядок в каждой попытке: проверка → мостик вручную → мостик силами dio.
  Future<bool> _ensureUpSession({int attempts = 3}) async {
    const delays = [
      Duration(milliseconds: 300),
      Duration(milliseconds: 800),
      Duration(milliseconds: 1800),
    ];
    final trace = <String>[];
    var unknowns = 0;

    for (var attempt = 0; attempt < attempts; attempt++) {
      if (attempt > 0) await Future<void>.delayed(delays[attempt - 1]);

      final before = await checkSession();
      trace.add('check$attempt=${before.name}');
      if (before == SessionCheck.valid) return _finishSso(trace, true);
      // Сеть не отвечает — долбить её ещё двумя раундами бессмысленно.
      if (before == SessionCheck.unknown && ++unknowns >= 2) {
        return _finishSso(trace, false);
      }

      // Протухший PHPSESSID мешает порталу выдать новую сессию.
      await _dropUpSessionCookie();
      await _shareCookiesToSubdomain();

      trace.add('bridge$attempt${await _bridgeSsoFromEcab()}');
      if (await checkSession() == SessionCheck.valid) {
        return _finishSso(trace, true);
      }

      trace.add('auto$attempt${await _bridgeSsoAutoFollow()}');
      if (await checkSession() == SessionCheck.valid) {
        return _finishSso(trace, true);
      }
    }
    return _finishSso(trace, false);
  }

  bool _finishSso(List<String> trace, bool ok) {
    debugPrint('[LK SSO] ${ok ? 'ok' : 'FAILED'} ${trace.join(' ')}');
    return ok;
  }

  /// Копирует cookies, установленные на `omgtu.ru`, в jar для `up.omgtu.ru`,
  /// чтобы один логин Bitrix авторизовал и поддомен Yii2.
  ///
  /// Только авторизационные cookies Bitrix. `PHPSESSID` копировать нельзя:
  /// у Yii2-портала своя сессия, и чужой id с omgtu.ru ломает SSO-цепочку.
  Future<void> _shareCookiesToSubdomain() async {
    final source = Uri.parse(_ecabHost);
    final target = Uri.parse(_upBaseUrl);
    final cookies = await _cookieJar.loadForRequest(source);
    final shared = cookies.where((c) {
      final n = c.name.toUpperCase();
      return n.startsWith('BITRIX_SM_') || n == 'BX_USER_ID';
    }).toList();
    if (shared.isEmpty) return;
    await _cookieJar.saveFromResponse(target, shared);
  }

  /// Помечает PHPSESSID на up.omgtu.ru просроченным, чтобы портал выдал новый.
  Future<void> _dropUpSessionCookie() async {
    final target = Uri.parse(_upBaseUrl);
    final cookies = await _cookieJar.loadForRequest(target);
    final stale =
        cookies.where((c) => c.name.toUpperCase() == 'PHPSESSID').toList();
    if (stale.isEmpty) return;
    for (final c in stale) {
      c.maxAge = 0;
      c.expires = DateTime.fromMillisecondsSinceEpoch(0);
    }
    await _cookieJar.saveFromResponse(target, stale);
  }

  /// SSO-мостик с РУЧНЫМ следованием за редиректами.
  /// В браузере это клик по "Студенческий портал":
  ///   ecab/up.php?student=1 → 302 → up.omgtu.ru/index.php?code=XXX → 302 → ...
  /// → 200 site/index. На последнем шаге up.omgtu.ru ставит свой PHPSESSID.
  ///
  /// Делаю руками, потому что dio при followRedirects между разными
  /// поддоменами может терять cookie/Referer.
  ///
  /// Возвращает строку с диагностикой цепочки — решение об успехе принимает
  /// вызывающий по [checkSession].
  Future<String> _bridgeSsoFromEcab() async {
    final trail = StringBuffer();
    var currentUrl = _ecabSsoUrl;
    var referer = '$_ecabHost/ecab/index.php';

    for (var hop = 0; hop < 8; hop++) {
      Response res;
      try {
        res = await _dio.get(
          currentUrl,
          options: Options(
            followRedirects: false,
            validateStatus: (s) => s != null && s < 500,
            headers: {'Referer': referer},
          ),
        );
      } catch (_) {
        trail.write(' [hop$hop:ERR]');
        return trail.toString();
      }

      final status = res.statusCode ?? 0;
      trail.write(' →$status');
      if (status < 300 || status >= 400) return trail.toString();

      final location = res.headers.value('location');
      if (location == null || location.isEmpty) {
        trail.write('(no-location)');
        return trail.toString();
      }
      referer = currentUrl;
      // Резолвим от фактического URL ответа: dio мог сам сделать редирект.
      currentUrl = res.realUri.resolve(location).toString();
    }
    trail.write('(max-hops)');
    return trail.toString();
  }

  /// Тот же вход в портал, но редиректы обходит сам dio. Спасает, когда
  /// ручная цепочка спотыкается о нестандартный Location.
  Future<String> _bridgeSsoAutoFollow() async {
    try {
      final res = await _dio.get(
        _ecabSsoUrl,
        options: Options(
          followRedirects: true,
          maxRedirects: 8,
          headers: {'Referer': '$_ecabHost/ecab/'},
        ),
      );
      return '→${res.statusCode}';
    } catch (_) {
      return '→ERR';
    }
  }

  // ─────────────────────────── Тихий перелогин ───────────────────────────

  LkLoginException _expired() => LkLoginException(
      LkLoginResult.invalidCredentials, _msgSessionExpired,
      sessionExpired: true);

  /// Восстанавливает сессию без участия пользователя. PHPSESSID портала живёт
  /// минут 15, а «remember me»-cookies Bitrix (`USER_REMEMBER=Y`) — неделями,
  /// поэтому сначала пробуем только SSO-мост по ним, без пароля. Не вышло —
  /// полный логин с сохранёнными кредами.
  ///
  /// Параллельные вызовы ждут один и тот же перелогин. `false` — восстановить
  /// нечем (кредов нет). Бросает [LkLoginException], если сеть недоступна
  /// или сервер отверг пароль.
  Future<bool> reauthenticate() {
    return _reauthInFlight ??= _underCookieLock(_reauth).whenComplete(() {
      // Блоком: стрелка вернула бы сам Future, и whenComplete ждал бы себя.
      _reauthInFlight = null;
    });
  }

  Future<bool> _reauth() async {
    if (await _hasBitrixLoginCookie() &&
        await _ensureUpSession(attempts: 1)) {
      debugPrint('[LK SSO] перелогин по cookies: ok');
      return true;
    }
    final creds = await _credentials?.call();
    if (creds == null) return false;
    try {
      // _login, а не login: замок уже наш, повторный ждал бы сам себя.
      await _login(creds.username, creds.password);
      debugPrint('[LK SSO] перелогин паролем: ok');
      return true;
    } on LkLoginException catch (e) {
      debugPrint(
          '[LK SSO] перелогин не удался: ${e.diagnostics ?? e.result.name}');
      if (e.result == LkLoginResult.invalidCredentials) {
        onCredentialsRejected?.call();
      }
      rethrow;
    }
  }

  /// Выполняет запрос; если он упёрся в протухшую сессию — один раз
  /// перелогинивается и повторяет.
  Future<T> _withReauth<T>(Future<T> Function(bool retry) send) async {
    try {
      return await send(false);
    } on LkLoginException catch (e) {
      if (!e.sessionExpired) rethrow;
      debugPrint('[LK SSO] сессия истекла, тихий перелогин');
      if (!await reauthenticate()) rethrow;
      return send(true);
    }
  }

  // ───────────────────────────── Запросы ─────────────────────────────────

  /// GET страницы под `/index.php?r=...`, возвращает уже декодированный HTML.
  Future<String> fetchHtml(String route) =>
      _withReauth((_) => _fetchHtml(route));

  Future<String> _fetchHtml(String route) async {
    final res = await _dio.get('$_upBaseUrl/index.php?r=$route');
    if (res.statusCode != 200) {
      throw LkLoginException(LkLoginResult.networkError, _msgServerDown,
          diagnostics: 'HTTP ${res.statusCode} для $route');
    }
    final finalUrl = res.realUri.toString();
    if (finalUrl.contains('/ecab/')) {
      throw _expired();
    }
    return _decodeBody(res);
  }

  /// GET страницы под `/ecab/...` на bitrix-портале omgtu.ru.
  /// Эти страницы отдаются в **windows-1251**, поэтому забираем байтами
  /// и декодим через таблицу [decodeCp1251].
  ///
  /// Cookie-jar после login уже содержит сессионную cookie на `.omgtu.ru`,
  /// так что отдельной авторизации не требуется. Если же страница
  /// внезапно вернула форму логина — кидаем «сессия истекла».
  Future<String> fetchEcabHtml(String path) =>
      _withReauth((_) => _fetchEcabHtml(path));

  Future<String> _fetchEcabHtml(String path) async {
    final url = _ecabUrl(path);
    final res = await _dio.get<List<int>>(
      url,
      options: Options(
        responseType: ResponseType.bytes,
        headers: {
          'Referer': '$_ecabHost/ecab/',
          'X-Requested-With': 'XMLHttpRequest',
        },
      ),
    );
    if (res.statusCode != 200) {
      throw LkLoginException(LkLoginResult.networkError, _msgServerDown,
          diagnostics: 'HTTP ${res.statusCode} для $path');
    }
    final bytes = res.data ?? const <int>[];
    final html = decodeCp1251(bytes);
    if (_looksLikeLoginPage(html)) {
      throw _expired();
    }
    return html;
  }

  /// POST формы под `/ecab/...` (для AJAX-эндпоинтов Bitrix-портала).
  /// Используется для подгрузки секций vkr2.php, которые рендерятся
  /// jQuery `.load(url, data)` — а это именно POST с form-encoded телом.
  Future<String> postEcabForm(String path, Map<String, String> form) =>
      _withReauth((_) => _postEcabForm(path, form));

  Future<String> _postEcabForm(String path, Map<String, String> form) async {
    final url = _ecabUrl(path);
    final res = await _dio.post<List<int>>(
      url,
      data: _encodeForm(form),
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        responseType: ResponseType.bytes,
        headers: {
          'Referer': '$_ecabHost/ecab/vkr2.php',
          'X-Requested-With': 'XMLHttpRequest',
        },
      ),
    );
    if (res.statusCode != 200) {
      throw LkLoginException(LkLoginResult.networkError, _msgServerDown,
          diagnostics: 'HTTP ${res.statusCode} для $path');
    }
    final bytes = res.data ?? const <int>[];
    final html = decodeCp1251(bytes);
    if (_looksLikeLoginPage(html)) {
      throw _expired();
    }
    return html;
  }

  /// multipart POST под `/ecab/...` — загрузка файла отчётной работы.
  /// Таймауты шире общих: PDF до 10 МБ по мобильной сети за 20 с не уходит,
  /// а после отправки сервер ещё обрабатывает файл.
  ///
  /// Тело multipart после отправки не переиспользовать, поэтому для повтора
  /// после перелогина заранее держим копию.
  Future<String> postEcabMultipart(
    String path,
    FormData data, {
    ProgressCallback? onSendProgress,
  }) {
    final spare = data.clone();
    return _withReauth((retry) => _postEcabMultipart(
        path, retry ? spare : data,
        onSendProgress: onSendProgress));
  }

  Future<String> _postEcabMultipart(
    String path,
    FormData data, {
    ProgressCallback? onSendProgress,
  }) async {
    final url = _ecabUrl(path);
    final res = await _dio.post<List<int>>(
      url,
      data: data,
      onSendProgress: onSendProgress,
      options: Options(
        responseType: ResponseType.bytes,
        sendTimeout: const Duration(minutes: 3),
        receiveTimeout: const Duration(seconds: 90),
        headers: {
          'Referer': '$_ecabHost/ecab/vkr2.php',
          'X-Requested-With': 'XMLHttpRequest',
        },
      ),
    );
    if (res.statusCode != 200) {
      throw LkLoginException(LkLoginResult.networkError, _msgServerDown,
          diagnostics: 'HTTP ${res.statusCode} для $path');
    }
    final html = decodeCp1251(res.data ?? const <int>[]);
    if (_looksLikeLoginPage(html)) {
      throw _expired();
    }
    return html;
  }

  String _ecabUrl(String path) {
    if (path.startsWith('http')) return path;
    final clean = path.startsWith('/') ? path.substring(1) : path;
    return '$_ecabHost/ecab/$clean';
  }

  /// Скачивает произвольный файл (с up.omgtu.ru или omgtu.ru/ecab) с
  /// использованием активной сессионной cookie. Возвращает байты тела ответа.
  ///
  /// `relativeOrAbsoluteUrl` может быть как полным URL
  /// (`https://up.omgtu.ru/index.php?r=remote/read/downloadFile&id=...`
  /// либо `https://omgtu.ru/ecab/modules/vkr2/getotherfile.php?id=...`),
  /// так и относительным (`/index.php?r=...`).
  ///
  /// Базу для относительных URL выбираем по содержимому
  /// (если внутри есть `/ecab/` — берём omgtu.ru, иначе — up.omgtu.ru).
  /// Referer по умолчанию подставляется под хост файла.
  Future<List<int>> downloadBytes(String relativeOrAbsoluteUrl,
          {String? referer}) =>
      _withReauth(
          (_) => _downloadBytes(relativeOrAbsoluteUrl, referer: referer));

  Future<List<int>> _downloadBytes(String relativeOrAbsoluteUrl,
      {String? referer}) async {
    final isEcab = relativeOrAbsoluteUrl.contains('/ecab/');
    final base = isEcab ? _ecabHost : _upBaseUrl;
    final url = relativeOrAbsoluteUrl.startsWith('http')
        ? relativeOrAbsoluteUrl
        : relativeOrAbsoluteUrl.startsWith('/')
            ? '$base$relativeOrAbsoluteUrl'
            : '$base/$relativeOrAbsoluteUrl';
    final effectiveReferer = referer ??
        (isEcab
            ? '$_ecabHost/ecab/vkr2.php'
            : '$_upBaseUrl/index.php?r=remote/read');

    final res = await _dio.get<List<int>>(
      url,
      options: Options(
        responseType: ResponseType.bytes,
        headers: {
          'Referer': effectiveReferer,
        },
      ),
    );

    // Проверка истёкшей сессии:
    //  - для up.omgtu.ru-файла: редирект на /ecab/ означает разлогин;
    //  - для /ecab/-файла: тело начинается с HTML-формы логина
    //    (Content-Type обычно text/html, проверяем сигнатуру AUTH_FORM/USER_LOGIN).
    final finalUrl = res.realUri.toString();
    if (!isEcab && finalUrl.contains('/ecab/')) {
      throw _expired();
    }
    final ct = (res.headers.value('content-type') ?? '').toLowerCase();
    if (isEcab && ct.contains('text/html')) {
      final data = res.data;
      if (data != null && data.isNotEmpty) {
        final preview = decodeCp1251(
          data.length > 4096 ? data.sublist(0, 4096) : data,
        );
        if (_looksLikeLoginPage(preview)) {
          throw _expired();
        }
      }
    }
    if (res.statusCode != 200) {
      throw LkLoginException(LkLoginResult.networkError, _msgServerDown,
          diagnostics: 'HTTP ${res.statusCode} для файла');
    }
    final data = res.data;
    if (data == null || data.isEmpty) {
      throw LkLoginException(LkLoginResult.networkError, _msgServerDown,
          diagnostics: 'Пустой ответ для файла');
    }
    return data;
  }

  bool _looksLikeLoginPage(String html) {
    return html.contains('USER_LOGIN') &&
        html.contains('USER_PASSWORD') &&
        html.contains('AUTH_FORM');
  }

  /// Возвращает явное сообщение об ошибке от Bitrix, если оно есть в HTML.
  /// Сам факт наличия формы логина признаком ошибки не считается, потому что
  /// форма часто рендерится и на залогиненных страницах (sidebar/footer).
  String? _bitrixExplicitError(String html) {
    final patterns = [
      RegExp(r'<font[^>]*class="errortext"[^>]*>([^<]+)</font>',
          caseSensitive: false),
      RegExp(r'class="note-error[^"]*"[^>]*>([^<]+)<', caseSensitive: false),
      RegExp(r'class="errortext"[^>]*>([^<]+)<', caseSensitive: false),
      RegExp(r'(Неправильный\s+логин\s+или\s+пароль)', caseSensitive: false),
      RegExp(r'(Incorrect\s+(?:username|login)\s+or\s+password)',
          caseSensitive: false),
    ];
    for (final re in patterns) {
      final m = re.firstMatch(html);
      if (m != null) {
        final raw = m.group(1)?.trim();
        if (raw != null && raw.isNotEmpty) return raw;
      }
    }
    return null;
  }

  String _encodeForm(Map<String, String> data) {
    return data.entries
        .map((e) =>
            '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
  }

  String _decodeBody(Response res) {
    final data = res.data;
    if (data is String) return data;
    if (data is List<int>) {
      try {
        return utf8.decode(data, allowMalformed: true);
      } catch (_) {
        return String.fromCharCodes(data);
      }
    }
    return data?.toString() ?? '';
  }
}
