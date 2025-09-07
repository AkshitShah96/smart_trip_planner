export 'local_storage_stub.dart';
import 'dart:html' as html;
import 'local_storage_stub.dart';

class WebLocalStorage implements LocalStorage {
  @override
  String? getItem(String key) => html.window.localStorage[key];

  @override
  void setItem(String key, String value) {
    html.window.localStorage[key] = value;
  }

  @override
  void removeItem(String key) {
    html.window.localStorage.remove(key);
  }
}

void _init() {
  LocalStorage.instance = WebLocalStorage();
}

// Trigger initialization when this library is loaded on web
final _ = _init();


