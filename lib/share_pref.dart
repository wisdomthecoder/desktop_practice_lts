import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsHelper {
  static final SharedPrefsHelper _instance = SharedPrefsHelper._internal();
  factory SharedPrefsHelper() => _instance;
  SharedPrefsHelper._internal();

  static const String keyName = 'key';
  final StreamController<String?> _controller = StreamController.broadcast();
  Timer? _pollTimer;
  String? _lastValue;

  Future<void> init() async {
    _lastValue = await getValue();
    _controller.add(_lastValue);

    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final newValue = await getValue();
      if (newValue != _lastValue) {
        _lastValue = newValue;
        _controller.add(newValue);
      }
    });
  }

  Stream<String?> get stream => _controller.stream;

  Future<void> setValue(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyName, value);
    _lastValue = value;
    _controller.add(value);
  }

  Future<String?> getValue() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyName);
  }

  void dispose() {
    _pollTimer?.cancel();
    _controller.close();
  }
}
