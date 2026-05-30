import 'dart:convert';
import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'cp1251.dart';

/// Возможные исходы попытки логина.
enum LkLoginResult { ok, invalidCredentials, networkError }

class LkLoginException implements Exception {
  final LkLoginResult result;
  final String message;
  LkLoginException(this.result, this.message);
  @override
  String toString() => 'LkLoginException($result): $message';
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
  static const _upBaseUrl = 'https://up.omgtu.ru';
  static const _studentIndexUrl = '$_upBaseUrl/index.php?r=student/index';

  static const _userAgent =
      'Mozilla/5.0 (Linux; Android 12) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';

  final Dio _dio;
  final CookieJar _cookieJar;

  LkSession({Dio? dio, CookieJar? cookieJar})
      : _dio = dio ?? Dio(),
        _cookieJar = cookieJar ?? CookieJar() {
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
  static Future<LkSession> create({Dio? dio}) async {
    final dir = await getApplicationSupportDirectory();
    final cookiesPath = p.join(dir.path, 'lk_cookies');
    await Directory(cookiesPath).create(recursive: true);
    final jar = PersistCookieJar(
      ignoreExpires: false,
      storage: FileStorage('$cookiesPath${Platform.pathSeparator}'),
    );
    return LkSession(dio: dio, cookieJar: jar);
  }

  /// Проверка сессии. Дёргаем зачётку и смотрим, куда нас редиректнули:
  /// если конечный URL ушёл на /ecab/ — мы не залогинены.
  Future<bool> isAuthenticated() async {
    try {
      final res = await _dio.get(_studentIndexUrl);
      if (res.statusCode != 200) return false;
      final finalUrl = res.realUri.toString();
      if (finalUrl.contains('/ecab/')) return false;
      final html = _decodeBody(res);
      // На странице зачётки точно встречается «Номер книжки».
      // Если её нет — значит редирект не сработал, но данных тоже нет.
      return html.contains('Номер книжки') ||
          html.contains('student/index') &&
              !_looksLikeLoginPage(html);
    } catch (_) {
      return false;
    }
  }

  /// Логин через Bitrix-форму ecab. Бросает [LkLoginException] на ошибки.
  Future<void> login(String username, String password) async {
    // Шаг 1: GET страницу логина, чтобы получить начальные cookies.
    try {
      await _dio.get(_ecabHomeUrl);
    } on DioException catch (e) {
      throw LkLoginException(
          LkLoginResult.networkError, e.message ?? 'Сеть недоступна');
    }

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

    try {
      final res = await _dio.post(
        _ecabLoginUrl,
        data: _encodeForm(formData),
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            'Referer': _ecabHomeUrl,
            'Origin': _ecabHost,
          },
        ),
      );

      final html = _decodeBody(res);
      final explicitError = _bitrixExplicitError(html);
      if (explicitError != null) {
        throw LkLoginException(
            LkLoginResult.invalidCredentials, explicitError);
      }

      // Признак успеха №1 — Bitrix выставил сессионную cookie BITRIX_SM_LOGIN
      // (или USER_ID/UIDH). При неудаче этих cookies не будет.
      final hasLoginCookie = await _hasBitrixLoginCookie();
      if (!hasLoginCookie) {
        throw LkLoginException(
            LkLoginResult.invalidCredentials, 'Неверный логин или пароль');
      }

      // Клонируем cookies omgtu.ru на up.omgtu.ru на случай, если Bitrix
      // выставил их без атрибута Domain.
      await _shareCookiesToSubdomain();

      // Повторяем то, что делает пользователь в браузере: клик по
      // "Студенческий портал" — серверная цепь редиректов установит
      // PHPSESSID на up.omgtu.ru.
      final trail = await _bridgeSsoFromEcab();

      // Диагностика: список cookies, которые в итоге уехали на up.omgtu.ru.
      final upCookies = await _cookieJar.loadForRequest(Uri.parse(_upBaseUrl));
      final hasPhpSessId = upCookies.any((c) => c.name == 'PHPSESSID');

      // Финальная проверка — действительно ли зачётка нам доступна.
      final ok = await isAuthenticated();
      if (!ok) {
        final diag = StringBuffer('SSO failed.');
        diag.write(' trail:$trail');
        diag.write(' up-cookies:${upCookies.length}');
        diag.write(' phpsessid:$hasPhpSessId');
        throw LkLoginException(LkLoginResult.networkError, diag.toString());
      }
    } on LkLoginException {
      rethrow;
    } on DioException catch (e) {
      throw LkLoginException(
          LkLoginResult.networkError, e.message ?? 'Сеть недоступна');
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
    final jar = _cookieJar;
    if (jar is PersistCookieJar) {
      await jar.deleteAll();
    } else {
      jar.deleteAll();
    }
  }

