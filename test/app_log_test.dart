import 'package:campus2_0/services/app_log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppLog.sanitize вырезает пароли, cookies и sessid', () {
    final s = AppLog.sanitize(
      'POST USER_LOGIN=student&USER_PASSWORD=qwerty123&sessid=abc42\n'
      'Cookie: PHPSESSID=deadbeef; BITRIX_SM_LOGIN=x\n'
      'set BITRIX_SM_UIDH=topsecret;',
    );
    expect(s, contains('USER_PASSWORD=***'));
    for (final secret in ['qwerty123', 'student', 'abc42', 'deadbeef', 'topsecret']) {
      expect(s, isNot(contains(secret)));
    }
  });
}
