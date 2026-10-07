import 'dart:convert';
import 'dart:typed_data';

import 'package:campus2_0/services/lk/lk_credentials_storage.dart';
import 'package:campus2_0/services/lk/lk_session.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Подставной omgtu.ru: Bitrix-вход на `omgtu.ru/ecab/`, SSO-мост
/// `ecab/up.php` и портал `up.omgtu.ru`, которому сессию выдаёт мост.
class _FakeOmgtu implements HttpClientAdapter {
  String password = 'secret';
  bool online = true;

  /// Сессия портала жива (PHPSESSID не протух).
  bool upValid = false;

  /// «Remember me»-cookie Bitrix ещё принимается сервером.
  bool bitrixValid = false;

  int passwordLogins = 0;
  int bridges = 0;

  static const _loginPage =
      '<form><input name="AUTH_FORM"><input name="USER_LOGIN">'
      '<input name="USER_PASSWORD"></form>';

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (!online) {
      throw DioException.connectionError(
          requestOptions: options, reason: 'offline');
    }
    final uri = options.uri;
    final cookies = (options.headers['cookie'] ?? '').toString();

    if (uri.host == 'up.omgtu.ru') {
      if (!upValid) {
        return _html(_loginPage,
            redirects: [RedirectRecord(302, 'GET', Uri.parse('https://omgtu.ru/ecab/'))]);
      }
      final route = uri.queryParameters['r'];
      return _html(route == 'student/index'
          ? 'Номер книжки 123 student/index'
          : 'page:$route');
    }

    if (uri.path == '/ecab/index.php' && options.method == 'POST') {
      final body = utf8.decode(
          await requestStream!.expand((chunk) => chunk).toList());
      final form = Uri.splitQueryString(body);
      if (form['USER_PASSWORD'] != password) {
        return _html('<font class="errortext">Неверный логин или пароль</font>');
      }
      passwordLogins++;
      bitrixValid = true;
      return _html('ok', headers: {
        'set-cookie': ['BITRIX_SM_LOGIN=student; Path=/'],
      });
    }

    if (uri.path == '/ecab/up.php') {
      bridges++;
      if (cookies.contains('BITRIX_SM_LOGIN') && bitrixValid) upValid = true;
      return _html('bridged');
    }

    return _html(_loginPage); // omgtu.ru/ecab/ и прочее
  }

  ResponseBody _html(
    String body, {
    Map<String, List<String>> headers = const {},
    List<RedirectRecord> redirects = const [],
  }) =>
      ResponseBody.fromString(body, 200, headers: {
        Headers.contentTypeHeader: ['text/html; charset=utf-8'],
        ...headers,
      })
        ..redirects = redirects;

  @override
  void close({bool force = false}) {}
}

void main() {
  late _FakeOmgtu server;
  late LkSession session;
  var rejected = 0;

  LkSession makeSession({bool withCredentials = true}) {
    final s = LkSession(
      dio: Dio()..httpClientAdapter = server,
      credentials: withCredentials
          ? () async => const LkCredentials(username: 'u', password: 'secret')
          : null,
    );
    s.onCredentialsRejected = () => rejected++;
    return s;
  }

  setUp(() {
    server = _FakeOmgtu();
    rejected = 0;
    session = makeSession();
  });

  test('ручной вход поднимает сессию портала', () async {
    await session.login('u', 'secret');
    expect(await session.checkSession(), SessionCheck.valid);
    expect(server.passwordLogins, 1);
  });

  test('протухший PHPSESSID восстанавливается по cookies, без пароля', () async {
    await session.login('u', 'secret');
    server.upValid = false; // прошло 15 минут

    expect(await session.fetchHtml('student/record'), 'page:student/record');
    expect(server.passwordLogins, 1, reason: 'пароль второй раз не нужен');
  });

  test('протухли и cookies Bitrix — тихий вход по сохранённому паролю',
      () async {
    await session.login('u', 'secret');
    server
      ..upValid = false
      ..bitrixValid = false;

    expect(await session.fetchHtml('student/record'), 'page:student/record');
    expect(server.passwordLogins, 2);
    expect(rejected, 0);
  });

  test('сменённый на сайте пароль: ошибка и сигнал контроллеру', () async {
    await session.login('u', 'secret');
    server
      ..upValid = false
      ..bitrixValid = false
      ..password = 'changed';

    await expectLater(
      session.fetchHtml('student/record'),
      throwsA(isA<LkLoginException>().having(
          (e) => e.result, 'result', LkLoginResult.invalidCredentials)),
    );
    expect(rejected, 1);
  });

  test('без сети сессия не считается разлогиненной', () async {
    server.online = false;
    expect(await session.checkSession(), SessionCheck.unknown);
  });

  test('параллельные запросы ждут один перелогин', () async {
    await session.login('u', 'secret');
    server
      ..upValid = false
      ..bitrixValid = false;

    final pages = await Future.wait([
      session.fetchHtml('a'),
      session.fetchHtml('b'),
      session.fetchHtml('c'),
    ]);
    expect(pages, ['page:a', 'page:b', 'page:c']);
    expect(server.passwordLogins, 2, reason: 'один вход на три запроса');
  });

  test('без кредов и без живых cookies — сессия истекла, а не зацикливание',
      () async {
    session = makeSession(withCredentials: false);
    await expectLater(
      session.fetchHtml('student/record'),
      throwsA(isA<LkLoginException>()
          .having((e) => e.sessionExpired, 'sessionExpired', isTrue)),
    );
  });
}