  /// Копирует cookies, установленные на `omgtu.ru`, в jar для `up.omgtu.ru`,
  /// чтобы один логин Bitrix авторизовал и поддомен Yii2.
  Future<void> _shareCookiesToSubdomain() async {
    final source = Uri.parse(_ecabHost);
    final target = Uri.parse(_upBaseUrl);
    final cookies = await _cookieJar.loadForRequest(source);
    if (cookies.isEmpty) return;
    await _cookieJar.saveFromResponse(target, cookies);
  }

  /// SSO-мостик с РУЧНЫМ следованием за редиректами.
  /// В браузере это клик по "Студенческий портал":
  ///   ecab/up.php?student=1 → 302 → up.omgtu.ru/index.php?code=XXX → 302 → ...
  /// → 200 site/index. На последнем шаге up.omgtu.ru ставит свой PHPSESSID.
  ///
  /// Делаю руками, потому что dio при followRedirects между разными
  /// поддоменами может терять cookie/Referer.
  ///
  /// Возвращает строку с диагностикой — пустую при успехе.
  Future<String> _bridgeSsoFromEcab() async {
    final trail = StringBuffer();
    String currentUrl = '$_ecabHost/ecab/up.php?student=1';
    String referer = '$_ecabHost/ecab/index.php';

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
      } catch (e) {
        trail.write(' [hop$hop:ERR=$e]');
        return trail.toString();
      }

      final status = res.statusCode ?? 0;
      trail.write(' →$status');

      if (status == 200) return ''; // успех
      if (status < 300 || status >= 400) {
        trail.write(' (no-redirect, stopped)');
        return trail.toString();
      }
      final location = res.headers.value('location');
      if (location == null || location.isEmpty) {
        trail.write(' (no-location)');
        return trail.toString();
      }
      referer = currentUrl;
      currentUrl = Uri.parse(currentUrl).resolve(location).toString();
    }
    trail.write(' (too-many-redirects)');
    return trail.toString();
  }

  /// GET страницы под `/index.php?r=...`, возвращает уже декодированный HTML.
  Future<String> fetchHtml(String route) async {
    final res = await _dio.get('$_upBaseUrl/index.php?r=$route');
    if (res.statusCode != 200) {
      throw LkLoginException(
          LkLoginResult.networkError, 'HTTP ${res.statusCode} для $route');
    }
    final finalUrl = res.realUri.toString();
    if (finalUrl.contains('/ecab/')) {
      throw LkLoginException(
          LkLoginResult.invalidCredentials, 'Сессия истекла');
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
  Future<String> fetchEcabHtml(String path) async {
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
      throw LkLoginException(
          LkLoginResult.networkError, 'HTTP ${res.statusCode} для $path');
    }
    final bytes = res.data ?? const <int>[];
    final html = decodeCp1251(bytes);
    if (_looksLikeLoginPage(html)) {
      throw LkLoginException(
          LkLoginResult.invalidCredentials, 'Сессия истекла');
    }
    return html;
  }

  /// POST формы под `/ecab/...` (для AJAX-эндпоинтов Bitrix-портала).
  /// Используется для подгрузки секций vkr2.php, которые рендерятся
  /// jQuery `.load(url, data)` — а это именно POST с form-encoded телом.
  Future<String> postEcabForm(
      String path, Map<String, String> form) async {
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
      throw LkLoginException(
          LkLoginResult.networkError, 'HTTP ${res.statusCode} для $path');
    }
    final bytes = res.data ?? const <int>[];
    final html = decodeCp1251(bytes);
    if (_looksLikeLoginPage(html)) {
      throw LkLoginException(
          LkLoginResult.invalidCredentials, 'Сессия истекла');
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
      throw LkLoginException(
          LkLoginResult.invalidCredentials, 'Сессия истекла');
    }
    final ct = (res.headers.value('content-type') ?? '').toLowerCase();
    if (isEcab && ct.contains('text/html')) {
      final data = res.data;
      if (data != null && data.isNotEmpty) {
        final preview = decodeCp1251(
          data.length > 4096 ? data.sublist(0, 4096) : data,
        );
        if (_looksLikeLoginPage(preview)) {
          throw LkLoginException(
              LkLoginResult.invalidCredentials, 'Сессия истекла');
        }
      }
    }
    if (res.statusCode != 200) {
      throw LkLoginException(
          LkLoginResult.networkError, 'HTTP ${res.statusCode} для файла');
    }
    final data = res.data;
    if (data == null || data.isEmpty) {
      throw LkLoginException(
          LkLoginResult.networkError, 'Пустой ответ для файла');
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
