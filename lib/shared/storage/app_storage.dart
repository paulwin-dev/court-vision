import 'dart:convert';

import 'package:ace/features/matches/match_classes.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

class AppStorage {
  static Future<List<MatchPreset>> getSavedPresets() async {
    final prefs = await SharedPreferences.getInstance();
    final String? presetsJson = prefs.getString('match_presets');

    if (presetsJson != null) {
      final List<dynamic> decoded = jsonDecode(presetsJson);
      return decoded.map((item) => MatchPreset.fromJson(item)).toList();
    } else {
      return [
        MatchPreset(id: '1', name: 'Default', setsToWin: 2),
        MatchPreset(
          id: '2',
          name: 'LK Turnier',
          setsToWin: 2,
          useMatchTiebreak: true,
        ),
      ];
    }
  }

  static Future<int> saveMatch(Match match) async {
    final dir = await getApplicationDocumentsDirectory();
    final isar =
        Isar.getInstance() ??
        await Isar.open(
          [MatchSchema],
          directory: dir.path, // required parameter
        );

    return await isar.writeTxn(() async {
      return await isar.matchs.put(match); // put() returns the Id
    });
  }

  static Future<List<Match>> getAllMatches() async {
    final dir = await getApplicationDocumentsDirectory();
    final isar =
        Isar.getInstance() ??
        await Isar.open([MatchSchema], directory: dir.path);

    return await isar.matchs.where().sortByDateDesc().findAll();
  }

  static Future<Match?> getMatchById(int id) async {
    final dir = await getApplicationDocumentsDirectory();
    final isar =
        Isar.getInstance() ??
        await Isar.open([MatchSchema], directory: dir.path);

    return await isar.matchs.get(id);
  }
}
