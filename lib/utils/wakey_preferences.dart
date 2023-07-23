import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakey/objects/device.dart';

class WakeyPreferences {
  static late SharedPreferences _preferences;

  static const _keyDevices = "devices";

  static Future init() async => _preferences = await SharedPreferences.getInstance();

  static Future setDevices(List<Device> devices) async => await _preferences.setString(_keyDevices, jsonEncode(devices));

  static List<Device> getDevices() {
    final jsonValue = _preferences.getString(_keyDevices);
    if(jsonValue != null) {
      List<dynamic> parsedDevices = jsonDecode(jsonValue);
      return List<Device>.from(parsedDevices.map((e) => Device.fromJson(e)));
    }
    return [];
  }
}