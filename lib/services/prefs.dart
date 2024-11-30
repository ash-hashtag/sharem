import 'package:shared_preferences/shared_preferences.dart';

Future<String?> getMyUniqueName() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString("uniqueName");
}

Future<void> setUniqueName(String uniqueName) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString("uniqueName", uniqueName);
}

Future<String?> getOrSetUniqueName([String? uniqueName]) async {
  final prefs = await SharedPreferences.getInstance();
  final value = prefs.getString("uniqueName");
  if (value == null && uniqueName != null) {
    await prefs.setString("uniqueName", uniqueName);
  }
  return value ?? uniqueName;
}
