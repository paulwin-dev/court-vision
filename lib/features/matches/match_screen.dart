import 'package:ace/features/matches/match_classes.dart';
import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:ace/shared/storage/app_storage.dart';

enum MatchActionState {
  decideFirstServe,
  serving,
  firstServeFault,
  rally,
  rallyLocalPlayerWin,
  rallyLocalPlayerLose,
  rallyLocalPlayerLossType,
  matchComplete,
}

class MatchSnapshot {
  final MatchActionState actionState;
  final String serverName;
  final int setsP1, setsOpp;
  final int gamesP1, gamesOpp;
  final int gamePointsP1, gamePointsOpp;

  MatchSnapshot({
    required this.actionState,
    required this.serverName,
    required this.setsP1,
    required this.setsOpp,
    required this.gamesP1,
    required this.gamesOpp,
    required this.gamePointsP1,
    required this.gamePointsOpp,
  });
}

class MatchScreenPage extends StatefulWidget {
  final String opponentName;
  final String matchPreset;
  final String localPlayerName;

  const MatchScreenPage({
    super.key,
    required this.opponentName,
    required this.matchPreset,
    required this.localPlayerName,
  });

  @override
  State<MatchScreenPage> createState() => MatchScreenPageState();
}

class MatchScreenPageState extends State<MatchScreenPage> {
  List<MatchSet> allSets = [];
  List<MatchGame> currentSetGames = [];
  List<MatchPoint> currentGamePoints = [];

  PointType lastPointType = PointType.normal;

  MatchActionState currentActionState = MatchActionState.decideFirstServe;
  String serverName = "";

  final Stopwatch _rallyStopwatch = Stopwatch();
  Timer? _uiTimer;

  late MatchPreset preset;

  late String player1Short;
  late String opponentShort;
  int setsP1 = 0;
  int setsOpp = 0;
  int gamesP1 = 0;
  int gamesOpp = 0;
  int gamePointsP1 = 0;
  int gamePointsOpp = 0;

  bool isTiebreak = false;
  int tiebreakTarget = -1;

  List<MatchSnapshot> history = [];

  @override
  void initState() {
    super.initState();

    AppStorage.getSavedPresets().then((val) {
      preset = val.firstWhere((el) => el.id == widget.matchPreset);
    });
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    super.dispose();
  }

  void _saveState() {
    history.add(
      MatchSnapshot(
        actionState: currentActionState,
        serverName: serverName,
        setsP1: setsP1,
        setsOpp: setsOpp,
        gamesP1: gamesP1,
        gamesOpp: gamesOpp,
        gamePointsP1: gamePointsP1,
        gamePointsOpp: gamePointsOpp,
      ),
    );
  }

