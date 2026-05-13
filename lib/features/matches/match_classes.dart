import 'package:isar/isar.dart';

part 'match_classes.g.dart';

enum PointType { ace, winner, unforcedError, forcedError, doubleFault, normal, }

@embedded
class MatchPoint {
  bool wonByLocalPlayer = false;
  String serverName = "";
  int durationMs = 0;
  String? shotOutcome;

  @enumerated
  PointType type = PointType.normal;

  MatchPoint();

  MatchPoint.create({
    required this.wonByLocalPlayer,
    required this.serverName,
    required this.type,
    required this.durationMs,
    this.shotOutcome,
  });

  // --- ADD THESE ---
  Map<String, dynamic> toJson() => {
    'wonByLocalPlayer': wonByLocalPlayer,
    'serverName': serverName,
    'durationMs': durationMs,
    'shotOutcome': shotOutcome,
    'type': type.name, // Serializing enum as String
  };

  factory MatchPoint.fromJson(Map<String, dynamic> json) {
    return MatchPoint.create(
      wonByLocalPlayer: json['wonByLocalPlayer'] ?? false,
      serverName: json['serverName'] ?? "",
      durationMs: json['durationMs'] ?? 0,
      shotOutcome: json['shotOutcome'],
      type: PointType.values.byName(json['type'] ?? 'normal'),
    );
  }
  // -----------------

  MatchPoint copyWith({PointType? type, String? shotOutcome}) {
    return MatchPoint.create(
      wonByLocalPlayer: wonByLocalPlayer,
      serverName: serverName,
      type: type ?? this.type,
      durationMs: durationMs,
      shotOutcome: shotOutcome ?? this.shotOutcome,
    );
  }
}

@embedded
class MatchGame {
  List<MatchPoint> points = [];
  bool isTiebreak = false;

  MatchGame(); 

  MatchGame.create({required this.points, this.isTiebreak = false});

  // --- ADD THESE ---
  Map<String, dynamic> toJson() => {
    'isTiebreak': isTiebreak,
    'points': points.map((p) => p.toJson()).toList(),
  };

  factory MatchGame.fromJson(Map<String, dynamic> json) {
    return MatchGame.create(
      isTiebreak: json['isTiebreak'] ?? false,
      points: (json['points'] as List? ?? [])
          .map((pJson) => MatchPoint.fromJson(pJson))
          .toList(),
    );
  }
}

@embedded
class MatchSet {
  List<MatchGame> games = [];

  MatchSet();

  MatchSet.create({required this.games});

  Map<String, dynamic> toJson() => {
    'games': games.map((game) => game.toJson()).toList(),
  };

  factory MatchSet.fromJson(Map<String, dynamic> json) {
    return MatchSet.create(
      games: (json['games'] as List)
          .map((gameJson) => MatchGame.fromJson(gameJson))
          .toList(),
    );
  }
}

@collection
class Match {
  Id id = Isar.autoIncrement;

  String playerName = "";
  String opponentName = "";
  DateTime date = DateTime.now();
  List<MatchSet> sets = [];

  Match();

  Match.create({
    required this.playerName,
    required this.opponentName,
    required this.date,
    required this.sets,
  });

  // Convert Match to Map
  Map<String, dynamic> toJson() => {
    'playerName': playerName,
    'opponentName': opponentName,
    'sets': sets.map((set) => set.toJson()).toList(),
    'date': date.toIso8601String()
  };

  // Create Match from Map
  factory Match.fromJson(Map<String, dynamic> json) {
    return Match.create(
      playerName: json['playerName'],
      opponentName: json['opponentName'],
      sets: (json['sets'] as List)
          .map((setJson) => MatchSet.fromJson(setJson))
          .toList(),
      date: DateTime.parse(json['date'])
    );
  }

  bool get isWin {
    int localSetsWon = 0;
    int opponentSetsWon = 0;

    for (var set in sets) {
      var result = _getGamesInSet(set);
      if (result['p1']! > result['opp']!) {
        localSetsWon++;
      } else {
        opponentSetsWon++;
      }
    }
    return localSetsWon > opponentSetsWon;
  }

  String get finalScoreString {
    List<String> setScores = [];

    for (var set in sets) {
      var counts = _getGamesInSet(set);
      String score = "${counts['p1']}-${counts['opp']}";

      if (set.games.isNotEmpty && set.games.last.isTiebreak) {
        var tbPoints = _getPointsInGame(set.games.last);
        int loserPoints = tbPoints['p1']! < tbPoints['opp']!
            ? tbPoints['p1']!
            : tbPoints['opp']!;
        score += "($loserPoints)";
      }

      setScores.add(score);
    }
    return setScores.join(" ");
  }

  Map<String, int> _getGamesInSet(MatchSet set) {
    int p1 = 0;
    int opp = 0;
    for (var game in set.games) {
      var pts = _getPointsInGame(game);
      if (pts['p1']! > pts['opp']!) {
        p1++;
      } else {
        opp++;
      }
    }
    return {'p1': p1, 'opp': opp};
  }

  Map<String, int> _getPointsInGame(MatchGame game) {
    int p1 = 0;
    int opp = 0;
    for (var pt in game.points) {
      if (pt.wonByLocalPlayer) {
        p1++;
      } else {
        opp++;
      }
    }
    return {'p1': p1, 'opp': opp};
  }
}

class MatchPreset {
  final String id;
  final String name;
  final int setsToWin;
  final int gamesPerSet;
  final bool useSetTiebreak;
  final int setTiebreakTo;
  final bool useMatchTiebreak;
  final int matchTiebreakTo;

  MatchPreset({
    required this.id,
    required this.name,
    this.setsToWin = 2,
    this.gamesPerSet = 6,
    this.useSetTiebreak = true,
    this.setTiebreakTo = 7,
    this.useMatchTiebreak = true,
    this.matchTiebreakTo = 10,
  });

  // Manual factory or use json_serializable
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'setsToWin': setsToWin,
    'gamesPerSet': gamesPerSet,
    'useSetTiebreak': useSetTiebreak,
    'setTiebreakTo': setTiebreakTo,
    'useMatchTiebreak': useMatchTiebreak,
    'matchTiebreakTo': matchTiebreakTo,
  };

  factory MatchPreset.fromJson(Map<String, dynamic> json) => MatchPreset(
    id: json['id'],
    name: json['name'],
    setsToWin: json['setsToWin'],
    gamesPerSet: json['gamesPerSet'],
    useSetTiebreak: json['useSetTiebreak'],
    setTiebreakTo: json['setTiebreakTo'],
    useMatchTiebreak: json['useMatchTiebreak'],
    matchTiebreakTo: json['matchTiebreakTo'],
  );
}
