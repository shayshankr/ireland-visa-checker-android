import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_number.dart';

class SavedNumbersService {
  static const _key = 'saved_numbers_v1';

  static final RegExp _irlPrefix = RegExp(r'^[Ii][Rr][Ll]');
  static final RegExp _nonDigit = RegExp(r'\D');

  static String normalize(String input) =>
      input.trim().replaceAll(_irlPrefix, '').replaceAll(_nonDigit, '');

  static Future<List<SavedNumber>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => SavedNumber.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> _writeAll(List<SavedNumber> numbers) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, jsonEncode(numbers.map((n) => n.toJson()).toList()));
  }

  static Future<void> add(SavedNumber number) async {
    final all = await getAll();
    if (all.any((n) => n.number == number.number)) return;
    await _writeAll([...all, number]);
  }

  static Future<void> update(SavedNumber updated) async {
    final all = await getAll();
    await _writeAll(
        all.map((n) => n.number == updated.number ? updated : n).toList());
  }

  static Future<void> remove(String number) async {
    final all = await getAll();
    await _writeAll(all.where((n) => n.number != number).toList());
  }

  static Future<bool> contains(String number) async {
    final all = await getAll();
    return all.any((n) => n.number == number);
  }
}
