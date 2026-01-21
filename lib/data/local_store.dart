import 'package:hive_flutter/hive_flutter.dart';

class LocalStore {
  static const boxName = 'asset_secretary_box';
  static late Box box;

  static Future<void> init() async {
    await Hive.initFlutter();
    box = await Hive.openBox(boxName);
  }

  static T? get<T>(String key) => box.get(key) as T?;
  static Future<void> set(String key, dynamic value) => box.put(key, value);
  static Future<void> delete(String key) => box.delete(key);
}
