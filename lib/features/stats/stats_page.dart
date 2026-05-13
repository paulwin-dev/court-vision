import 'package:ace/features/matches/match_classes.dart';
import 'package:ace/features/stats/stats_classes.dart';
import "package:flutter/material.dart";
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';
import 'package:ace/shared/storage/app_storage.dart';
import 'package:intl/intl.dart';

class MatchStatsPage extends StatefulWidget {
  final Id matchId;
  const MatchStatsPage({super.key, required this.matchId});

  @override
  State<MatchStatsPage> createState() => MatchStatsPageState();
}

class MatchStatsPageState extends State<MatchStatsPage> {
  Match? match;
  MatchStats? stats;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadMatch();
  }

  Future<void> _loadMatch() async {
    final m = await AppStorage.getMatchById(widget.matchId);
    if (m != null) {
      setState(() {
        match = m;
        stats = MatchStats.fromMatch(m);
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (loading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: colors.primary)),
      );
    }

    if (match == null || stats == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Match not found.',
            style: GoogleFonts.outfit(fontSize: 16),
          ),
        ),
      );
    }

    final m = match!;
    final s = stats!;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context, m, colors),
              const SizedBox(height: 14),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildScoreCard(context, m, colors),
                      const SizedBox(height: 12),
                      _buildComparisonSection(
                        context,
                        m,
                        s.localPlayerStats,
                        s.opponentStats,
                        colors,
                      ),
                      const SizedBox(height: 12),
                      _buildShotOutcomeRow(context, m, s, colors),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, Match m, ColorScheme colors) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.outline, width: 1),
            ),
            child: Icon(Icons.arrow_back, color: colors.onSurface, size: 20),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MATCH STATS',
                style: GoogleFonts.outfit(
                  color: colors.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                DateFormat.yMMMMd(
                  Localizations.localeOf(context).toString(),
                ).format(m.date),
                style: GoogleFonts.outfit(
                  color: colors.onSurface.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Score Card ────────────────────────────────────────────────────────────

  Widget _buildScoreCard(BuildContext context, Match m, ColorScheme colors) {
    return _OutlinedCard(
      label: 'FINAL SCORE',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.playerName,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    _WinLossBadge(isWin: m.isWin, colors: colors),
                  ],
                ),
              ),
              Text(
                m.finalScoreString,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  color: colors.primary,
                  letterSpacing: 1,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      m.opponentName,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _WinLossBadge(isWin: !m.isWin, colors: colors),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Per-set breakdown
          if (m.sets.isNotEmpty) ...[
            const SizedBox(height: 16),
            Divider(color: colors.outlineVariant, height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: m.sets.asMap().entries.map((entry) {
                final i = entry.key;
                final set = entry.value;
                final sc = _gamesInSet(set);
                final localMore = sc['p1']! > sc['opp']!;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      Text(
                        'SET ${i + 1}',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: colors.onSurface.withValues(alpha: 0.4),
                          letterSpacing: 1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${sc['p1']}-${sc['opp']}',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: localMore
                              ? colors.primary
                              : colors.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Comparison Section ────────────────────────────────────────────────────

  Widget _buildComparisonSection(
    BuildContext context,
    Match m,
    PlayerStats local,
    PlayerStats opp,
    ColorScheme colors,
  ) {
    return _OutlinedCard(
      label: 'STATISTICS',
      child: Column(
        children: [
          // Column headers
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    m.playerName,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: colors.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: Text('', textAlign: TextAlign.center),
                ),
                Expanded(
                  child: Text(
                    m.opponentName,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: colors.onSurface.withValues(alpha: 0.55),
                    ),
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          Divider(color: colors.outlineVariant, height: 1),
          const SizedBox(height: 10),

          _statSection('SERVE', colors),
          _ComparisonBar(
            label: 'Aces',
            localVal: local.aces.toDouble(),
            oppVal: opp.aces.toDouble(),
            formatInt: true,
            higherIsBetter: true,
            colors: colors,
          ),
          _ComparisonBar(
            label: 'Double Faults',
            localVal: local.doubleFaults.toDouble(),
            oppVal: opp.doubleFaults.toDouble(),
            formatInt: true,
            higherIsBetter: false,
            colors: colors,
          ),
          _ComparisonBar(
            label: '1st Serve %',
            localVal: local.firstServePercentage,
            oppVal: opp.firstServePercentage,
            formatPercent: true,
            higherIsBetter: true,
            colors: colors,
          ),
          _ComparisonBar(
            label: '2nd Serve Win %',
            localVal: local.secondServePercentage,
            oppVal: opp.secondServePercentage,
            formatPercent: true,
            higherIsBetter: true,
            colors: colors,
          ),

          const SizedBox(height: 14),
          _statSection('SHOTS', colors),
          _ComparisonBar(
            label: 'Winners',
            localVal: local.winners.toDouble(),
            oppVal: opp.winners.toDouble(),
            formatInt: true,
            higherIsBetter: true,
            colors: colors,
          ),
          _ComparisonBar(
            label: 'Unforced Errors',
            localVal: local.unforcedErrors.toDouble(),
            oppVal: opp.unforcedErrors.toDouble(),
            formatInt: true,
            higherIsBetter: false,
            colors: colors,
          ),
          _ComparisonBar(
            label: 'Forced Errors',
            localVal: local.forcedErrors.toDouble(),
            oppVal: opp.forcedErrors.toDouble(),
            formatInt: true,
            higherIsBetter: false,
            colors: colors,
          ),

          const SizedBox(height: 14),
          _statSection('RALLY', colors),
          _ComparisonBar(
            label: 'Avg Rally (s)',
            localVal: local.avgRallyLength,
            oppVal: opp.avgRallyLength,
            formatDecimal: true,
            higherIsBetter: true,
            colors: colors,
          ),
          _ComparisonBar(
            label: 'Aggressive Margin',
            localVal: local.aggressiveMargin.toDouble(),
            oppVal: opp.aggressiveMargin.toDouble(),
            formatInt: true,
            higherIsBetter: true,
            allowNegative: true,
            colors: colors,
          ),
        ],
      ),
    );
  }

  Widget _statSection(String label, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w800,
              color: colors.primary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: colors.outlineVariant, height: 1)),
        ],
      ),
    );
  }

  // ─── Shot Outcome Row ──────────────────────────────────────────────────────

  Widget _buildShotOutcomeRow(
    BuildContext context,
    Match m,
    MatchStats s,
    ColorScheme colors,
  ) {
    return Row(
      children: [
        Expanded(
          child: _OutlinedCard(
            label: 'COMMON MISSES',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MissChip(
                  playerName: m.playerName,
                  ue: s.localPlayerStats.commonUE,
                  fe: s.localPlayerStats.commonFE,
                  colors: colors,
                  isLocal: true,
                ),
                const SizedBox(height: 10),
                Divider(color: colors.outlineVariant, height: 1),
                const SizedBox(height: 10),
                _MissChip(
                  playerName: m.opponentName,
                  ue: s.opponentStats.commonUE,
                  fe: s.opponentStats.commonFE,
                  colors: colors,
                  isLocal: false,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  Map<String, int> _gamesInSet(MatchSet set) {
    int p1 = 0, opp = 0;
    for (final g in set.games) {
      int gp1 = 0, gopp = 0;
      for (final p in g.points) {
        p.wonByLocalPlayer ? gp1++ : gopp++;
      }
      gp1 > gopp ? p1++ : opp++;
    }
    return {'p1': p1, 'opp': opp};
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _OutlinedCard extends StatelessWidget {
  final String label;
  final Widget child;

  const _OutlinedCard({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.outline, width: 1),
          ),
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
          child: child,
        ),
        Positioned(
          top: 10,
          left: 14,
          child: Container(
            color: colors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              label,
              style: GoogleFonts.outfit(
                color: colors.primary,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WinLossBadge extends StatelessWidget {
  final bool isWin;
  final ColorScheme colors;

  const _WinLossBadge({required this.isWin, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isWin
            ? colors.primary.withValues(alpha: 0.15)
            : Colors.red.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isWin ? 'WIN' : 'LOSS',
        style: GoogleFonts.outfit(
          color: isWin ? colors.primary : Colors.red,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _ComparisonBar extends StatelessWidget {
  final String label;
  final double localVal;
  final double oppVal;
  final bool higherIsBetter;
  final bool formatInt;
  final bool formatPercent;
  final bool formatDecimal;
  final bool allowNegative;
  final ColorScheme colors;

  const _ComparisonBar({
    required this.label,
    required this.localVal,
    required this.oppVal,
    required this.higherIsBetter,
    required this.colors,
    this.formatInt = false,
    this.formatPercent = false,
    this.formatDecimal = false,
    this.allowNegative = false,
  });

  String _fmt(double v) {
    if (formatPercent) return '${(v * 100).toStringAsFixed(0)}%';
    if (formatDecimal) return v.toStringAsFixed(1);
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final total = localVal.abs() + oppVal.abs();
    // Determine which side "wins" this stat
    final localLeads = higherIsBetter ? localVal >= oppVal : localVal <= oppVal;
    final tied = localVal == oppVal;

    final localColor = tied
        ? colors.onSurface.withValues(alpha: 0.4)
        : localLeads
        ? colors.primary
        : colors.onSurface.withValues(alpha: 0.35);
    final oppColor = tied
        ? colors.onSurface.withValues(alpha: 0.4)
        : !localLeads
        ? Colors.red.withValues(alpha: 0.8)
        : colors.onSurface.withValues(alpha: 0.35);

    // Bar widths: proportional, clamped to avoid zero-width
    double localFrac = total == 0 ? 0.5 : (localVal.abs() / total);
    double oppFrac = 1.0 - localFrac;

    // For allowNegative stats, just show absolute bars
    if (allowNegative) {
      localFrac = 0.5;
      oppFrac = 0.5;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 48,
                child: Text(
                  _fmt(localVal),
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: localColor,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: colors.onSurface.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(
                width: 48,
                child: Text(
                  _fmt(oppVal),
                  textAlign: TextAlign.end,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: oppColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Row(
              children: [
                Expanded(
                  flex: (localFrac * 100).round().clamp(5, 95),
                  child: Container(height: 4, color: localColor),
                ),
                const SizedBox(width: 2),
                Expanded(
                  flex: (oppFrac * 100).round().clamp(5, 95),
                  child: Container(height: 4, color: oppColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MissChip extends StatelessWidget {
  final String playerName;
  final String ue;
  final String fe;
  final ColorScheme colors;
  final bool isLocal;

  const _MissChip({
    required this.playerName,
    required this.ue,
    required this.fe,
    required this.colors,
    required this.isLocal,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          playerName,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: isLocal
                ? colors.primary
                : colors.onSurface.withValues(alpha: 0.55),
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _Chip(label: 'UE', value: ue, color: Colors.orange, colors: colors),
            const SizedBox(width: 8),
            _Chip(label: 'FE', value: fe, color: Colors.red, colors: colors),
          ],
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final ColorScheme colors;

  const _Chip({
    required this.label,
    required this.value,
    required this.color,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label  ',
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.onSurface.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}