  // 3. The Undo function
  void _undoLastAction() {
    if (history.isEmpty) return;

    setState(() {
      final lastState = history.removeLast();
      currentActionState = lastState.actionState;
      serverName = lastState.serverName;
      setsP1 = lastState.setsP1;
      setsOpp = lastState.setsOpp;
      gamesP1 = lastState.gamesP1;
      gamesOpp = lastState.gamesOpp;
      gamePointsP1 = lastState.gamePointsP1;
      gamePointsOpp = lastState.gamePointsOpp;
    });

    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    player1Short = widget.localPlayerName.substring(0, 1).toUpperCase();
    opponentShort = widget.opponentName.substring(0, 1).toUpperCase();

    final colors = Theme.of(context).colorScheme;

    const double outerPadding = 16.0;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(outerPadding),
          child: Column(
            children: [
              buildMatchLabel(colors),
              const SizedBox(height: 12),

              buildScorePanel(colors),

              const Spacer(),
              buildDynamicSubtitle(),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: buildActionButtons(context),
              ),
              buildUndoButton(colors),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget buildMatchLabel(ColorScheme colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'MATCH',
          style: GoogleFonts.outfit(
            color: colors.primary,
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget buildUndoButton(ColorScheme colors) {
    if (history.isEmpty) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 15),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton.icon(
          onPressed: _undoLastAction,
          icon: const Icon(Icons.undo, size: 18),
          label: Text(
            "UNDO",
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.surfaceBright,
            side: BorderSide(color: colors.surface),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildScorePanel(ColorScheme colors) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant, width: 1),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Player Row
          ScoreRow(
            shortName: player1Short,
            sets: setsP1,
            games: gamesP1,
            points: formatTennisPoint(gamePointsP1, gamePointsOpp),
          ),
          const SizedBox(height: 12), // Space between player rows
          // Opponent Row
          ScoreRow(
            shortName: opponentShort,
            sets: setsOpp,
            games: gamesOpp,
            points: formatTennisPoint(gamePointsOpp, gamePointsP1),
          ),
        ],
      ),
    );
  }

  Widget buildActionButtons(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    const double rowHeight = 100.0;
    const double largeText = 22.0;

    switch (currentActionState) {
      case MatchActionState.decideFirstServe:
        return Column(
          children: [
            SizedBox(
              height: rowHeight,
              child: Row(
                children: [
                  Expanded(
                    child: TextActionButton(
                      text: widget.localPlayerName.toUpperCase(),
                      color: colors.primary,
                      textColor: Colors.black,
                      onPressed: () {
                        _saveState();
                        setState(() {
                          serverName = widget.localPlayerName;
                          currentActionState = MatchActionState.serving;
                        });
                      },
                      style: GoogleFonts.outfit(fontSize: largeText),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextActionButton(
                      text: widget.opponentName.toUpperCase(),
                      color: colors.surface,
                      textColor: Colors.white,
                      onPressed: () {
                        _saveState();
                        setState(() {
                          serverName = widget.opponentName;
                          currentActionState = MatchActionState.serving;
                        });
                      },
                      style: GoogleFonts.outfit(fontSize: largeText),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      case MatchActionState.serving:
        return Column(
          children: [
            SizedBox(
              height: rowHeight,
              child: Row(
                children: [
                  Expanded(
                    child: TextActionButton(
                      text: 'ACE',
                      color: colors.primary,
                      textColor: Colors.black,
                      onPressed: () {
                        _saveState();
                        _pointWonBy(serverName == widget.localPlayerName);
                        lastPointType = PointType.ace;
                      },
                      style: GoogleFonts.outfit(fontSize: largeText),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextActionButton(
                      text: 'IN',
                      color: colors.surface,
                      textColor: Colors.white,
                      onPressed: () {
                        _saveState();
                        setState(() {
                          currentActionState = MatchActionState.rally;
                          _rallyStopwatch.reset();
                          _rallyStopwatch.start();
                          _uiTimer = Timer.periodic(
                            const Duration(milliseconds: 100),
                            (timer) {
                              setState(() {});
                            },
                          );
                        });
                      },
                      style: GoogleFonts.outfit(fontSize: largeText),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 100,
              child: TextActionButton(
                text: 'FAULT',
                color: colors.errorContainer,
                textColor: Colors.red,
                borderColor: colors.onErrorContainer,
                onPressed: () {
                  _saveState();
                  setState(() {
                    currentActionState = MatchActionState.firstServeFault;
                  });
                },
                style: GoogleFonts.outfit(fontSize: largeText),
              ),
            ),
          ],
        );

      case MatchActionState.firstServeFault:
        return Column(
          children: [
            SizedBox(
              height: rowHeight,
              child: Row(
                children: [
                  Expanded(
                    child: TextActionButton(
                      text: 'ACE',
                      color: colors.primary,
                      textColor: Colors.black,
                      onPressed: () {
                        _saveState();
                        _pointWonBy(serverName == widget.localPlayerName);
                        lastPointType = PointType.ace;
                      },
                      style: GoogleFonts.outfit(fontSize: largeText),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextActionButton(
                      text: 'IN',
                      color: colors.surface,
                      textColor: Colors.white,
                      onPressed: () {
                        _saveState();
                        setState(() {
                          currentActionState = MatchActionState.rally;
                        });
                      },
                      style: GoogleFonts.outfit(fontSize: largeText),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 100,
              child: TextActionButton(
                text: 'DOUBLE FAULT',
                color: colors.errorContainer,
                textColor: Colors.red,
                borderColor: colors.onErrorContainer,
                onPressed: () {
                  _saveState();
                  _pointWonBy(serverName != widget.localPlayerName);
                  lastPointType = PointType.doubleFault;
                },
                style: GoogleFonts.outfit(fontSize: largeText),
              ),
            ),
          ],
        );

      case MatchActionState.rally:
        return Column(
          children: [
            SizedBox(
              height: rowHeight,
              child: Row(
                children: [
                  Expanded(
                    child: TextActionButton(
                      text: "WIN",
                      color: colors.primary,
                      textColor: Colors.black,
                      onPressed: () {
                        _saveState();
                        _pointWonBy(true);
                        setState(() {
                          currentActionState =
                              MatchActionState.rallyLocalPlayerWin;
                        });
                      },
                      style: GoogleFonts.outfit(fontSize: largeText),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextActionButton(
                      text: "LOSE",
                      color: colors.surface,
                      textColor: Colors.white,
                      onPressed: () {
                        _saveState();
                        _pointWonBy(false);
                        setState(() {
                          currentActionState =
                              MatchActionState.rallyLocalPlayerLose;
                        });
                      },
                      style: GoogleFonts.outfit(fontSize: largeText),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      case MatchActionState.rallyLocalPlayerWin:
        return Column(
          children: [
            SizedBox(
              height: rowHeight,
              child: Row(
                children: [
                  Expanded(
                    child: TextActionButton(
                      text: 'WINNER',
                      color: colors.primary,
                      textColor: Colors.black,
                      onPressed: () {
                        _saveState();
                        setState(() {
                          currentActionState = MatchActionState.serving;
                          lastPointType = PointType.winner;
                        });
                      },
                      style: GoogleFonts.outfit(fontSize: largeText),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextActionButton(
                      text: 'FORCED',
                      color: colors.surface,
                      textColor: Colors.white,
                      onPressed: () {
                        _saveState();
                        setState(() {
                          currentActionState = MatchActionState.serving;
                          lastPointType = PointType.forcedError;
                        });
                      },
                      style: GoogleFonts.outfit(fontSize: largeText),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 100,
              child: TextActionButton(
                text: 'UNFORCED',
                color: colors.errorContainer,
                textColor: Colors.red,
                borderColor: colors.onErrorContainer,
                onPressed: () {
                  _saveState();
                  setState(() {
                    currentActionState = MatchActionState.serving;
                    lastPointType = PointType.unforcedError;
                  });
                },
                style: GoogleFonts.outfit(fontSize: largeText),
              ),
            ),
          ],
        );

      case MatchActionState.rallyLocalPlayerLose:
        return Column(
          children: [
            SizedBox(
              height: rowHeight,
              child: Row(
                children: [
                  Expanded(
                    child: TextActionButton(
                      text: 'WINNER',
                      color: colors.primary,
                      textColor: Colors.black,
                      onPressed: () {
                        _saveState();
                        setState(() {
                          currentActionState = MatchActionState.serving;
                          lastPointType = PointType.winner;
                        });
                      },
                      style: GoogleFonts.outfit(fontSize: largeText),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextActionButton(
                      text: 'FORCED',
                      color: colors.surface,
                      textColor: Colors.white,
                      onPressed: () {
                        _saveState();
                        setState(() {
                          currentActionState =
                              MatchActionState.rallyLocalPlayerLossType;
                          lastPointType = PointType.forcedError;
                        });
                      },
                      style: GoogleFonts.outfit(fontSize: largeText),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 100,
              child: TextActionButton(
                text: 'UNFORCED',
                color: colors.errorContainer,
                textColor: Colors.red,
                borderColor: colors.onErrorContainer,
                onPressed: () {
                  _saveState();
                  setState(() {
                    currentActionState =
                        MatchActionState.rallyLocalPlayerLossType;
                    lastPointType = PointType.unforcedError;
                  });
                },
                style: GoogleFonts.outfit(fontSize: largeText),
              ),
            ),
          ],
        );

      case MatchActionState.rallyLocalPlayerLossType:
        return Column(
          children: [
            SizedBox(
              height: rowHeight,
              child: Row(
                children: [
                  Expanded(
                    child: TextActionButton(
                      text: 'OUT',
                      color: colors.surface,
                      textColor: Colors.white,
                      onPressed: () {
                        _updateLastPointMetadata(outcome: "out");
                        _saveState();
                        setState(() {
                          currentActionState = MatchActionState.serving;
                        });
                      },
                      style: GoogleFonts.outfit(fontSize: largeText),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextActionButton(
                      text: 'NET',
                      color: colors.errorContainer,
                      borderColor: colors.onErrorContainer,
                      textColor: Colors.red,
                      onPressed: () {
                        _updateLastPointMetadata(outcome: "net");
                        _saveState();
                        setState(() {
                          currentActionState = MatchActionState.serving;
                        });
                      },
                      style: GoogleFonts.outfit(fontSize: largeText),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      case MatchActionState.matchComplete:
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 100,
              child: TextActionButton(
                text: 'FINISH MATCH',
                color: colors.primary,
                textColor: Colors.black,
                onPressed: () {
                  Match finalResult = Match.create(
                    playerName: widget.localPlayerName,
                    opponentName: widget.opponentName,
                    sets: allSets,
                    date: DateTime.now(),
                  );

                  AppStorage.saveMatch(finalResult).then((_) {
                    // ignore: use_build_context_synchronously
                    context.pushReplacement("/stats/${finalResult.id}");
                  });
                },
                style: GoogleFonts.outfit(fontSize: 22),
              ),
            ),
          ],
        );
    }
  }

  Widget buildDynamicSubtitle() {
    String subtitle = "";

    switch (currentActionState) {
      case MatchActionState.decideFirstServe:
        subtitle = "WHO IS SERVING FIRST?";
        break;
      case MatchActionState.serving:
      case MatchActionState.firstServeFault:
        subtitle = "${serverName.toUpperCase()} IS SERVING";
        break;
      case MatchActionState.rally:
        final elapsed = _rallyStopwatch.elapsed;
        final seconds = elapsed.inSeconds;
        final tenths = (elapsed.inMilliseconds % 1000) ~/ 100;
        subtitle = "RALLY LENGTH: $seconds.${tenths}s";
        break;
      case MatchActionState.rallyLocalPlayerWin:
        subtitle = "HOW DID ${widget.localPlayerName.toUpperCase()} WIN?";
        break;
      case MatchActionState.rallyLocalPlayerLose:
        subtitle = "HOW DID ${widget.localPlayerName.toUpperCase()} LOSE?";
        break;
      case MatchActionState.rallyLocalPlayerLossType:
        subtitle = "WHERE DID THE BALL GO?";
        break;
      case MatchActionState.matchComplete:
        final winnerName = setsP1 > setsOpp
            ? widget.localPlayerName
            : widget.opponentName;
        subtitle = "${winnerName.toUpperCase()} WINS THE MATCH!";
    }

    return Text(
      subtitle,
      style: GoogleFonts.outfit(
        color: Colors.white,
        fontWeight: FontWeight.w800,
        fontSize: 16,
      ),
    );
  }

  String formatTennisPoint(int p, int oppP) {
    // If in a tiebreak, just show the number
    if (isTiebreak) {
      return p.toString();
    }

    // Standard Tennis Logic
    if (p >= 3 && oppP >= 3) {
      if (p == oppP) return "40";
      if (p > oppP) return "AD";
      return "40";
    }
    const scores = ["0", "15", "30", "40"];
    return scores[p];
  }

  void _pointWonBy(bool isLocalPlayer) {
    _rallyStopwatch.stop();
    _uiTimer?.cancel();

    // 1. Record the point immediately
    currentGamePoints.add(
      MatchPoint.create(
        wonByLocalPlayer: isLocalPlayer,
        serverName: serverName,
        type: lastPointType,
        durationMs: _rallyStopwatch.elapsedMilliseconds,
      ),
    );

    setState(() {
      if (isLocalPlayer) {
        gamePointsP1++;
      } else {
        gamePointsOpp++;
      }

      bool gameEnded = false;
      bool setEnded = false;

      // --- 1. HANDLE TIEBREAK SCORING ---
      if (isTiebreak) {
        if ((gamePointsP1 >= tiebreakTarget ||
                gamePointsOpp >= tiebreakTarget) &&
            (gamePointsP1 - gamePointsOpp).abs() >= 2) {
          if (gamePointsP1 > gamePointsOpp) {
            setsP1++;
            gamesP1++;
          } else {
            setsOpp++;
            gamesOpp++;
          }

          gameEnded = true;
          setEnded = true; // Tiebreaks (Set or Match) always end the set
          isTiebreak = false;
        } else {
          int totalPoints = gamePointsP1 + gamePointsOpp;
          if (totalPoints % 2 == 1) _rotateServer();
        }
      }
      // --- 2. HANDLE STANDARD SCORING ---
      else {
        if ((gamePointsP1 >= 4 || gamePointsOpp >= 4) &&
            (gamePointsP1 - gamePointsOpp).abs() >= 2) {
          if (gamePointsP1 > gamePointsOpp) {
            gamesP1++;
          } else {
            gamesOpp++;
          }

          gameEnded = true;
          _rotateServer();

          // Check for 6-6 (Tiebreak start)
          if (gamesP1 == preset.gamesPerSet &&
              gamesOpp == preset.gamesPerSet &&
              preset.useSetTiebreak) {
            isTiebreak = true;
            tiebreakTarget = preset.setTiebreakTo;
          }
          // Check for Set End
          else if ((gamesP1 >= preset.gamesPerSet ||
                  gamesOpp >= preset.gamesPerSet) &&
              (gamesP1 - gamesOpp).abs() >= 2) {
            if (gamesP1 > gamesOpp) {
              setsP1++;
            } else {
              setsOpp++;
            }
            setEnded = true;

            int setsToWin = preset.setsToWin;
            if (setsP1 == setsOpp &&
                setsToWin - setsP1 == 1 &&
                preset.useMatchTiebreak) {
              isTiebreak = true;
              tiebreakTarget = preset.matchTiebreakTo;
            }
          }
        }
      }

      // --- 3. STORE DATA STRUCTURES ---
      if (gameEnded) {
        currentSetGames.add(
          MatchGame.create(
            points: List.from(currentGamePoints),
            isTiebreak:
                setEnded && (gamesP1 + gamesOpp > 10), // Simple tiebreak check
          ),
        );
        currentGamePoints.clear();
        gamePointsP1 = 0;
        gamePointsOpp = 0;
      }

      if (setEnded) {
        allSets.add(MatchSet.create(games: List.from(currentSetGames)));
        currentSetGames.clear();
        gamesP1 = 0;
        gamesOpp = 0;
      }

      // --- 4. NAVIGATION STATE ---
      if (setsP1 >= preset.setsToWin || setsOpp >= preset.setsToWin) {
        currentActionState = MatchActionState.matchComplete;
        HapticFeedback.vibrate();
      } else {
        currentActionState = MatchActionState.serving;
      }

      lastPointType = PointType.normal;
    });
  }

  void _updateLastPointMetadata({PointType? type, String? outcome}) {
    if (currentGamePoints.isEmpty) return;

    setState(() {
      int lastIdx = currentGamePoints.length - 1;

      currentGamePoints[lastIdx] = currentGamePoints[lastIdx].copyWith(
        type: type,
        shotOutcome: outcome,
      );
    });
  }

  void _rotateServer() {
    serverName = (serverName == widget.localPlayerName)
        ? widget.opponentName
        : widget.localPlayerName;
  }
}

// ignore: must_be_immutable
class ScoreRow extends StatelessWidget {
  final String shortName;
  int sets;
  int games;
  String points;

  ScoreRow({
    super.key,
    required this.shortName,
    required this.sets,
    required this.games,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    // Style for the 'shortName' text (P or B)
    final textStyle = GoogleFonts.outfit(
      color: Colors.white,
      fontWeight: FontWeight.w800,
      fontSize: 22,
      fontFeatures: [const FontFeature.tabularFigures()],
    );

    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        SizedBox(width: 30, child: Text(shortName, style: textStyle)),
        const SizedBox(width: 12),
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // The main capsule container (Sets and Games)
              Container(
                height: 50,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colors.background,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: const Color(0xFF262626), // Very dark border
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(sets.toString(), style: textStyle),
                      const SizedBox(width: 4),
                      Text(
                        '|',
                        style: textStyle.copyWith(color: Colors.grey[700]),
                      ),
                      const SizedBox(width: 4),
                      Text(games.toString(), style: textStyle),
                    ],
                  ),
                ),
              ),
              // The Points score (floating on the right)
              Positioned(
                right: 20,
                child: Text(
                  points.toString(),
                  style: textStyle.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class TextActionButton extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;
  final Color? borderColor;
  final TextStyle style;
  final VoidCallback onPressed;

  const TextActionButton({
    super.key,
    required this.text,
    required this.color,
    required this.textColor,
    required this.onPressed,
    required this.style,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return OutlinedButton(
      onPressed: onPressed,
      style:
          OutlinedButton.styleFrom(
            // Ensure this is set to the solid color you want
            backgroundColor: color,
            // This handles the text and icon color
            foregroundColor: textColor,
            side: BorderSide(
              color: borderColor ?? colors.outlineVariant,
              width: 1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
            // Adding this ensures the button is opaque
            elevation: 0,
          ).copyWith(
            // Sometimes the theme forces overlay colors, this clears them
            overlayColor: WidgetStateProperty.all(
              textColor.withValues(alpha: 0.1),
            ),
          ),
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.outfit(
            color: textColor,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class PlaceholderButton extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback? onPressed;

  const PlaceholderButton({
    super.key,
    required this.text,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextActionButton(
      text: text,
      color: color,
      textColor: Colors.black,
      onPressed: onPressed ?? () {},
      style: GoogleFonts.outfit(fontSize: 22),
    );
  }
}
