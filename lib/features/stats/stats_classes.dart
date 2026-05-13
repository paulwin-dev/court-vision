import 'package:ace/features/matches/match_classes.dart';

class MatchStats {
  final PlayerStats localPlayerStats;
  final PlayerStats opponentStats;

  MatchStats({
    required this.localPlayerStats,
    required this.opponentStats,
  });

  factory MatchStats.fromMatch(Match match) {
    final allPoints = match.sets
        .expand((s) => s.games)
        .expand((g) => g.points)
        .toList();

    return MatchStats(
      localPlayerStats: _computeStatsForPlayer(
        points: allPoints,
        playerName: match.playerName,
        forLocalPlayer: true,
      ),
      opponentStats: _computeStatsForPlayer(
        points: allPoints,
        playerName: match.opponentName,
        forLocalPlayer: false,
      ),
    );
  }

  static PlayerStats _computeStatsForPlayer({
    required List<MatchPoint> points,
    required String playerName,
    required bool forLocalPlayer,
  }) {
    final aces = points
        .where((p) =>
            p.type == PointType.ace && p.wonByLocalPlayer == forLocalPlayer)
        .length;

    final doubleFaults = points
        .where((p) =>
            p.type == PointType.doubleFault &&
            p.wonByLocalPlayer != forLocalPlayer)
        .length;

    final winners = points
        .where((p) =>
            p.type == PointType.winner &&
            p.wonByLocalPlayer == forLocalPlayer)
        .length;

    final unforcedErrors = points
        .where((p) =>
            p.type == PointType.unforcedError &&
            p.wonByLocalPlayer != forLocalPlayer)
        .length;

    final forcedErrors = points
        .where((p) =>
            p.type == PointType.forcedError &&
            p.wonByLocalPlayer != forLocalPlayer)
        .length;

    // Serve stats using serverName
    final servePoints = points
        .where((p) => p.serverName == playerName)
        .toList();

    final totalServePoints = servePoints.length;

    // First serve in: served points that are NOT double faults
    final firstServeIn = servePoints
        .where((p) => p.type != PointType.doubleFault)
        .length;

    final firstServePercentage = totalServePoints == 0
        ? 0.0
        : firstServeIn / totalServePoints;

    // Second serve points won: approximated as non-doubleFault serve points won
    // minus aces (which are typically first-serve winners)
    final secondServePoints = servePoints
        .where((p) => p.type != PointType.doubleFault && p.type != PointType.ace)
        .toList();

    final secondServeWon = secondServePoints
        .where((p) => p.wonByLocalPlayer == forLocalPlayer)
        .length;

    final secondServePercentage = secondServePoints.isEmpty
        ? 0.0
        : secondServeWon / secondServePoints.length;

    // Avg rally length in seconds
    final totalDurationMs =
        points.fold<int>(0, (sum, p) => sum + p.durationMs);
    final avgRallyLength =
        points.isEmpty ? 0.0 : totalDurationMs / points.length / 1000.0;

    final aggressiveMargin = winners - unforcedErrors;

    String mostCommon(List<String?> outcomes) {
      if (outcomes.isEmpty) return '-';
      final freq = <String, int>{};
      for (final o in outcomes) {
        if (o != null && o.isNotEmpty) {
          freq[o] = (freq[o] ?? 0) + 1;
        }
      }
      if (freq.isEmpty) return '-';
      return freq.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;
    }

    final ueOutcomes = points
        .where((p) =>
            p.type == PointType.unforcedError &&
            p.wonByLocalPlayer != forLocalPlayer)
        .map((p) => p.shotOutcome)
        .toList();

    final feOutcomes = points
        .where((p) =>
            p.type == PointType.forcedError &&
            p.wonByLocalPlayer != forLocalPlayer)
        .map((p) => p.shotOutcome)
        .toList();

    return PlayerStats(
      aces: aces,
      doubleFaults: doubleFaults,
      winners: winners,
      unforcedErrors: unforcedErrors,
      forcedErrors: forcedErrors,
      firstServePercentage: firstServePercentage,
      secondServePercentage: secondServePercentage,
      avgRallyLength: avgRallyLength,
      aggressiveMargin: aggressiveMargin,
      commonUE: mostCommon(ueOutcomes),
      commonFE: mostCommon(feOutcomes),
    );
  }
}

class PlayerStats {
  final int aces;
  final int doubleFaults;
  final int winners;
  final int unforcedErrors;
  final int forcedErrors;
  final double firstServePercentage;
  final double secondServePercentage;
  final double avgRallyLength;
  final int aggressiveMargin;
  final String commonUE; // Most common Unforced Error miss
  final String commonFE; // Most common Forced Error miss

  PlayerStats({
    required this.aces,
    required this.doubleFaults,
    required this.winners,
    required this.unforcedErrors,
    required this.forcedErrors,
    required this.firstServePercentage,
    required this.secondServePercentage,
    required this.avgRallyLength,
    required this.aggressiveMargin,
    required this.commonUE,
    required this.commonFE,
  });
}
