export 'local_storage_stub.dart';
import 'local_storage_stub.dart';

class IoLocalStorage implements LocalStorage {
  final Map<String, String> _memory = {};

  @override
  String? getItem(String key) => _memory[key];

  @override
  void setItem(String key, String value) {
    _memory[key] = value;
  }

  @override
  void removeItem(String key) {
    _memory.remove(key);
  }
}

void _init() {
  LocalStorage.instance = IoLocalStorage();
}

final _ = _init();


