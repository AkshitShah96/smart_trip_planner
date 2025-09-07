export 'local_storage_stub.dart';
abstract class LocalStorage {
  static LocalStorage instance = _NoopLocalStorage();

  String? getItem(String key);
  void setItem(String key, String value);
  void removeItem(String key);
}

class _NoopLocalStorage implements LocalStorage {
  final Map<String, String> _memory = {};

  @override
  String? getItem(String key) => _memory[key];

  @override
  void removeItem(String key) {
    _memory.remove(key);
  }

  @override
  void setItem(String key, String value) {
    _memory[key] = value;
  }
}


