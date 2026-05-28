import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Безопасное хранилище логина/пароля от ЛК up.omgtu.ru.
/// Использует Keychain (iOS/macOS), EncryptedSharedPreferences (Android),
/// DPAPI (Windows), libsecret (Linux). Пароль никогда не пишется в обычные
/// SharedPreferences и не должен попадать в логи.
class LkCredentials {
  final String username;
  final String password;

  const LkCredentials({required this.username, required this.password});
}

class LkCredentialsStorage {
  static const _usernameKey = 'lk_username';
  static const _passwordKey = 'lk_password';

  final FlutterSecureStorage _storage;

  LkCredentialsStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  Future<LkCredentials?> read() async {
    final username = await _storage.read(key: _usernameKey);
    final password = await _storage.read(key: _passwordKey);
    if (username == null || password == null || username.isEmpty) return null;
    return LkCredentials(username: username, password: password);
  }

  Future<void> save(LkCredentials creds) async {
    await _storage.write(key: _usernameKey, value: creds.username);
    await _storage.write(key: _passwordKey, value: creds.password);
  }

  Future<void> clear() async {
    await _storage.delete(key: _usernameKey);
    await _storage.delete(key: _passwordKey);
  }
}
